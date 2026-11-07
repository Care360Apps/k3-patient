"""Source-independent tests for Care360 16 KiB ELF and APK/AAB scanning."""
import importlib.util
from pathlib import Path
import struct
import tempfile
import unittest
import zipfile

source = Path(__file__).with_name("k3_android_native_page_alignment.py")
spec = importlib.util.spec_from_file_location("k3_android_native_page_alignment", source)
native = importlib.util.module_from_spec(spec)
spec.loader.exec_module(native)


def synthetic_arm64_elf(alignment=16384, offset=0, vaddr=0):
    # Minimal ELF64 header with one PT_LOAD. No application code is included.
    elf = bytearray(120)
    elf[0:6] = b"\x7fELF\x02\x01"
    struct.pack_into("<H", elf, 16, 3)  # shared object
    struct.pack_into("<H", elf, 18, 183)  # AArch64
    struct.pack_into("<Q", elf, 32, 64)  # phoff
    struct.pack_into("<H", elf, 54, 56)  # phentsize
    struct.pack_into("<H", elf, 56, 1)  # phnum
    struct.pack_into("<IIQQQQQQ", elf, 64, 1, 5, offset, vaddr, 0, 0, 0, alignment)
    return bytes(elf)


class AndroidNativeAlignmentTests(unittest.TestCase):
    def test_good_arm64_16kb_segments(self):
        self.assertEqual(native.inspect_elf(synthetic_arm64_elf()), [])
        self.assertEqual(native.inspect_elf(synthetic_arm64_elf(65536)), [])

    def test_4kb_sdk_is_rejected(self):
        errors = native.inspect_elf(synthetic_arm64_elf(4096))
        self.assertTrue(any("below 16 KiB" in e for e in errors))

    def test_page_offsets_require_congruence(self):
        errors = native.inspect_elf(synthetic_arm64_elf(16384, 0, 4096))
        self.assertTrue(any("do not align" in e for e in errors))

    def test_missing_elf_or_truncated_headers_fail_closed(self):
        for bad in (b"not an ELF", b"\x7fELF", synthetic_arm64_elf()[:80]):
            with self.subTest(blob=bad[:8]), self.assertRaises(native.AlignmentError):
                native.inspect_elf(bad)

    def test_zip_scan_in_apk_and_app_bundle(self):
        with tempfile.TemporaryDirectory() as folder:
            for name, prefix in (
                ("fixture.apk", "lib/arm64-v8a/"),
                ("fixture.aab", "base/lib/arm64-v8a/"),
            ):
                path = Path(folder) / name
                with zipfile.ZipFile(path, "w") as archive:
                    archive.writestr(prefix + "libcare360.so", synthetic_arm64_elf())
                count, errors = native.inspect_archive(path)
                self.assertEqual(count, 1)
                self.assertEqual(errors, [])
                with zipfile.ZipFile(path, "w") as archive:
                    archive.writestr(prefix + "libcare360.so", synthetic_arm64_elf(4096))
                count, errors = native.inspect_archive(path)
                self.assertEqual(count, 1)
                self.assertEqual(len(errors), 1)

    def test_wrong_architecture_is_not_accepted(self):
        elf = bytearray(synthetic_arm64_elf())
        struct.pack_into("<H", elf, 18, 62)  # x86-64
        with self.assertRaises(native.AlignmentError):
            native.inspect_elf(bytes(elf))


if __name__ == "__main__":
    unittest.main()
