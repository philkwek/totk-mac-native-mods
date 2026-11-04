#!/usr/bin/env python3
"""Source-level checks for the overlay. No game data or keys are read."""
import json
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
UPSTREAM = ROOT / ".upstream"
PATCH = ROOT / "patches" / "0001-gameplay-switches.patch"
SERIES = ROOT / "patches" / "series"


class PatchSeries(unittest.TestCase):
    def test_series_lists_existing_patches(self):
        listed = [line.strip() for line in SERIES.read_text().splitlines()
                  if line.strip() and not line.lstrip().startswith("#")]
        self.assertTrue(listed)
        for name in listed:
            self.assertTrue((ROOT / "patches" / name).is_file(), name)

    def test_upstream_is_at_the_pinned_commit(self):
        data = json.loads((ROOT / "upstream.json").read_text())
        self.assertTrue((UPSTREAM / ".git").is_dir(),
                        "run scripts/bootstrap.sh first")
        head = subprocess.check_output(
            ["git", "-C", str(UPSTREAM), "rev-parse", "HEAD"], text=True).strip()
        self.assertEqual(head, data["commit"])

    def test_patch_mentions_all_four_switches(self):
        text = PATCH.read_text()
        for token in (
            "unlimited-durability.txt",
            "unlimited-health.txt",
            "unlimited-arrows.txt",
            "unlimited-battery.txt",
            "0x2393714",
            "0xb6b27c",
            "0x4646C60",
        ):
            self.assertIn(token, text)

    def test_applied_tree_has_the_switches(self):
        patches = (UPSTREAM / "games/totk/runtime/game_patches.c").read_text()
        panel = (UPSTREAM / "games/totk/runtime/settings_panel.h").read_text()
        for token in ("unlimited-arrows.txt", "unlimited-battery.txt",
                      "0x2393714", "0xb6b27c"):
            self.assertIn(token, patches)
        for token in ("Unlimited arrows", "Unlimited battery",
                      "unlimited-arrows.txt", "unlimited-battery.txt"):
            self.assertIn(token, panel)

    def test_no_game_data_in_the_patch(self):
        text = PATCH.read_text().lower()
        for forbidden in (".xci", ".nsp", ".keys", ".sav", ".bfttf",
                          "prod.keys", "romfs.bin"):
            self.assertNotIn(forbidden, text)


if __name__ == "__main__":
    unittest.main()
