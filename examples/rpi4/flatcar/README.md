# Flatcar Container Linux

Download the desired `arm64` version of Flatcar Container Linux from the
[offical mirror](https://kinvolk.io/flatcar-container-linux/releases/). You will
need the following files:

* flatcar_production_pxe_image.cpio.gz
* flatcar_production_pxe_image.cpio.gz.sig
* flatcar_production_pxe.vmlinuz
* flatcar_production_pxe.vmlinuz.sig

Make sure that the `*.sig` file content matches the signature of the other
corresponding files.

Now, place all files above and [flatcar.ipxe](flatcar.ipxe) in the root
directory of your `tftp` server. Also prepare your `dhcp` and `tftp` servers
accordingly, so that the Raspberry Pi once booted loads
[flatcar.ipxe](flatcar.ipxe).

Then follow the steps described [here](../../../README.md#use) and finally power
on your Raspberry Pi.
