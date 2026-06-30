import unittest
import cv2
import numpy as np
import json
import os
import sys
import tempfile
import shutil

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../..')))
import app.tools.arena_compiler.compiler as comp
import app.tools.arena_compiler.derive.navgraph as nav
import app.tools.arena_compiler.derive.container as cont
from app.tools.arena_compiler.compile_level import DERIVED_FILES
from app.tools.arena_compiler.compile_level import compile_level

class TestArenaCompiler(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.test_dir = os.path.dirname(__file__)
        cls.goldens_dir = os.path.join(cls.test_dir, 'goldens')
        cls.source_path = os.path.join(cls.goldens_dir, 'test_source.png')
        cls.golden_sem = os.path.join(cls.goldens_dir, 'golden_semantic_map.png')
        cls.golden_nav = os.path.join(cls.goldens_dir, 'golden_navgraph.json')
        cls.golden_cont = os.path.join(cls.goldens_dir, 'golden_container.json')
        cls.golden_grid = os.path.join(cls.goldens_dir, 'golden_grid.json')
        cls.golden_occupancy = os.path.join(cls.goldens_dir, 'golden_occupancy.png')
        cls.golden_platform_edges = os.path.join(cls.goldens_dir, 'golden_platform_edges.json')
        cls.golden_track_centerline = os.path.join(cls.goldens_dir, 'golden_track_centerline.json')
        cls.golden_authoring_profile = os.path.join(cls.goldens_dir, 'golden_authoring_profile.json')
        
        cls._temp_dir_obj = tempfile.TemporaryDirectory()
        cls.temp_dir_path = cls._temp_dir_obj.name

    @classmethod
    def tearDownClass(cls):
        cls._temp_dir_obj.cleanup()

    def test_compile(self):
        out_path = os.path.join(self.temp_dir_path, 'out_semantic.png')
        comp.compile_map(self.source_path, out_path)
        
        out_img = cv2.imread(out_path)
        golden_img = cv2.imread(self.golden_sem)
        
        self.assertIsNotNone(out_img)
        self.assertIsNotNone(golden_img)
        
        diff = cv2.subtract(out_img, golden_img)
        self.assertEqual(np.count_nonzero(diff), 0, "Compiler output does not match golden image")
        
    def test_navgraph(self):
        out_path = os.path.join(self.temp_dir_path, 'out_navgraph.json')
        nav.extract_navgraph(self.golden_sem, out_path)
        
        with open(out_path, 'r') as f:
            out_data = json.load(f)
            
        with open(self.golden_nav, 'r') as f:
            golden_data = json.load(f)
            
        self.assertEqual(out_data, golden_data, "Navgraph output does not match golden JSON")
        
    def test_container(self):
        out_path = os.path.join(self.temp_dir_path, 'out_container.json')
        cont.extract_container(self.golden_sem, out_path)
        
        with open(out_path, 'r') as f:
            out_data = json.load(f)
            
        with open(self.golden_cont, 'r') as f:
            golden_data = json.load(f)
            
        self.assertEqual(out_data, golden_data, "Container output does not match golden JSON")

    def test_grid(self):
        import app.tools.arena_compiler.derive.grid as grid
        out_path = os.path.join(self.temp_dir_path, 'out_grid.json')
        grid.generate_grid(self.golden_sem, out_path, cell_px=32)
        
        with open(out_path, 'r') as f:
            out_data = json.load(f)
            
        with open(self.golden_grid, 'r') as f:
            golden_data = json.load(f)
            
        self.assertEqual(out_data, golden_data, "Grid output does not match golden JSON")

    def test_compile_level_full_derived_set(self):
        level_dir = os.path.join(self.temp_dir_path, 'fixture_level')
        os.makedirs(level_dir, exist_ok=True)
        shutil.copyfile(self.golden_sem, os.path.join(level_dir, 'semantic_map.png'))

        first = compile_level(level_dir)
        second = compile_level(level_dir)
        self.assertEqual([os.path.basename(path) for path in first["files"]], list(DERIVED_FILES))
        self.assertEqual(first["source_kind"], "semantic_map")
        self.assertEqual(second["source_kind"], "semantic_map")

        derived_dir = os.path.join(level_dir, 'derived')
        for filename in DERIVED_FILES:
            self.assertTrue(os.path.exists(os.path.join(derived_dir, filename)), f"Missing {filename}")

        json_goldens = {
            "navgraph.json": self.golden_nav,
            "container.json": self.golden_cont,
            "grid.json": self.golden_grid,
            "platform_edges.json": self.golden_platform_edges,
            "track_centerline.json": self.golden_track_centerline,
            "authoring_profile.json": self.golden_authoring_profile,
        }
        for filename, golden_path in json_goldens.items():
            with open(os.path.join(derived_dir, filename), 'rb') as f:
                out_bytes = f.read()
            with open(golden_path, 'rb') as f:
                golden_bytes = f.read()
            self.assertEqual(out_bytes, golden_bytes, f"{filename} bytes do not match golden")

        out_occ = cv2.imread(os.path.join(derived_dir, 'occupancy.png'), cv2.IMREAD_UNCHANGED)
        golden_occ = cv2.imread(self.golden_occupancy, cv2.IMREAD_UNCHANGED)
        self.assertIsNotNone(out_occ)
        self.assertIsNotNone(golden_occ)
        self.assertEqual(np.count_nonzero(cv2.subtract(out_occ, golden_occ)), 0)

if __name__ == '__main__':
    unittest.main()
