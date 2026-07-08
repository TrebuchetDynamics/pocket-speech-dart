import argparse
import pathlib
import tempfile
import unittest

from tool import download_kokoro_assets as assets


class DownloadKokoroAssetsTest(unittest.TestCase):
    def test_parse_voices_trims_and_rejects_empty(self):
        self.assertEqual(assets.parse_voices(' af_heart, ef_dora '), ['af_heart', 'ef_dora'])
        with self.assertRaises(argparse.ArgumentTypeError):
            assets.parse_voices(' , ')

    def test_sha256_and_report_include_size(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = pathlib.Path(tmp) / 'sample.bin'
            path.write_bytes(b'kokoro')

            self.assertEqual(
                assets.sha256_file(path),
                '1791019474d9bf5395919bfeda11bf46fd60579a5b6b43e6e4495731a397dc7d',
            )
            self.assertIn('6 bytes', assets.report(path))

    def test_download_rejects_wrong_size_without_network_when_file_exists(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = pathlib.Path(tmp) / 'model.onnx'
            path.write_bytes(b'x')

            with self.assertRaises(RuntimeError):
                assets.download(path, 'https://example.invalid/model.onnx', expected_size=2, force=False)


if __name__ == '__main__':
    unittest.main()
