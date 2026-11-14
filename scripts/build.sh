#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="${BUILD_DIR:-$ROOT/.build}"
SRC="$WORK/android_kernel_sony_sdm845"
KSU_TAG="v3.4.0-legacy-susfs-v2"
KERNEL_COMMIT="1a8fc01dce4296fc3d5437dc4f2a713ecec621e9"
BASE_BOOT="$ROOT/base/boot-lineage-22.2-xz3.img"

mkdir -p "$WORK" "$ROOT/dist"
rm -rf "$SRC"
git clone --filter=blob:none --no-checkout https://github.com/LineageOS/android_kernel_sony_sdm845.git "$SRC"
git -C "$SRC" fetch --depth=1 origin "$KERNEL_COMMIT"
git -C "$SRC" checkout --detach FETCH_HEAD
git -C "$SRC" apply "$ROOT/patches/0001-kernel-ksunext-susfs.patch"

git clone --depth=1 --branch "$KSU_TAG" https://github.com/sidex15/KernelSU-Next.git "$SRC/KernelSU-Next"
git -C "$SRC/KernelSU-Next" apply "$ROOT/patches/0002-ksunext-runtime-fixes.patch"
ln -s ../KernelSU-Next/kernel "$SRC/drivers/kernelsu"

make -C "$SRC" O="$SRC/out" ARCH=arm64 \
  CROSS_COMPILE=aarch64-linux-gnu- \
  CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
  tama_akatsuki_defconfig

make -C "$SRC" O="$SRC/out" ARCH=arm64 \
  CROSS_COMPILE=aarch64-linux-gnu- \
  CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
  KALLSYMS_EXTRA_PASS=1 -j"$(nproc)" Image.gz-dtb dtbs

KERNEL_IMAGE="$SRC/out/arch/arm64/boot/Image.gz-dtb"
test -s "$KERNEL_IMAGE"
test -s "$BASE_BOOT"
cp "$KERNEL_IMAGE" "$ROOT/dist/Image.gz-dtb"
python3 "$ROOT/scripts/package_boot.py" \
  --base-boot "$BASE_BOOT" \
  --kernel "$KERNEL_IMAGE" \
  --output "$ROOT/dist/boot.img" \
  --work "$WORK/boot"
git -C "$SRC" rev-parse HEAD > "$ROOT/dist/kernel-source-commit.txt"
git -C "$SRC/KernelSU-Next" rev-parse HEAD > "$ROOT/dist/ksunext-commit.txt"
echo "Built $ROOT/dist/boot.img"
