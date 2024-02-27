

## docker  build  -f Dockerfile  .  -t ipxe_pipxe_localbuild  --output "./" --target copytohost

## docker via podman
## docker  --cgroup-manager cgroupfs  build  -f Dockerfile  .  -t ipxe_pipxe_localbuild  --output "./" --target copytohost


## todo use volume map for build and output
## (untested) docker  build  -f Dockerfile  .  -v $(pwd):/opt/thisrepo  -t ipxe_pipxe_localbuild 



FROM ubuntu:22.04 as runner

RUN \
  apt update && \
  DEBIAN_FRONTEND=noninteractive  apt install -y --no-install-recommends \
    binutils \
    ca-certificates \
    gcc \
    g++ \
    git \
    make \
    python-is-python3 \
    python3

RUN \
  apt clean




## jammy's mtools (ver 4.0.32) has breaking bug; noble's (ver 4.0.43) works

## mtools hack (for ubuntu 22.04); set default apt release
ENV MTOOLS_UBUNTU_RELEASE_NAME=noble
RUN \
  cat <<EOFF > /etc/apt/apt.conf.d/01-default-release
APT
{
  Default-Release "jammy";
};
EOFF
RUN \
  cat <<EOFF >> /etc/apt/sources.list

## hack for mtools; add different source repo
deb http://security.ubuntu.com/ubuntu ${MTOOLS_UBUNTU_RELEASE_NAME} main
EOFF

## package pin for mtools to use different source repo
RUN \
  cat <<EOFF >> /etc/apt/preferences.d/01-mtools
Package: mtools
Pin: release n=${MTOOLS_UBUNTU_RELEASE_NAME}
Pin-Priority: 995
EOFF




## install packages
RUN apt update
RUN apt install -y -o Acquire::Retries=50 \
  gcc-aarch64-linux-gnu iasl mtools \
  lzma-dev uuid-dev zip




FROM runner as builder




## copy in repo
## improve? with mounting $(pwd):/opt/thisrepo
COPY . /opt/thisrepo




WORKDIR /opt/thisrepo




## run make: Sources (git)
RUN \
  make submodules

## run make: Sources (git sparce-checkout)
RUN \
  make firmware




FROM builder as build




## run make: Build (EFI)
RUN \
  make efi -e RPI_MAJ_VER=3

## run make: Build (iPXE)
RUN \
  make ipxe -j 4 -e RPI_MAJ_VER=3

## run make: SD card (rpi3)
RUN \
  make -e RPI_MAJ_VER=3

## run make: SD card (rpi4)
RUN \
  make -e RPI_MAJ_VER=4

RUN \
  chmod 666 sdcard_rpi*.*


FROM scratch as copytohost


COPY --link --from=build /opt/thisrepo/sdcard_rpi3.zip /outs/sdcard_rpi3.img
COPY --link --from=build /opt/thisrepo/sdcard_rpi3.zip /outs/sdcard_rpi3.zip

COPY --link --from=build /opt/thisrepo/sdcard_rpi4.zip /outs/sdcard_rpi4.img
COPY --link --from=build /opt/thisrepo/sdcard_rpi4.zip /outs/sdcard_rpi4.zip
