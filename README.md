# Xperia XZ3 KernelSU-Next + SUSFS

Builds the LineageOS 22.2 kernel for Xperia XZ3 (akatsuki / SDM845) with KernelSU-Next v3.4.0 and SUSFS v2.3.0. The source patches include the init.rc filtering, KernelSU boot hooks and the SELinux transition fix from the build that was reported working on-device.

## Build with GitHub Actions

1. Open **Actions → Build Xperia XZ3 boot image → Run workflow**.
2. Wait for the job to finish.
3. Download the `xz3-ksunext-susfs-boot` artifact. It contains `boot.img`, `Image.gz-dtb`, and the build log.

The workflow also runs on pushes to `main`. It starts from the pinned LineageOS kernel commit and the base boot image in `base/`.

## Build locally (Ubuntu 22.04)

Install `bc bison flex gcc-aarch64-linux-gnu gcc-arm-linux-gnueabi libelf-dev libncurses-dev libssl-dev make python3`, then run:

```bash
bash scripts/build.sh
```

The output is written to `dist/boot.img`.

## Device and image notes

- Device: Sony Xperia XZ3 (akatsuki), SDM845
- ROM base: LineageOS 22.2, Android 15
- Kernel source base: `LineageOS/android_kernel_sony_sdm845`, commit `1a8fc01dce4296fc3d5437dc4f2a713ecec621e9`
- KernelSU-Next: `sidex15/KernelSU-Next`, tag `v3.4.0-legacy-susfs-v2`
- KernelSU manager ABI tested: 33294 (v3.4.0)
- SUSFS: v2.3.0 (non-GKI)
- Hook mode: manual

The included `base/boot-lineage-22.2-xz3.img` supplies the LineageOS ramdisk and boot header used by the packaging step. Use the generated image only with the matching Xperia XZ3 LineageOS 22.2 installation. Keep a known-good boot image available for recovery.

## Source patches

- `patches/0001-kernel-ksunext-susfs.patch`: kernel SUSFS integration, KSU config, manual hooks and device build fixes.
- `patches/0002-ksunext-runtime-fixes.patch`: init.rc detection and init hook adjustments for this ROM's FBE boot sequence.

Kernel source retains its upstream GPL-2.0 license. KernelSU-Next and the boot image retain their respective upstream and ROM licenses.
