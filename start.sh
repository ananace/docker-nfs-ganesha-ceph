#!/bin/bash
set -e

# Options for starting Ganesha
: ${GANESHA_LOGFILE:="/dev/stdout"}
: ${GANESHA_CONFIGFILE:="/etc/ganesha/ganesha.conf"}
: ${GANESHA_OPTIONS:="-N NIV_EVENT"} # NIV_DEBUG
: ${GANESHA_EPOCH:=""}
: ${GANESHA_EXPORT_ID:="77"}
: ${GANESHA_EXPORT:="/export"}
: ${GANESHA_PSEUDO_PATH:="/"}
: ${GANESHA_NFS_PROTOCOLS:="3,4"}
: ${GANESHA_TRANSPORTS:="UDP,TCP"}
: ${GANESHA_ACCESS:="*"}
: ${GANESHA_ROOT_ACCESS:="*"}
: ${GANESHA_BOOTSTRAP_CONFIG:="yes"}

function ensure_mtab {
  if ! [ -e "/etc/mtab" ]; then
    ln -s /proc/mounts /etc/mtab
  fi
}

function bootstrap_config {
  echo "Bootstrapping Ganesha NFS config"

  local squash="Root_Squash"
  local global_access="RW";

  if [ "$GANESHA_ACCESS" != "*" ]; then
    if [ -n "$GANESHA_ACCESS" ]; then
      local ganesha_client="$(echo -e "CLIENT {\n    Clients = \"${GANESHA_ACCESS}\";\n    Squash = Root_Squash;\n    Access_Type = RW;\n  }")"
    fi
    global_access="None"
  fi

  if [ "$GANESHA_ROOT_ACCESS" != "*" ] && [ -n "$GANESHA_ROOT_ACCESS" ]; then
    local ganesha_root_client="$(echo -e "CLIENT {\n    Clients = \"${GANESHA_ROOT_ACCESS}\";\n    Squash = No_Root_Squash;\n    Access_Type = RW;\n  }")"
  elif [ "$GANESHA_ROOT_ACCESS" == "*" ]; then
    squash="No_Root_Squash"
  fi

  cat <<END >${GANESHA_CONFIGFILE}
# NFS protocol options
EXPORT
{
  # Export Id (mandatory, each EXPORT must have a unique Export_Id)
  Export_Id = ${GANESHA_EXPORT_ID};

  # Exported path (mandatory)
  Path = ${GANESHA_EXPORT};

  # Pseudo Path (for NFS v4)
  Pseudo = ${GANESHA_PSEUDO_PATH};

  # Access control options
  Access_Type = $global_access;
  Squash = $squash;

  # NFS protocol options
  SecType = "sys";
  Transports = ${GANESHA_TRANSPORTS};
  Protocols = ${GANESHA_NFS_PROTOCOLS};

  $ganesha_client
  $ganesha_root_client

  # Exporting FSAL
  FSAL {
    Name = VFS;
  }
}

END
}

function bootstrap_export {
  if [ ! -f ${GANESHA_EXPORT} ]; then
    mkdir -p "${GANESHA_EXPORT}"
  fi
}

function init_rpc {
  echo "Starting rpcbind"
  rpcbind || return 0
  rpc.statd -L || return 0
  rpc.idmapd || return 0
  sleep 1
}

function init_dbus {
  echo "Starting dbus"
  rm -f /var/run/dbus/system_bus_socket
  rm -f /var/run/dbus/pid
  dbus-uuidgen --ensure
  dbus-daemon --system --fork
  sleep 1
}

function startup_script {
  if [ -f "${STARTUP_SCRIPT}" ]; then
    /bin/sh "${STARTUP_SCRIPT}"
  fi
}

if [[ "${GANESHA_BOOTSTRAP_CONFIG}" = "yes" ]]
then
 bootstrap_config
fi

ensure_mtab
bootstrap_export
startup_script

init_rpc
init_dbus


echo "Starting Ganesha NFS"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib
exec /usr/bin/ganesha.nfsd -F -L ${GANESHA_LOGFILE} -f ${GANESHA_CONFIGFILE} ${GANESHA_OPTIONS}
