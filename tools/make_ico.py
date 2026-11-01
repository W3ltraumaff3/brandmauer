"""Packs PNG renders of icon.svg into a Windows .ico (PNG-compressed entries).

Usage: python tools/make_ico.py <png_dir> <out.ico>
Run tools/render_icon.gd first to create icon_16/32/48/256.png.
"""
import struct
import sys
from pathlib import Path


def main() -> None:
	png_dir, out = Path(sys.argv[1]), Path(sys.argv[2])
	sizes = [16, 32, 48, 256]
	blobs = [(png_dir / f"icon_{s}.png").read_bytes() for s in sizes]
	header = struct.pack("<HHH", 0, 1, len(sizes))
	offset = 6 + 16 * len(sizes)
	entries = b""
	for size, blob in zip(sizes, blobs):
		dim = 0 if size == 256 else size
		entries += struct.pack("<BBBBHHII", dim, dim, 0, 0, 1, 32, len(blob), offset)
		offset += len(blob)
	out.write_bytes(header + entries + b"".join(blobs))
	print(f"wrote {out} ({out.stat().st_size} bytes)")


if __name__ == "__main__":
	main()
