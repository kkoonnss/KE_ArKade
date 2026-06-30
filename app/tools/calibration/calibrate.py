import cv2
import numpy as np
import yaml
import sys
import os

def calibrate_manual(source_img_path, scene_dir):
    img = cv2.imread(source_img_path)
    if img is None:
        raise ValueError(f"Could not load {source_img_path}")
        
    clone = img.copy()
    src_points = []
    
    def select_point(event, x, y, flags, param):
        if event == cv2.EVENT_LBUTTONDOWN:
            if len(src_points) < 4:
                src_points.append((x, y))
                cv2.circle(clone, (x, y), 5, (0, 0, 255), -1)
                cv2.imshow("Select 4 source corners", clone)

    cv2.namedWindow("Select 4 source corners")
    cv2.setMouseCallback("Select 4 source corners", select_point)
    
    print("Click 4 corners in the source image (top-left, top-right, bottom-right, bottom-left). Press 'q' to quit early.")
    while True:
        cv2.imshow("Select 4 source corners", clone)
        key = cv2.waitKey(1) & 0xFF
        if len(src_points) == 4 or key == ord('q'):
            break
            
    cv2.destroyAllWindows()
    
    if len(src_points) != 4:
        print("Need exactly 4 points.")
        return
        
    h, w = img.shape[:2]
    tgt_points = [(0, 0), (w-1, 0), (w-1, h-1), (0, h-1)]
    
    H, _ = cv2.findHomography(np.array(src_points), np.array(tgt_points))
    warped = cv2.warpPerspective(img, H, (w, h))
    
    cv2.imshow("Warped Preview - Press 's' to save, 'q' to quit", warped)
    key = cv2.waitKey(0) & 0xFF
    cv2.destroyAllWindows()
    
    if key == ord('s'):
        calib_dir = os.path.join(scene_dir, 'calibration')
        os.makedirs(calib_dir, exist_ok=True)
        
        calib_data = {
            "schema": "calibration",
            "version": "1.0.0",
            "homography": H.tolist()
        }
        
        temp_file = os.path.join(calib_dir, 'temp.yaml')
        curr_file = os.path.join(calib_dir, 'current.yaml')
        
        with open(temp_file, 'w') as f:
            yaml.dump(calib_data, f)
            
        if os.path.exists(curr_file):
            os.replace(temp_file, curr_file)
        else:
            os.rename(temp_file, curr_file)
            
        print("Saved to", curr_file)
    else:
        print("Discarded.")

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python calibrate.py <source_image> <scene_dir>")
        sys.exit(1)
    calibrate_manual(sys.argv[1], sys.argv[2])
