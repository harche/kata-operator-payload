FROM centos:8.2.2004 as katapackages

ADD CentOS-8-Virt-SIG-Advanced-Virtualization.repo /etc/yum.repos.d/CentOS-8-Virt-SIG-Advanced-Virtualization.repo

WORKDIR /etc/yum.repos.d
RUN curl -O https://copr.fedorainfracloud.org/coprs/fidencio/kata-containers/repo/epel-8/fidencio-kata-containers-epel-8.repo

WORKDIR /usr/src/kata-containers

#Call `dnf install` early like this, otherwise the successful transaction would
#cleanup the packages downloaded, down in this file.
RUN dnf install -y createrepo
RUN mkdir packages

RUN dnf module disable -y virt:rhel

RUN dnf install -y --downloadonly --downloaddir=/usr/src/kata-containers/packages \
    qemu-kvm

#Needed as these packages are installed by default on CentOS:8.2.2004, while
#they're **not** #present on a RHCOS installation 
RUN dnf reinstall -y --downloadonly --downloaddir=/usr/src/kata-containers/packages \
    snappy \
    lzo

RUN dnf install -y --downloadonly --downloaddir=/usr/src/kata-containers/packages \
    kata-runtime \
    kata-osbuilder

#We don't need kata-shim installed on OpenShift
RUN rm /usr/src/kata-containers/packages/kata-shim*.rpm

RUN ls -lR /usr/src/kata-containers/
RUN createrepo /usr/src/kata-containers/packages

COPY . .

############################
# STEP 2 build a small image
############################
FROM scratch

WORKDIR /
# Copy our static executable.

COPY --from=katapackages /usr/src/kata-containers/packages  packages/

COPY CentOS-8-Virt-SIG-Advanced-Virtualization.repo .
COPY packages.repo .
COPY kata-cleanup.sh .


