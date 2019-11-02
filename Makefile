FW_URL		:= https://github.com/raspberrypi/firmware/branches/stable/boot

EFI_BUILD	:= RELEASE
EFI_ARCH	:= AARCH64
EFI_TOOLCHAIN	:= GCC5
EFI_TIMEOUT	:= 3
EFI_FLAGS	:= --pcd=PcdPlatformBootTimeOut=$(EFI_TIMEOUT)
EFI_DSC		:= edk2-platforms/Platform/RaspberryPi/RPi3/RPi3.dsc
EFI_FD		:= Build/RPi3/$(EFI_BUILD)_$(EFI_TOOLCHAIN)/FV/RPI_EFI.fd

IPXE_CROSS	:= aarch64-linux-gnu-
IPXE_SRC	:= ipxe/src
IPXE_TGT	:= bin-arm64-efi/rpi.efi
IPXE_EFI	:= $(IPXE_SRC)/$(IPXE_TGT)

SDCARD_MB	:= 32
export MTOOLSRC	:= mtoolsrc

all : sdcard.img

submodules :
	git submodule update --init --recursive

firmware :
	if [ ! -e firmware ] ; then \
		$(RM) -rf firmware-tmp ; \
		svn export $(FW_URL) firmware-tmp && \
		mv firmware-tmp firmware ; \
	fi

efi : $(EFI_FD)

efi-basetools : submodules
	$(MAKE) -C edk2/BaseTools

$(EFI_FD) : submodules efi-basetools
	. ./edksetup.sh && \
	build -b $(EFI_BUILD) -a $(EFI_ARCH) -t $(EFI_TOOLCHAIN) \
		-p $(EFI_DSC) $(EFI_FLAGS)

ipxe : $(IPXE_EFI)

$(IPXE_EFI) : submodules
	$(MAKE) -C $(IPXE_SRC) CROSS=$(IPXE_CROSS) CONFIG=rpi $(IPXE_TGT)

sdcard.img : firmware efi ipxe
	truncate -s $(SDCARD_MB)M $@
	mpartition -I -c -b 32 -s 32 -h 64 -t $(SDCARD_MB) -a "z:"
	mformat -v "piPXE" "z:"
	mcopy -s $(sort $(filter-out firmware/kernel%,$(wildcard firmware/*))) "z:"
	mcopy config.txt $(EFI_FD) edk2/License.txt "z:"
	mmd "z:/efi" "z:/efi/boot"
	mcopy $(IPXE_EFI) "z:/efi/boot/bootaa64.efi"
	mcopy ipxe/COPYING* "z:"

update:
	git submodule foreach git pull origin master

tag :
	git tag v`git show -s --format='%ad' --date=short | tr -d -`

.PHONY : submodules firmware efi efi-basetools $(EFI_FD) ipxe $(IPXE_EFI) sdcard.img

clean :
	$(RM) -rf firmware Build sdcard.img
	if [ -d $(IPXE_SRC) ] ; then $(MAKE) -C $(IPXE_SRC) clean ; fi
