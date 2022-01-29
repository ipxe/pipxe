FROM registry.fedoraproject.org/fedora-minimal:33

RUN microdnf update -y && microdnf install -y \
		binutils gcc gcc-aarch64-linux-gnu \
        iasl libuuid-devel make \
        mtools perl python subversion xz-devel tar git

WORKDIR /opt/build

ENV RASPI_VERSION=RPi4

COPY . /opt/build

CMD make RASPI_VERSION="${RASPI_VERSION}" all
