# piPXE - iPXE for the Raspberry Pi

piPXE is a build of the [iPXE] network boot firmware for the [Raspberry].

## Learn More

How would you like to get started?

### Limitations

* Depending on your target, the patches described in [patch.sh](patch.sh) are
  applied
* If you target Raspberry Pi 4, you need to use an OS patched for direct memory
  access which in Linux, requires kernel 5.8 or later. This is the result of a
  hardware bug in the Broadcom CPU that powers the device.
* You will not get SD or wireless support in Linux, unless you use a recent
  Linux kernel (version 5.12 or later) or one into which the 5.12 fixes have
  been backported as well as a recent Linux wireless firmware package.

### How it works

The SD card image contains:

* [Firmware]: `bootcode.bin` and related files
* [EDK2] UEFI firmware built for the [RPi] platform: `RPI_EFI.fd`
* [iPXE] built for the `arm64-efi` platform: `/efi/boot/bootaa64.efi`

The Raspberry Pi has a somewhat convoluted boot process in which the VC4 GPU is
responsible for loading the initial executable ARM CPU code. The flow of
execution is approximately:

1. The GPU code in the onboard boot ROM loads `bootcode.bin` from the SD card.
2. The GPU executes `bootcode.bin` and loads `RPI_EFI.fd` from the SD card.
3. The GPU allows the CPU to start executing `RPI_EFI.fd`.
4. The CPU executes `RPI_EFI.fd` and loads `bootaa64.efi` from the SD card.
5. The CPU executes `bootaa64.efi` (i.e. iPXE) to boot from the network.

### Use

Download the disk image using [oras]:

```bash
podman run -it --rm -v $(pwd):/workspace:Z ghcr.io/oras-project/oras:v0.12.0 pull ghcr.io/raballew/pipxe/pipxe:${GIT_REVISION} -a
```

Where:

* `${GIT_REVISION}` -  Full `SHA-1 object name` from main branch, [SemVer]
  compliant `tag` or `latest`

You should now see a bunch of `*.img` files in your current working directory.

### PXE Chainloading

This configuration only works with Raspberry Pi 4's. In the EEPROM adjust the
[BOOT_ORDER
configuration](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#raspberry-pi-4-bootloader-configuration)
in the bootloader to include PXE booting from the network. Shut down your
Raspberry Pi.

First inspect the `RPi4.img`:

```bash
fdisk -l RPi4.img

Disk RPi4.img: 32 MiB, 33554432 bytes, 65536 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x00000000

Device     Boot Start   End Sectors Size Id Type
RPi4.img1  *       32 65535   65504  32M  6 FAT16
```

As shown above, each sectors has a size of 512 bytes and the position of the
start block is 32. Hence, the offset for mounting the image is 512 * 32 = 16384
bytes. Then mount the previously downloaded `RPi4.img` into your TFTP server
root directory.

```bash
mkdir -p $TFTP_ROOT_DIR
mount -v -o offset=$OFFSET RPi4.img $TFTP_ROOT_DIR
```

Where:

* `$TFTP_ROOT_DIR` - The TFTP server directory.
* `$OFFSET` - Offset e.g. 16384

Now setup your DHCP server to let the Raspberry Pi perform its standard network
boot with the aforementioned TFTP server. The device will identify itself with
vendor class `PXEClient:Arch:00000:UNDI:002001`. Different versions of Raspberry
Pi's might use different vendor classes at this stage. Make sure to adapt it too
your needs. Set the boot file to the built iPXE EFI firmware. This should be
located at `$TFTP_ROOT_DIR/efi/boot/bootaa64.efi`. Now the device will identify
itself with the slightly different vendor class
`PXEClient:Arch:00011:UNDI:003000`. Use this to setup the iPXE process after
chainloading piPXE. Power on your Raspberry Pi.

### SD Card

This configuration works with both, Raspberry Pi 3's and 4's. Select the
appropriate one for your hardware and write it onto any blank micro SD card.
Then insert the micro SD card into your Raspberry Pi and power it on. Within a
few seconds you should see iPXE appear and begin booting from the network.

### Develop

To build from source, clone this repository and run `make all`. This will build
all of the required components and eventually generate the SD card image.

You will need various build tools installed, including a cross-compiling version
of `gcc` for building AArch64 binaries. See the [Containerfile](Containerfile)
for hints on which packages to install. Or you might be to just build the disk
image locally in a container:

```bash
podman build -t localhost/pipxe -f Containerfile .
podman rm -i $(cat ${RASPI_VERSION}.cid)
rm ${RASPI_VERSION}.cid
podman run --cidfile ${RASPI_VERSION}.cid -e RASPI_VERSION=${RASPI_VERSION} -t localhost/pipxe
podman cp $(cat ${RASPI_VERSION}.cid):/opt/build/sdcard.img ${RASPI_VERSION}.img
```

Where:

* `${RASPI_VERSION}` - Either `RPi3` or `RPi4`

## Code of Conduct

The Rust [code of conduct](https://www.rust-lang.org/conduct.html) is adhered by
the piPXE project.

All contributors, community members, and visitors are expected to familiarize
themselves with the code of conduct and to follow these standards in all
piPXE-affiliated environments, which includes but is not limited to
repositories, chats, and meetup events.

## License

Every component is under an open source license. See the individual subproject
licensing terms for more details:

* <https://github.com/raspberrypi/firmware/blob/master/boot/LICENCE.broadcom>
* <https://github.com/tianocore/edk2/blob/master/License.txt>
* <https://ipxe.org/licensing>

[iPXE]: https://ipxe.org
[Raspberry]: https://www.raspberrypi.org
[oras]: https://github.com/oras-project/oras
[SemVer]: https://semver.org/
[Firmware]: https://github.com/raspberrypi/firmware/tree/master/boot
[EDK2]: https://github.com/tianocore/edk2
[RPi]: https://github.com/tianocore/edk2-platforms/tree/master/Platform/RaspberryPi/
