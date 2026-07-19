import tempfile
import unittest
from pathlib import Path

from app.tools.calibration import profile


class CalibrationProfileTests(unittest.TestCase):
    def test_new_profile_defaults_to_four_corner_mesh(self):
        data = profile.new_profile("studio_wall", "Studio Wall")

        self.assertEqual(data["schema"], profile.SCHEMA)
        self.assertEqual(data["warp"]["mesh_size"], [2, 2])
        self.assertEqual(len(data["warp"]["pins"]), 4)
        self.assertEqual(data["warp"]["pins"][0]["target"], [0.0, 0.0])
        self.assertEqual(data["warp"]["pins"][-1]["target"], [1919.0, 1079.0])
        self.assertEqual(profile.validate_profile(data), [])

    def test_dense_mesh_adds_interior_refinement_pin(self):
        data = profile.new_profile("studio_wall_refined", "Studio Wall Refined", mesh=(3, 3))

        self.assertEqual(data["warp"]["mesh_size"], [3, 3])
        self.assertEqual(len(data["warp"]["pins"]), 9)
        center = data["warp"]["pins"][4]
        self.assertEqual(center["id"], "r1_c1")
        self.assertEqual(center["role"], "interior")

    def test_profile_round_trips_as_yaml(self):
        data = profile.new_profile("portable_projector", "Portable Projector", mesh=(4, 3))

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "portable_projector.yaml"
            profile.save_profile(path, data)
            loaded = profile.load_profile(path)

        self.assertEqual(loaded["profile_id"], "portable_projector")
        self.assertEqual(loaded["warp"]["mesh_size"], [4, 3])
        self.assertEqual(profile.validate_profile(loaded), [])

    def test_validation_rejects_missing_pin(self):
        data = profile.new_profile("bad_profile", "Bad Profile", mesh=(3, 3))
        data["warp"]["pins"].pop()

        errors = profile.validate_profile(data)

        self.assertTrue(any("must contain 9 pins" in err for err in errors))


if __name__ == "__main__":
    unittest.main()
