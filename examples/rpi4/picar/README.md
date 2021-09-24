# piCar

Download the desired version of piCar by following the instructions provided
[here](https://github.com/raballew/picar/blob/main/README.md). You will need the
following files:

* flatcar_production_pxe_image.cpio.gz
* flatcar_production_pxe.vmlinuz

Then check that the content of `/etc/fake-cpuinfo` in [picar.ign](picar.ign) is
equal to your devices specifications for `Revision` that is usually stored in
`/proc/cpuinfo` when using Raspbian.

Now, place all files above [picar.ipxe](picar.ipxe) and [picar.ign](picar.ign)
in the root directory of your `tftp` server. Also prepare your `dhcp` and `tftp`
servers accordingly, so that the Raspberry Pi once booted loads
[picar.ipxe](picar.ipxe).

Then follow the steps described [here](../../../README.md#use) and finally power
on your Raspberry Pi.
