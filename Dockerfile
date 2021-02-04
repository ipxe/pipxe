FROM fedora:32

RUN dnf update -y \
    && dnf install -y \
	binutils \
	gcc \
	gcc-aarch64-linux-gnu \
	git-core \
	iasl \
	libuuid-devel \
	make \
	mtools \
	perl \
	python \
	subversion \
	xz-devel \
    && dnf clean all

RUN mkdir -p /opt/build

COPY . /opt/build

CMD make -C /opt/build
