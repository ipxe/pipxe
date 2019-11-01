WGET		:= wget --quiet --timestamping --continue

FWURL		:= https://raw.githubusercontent.com/raspberrypi/firmware
FWFILES		:= LICENCE.broadcom bootcode.bin

EFI_BUILD	:= RELEASE
EFI_ARCH	:= AARCH64
EFI_TOOLCHAIN	:= GCC5
EFI_TIMEOUT	:= 3
EFI_FLAGS	:= --pcd=PcdPlatformBootTimeOut=$(EFI_TIMEOUT)
EFI_DSC		:= edk2-platforms/Platform/RaspberryPi/RPi3/RPi3.dsc
EFI_FD		:= Build/RPi3/$(EFI_BUILD)_$(EFI_TOOLCHAIN)/FV/RPI_EFI.fd

all : submodules fwfiles efi

submodules :
	git submodule update --init --recursive

fwfiles : $(FWFILES)

$(FWFILES) :
	$(WGET) $(FWURL)/stable/boot/$@

efi : $(EFI_FD)

efi-basetools : submodules
	$(MAKE) -C edk2/BaseTools

$(EFI_FD) : submodules efi-basetools
	. ./edksetup.sh && \
	build -b $(EFI_BUILD) -a $(EFI_ARCH) -t $(EFI_TOOLCHAIN) \
		-p $(EFI_DSC) $(EFI_FLAGS)

.PHONY : submodules fwfiles $(FWFILES) efi efi-basetools $(EFI_FD)

clean :
	$(RM) -f $(FWFILES) Build
