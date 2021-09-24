# Fedora CoreOS

First, navigate to this directory and download the latest stable `aarch64`
version of Fedora CoreOS.

```bash
podman run --privileged --pull=always --rm -v ./:/data -w /data quay.io/coreos/coreos-installer:release download -f pxe --architecture aarch64
# use default names
mv fedora-coreos-*-live-initramfs.aarch64.img fedora-coreos-live-initramfs.aarch64.img
mv fedora-coreos-*-live-rootfs.aarch64.img fedora-coreos-live-rootfs.aarch64.img
mv fedora-coreos-*-live-kernel-aarch64 fedora-coreos-live-kernel-aarch64.gz 
# piPXE uses EFI which only supports uncompressed kernel artifacts
gzip -d fedora-coreos-live-kernel-aarch64.gz 
```

Then check that [fake-cpuinfo](fake-cpuinfo) content is equal to your devices
specifications for `Revision` that is usually stored in `/proc/cpuinfo` when
using Raspbian.

Now render the ignition file:

```bash
podman run --rm -v ./:/data:z quay.io/coreos/fcct:v0.13.1 --pretty --strict -d /data/ /data/fcos.fcc -o /data/fcos.ign
podman run --rm -i quay.io/coreos/ignition-validate:v2.12.0 - < ./fcos.ign
```

Now, place [fcos.ipxe](fcos.ipxe) in the root directory of your `tftp` server.
Then move all downloaded files and `fcos.ign` to your HTTP servers root
directory. Finally, prepare your `http`, `dhcp` and `tftp` servers accordingly,
so that the Raspberry Pi once booted loads [fcos.ipxe](fcos.ipxe) and has access
to all artifacts.

Then follow the steps described [here](../../../README.md#use) and finally power
on your Raspberry Pi.
