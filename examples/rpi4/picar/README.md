# piCar

Download the desired version of piCar by following the instructions provided
[here](https://github.com/raballew/picar/blob/main/README.md). You will need the
following files:

* flatcar_production_pxe_image.cpio.gz
* flatcar_production_pxe.vmlinuz

Now, place all files above and [picar.ipxe](picar.ipxe) in the root directory of
your `tftp` server. Also prepare your `dhcp` and `tftp` servers accordingly, so
that the Raspberry Pi once booted loads [picar.ipxe](picar.ipxe).

Then follow the steps described [here](../../../README.md#use) and finally power
on your Raspberry Pi.
