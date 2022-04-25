# Flatcar Container Linux

Download the desired `arm64` version of Flatcar Container Linux from the
[official mirror](https://www.flatcar.org/). You will need the following
files:

* flatcar_production_pxe_image.cpio.gz
* flatcar_production_pxe.vmlinuz

Now, place all files above and [flatcar.ipxe](flatcar.ipxe) in the root
directory of your `tftp` server. Also prepare your `dhcp` and `tftp` servers
accordingly, so that the Raspberry Pi once booted loads
[flatcar.ipxe](flatcar.ipxe).

Then follow the steps described [here](../../../README.md#use) and finally power
on your Raspberry Pi.
