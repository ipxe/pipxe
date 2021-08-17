FROM docker.io/ubuntu:20.04

RUN apt update && \
	apt install -y -o Acquire::Retries=50 \
		build-essential gcc-aarch64-linux-gnu \
		git iasl lzma-dev mtools perl python \
		subversion uuid-dev zip unzip

WORKDIR /opt/build

ENV RASPI_VERSION=RPi4

COPY . /opt/build

CMD make RASPI_VERSION="${RASPI_VERSION}" all
