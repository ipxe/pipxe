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

### SD Card

This configuration works with both, Raspberry Pi 3's and 4's. Select the
appropriate one for your hardware and write it onto any blank micro SD card.
Then insert the micro SD card into your Raspberry Pi and power it on. Within a
few seconds you should see iPXE appear and begin booting from the network.

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
mkdir -p $TFTP_ROOT_DIR/rpi4
mount -v -o offset=$OFFSET RPi4.img $TFTP_ROOT_DIR/rpi4
```

> You might need to mount the image with the correct permissions set. You can
> use `-o umask=$UMASK,gid=$GID,uid=$UID` to do so. If you are using `dnsmasq`
> with the TFTP option enable the command could look like this `mount -v -o
> offset=$OFFSET -o umask=022,gid=991,uid=994 RPi4.img $TFTP_ROOT_DIR`

Where:

* `$TFTP_ROOT_DIR` - The TFTP server directory.
* `$OFFSET` - Offset e.g. 16384

Now setup your DHCP server to let the Raspberry Pi perform its standard network
boot with the aforementioned TFTP server. If you boot your Raspberry Pi right
away and look at the DHCP and TFTP servers logs you should see the following:

```log
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 available DHCP range: 10.42.0.101 -- 10.42.0.200
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 vendor class: PXEClient:Arch:00000:UNDI:002001
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 DHCPDISCOVER(enp0s31f6) e4:5f:01:09:02:f7
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 tags: known, baremetal-rpi-4b, enp0s31f6
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 DHCPOFFER(enp0s31f6) 10.42.0.111 e4:5f:01:09:02:f7
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 requested options: 1:netmask, 3:router, 43:vendor-encap, 60:vendor-class,
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 requested options: 66:tftp-server, 67:bootfile-name, 128, 129,
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 requested options: 130, 131, 132, 133, 134, 135
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 next server: 10.42.0.1
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 sent size:  1 option: 53 message-type  2
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 sent size:  4 option: 54 server-identifier  10.42.0.1
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 sent size:  4 option: 51 lease-time  6h
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 sent size:  4 option: 58 T1  3h
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 sent size:  4 option: 59 T2  5h15m
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 sent size:  4 option:  1 netmask  255.255.255.0
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 sent size:  4 option: 28 broadcast  10.42.0.255
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 sent size:  4 option:  3 router  10.42.0.1
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 sent size:  9 option: 60 vendor-class  50:58:45:43:6c:69:65:6e:74
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 sent size: 17 option: 97 client-machine-id  00:34:69:50:52:14:31:d0:00:01:09:02:f7:3d...
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 sent size: 32 option: 43 vendor-encap  06:01:03:0a:04:00:50:58:45:09:14:00:00:11...
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 available DHCP range: 10.42.0.101 -- 10.42.0.200
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 vendor class: PXEClient:Arch:00000:UNDI:002001
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 DHCPREQUEST(enp0s31f6) 10.42.0.111 e4:5f:01:09:02:f7
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 tags: known, baremetal-rpi-4b, enp0s31f6
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 DHCPACK(enp0s31f6) 10.42.0.111 e4:5f:01:09:02:f7
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 next server: 10.42.0.1
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 sent size:  1 option: 53 message-type  5
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 sent size:  4 option: 54 server-identifier  10.42.0.1
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 sent size:  4 option: 51 lease-time  6h
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 sent size:  4 option: 58 T1  3h
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 sent size:  4 option: 59 T2  5h15m
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 sent size:  4 option:  1 netmask  255.255.255.0
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 sent size:  4 option: 28 broadcast  10.42.0.255
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 sent size:  4 option:  3 router  10.42.0.1
Oct 21 12:08:16 dnsmasq-dhcp[19730]: 2713259800 sent size:  8 option:  6 dns-server  8.8.8.8, 8.8.4.4
Oct 21 12:08:16 dnsmasq-tftp[19730]: error 0 Early terminate received from 10.42.0.111
Oct 21 12:08:16 dnsmasq-tftp[19730]: sent /var/lib/tftpboot/91cdf03d/start4.elf to 10.42.0.111
Oct 21 12:08:16 dnsmasq-tftp[19730]: sent /var/lib/tftpboot/91cdf03d/config.txt to 10.42.0.111
Oct 21 12:08:16 dnsmasq-tftp[19730]: file /var/lib/tftpboot/91cdf03d/pieeprom.sig not found
Oct 21 12:08:16 dnsmasq-tftp[19730]: file /var/lib/tftpboot/91cdf03d/recover4.elf not found
Oct 21 12:08:16 dnsmasq-tftp[19730]: file /var/lib/tftpboot/91cdf03d/recovery.elf not found
Oct 21 12:08:18 dnsmasq-tftp[19730]: sent /var/lib/tftpboot/91cdf03d/start4.elf to 10.42.0.111
Oct 21 12:08:18 dnsmasq-tftp[19730]: sent /var/lib/tftpboot/91cdf03d/fixup4.dat to 10.42.0.111
Oct 21 12:08:18 dnsmasq-tftp[19730]: file /var/lib/tftpboot/91cdf03d/recovery.elf not found
Oct 21 12:08:18 dnsmasq-tftp[19730]: error 0 Early terminate received from 10.42.0.111
Oct 21 12:08:18 dnsmasq-tftp[19730]: sent /var/lib/tftpboot/91cdf03d/config.txt to 10.42.0.111
Oct 21 12:08:18 dnsmasq-tftp[19730]: sent /var/lib/tftpboot/91cdf03d/config.txt to 10.42.0.111
Oct 21 12:08:18 dnsmasq-tftp[19730]: file /var/lib/tftpboot/91cdf03d/dt-blob.bin not found
Oct 21 12:08:18 dnsmasq-tftp[19730]: file /var/lib/tftpboot/91cdf03d/recovery.elf not found
Oct 21 12:08:18 dnsmasq-tftp[19730]: error 0 Early terminate received from 10.42.0.111
Oct 21 12:08:18 dnsmasq-tftp[19730]: sent /var/lib/tftpboot/91cdf03d/config.txt to 10.42.0.111
Oct 21 12:08:18 dnsmasq-tftp[19730]: sent /var/lib/tftpboot/91cdf03d/config.txt to 10.42.0.111
Oct 21 12:08:19 dnsmasq-tftp[19730]: file /var/lib/tftpboot/91cdf03d/bootcfg.txt not found
Oct 21 12:08:19 dnsmasq-tftp[19730]: error 0 Early terminate received from 10.42.0.111
Oct 21 12:08:19 dnsmasq-tftp[19730]: failed sending /var/lib/tftpboot/91cdf03d/bcm2711-rpi-4-b.dtb to 10.42.0.111
Oct 21 12:08:19 dnsmasq-tftp[19730]: sent /var/lib/tftpboot/91cdf03d/bcm2711-rpi-4-b.dtb to 10.42.0.111
Oct 21 12:08:19 dnsmasq-tftp[19730]: error 0 Early terminate received from 10.42.0.111
Oct 21 12:08:19 dnsmasq-tftp[19730]: failed sending /var/lib/tftpboot/91cdf03d/overlays/overlay_map.dtb to 10.42.0.111
Oct 21 12:08:19 dnsmasq-tftp[19730]: sent /var/lib/tftpboot/91cdf03d/overlays/overlay_map.dtb to 10.42.0.111
Oct 21 12:08:19 dnsmasq-tftp[19730]: error 0 Early terminate received from 10.42.0.111
Oct 21 12:08:19 dnsmasq-tftp[19730]: sent /var/lib/tftpboot/91cdf03d/config.txt to 10.42.0.111
Oct 21 12:08:19 dnsmasq-tftp[19730]: sent /var/lib/tftpboot/91cdf03d/config.txt to 10.42.0.111
Oct 21 12:08:19 dnsmasq-tftp[19730]: error 0 Early terminate received from 10.42.0.111
Oct 21 12:08:19 dnsmasq-tftp[19730]: failed sending /var/lib/tftpboot/91cdf03d/overlays/mcp2515-can0.dtbo to 10.42.0.111
Oct 21 12:08:19 dnsmasq-tftp[19730]: sent /var/lib/tftpboot/91cdf03d/overlays/mcp2515-can0.dtbo to 10.42.0.111
Oct 21 12:08:19 dnsmasq-tftp[19730]: file /var/lib/tftpboot/91cdf03d/cmdline.txt not found
Oct 21 12:08:19 dnsmasq-tftp[19730]: file /var/lib/tftpboot/91cdf03d/recovery8.img not found
Oct 21 12:08:19 dnsmasq-tftp[19730]: file /var/lib/tftpboot/91cdf03d/kernel8.img not found
Oct 21 12:08:19 dnsmasq-tftp[19730]: error 0 Early terminate received from 10.42.0.111
Oct 21 12:08:19 dnsmasq-tftp[19730]: failed sending /var/lib/tftpboot/91cdf03d/RPI_EFI.fd to 10.42.0.111
Oct 21 12:08:19 dnsmasq-tftp[19730]: error 0 Early terminate received from 10.42.0.111
Oct 21 12:08:19 dnsmasq-tftp[19730]: failed sending /var/lib/tftpboot/91cdf03d/RPI_EFI.fd to 10.42.0.111
Oct 21 12:08:19 dnsmasq-tftp[19730]: error 0 Early terminate received from 10.42.0.111
Oct 21 12:08:19 dnsmasq-tftp[19730]: failed sending /var/lib/tftpboot/91cdf03d/RPI_EFI.fd to 10.42.0.111
Oct 21 12:08:20 dnsmasq-tftp[19730]: sent /var/lib/tftpboot/91cdf03d/RPI_EFI.fd to 10.42.0.111
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 available DHCP range: 10.42.0.101 -- 10.42.0.200
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 vendor class: PXEClient:Arch:00011:UNDI:003000
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 DHCPDISCOVER(enp0s31f6) e4:5f:01:09:02:f7
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 tags: known, pipxe, enp0s31f6
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 DHCPOFFER(enp0s31f6) 10.42.0.111 e4:5f:01:09:02:f7
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 requested options: 1:netmask, 2:time-offset, 3:router, 4, 5,
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 requested options: 6:dns-server, 12:hostname, 13:boot-file-size,
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 requested options: 15:domain-name, 17:root-path, 18:extension-path,
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 requested options: 22:max-datagram-reassembly, 23:default-ttl,
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 requested options: 28:broadcast, 40:nis-domain, 41:nis-server,
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 requested options: 42:ntp-server, 43:vendor-encap, 50:requested-address,
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 requested options: 51:lease-time, 54:server-identifier, 58:T1,
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 requested options: 59:T2, 60:vendor-class, 66:tftp-server, 67:bootfile-name,
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 requested options: 97:client-machine-id, 128, 129, 130, 131,
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 requested options: 132, 133, 134, 135
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 bootfile name: fcos.pxe
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 next server: 10.42.0.1
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 broadcast response
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 sent size:  1 option: 53 message-type  2
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 sent size:  4 option: 54 server-identifier  10.42.0.1
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 sent size:  4 option: 51 lease-time  6h
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 sent size:  4 option: 58 T1  3h
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 sent size:  4 option: 59 T2  5h15m
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 sent size:  4 option:  1 netmask  255.255.255.0
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 sent size:  4 option: 28 broadcast  10.42.0.255
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 sent size:  4 option:  3 router  10.42.0.1
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 sent size:  8 option:  6 dns-server  8.8.8.8, 8.8.4.4
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 sent size:  9 option: 60 vendor-class  50:58:45:43:6c:69:65:6e:74
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 sent size: 17 option: 97 client-machine-id  00:14:31:d0:00:00:00:00:00:00:00:e4:5f:01...
Oct 21 12:08:25 dnsmasq-dhcp[19730]: 2493352371 sent size: 10 option: 43 vendor-encap  06:01:08:0a:04:00:50:58:45:ff
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 available DHCP range: 10.42.0.101 -- 10.42.0.200
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 vendor class: PXEClient:Arch:00011:UNDI:003000
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 DHCPREQUEST(enp0s31f6) 10.42.0.111 e4:5f:01:09:02:f7
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 tags: known, pipxe, enp0s31f6
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 DHCPACK(enp0s31f6) 10.42.0.111 e4:5f:01:09:02:f7
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 requested options: 1:netmask, 2:time-offset, 3:router, 4, 5,
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 requested options: 6:dns-server, 12:hostname, 13:boot-file-size,
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 requested options: 15:domain-name, 17:root-path, 18:extension-path,
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 requested options: 22:max-datagram-reassembly, 23:default-ttl,
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 requested options: 28:broadcast, 40:nis-domain, 41:nis-server,
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 requested options: 42:ntp-server, 43:vendor-encap, 50:requested-address,
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 requested options: 51:lease-time, 54:server-identifier, 58:T1,
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 requested options: 59:T2, 60:vendor-class, 66:tftp-server, 67:bootfile-name,
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 requested options: 97:client-machine-id, 128, 129, 130, 131,
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 requested options: 132, 133, 134, 135
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 bootfile name: fcos.pxe
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 next server: 10.42.0.1
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 broadcast response
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 sent size:  1 option: 53 message-type  5
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 sent size:  4 option: 54 server-identifier  10.42.0.1
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 sent size:  4 option: 51 lease-time  6h
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 sent size:  4 option: 58 T1  3h
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 sent size:  4 option: 59 T2  5h15m
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 sent size:  4 option:  1 netmask  255.255.255.0
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 sent size:  4 option: 28 broadcast  10.42.0.255
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 sent size:  4 option:  3 router  10.42.0.1
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 sent size:  8 option:  6 dns-server  8.8.8.8, 8.8.4.4
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 sent size:  9 option: 60 vendor-class  50:58:45:43:6c:69:65:6e:74
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 sent size: 17 option: 97 client-machine-id  00:14:31:d0:00:00:00:00:00:00:00:e4:5f:01...
Oct 21 12:08:28 dnsmasq-dhcp[19730]: 2493352371 sent size: 10 option: 43 vendor-encap  06:01:08:0a:04:00:50:58:45:ff
Oct 21 12:08:28 dnsmasq-tftp[19730]: error 8 User aborted the transfer received from 10.42.0.111
Oct 21 12:08:28 dnsmasq-tftp[19730]: sent /var/lib/tftpboot/fcos.pxe to 10.42.0.111
Oct 21 12:08:28 dnsmasq-tftp[19730]: sent /var/lib/tftpboot/fcos.pxe to 10.42.0.111
```

In this case `$TFTP_ROOT` is set to `/var/lib/tftpboot/`, and the image is
mounted at `/var/lib/tftpboot/rpi4/` but still the Raspberry Pi is trying to
access `/var/lib/tftpboot/91cdf03d/*`. This is due to a limitation of the
implementation of the network boot process of the Raspberry Pi which always
tries to read files in a sub-directory equal to its serial number. `91cdf03d` is
the serial number of the Raspberry Pi trying to boot. Setting a boot file option
in DHCP does not work and is simply being ignored. Hence the only way, to
chainload iPXE is by setting a relative symbolic link to the directory:

```bash
cd $TFTP_ROOT
ln -s rpi4/ 91cdf03d
```

Once powered on the device will identify itself with vendor class
`PXEClient:Arch:00000:UNDI:002001` as shown in the log above. Different versions
of Raspberry Pi's might use different vendor classes at this stage. Make sure to
adapt it too your needs. Once the chainloading happened the device will identify
itself with the slightly different vendor class
`PXEClient:Arch:00011:UNDI:003000`. Use this to setup the iPXE process after
chainloading piPXE. A sample
[dnsmasq.conf](examples/rpi4/pxe-chainloading/dnsmasq.conf) can be found in the
examples directory.

> Even though the chainloading works is usage is quite limited, since as of now
> only HTTP and PXE protocols seem to work somehow. iPXE itself is not yet
> supported.

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
[RPi]:
    https://github.com/tianocore/edk2-platforms/tree/master/Platform/RaspberryPi/
