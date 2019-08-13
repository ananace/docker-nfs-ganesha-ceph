FROM ubuntu:bionic

LABEL Name=nfs-ganesha-ceph \
      Version=2.8 \
      Maintainer="Alexander Olofsson <alexander.olofsson@liu.se>"

# install prerequisites
RUN DEBIAN_FRONTEND=noninteractive \
 && apt-get update \
 && apt-get install -y gnupg curl --no-install-recommends \
 && curl -sSL 'http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x10353E8834DC57CA' | apt-key add - \
 && echo "deb http://ppa.launchpad.net/nfs-ganesha/nfs-ganesha-2.8/ubuntu bionic main" > /etc/apt/sources.list.d/nfs-ganesha.list \
 && echo "deb http://ppa.launchpad.net/nfs-ganesha/libntirpc-1.8/ubuntu bionic main" > /etc/apt/sources.list.d/libntirpc.list \
 && apt-get update \
 && apt-get install -y liburcu6 netbase nfs-common dbus nfs-ganesha nfs-ganesha-ceph nfs-ganesha-rgw nfs-ganesha-vfs libnss-sss netcat --no-install-recommends \
 && apt-get remove -y curl gnupg \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
 && mkdir -p /run/rpcbind /export /var/run/dbus \
 && chown messagebus:messagebus /var/run/dbus \
 && touch /run/rpcbind/rpcbind.xdr /run/rpcbind/portmap.xdr \
 && chmod 755 /run/rpcbind/*

# Add startup script
COPY start.sh /

# NFS ports and portmapper
EXPOSE 2049 38465-38467 662 111/udp 111

# Start Ganesha NFS daemon by default
CMD ["/start.sh"]
