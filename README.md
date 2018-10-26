# NFS Ganesha
A user mode nfs server implemented in a container. Supports serving NFS (v3, 4.0, 4.1, 4.1 pNFS, 4.2) and 9P. This container is also configured with the nfs-ganesha Ceph FSAL backend.

Currently generates a config for just serving a local path over nfs. However supplying `GANESHA_CONFIGFILE` would allow ganesha to be pointed to a bind mounted config file for other FASLs/more advanced configuration.

### Versions
* ganesha: 2.7

### Environment Variables
* `GANESHA_LOGFILE`: log file location, defaults to `/dev/stdout`
* `GANESHA_CONFIGFILE`: location of ganesha.conf, defaults to `/etc/ganesha/ganesha.conf`
* `GANESHA_OPTIONS`: command line options to pass to ganesha, defaults to `-N NIV_EVENT`
* `GANESHA_EPOCH`: ganesha epoch value
* `GANESHA_EXPORT_ID`: ganesha unique export id, defaults to `77`
* `GANESHA_EXPORT`: export location, defaults to `/export`
* `GANESHA_PSEUDO_PATH`: NFSv4 pseudo-path of the export, defaults to `/`
* `GANESHA_NFS_PROTOCOLS`: nfs protocols to support, defaults to `3,4`
* `GANESHA_TRANSPORTS`: nfs transports to support, defaults to `UDP,TCP`
* `GANESHA_BOOTSTRAP_CONFIG`: write fresh config file on start, defaults to `yes`
* `STARTUP_SCRIPT`: location of a shell script to execute on start

#### Environment Placement in Config File
````
EXPORT
{
  # Export Id (mandatory, each EXPORT must have a unique Export_Id)
  Export_Id = ${GANESHA_EXPORT_ID};

  # Exported path (mandatory)
  Path = ${GANESHA_EXPORT};

  # Pseudo Path (for NFS v4)
  Pseudo = ${GANESHA_PSEUDO_PATH};

  # Access control options
  Access_Type = RW;
  Squash = No_Root_Squash;

  # NFS protocol options
  SecType = "sys";
  Transports = "${GANESHA_TRANSPORTS}";
  Protocols = "${GANESHA_NFS_PROTOCOLS}";

  # Exporting FSAL
  FSAL {
    Name = VFS;
  }
}
````

### Usage
```bash
docker run -d \
--name nfs \
-v /local/export/path:/export \
ananace/nfs-ganesha-ceph \
```

### Credits
* [janeczku/docker-nfs-ganesha](https://github.com/janeczku/docker-nfs-ganesha)
