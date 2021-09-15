RASPI_VERSION	= RPi4

FW_URL			:= https://github.com/raspberrypi/firmware/branches/stable/boot
SHELL			:= /bin/bash
EFI_BUILD		:= RELEASE
EFI_ARCH		:= AARCH64
EFI_TOOLCHAIN	:= GCC5
EFI_TIMEOUT		:= 3
EFI_FLAGS		:= --pcd=PcdPlatformBootTimeOut=$(EFI_TIMEOUT)
EFI_DSC			:= edk2-platforms/Platform/RaspberryPi/$(RASPI_VERSION)/$(RASPI_VERSION).dsc
EFI_FD			:= Build/$(RASPI_VERSION)/$(EFI_BUILD)_$(EFI_TOOLCHAIN)/FV/RPI_EFI.fd

IPXE_CROSS		:= aarch64-linux-gnu-
IPXE_SRC		:= ipxe/src
IPXE_TGT		:= bin-arm64-efi/snp.efi
IPXE_EFI		:= $(IPXE_SRC)/$(IPXE_TGT)

SDCARD_MB		:= 32
export MTOOLSRC	:= mtoolsrc

all : sdcard sdcard.img sdcard.zip

submodules :
	git submodule update --init --recursive

patches :
	./patch.sh $(RASPI_VERSION)

firmware :
	if [ ! -e firmware ] ; then \
		$(RM) -rf firmware-tmp ; \
		svn export $(FW_URL) firmware-tmp && \
		mv firmware-tmp firmware ; \
	fi

efi : $(EFI_FD)

efi-basetools : submodules patches
	$(MAKE) -C edk2/BaseTools

$(EFI_FD) : submodules patches efi-basetools
	. ./edksetup.sh && \
	build -b $(EFI_BUILD) -a $(EFI_ARCH) -t $(EFI_TOOLCHAIN) \
		-p $(EFI_DSC) $(EFI_FLAGS)

ipxe : $(IPXE_EFI)

$(IPXE_EFI) : submodules patches
	$(MAKE) -C $(IPXE_SRC) CROSS=$(IPXE_CROSS) CONFIG=rpi $(IPXE_TGT)

sdcard : firmware efi ipxe
	$(RM) -rf sdcard
	mkdir -p sdcard
	cp -r $(sort $(filter-out firmware/kernel%,$(wildcard firmware/*))) \
		sdcard/
	cp config.txt $(EFI_FD) edk2/License.txt sdcard/
	mkdir -p sdcard/efi/boot
	cp $(IPXE_EFI) sdcard/efi/boot/bootaa64.efi
	cp ipxe/COPYING* sdcard/

sdcard.img : sdcard
	truncate -s $(SDCARD_MB)M $@
	mpartition -I -c -b 32 -s 32 -h 64 -t $(SDCARD_MB) -a "z:"
	mformat -v "piPXE" "z:"
	mcopy -s sdcard/* "z:"

sdcard.zip : sdcard
	$(RM) -f $@
	( pushd $< ; zip -q -r ../$@ * ; popd )

update :
	git -C edk2/ checkout $(shell curl --silent "https://api.github.com/repos/tianocore/edk2/releases/latest" | jq -r .tag_name)
	git -C edk2-non-osi/ pull origin master
	git -C edk2-platforms/ pull origin master
	git -C ipxe/ pull origin master

.PHONY : submodules patches firmware efi efi-basetools $(EFI_FD) ipxe $(IPXE_EFI) sdcard sdcard.img

clean :
	$(RM) -rf firmware Build sdcard sdcard.img sdcard.zip
	if [ -d $(IPXE_SRC) ] ; then $(MAKE) -C $(IPXE_SRC) clean ; fi
