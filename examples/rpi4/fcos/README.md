# Fedora CoreOS

First, navigate to this directory and download the latest stable `aarch64`
version of Fedora CoreOS.

```bash
podman run --pull=always --rm -v ${PWD}:/data -w /data quay.io/coreos/coreos-installer:release download -f pxe --architecture aarch64
# use static names
mv fedora-coreos-*-live-initramfs.aarch64.img fedora-coreos-live-initramfs.aarch64.img
mv fedora-coreos-*-live-rootfs.aarch64.img fedora-coreos-live-rootfs.aarch64.img
mv fedora-coreos-*-live-kernel-aarch64 fedora-coreos-live-kernel-aarch64.gz
```

Now, place [fcos.ipxe](fcos.ipxe) in the root directory of your `tftp` server.
Then move all downloaded files to your HTTP servers root directory. Finally,
prepare your `http`, `dhcp` and `tftp` servers accordingly, so that the
Raspberry Pi once booted loads [fcos.ipxe](fcos.ipxe) and has access to all
artifacts.

Then follow the steps described [here](../../../README.md#use) and finally power
on your Raspberry Pi.

## kmods via Containers

First create a base ignition config that you'd like to use. It will contain the
ssh pub key to add to the authorized keys file for the core user and also a
systemd unit (`require-simple-kmod.service` that requires
`kmods-via-containers@simple-kmod.service`. The systemd unit is a workaround for
a an [upstream bug](https://github.com/coreos/ignition/issues/586) and makes
sure the `kmods-via-containers@simple-kmod.service` gets started on boot.

```bash
podman run -i --rm quay.io/coreos/butane:release --pretty --strict < base.bu > base.ign
```

Next we will create a fakeroot directory and populate it with files that we want
to deliver via Ignition:

```bash
FAKEROOT=$(mktemp -d)
cd kmods-via-containers
make install DESTDIR=${FAKEROOT}/usr/local CONFDIR=${FAKEROOT}/etc/
cd ..
cd kvc-simple-kmod
make install DESTDIR=${FAKEROOT}/usr/local CONFDIR=${FAKEROOT}/etc/
cd ..
```

Now we will use a tool called the filetranspiler to generate a final Ignition
config given the base ignition config and the fakeroot directory with files we
would like to deliver:

```bash
cd filetranspiler
make container
cd ..
podman run --rm -ti -v ${PWD}:/srv:z -v ${FAKEROOT}:/fakeroot:z localhost/filetranspiler:latest -i base.ign -f /fakeroot > fcos.ign
```

Now we can use this ignition config to start a Fedora CoreOS or RHEL CoreOS node
and see the `kmods-via-containers@simple-kmod.service` and the kernel modules
associated with `simple-kmods` get loaded.

You can check the modules are loaded with:

```bash
lsmod | grep simple

simple_procfs_kmod     20480  0
simple_kmod            16384  0
```

[oras]: https://github.com/oras-project/oras
