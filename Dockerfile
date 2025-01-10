# Use UBI 9 as the base image
FROM registry.access.redhat.com/ubi9/ubi

# Install systemd and other necessary packages
RUN dnf -y update && \
    dnf -y install systemd && \
    dnf clean all

# Install glibc-langpack-en for locales and systemd for initialization

RUN dnf -y update && \
    dnf -y install procps-ng gettext glibc-langpack-en && \
    dnf clean all


# Set the locale environment variables
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Configure systemd in the container
ENV container=docker
RUN (cd /lib/systemd/system/sysinit.target.wants/; \
     for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done) && \
    rm -f /lib/systemd/system/multi-user.target.wants/* && \
    rm -f /etc/systemd/system/*.wants/* && \
    rm -f /lib/systemd/system/local-fs.target.wants/* && \
    rm -f /lib/systemd/system/sockets.target.wants/*udev* && \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl* && \
    rm -f /lib/systemd/system/basic.target.wants/* && \
    rm -f /lib/systemd/system/anaconda.target.wants/*

# Expose necessary ports if required
EXPOSE 80 443

# Set default command to start systemd
CMD ["/usr/sbin/init"]

# Install required packages and configure PostgreSQL as root
RUN yum update -y && yum install -y vim \
    && yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-$(rpm -E %{rhel})-x86_64/pgdg-redhat-repo-latest.noarch.rpm \
    && yum -y install postgresql14 postgresql14-server postgresql14-contrib \
    && yum clean all

# Update PostgreSQL configuration for permissions
RUN sed -i 's|^d /run/postgresql 0755 postgres postgres -|d /run/postgresql 2777 postgres postgres - -|' /usr/lib/tmpfiles.d/postgresql-14.conf

# Expose PostgreSQL default port
EXPOSE 5432

# Configure sysctl and ulimit
RUN echo "vm.max_map_count=262144" >> /etc/sysctl.conf \
    && echo -e "ulimit -n 65536\nulimit -f unlimited\nulimit -u 4096" >> /etc/profile

RUN systemd-tmpfiles --create /usr/lib/tmpfiles.d/postgresql-14.conf
RUN ls -ld /run/postgresql
    
# Add user for Collibra DGC
RUN useradd -m -s /bin/bash woffles

# Copy Collibra installation files
COPY dgc-linux-5.9.2-33.sh /home/woffles/
COPY config.json /home/woffles/
RUN chmod a+x /home/woffles/dgc-linux-5.9.2-33.sh

# Install Collibra DGC as the woffles user
USER woffles
RUN /home/woffles/dgc-linux-5.9.2-33.sh -- --config /home/woffles/config.json

# Switch back to root for further instructions
USER root
RUN /home/woffles/collibra/console/bin/console start

EXPOSE 5432
EXPOSE 4400
EXPOSE 4430
EXPOSE 4404
EXPOSE 4414
EXPOSE 4424
EXPOSE 4434
EXPOSE 4407
EXPOSE 4401
EXPOSE 4402
EXPOSE 4420
EXPOSE 4403