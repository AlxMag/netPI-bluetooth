#use fixed armv7hf compatible raspbian OS version from group resin.io as base image
FROM resin/armv7hf-debian:jessie-20171021

#enable building ARM container on x86 machinery on the web (comment out next 3 lines if built on Raspberry) 
ENV QEMU_EXECVE 1
COPY armv7hf-debian-qemu /usr/bin
RUN [ "cross-build-start" ]

#execute all commands as root
USER root

#labeling
LABEL maintainer="netpi@hilscher.com" \
      version="V1.1.0.0" \
      description="Debian with bluez protocol stack"

#version
ENV HILSCHERNETPI_BLUEZ_VERSION 1.1.0.0

#install prerequisites
RUN apt-get update  \
    && apt-get install -y openssh-server build-essential wget tar dbus \
       libical-dev libdbus-1-dev libglib2.0-dev libreadline-dev libudev-dev \
    && echo 'root:root' | chpasswd \
    && sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd \
    && mkdir /var/run/sshd \
    # && sed -i -e 's;Port 22;Port 23;' /etc/ssh/sshd_config \ #Comment in if other SSH port (22->23) is needed 
    && rm -rf /var/lib/apt/lists/*

#define bluez version
ENV BLUEZ_VERSION 5.47 

#get BCM firmware and bluez source and compile it
RUN mkdir /etc/firmware \
    && curl -o /etc/firmware/BCM43430A1.hcd -L https://github.com/OpenELEC/misc-firmware/raw/master/firmware/brcm/BCM43430A1.hcd \
    && cd /tmp \
    && wget -O mybluez.tar.gz https://www.kernel.org/pub/linux/bluetooth/bluez-${BLUEZ_VERSION}.tar.gz \
    && tar xf mybluez.tar.gz \
    && rm mybluez.tar.gz \
    && cd /tmp/bluez-${BLUEZ_VERSION} \
    && ./configure --prefix=/usr \
       --mandir=/usr/share/man \
       --sysconfdir=/etc \
       --localstatedir=/var \
       --enable-library \
       --enable-experimental \
       --enable-maintainer-mode \
       --enable-deprecated \
    && make -j4 \
    && make install \
    && rm -r /tmp/bluez-${BLUEZ_VERSION}

#SSH port
EXPOSE 22

#do startscript
COPY "./files-to-copy-to-image/entrypoint.sh" /
RUN chmod +x /entrypoint.sh 
ENTRYPOINT ["/entrypoint.sh"]

#set STOPSGINAL
STOPSIGNAL SIGTERM

#stop processing ARM emulation (comment out next line if built on Raspberry)
RUN [ "cross-build-end" ]
