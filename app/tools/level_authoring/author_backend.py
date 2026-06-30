import cv2
import json
import numpy as np
import sys
import os
import argparse

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../..')))
try:
    from app.shared.palette import CLASSES
except ImportError:
    CLASSES = {0: {'name': 'empty', 'authoring_color': '#000000'}, 1: {'name': 'solid', 'authoring_color': '#FFFFFF'}}

def hex_to_bgr(hex_str):
    hex_str = hex_str.lstrip('#')
    return tuple(int(hex_str[i:i+2], 16) for i in (4, 2, 0))

class AuthoringBackend:
    def __init__(self, args_dict):
        self.args = args_dict
        
    def _class_id(self, class_name):
        for cid, info in CLASSES.items():
            if info["name"] == class_name:
                return cid
        return 0

    def _class_bgr(self, class_name):
        return hex_to_bgr(CLASSES[self._class_id(class_name)]["authoring_color"])

    def _paint_class_mask(self, map_bgr, mask, class_name):
        map_bgr[mask.astype(bool)] = self._class_bgr(class_name)

    def _edge_feature_mask(self, gray):
        blur_val = int(self.args.get("blur", 2)) * 2 + 1
        blurred = gray
        if blur_val > 1:
            blurred = cv2.GaussianBlur(gray, (blur_val, blur_val), 0)
        edges = cv2.Canny(
            blurred,
            int(self.args.get("canny_low", 50)),
            int(self.args.get("canny_high", 150))
        )
        morph_val = int(self.args.get("morph_dilate", 2))
        if morph_val > 0:
            kernel = np.ones((3, 3), np.uint8)
            edges = cv2.dilate(edges, kernel, iterations=morph_val)
            edges = cv2.erode(edges, kernel, iterations=max(1, morph_val // 2))
        min_area = int(self.args.get("min_contour_area", 100))
        mask = np.zeros_like(edges)
        contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        for cnt in contours:
            if cv2.contourArea(cnt) >= min_area:
                cv2.drawContours(mask, [cnt], -1, 255, -1)
                cv2.drawContours(mask, [cnt], -1, 255, thickness=2)
        
        if self.args.get("invert_mask", False):
            mask = cv2.bitwise_not(mask)
            
        return mask

    def _nearest_walkable_point(self, preferred, walk_mask):
        ys, xs = np.where(walk_mask)
        if len(xs) == 0:
            return None
        px, py = preferred
        dist = (xs - px) ** 2 + (ys - py) ** 2
        idx = int(np.argmin(dist))
        return int(xs[idx]), int(ys[idx])

    def _stamp_safe_class(self, map_bgr, class_name, preferred, walk_mask, radius):
        point = self._nearest_walkable_point(preferred, walk_mask)
        if point is None:
            return None
        cv2.circle(map_bgr, point, radius, self._class_bgr(class_name), -1)
        return point

    def _sample_walkable_points(self, walk_mask, count, min_spacing):
        ys, xs = np.where(walk_mask)
        if len(xs) == 0 or count <= 0:
            return []
        h, w = walk_mask.shape[:2]
        stride = max(1, len(xs) // max(1, count * 24))
        candidates = []
        for i in range(0, len(xs), stride):
            x = int(xs[i])
            y = int(ys[i])
            rank = abs(x - w * 0.5) + abs(y - h * 0.5)
            candidates.append((rank, x, y))
        candidates.sort()
        points = []
        min_spacing_sq = min_spacing * min_spacing
        for _, x, y in candidates:
            if all((x - px) ** 2 + (y - py) ** 2 >= min_spacing_sq for px, py in points):
                points.append((x, y))
                if len(points) >= count:
                    break
        return points

    def process(self):
        source_img_path = self.args.get("source_img_path")
        output_map_path = self.args.get("output_map_path")
        
        if not source_img_path or not output_map_path:
            raise ValueError("Missing source_img_path or output_map_path")
            
        source_img_bgr = cv2.imread(source_img_path)
        if source_img_bgr is None:
            raise ValueError(f"Could not read image: {source_img_path}")
            
        h, w = source_img_bgr.shape[:2]
        map_bgr = np.zeros((h, w, 3), dtype=np.uint8)

        gray = cv2.cvtColor(source_img_bgr, cv2.COLOR_BGR2GRAY)
        hsv = cv2.cvtColor(source_img_bgr, cv2.COLOR_BGR2HSV)
        hue = hsv[:, :, 0]
        sat = hsv[:, :, 1]
        val = hsv[:, :, 2]

        feature_mask = self._edge_feature_mask(gray)
        feature_density = int(self.args.get("feature_density", 55))
        if feature_density > 0:
            iterations = max(1, feature_density // 35)
            feature_mask = cv2.dilate(feature_mask, np.ones((3, 3), np.uint8), iterations=iterations)

        border_px = max(2, min(h, w) // 80)
        feature_mask[:border_px, :] = 255
        feature_mask[-border_px:, :] = 255
        feature_mask[:, :border_px] = 255
        feature_mask[:, -border_px:] = 255

        open_mask = feature_mask == 0
        walkable_bias = int(self.args.get("walkable_bias", 72))
        erode_steps = max(1, int((100 - walkable_bias) / 18) + 1)
        safe_walk = cv2.erode(open_mask.astype(np.uint8) * 255, np.ones((3, 3), np.uint8), iterations=erode_steps) > 0
        if np.count_nonzero(safe_walk) < (h * w * 0.08):
            safe_walk = open_mask

        # Start with empty class
        map_bgr[:] = self._class_bgr("empty")
        self._paint_class_mask(map_bgr, safe_walk, "path")
        self._paint_class_mask(map_bgr, feature_mask > 0, "solid")

        platform_strength = int(self.args.get("platform_bias", 45))
        if platform_strength > 0:
            sobel_y = cv2.Sobel(gray, cv2.CV_16S, 0, 1, ksize=3)
            horizontal = cv2.convertScaleAbs(sobel_y)
            threshold = max(35, 190 - platform_strength)
            _, platform_mask = cv2.threshold(horizontal, threshold, 255, cv2.THRESH_BINARY)
            kernel_w = max(9, w // 60)
            platform_mask = cv2.morphologyEx(platform_mask, cv2.MORPH_OPEN, np.ones((1, kernel_w), np.uint8))
            platform_mask = cv2.dilate(platform_mask, np.ones((2, 3), np.uint8), iterations=1)
            self._paint_class_mask(map_bgr, (platform_mask > 0) & open_mask, "platform_top")

        hazard_strength = int(self.args.get("hazard_density", 18))
        if hazard_strength > 0:
            warm_mask = (((hue < 18) | (hue > 165)) & (sat > 90) & (val > 80)) | ((hue > 18) & (hue < 36) & (sat > 90))
            if np.count_nonzero(warm_mask) < 20:
                hazard_band = np.zeros((h, w), dtype=bool)
                band_h = max(6, int(h * hazard_strength / 800.0))
                hazard_band[h - border_px - band_h:h - border_px, border_px:w - border_px] = True
                warm_mask = hazard_band
            self._paint_class_mask(map_bgr, warm_mask & safe_walk, "hazard")

        tracking_strength = int(self.args.get("tracking_ui_guide", 30))
        if tracking_strength > 0:
            dist = cv2.distanceTransform(safe_walk.astype(np.uint8), cv2.DIST_L2, 5)
            if float(dist.max()) > 0:
                cutoff = np.percentile(dist[dist > 0], max(55, 95 - tracking_strength // 2))
                tracking_mask = dist >= cutoff
                self._paint_class_mask(map_bgr, tracking_mask & safe_walk, "tracking")

        ui_safe_mask = np.zeros((h, w), dtype=bool)
        inset = max(8, int(min(h, w) * max(10, tracking_strength) / 1200.0))
        ui_safe_mask[:inset, :] = True
        ui_safe_mask[:, :inset] = True
        self._paint_class_mask(map_bgr, ui_safe_mask & open_mask, "ui_safe")

        pickup_strength = int(self.args.get("pickup_density", 45))
        pickup_count = max(0, int((pickup_strength / 100.0) * 18))
        pickup_radius = max(3, min(h, w) // 180)
        for point in self._sample_walkable_points(safe_walk, pickup_count, max(24, min(h, w) // 10)):
            cv2.circle(map_bgr, point, pickup_radius, self._class_bgr("pickup"), -1)

        stamp_radius = max(5, min(h, w) // 90)
        preset = self.args.get("preset", "Balanced Semantic")
        if preset == "Open Flow":
            spawn_pref = (int(w * 0.20), int(h * 0.55))
            goal_pref = (int(w * 0.80), int(h * 0.55))
        elif preset == "Vertical Surfaces":
            spawn_pref = (int(w * 0.18), int(h * 0.82))
            goal_pref = (int(w * 0.82), int(h * 0.18))
        else:
            spawn_pref = (int(w * 0.18), int(h * 0.72))
            goal_pref = (int(w * 0.82), int(h * 0.28))
            
        self._stamp_safe_class(map_bgr, "spawn", spawn_pref, safe_walk, stamp_radius)
        self._stamp_safe_class(map_bgr, "goal", goal_pref, safe_walk, stamp_radius)
        
        cv2.imwrite(output_map_path, map_bgr)
        from app.tools.arena_compiler.compile_level import compile_level
        derived = compile_level(output_map_path, authoring_profile=self._authoring_profile_data())
        return {"status": "success", "output": output_map_path, "derived": derived}

    def _authoring_profile_data(self):
        return {
            "schema": "authoring_profile",
            "version": "1.0.0",
            "preset": self.args.get("preset", "Balanced Semantic"),
            "intent": "neutral_semantic_assist",
            "cv": {
                "blur": int(self.args.get("blur", 2)),
                "canny_low": int(self.args.get("canny_low", 50)),
                "canny_high": int(self.args.get("canny_high", 150)),
                "morph_dilate": int(self.args.get("morph_dilate", 2)),
                "min_contour_area": int(self.args.get("min_contour_area", 100)),
                "invert_mask": bool(self.args.get("invert_mask", False)),
            },
            "semantic_assist": {
                "walkable_bias": int(self.args.get("walkable_bias", 72)),
                "feature_density": int(self.args.get("feature_density", 55)),
                "hazard_density": int(self.args.get("hazard_density", 18)),
                "pickup_density": int(self.args.get("pickup_density", 45)),
                "platform_bias": int(self.args.get("platform_bias", 45)),
                "tracking_ui_guide": int(self.args.get("tracking_ui_guide", 30)),
            },
        }

def main():
    parser = argparse.ArgumentParser(description="Authoring backend for CV level derivation")
    parser.add_argument("args_json", help="Path to JSON file containing arguments")
    args = parser.parse_args()
    
    with open(args.args_json, 'r') as f:
        args_dict = json.load(f)
        
    backend = AuthoringBackend(args_dict)
    try:
        result = backend.process()
        print(json.dumps(result))
    except Exception as e:
        print(json.dumps({"status": "error", "message": str(e)}))
        sys.exit(1)

if __name__ == '__main__':
    main()
