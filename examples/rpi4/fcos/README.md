# Fedora CoreOS

First, navigate to this directory and download the latest stable `aarch64`
version of Fedora CoreOS.

```bash
podman run --pull=always --rm -v ${PWD}:/data -w /data quay.io/coreos/coreos-installer:release download -f pxe --architecture aarch64
# use static names
mv fedora-coreos-*-live-initramfs.aarch64.img fedora-coreos-live-initramfs.aarch64.img
mv fedora-coreos-*-live-rootfs.aarch64.img fedora-coreos-live-rootfs.aarch64.img
mv fedora-coreos-*-live-kernel-aarch64 fedora-coreos-live-kernel-aarch64.gz
# piPXE uses EFI which only supports uncompressed kernel artifacts
gzip -d fedora-coreos-live-kernel-aarch64.gz
```

Now, place [fcos.ipxe](fcos.ipxe) in the root directory of your `tftp` server.
Then move all downloaded files to your HTTP servers root directory. Finally,
prepare your `http`, `dhcp` and `tftp` servers accordingly, so that the
Raspberry Pi once booted loads [fcos.ipxe](fcos.ipxe) and has access to all
artifacts.

Then follow the steps described [here](../../../README.md#use) and finally power
on your Raspberry Pi.

[oras]: https://github.com/oras-project/oras
