#!/usr/bin/env python3
"""Check native ELF PT_LOAD segment alignment for 16 KiB Android page sizes.

This is a *static* ARM64 ABI check, not a substitute for installing a
release-generated Play APK on a real/emulated 16 KiB page-size device.

Examples:
  python3 tools/k3_android_native_page_alignment.py build/app/outputs/flutter-apk/app-debug.apk
  python3 tools/k3_android_native_page_alignment.py build/app/outputs/bundle/release/app-release.aab

No API keys, keystores, patient records, uploads or network operations.
"""
import argparse
from pathlib import Path
import struct
import sys
import zipfile

PAGE = 16384
PT_LOAD = 1
ELF_MAGIC = b"\x7fELF"
ARM64 = 183


class AlignmentError(ValueError):
    pass


def inspect_elf(blob: bytes) -> list[str]:
    """Return ELF alignment failures without exposing any binary data."""
    if len(blob) < 64 or blob[:4] != ELF_MAGIC:
        raise AlignmentError("not a complete ELF header")
    elf_class, encoding = blob[4], blob[5]
    if elf_class != 2 or encoding not in (1, 2):
        raise AlignmentError("expected 64-bit ELF with supported endianness")
    endian = "<" if encoding == 1 else ">"
    (machine,) = struct.unpack_from(endian + "H", blob, 18)
    if machine != ARM64:
        raise AlignmentError("expected AArch64 native code")
    ph_offset = struct.unpack_from(endian + "Q", blob, 32)[0]
    ph_entry_size, ph_count = struct.unpack_from(endian + "HH", blob, 54)
    if ph_count == 0 or ph_count == 0xFFFF or ph_entry_size < 56:
        raise AlignmentError("missing or invalid program header table")
    if ph_offset + ph_entry_size * ph_count > len(blob):
        raise AlignmentError("truncated program header table")
    result: list[str] = []
    found_load = False
    for index in range(ph_count):
        base = ph_offset + index * ph_entry_size
        (kind, _, offset, vaddr, _, _, _, align) = struct.unpack_from(
            endian + "IIQQQQQQ", blob, base)
        if kind != PT_LOAD:
            continue
        found_load = True
        if align < PAGE or align & (align - 1):
            result.append(f"PT_LOAD #{index}: alignment {align} is below 16 KiB or not a power of two")
        if (vaddr - offset) % PAGE != 0:
            result.append(f"PT_LOAD #{index}: file and virtual-address offsets do not align to 16 KiB")
    if not found_load:
        raise AlignmentError("ELF has no PT_LOAD segments")
    return result


def inspect_archive(path: Path) -> tuple[int, list[str]]:
    if path.suffix not in (".apk", ".aab"):
        raise AlignmentError("provide an APK or AAB; a debug APK is not a Play release")
    total = 0
    problems: list[str] = []
    prefix = "lib/arm64-v8a/" if path.suffix == ".apk" else "base/lib/arm64-v8a/"
    with zipfile.ZipFile(path) as archive:
        entries = [
            entry for entry in archive.infolist()
            if entry.filename.startswith(prefix)
            and entry.filename.endswith(".so")
            and not entry.is_dir()
        ]
        if not entries:
            raise AlignmentError("no ARM64 native libraries found; confirm archive architecture")
        for entry in entries:
            total += 1
            try:
                # Keep the scan bounded; SDK .so files must not exhaust CI memory.
                if entry.file_size > 160 * 1024 * 1024:
                    raise AlignmentError("native library exceeds the size inspection limit")
                blob = archive.read(entry)
                failures = inspect_elf(blob)
                problems.extend(f"{entry.filename}: {msg}" for msg in failures)
            except (AlignmentError, struct.error) as exc:
                problems.append(f"{entry.filename}: {exc}")
    return total, problems


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("archive", type=Path)
    args = parser.parse_args()
    try:
        n, problems = inspect_archive(args.archive)
    except (AlignmentError, OSError, zipfile.BadZipFile) as exc:
        print(f"Care360 16 KiB Android ELF check BLOCKED: {exc}", file=sys.stderr)
        return 2
    print(f"Checked {n} ARM64 native libraries for 16 KiB PT_LOAD compatibility.")
    if problems:
        for problem in problems:
            print(f"FAIL: {problem}")
        print("Release blocked: upgrade/rebuild incompatible native SDKs and retest.")
        return 1
    print("PASS: ARM64 ELF load segments meet static 16 KiB alignment requirements.")
    print("Still required: AAB zip page alignment verification and 16 KiB device runtime smoke test.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
