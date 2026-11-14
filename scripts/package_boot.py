#!/usr/bin/env python3
"""Replace the kernel in an Android v1 boot image, preserving its ramdisk/header."""
import argparse
import os
import struct
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-boot", required=True)
    parser.add_argument("--kernel", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--work", required=True)
    args = parser.parse_args()

    with open(args.base_boot, "rb") as f:
        data = f.read()
    if data[:8] != b"ANDROID!":
        raise SystemExit("Base image is not an Android boot image")
    fields = struct.unpack_from("<10I", data, 8)
    kernel_addr, ramdisk_addr, second_size = fields[1], fields[3], fields[4]
    tags_addr, page_size, header_version, os_word = fields[6], fields[7], fields[8], fields[9]
    if header_version != 1 or second_size:
        raise SystemExit("Expected a boot image v1 with no second-stage bootloader")

    board = data[48:64].split(b"\0", 1)[0].decode("ascii")
    cmdline = (data[64:576] + data[608:1632]).split(b"\0", 1)[0].decode("ascii")
    os_ver = os_word >> 11
    os_version = f"{(os_ver >> 14) & 0x7f}.{(os_ver >> 7) & 0x7f}.{os_ver & 0x7f}"
    patch = os_word & 0x7ff
    patch_level = f"{2000 + (patch >> 4)}-{patch & 0xf:02d}-01"

    os.makedirs(args.work, exist_ok=True)
    unpacked = os.path.join(args.work, "base")
    subprocess.run([
        sys.executable, os.path.join(os.path.dirname(__file__), "unpack_bootimg.py"),
        "--boot_img", args.base_boot, "--out", unpacked,
    ], check=True)

    command = [
        sys.executable, os.path.join(os.path.dirname(__file__), "mkbootimg.py"),
        "--kernel", args.kernel,
        "--ramdisk", os.path.join(unpacked, "ramdisk"),
        "--base", "0",
        "--kernel_offset", hex(kernel_addr),
        "--ramdisk_offset", hex(ramdisk_addr),
        "--tags_offset", hex(tags_addr),
        "--pagesize", str(page_size),
        "--header_version", str(header_version),
        "--os_version", os_version,
        "--os_patch_level", patch_level,
        "--board", board,
        "--cmdline", cmdline,
        "--output", args.output,
    ]
    subprocess.run(command, check=True)


if __name__ == "__main__":
    main()
