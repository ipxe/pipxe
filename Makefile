WGET		:= wget --quiet --timestamping --continue

FWURL		:= https://raw.githubusercontent.com/raspberrypi/firmware
FWFILES		:= LICENCE.broadcom bootcode.bin

all : $(FWFILES)

$(FWFILES) :
	$(WGET) $(FWURL)/stable/boot/$@

.PHONY : $(FWFILES)

clean :
	$(RM) -f $(FWFILES)
