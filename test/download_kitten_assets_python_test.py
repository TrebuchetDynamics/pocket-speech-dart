import argparse
import pathlib
import tempfile
import unittest

from tool import download_kitten_assets as assets


class DownloadKittenAssetsTest(unittest.TestCase):
    def test_parse_models_accepts_multiple_and_rejects_unknown(self):
        self.assertEqual(assets.parse_models("mini, nano-fp32,mini"), ["mini", "nano-fp32"])
        with self.assertRaises(argparse.ArgumentTypeError):
            assets.parse_models("unknown")

    def test_download_verifies_existing_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = pathlib.Path(tmp) / "model.onnx"
            path.write_bytes(b"kitten")
            with self.assertRaises(RuntimeError):
                assets.download(path, "https://example.invalid", 6, "wrong")


if __name__ == "__main__":
    unittest.main()
