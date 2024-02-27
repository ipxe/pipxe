
## make -e RPI_MAJ_VER=3 -e BOOTLOADER_FILENAME=embeded_bootloader.ipxe -e TRUST_FILES=example1.crt,example2.crt
## make -e RPI_MAJ_VER=4 -e BOOTLOADER_FILENAME=embeded_bootloader.ipxe -e TRUST_FILES=example1.crt,example2.crt


FW_REPO_URL	:= https://github.com/raspberrypi/firmware
FW_BRANCH	:= stable
FW_SUBDIR	:= boot

RPI_MAJ_VER	?= 4 # values: 3, 4 # influences IPXE_TGT and output img/zip names

EFI_BUILD	:= RELEASE
EFI_ARCH	:= AARCH64
EFI_TOOLCHAIN	:= GCC5
EFI_TIMEOUT	:= 3
EFI_FLAGS	:= --pcd=PcdPlatformBootTimeOut=$(EFI_TIMEOUT)

EFI_DSC		:= edk2-platforms/Platform/RaspberryPi/RPi$(RPI_MAJ_VER)/RPi$(RPI_MAJ_VER).dsc
EFI_FD		:= Build/RPi$(RPI_MAJ_VER)/$(EFI_BUILD)_$(EFI_TOOLCHAIN)/FV/RPI_EFI.fd

IPXE_CROSS	:= aarch64-linux-gnu-
IPXE_SRC	:= ipxe/src

ifeq ( $(RPI_MAJ_VER), 3 )
	IPXE_TGT	:= bin-arm64-efi/rpi.efi
else
	IPXE_TGT	:= bin-arm64-efi/snp.efi
endif

IPXE_EFI	:= $(IPXE_SRC)/$(IPXE_TGT)

SDCARD_MB	:= 32
export MTOOLSRC	:= mtoolsrc

SHELL		:= /bin/bash


## -e BOOTLOADER_FILENAME: example.ipxe # ipxe file to embed
ifdef BOOTLOADER_FILENAME
	arg_Bootloader_Filename := "EMBED=$(BOOTLOADER_FILENAME)"
endif

## -e TRUST_FILES: example1.crt,example2.crt # adds cert data
ifdef TRUST_FILES
	arg_Trust_Files := "TRUST=$(TRUST_FILES)"
endif




all : sdcard sdcard_rpi$(RPI_MAJ_VER).img sdcard_rpi$(RPI_MAJ_VER).zip




submodules :
	git submodule update --init --recursive -- #--force
#       git submodule update --remote --recursive --

## attempted sed to fix warnings when building older submodule commits
#_	sed -i -r 's@(-nostdlib)( -g)@\1 -Wno-vla-parameter -Wno-stringop-overflow -Wno-use-after-free -Wno-dangling-pointer\2@g'   edk2/BaseTools/Source/C/Makefiles/header.makefile ## compile time ignore more warnings




firmware :
	if [ ! -e firmware ] ; then \
		$(RM) -rf rpi_firmware ; \
		git clone --depth 1 --no-checkout --branch $(FW_BRANCH)  '$(FW_REPO_URL)'   rpi_firmware ; \
		cd rpi_firmware ; \
		git config core.sparseCheckout true ; \
		git sparse-checkout set $(FW_SUBDIR) ; \
		git checkout ; \
		cd - ; \
		mv rpi_firmware/$(FW_SUBDIR) firmware ; \
		$(RM) -rf rpi_firmware ; \
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
	$(MAKE) -C $(IPXE_SRC) CROSS=$(IPXE_CROSS) CONFIG=rpi $(arg_Bootloader_Filename) $(arg_Trust_Files) $(IPXE_TGT)


sdcard : firmware efi ipxe
	$(RM) -rf sdcard
	mkdir -p sdcard
	cp -r $(sort $(filter-out firmware/kernel%,$(wildcard firmware/*))) \
		sdcard/
	cp config.txt $(EFI_FD) edk2/License.txt sdcard/
	mkdir -p sdcard/efi/boot
	cp $(IPXE_EFI) sdcard/efi/boot/bootaa64.efi
	cp ipxe/COPYING* sdcard/


sdcard_rpi$(RPI_MAJ_VER).img : sdcard
	sed -r -i 's/(sdcard)(\.img)/\1_rpi'"$(RPI_MAJ_VER)"'\2/g' "$(MTOOLSRC)"
	truncate -s $(SDCARD_MB)M $@
	mpartition -I -c -b 32 -s 32 -h 64 -t $(SDCARD_MB) -a "z:"
	mformat -v "piPXE" "z:"
	mcopy -s sdcard/* "z:"



sdcard_rpi$(RPI_MAJ_VER).zip : sdcard
	$(RM) -f $@
	( pushd $< ; zip -q -r ../$@ * ; popd )


update:
	git submodule foreach git pull origin master


tag :
	git tag v`git show -s --format='%ad' --date=short | tr -d -`


.PHONY : submodules firmware efi efi-basetools $(EFI_FD) ipxe $(IPXE_EFI) \
	sdcard sdcard_rpi$(RPI_MAJ_VER).img tag update


clean :
	$(RM) -rf firmware rpi_firmware Build sdcard sdcard_rpi$(RPI_MAJ_VER).img sdcard_rpi$(RPI_MAJ_VER).zip
	if [ -d $(IPXE_SRC) ] ; then $(MAKE) -C $(IPXE_SRC) clean ; fi
