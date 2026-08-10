# SeaweedFS

SeaweedFS is a fast distributed storage system for blobs, objects, files, and data lake, for billions of files! Blob store has O(1) disk seek, cloud tiering. Filer supports Cloud Drive, cross-DC active-active replication, Kubernetes, POSIX FUSE mount, S3 API, S3 Gateway, Hadoop, WebDAV, encryption, Erasure Coding.

seaweedfs.com

<img src="https://raw.githubusercontent.com/seaweedfs/seaweedfs/master/note/seaweedfs.png" width="30%" height="auto" alt="SeaweedFS logo">

## How to use this Makejail

### Standalone

This image runs `weed mini -dir=/data` by default, so the only thing you pass is the env vars (and a volume mount if you want data to survive restarts):

```console
$ mkdir -p /var/appjail-volumes/seaweedfs/data
$ appjail oci run -Pd \
    -o expose=8333 \
    -o expose=8888 \
    -o expose=9333 \
    -o expose=23646 \
    -o overwrite=force \
    -o virtualnet=":<random> default" \
    -o nat \
    -o fstab="/var/appjail-volumes/seaweedfs/data /data" \
    -e AWS_ACCESS_KEY_ID="admin" \
    -e AWS_SECRET_ACCESS_KEY="secret" \
    -e S3_BUCKET="my-bucket" \
    ghcr.io/appjail-makejails/seaweedfs weed-mini
```

Exposed ports:

* `8333` — S3 endpoint
* `8888` — Filer UI
* `9333` — Master UI
* `23646` — Admin UI

Drop any of the env vars to skip that piece (no `S3_BUCKET` → no bucket created; no AWS keys → "Allow All" mode). Drop `-o fstab="/var/appjail-volumes/seaweedfs/data /data"` if you don't need data to persist across container restarts. Avoid using `-o expose` if you don't want external hosts to communicate with your service. You can always use the jail's IP address if you only want to communicate from the same host or from another jail.

#### Manage buckets after startup

Use the built-in `weed shell` — it talks directly to the master, so no AWS CLI or credentials needed:

```console
$ appjail oci exec weed-mini weed shell <<< "s3.bucket.create -name another-bucket"
$ appjail oci exec weed-mini weed shell <<< "s3.bucket.list"
```

For an interactive prompt: `appjail oci exec weed-mini weed shell`, then `help`.

### Deploy using `appjail-director`

**appjail-director.yml**:

```yaml
options:
  - virtualnet: ':<random> default'
  - nat:

services:
  master:
    name: seaweedfs-master
    makejail: gh+AppJail-makejails/seaweedfs
    oci:
      arguments: ['master', '-ip=seaweedfs-master', '-ip.bind=0.0.0.0', '-metricsPort=9324']
    options:
      - container: 'args:--pull'
  volume:
    name: seaweedfs-volume
    makejail: gh+AppJail-makejails/seaweedfs
    priority: 100
    oci:
      arguments: ['volume', '-ip=seaweedfs-volume', '-master=seaweedfs-master:9333', '-ip.bind=0.0.0.0', '-port=8080', '-metricsPort=9325']
    options:
      - depend: seaweedfs-master
      - container: 'args:--pull'
  filer:
    name: seaweedfs-filer
    makejail: gh+AppJail-makejails/seaweedfs
    priority: 101
    oci:
      arguments: ['filer', '-ip=seaweedfs-filer', '-master=seaweedfs-master:9333', '-ip.bind=0.0.0.0', '-metricsPort=9326']
    options:
      - depend: seaweedfs-master
      - depend: seaweedfs-volume
      - container: 'args:--pull'
  s3:
    name: seaweedfs-s3
    makejail: gh+AppJail-makejails/seaweedfs
    priority: 102
    oci:
      arguments: ['s3', '-filer=seaweedfs-filer:8888', '-ip.bind=0.0.0.0', '-metricsPort=9327']
    options:
      - depend: seaweedfs-master
      - depend: seaweedfs-volume
      - depend: seaweedfs-filer
      - container: 'args:--pull'
  webdav:
    name: seaweedfs-webdav
    makejail: gh+AppJail-makejails/seaweedfs
    priority: 102
    oci:
      arguments: ['webdav', '-filer=seaweedfs-filer:8888']
    options:
      - depend: seaweedfs-master
      - depend: seaweedfs-volume
      - depend: seaweedfs-filer
      - container: 'args:--pull'
```

**Console**:

```console
$ appjail-director up -p seaweedfs
Starting Director (project:seaweedfs) ...
Creating master (seaweedfs-master) ... Done.
 - Configuring arguments (OCI) ... Done.
Starting master (seaweedfs-master) ... Done.
Creating volume (seaweedfs-volume) ... Done.
 - Configuring arguments (OCI) ... Done.
Starting volume (seaweedfs-volume) ... Done.
Creating filer (seaweedfs-filer) ... Done.
 - Configuring arguments (OCI) ... Done.
Starting filer (seaweedfs-filer) ... Done.
Creating s3 (seaweedfs-s3) ... Done.
 - Configuring arguments (OCI) ... Done.
Starting s3 (seaweedfs-s3) ... Done.
Creating webdav (seaweedfs-webdav) ... Done.
 - Configuring arguments (OCI) ... Done.
Starting webdav (seaweedfs-webdav) ... Done.
Finished: seaweedfs
```

Please note that this assumes you have already configured [DNS in AppJail](https://appjail.readthedocs.io/en/latest/networking/DNS/).

### Arguments (stage: build)

* `seaweedfs_from` (default: `ghcr.io/appjail-makejails/seaweedfs`): Location of OCI image. See also [OCI Configuration](#oci-configuration).
* `seaweedfs_tag` (default: `latest`): OCI image tag. See also [OCI Configuration](#oci-configuration).

### Environment (OCI image)

* `PGID` (default: `1000`): Equivalent to `PUID` but for the Process Group ID.
* `PUID` (default: `1000`): Process User ID for the container's main process, allowing you to match the owner of files written to mounted host volumes to your host system's user. Writable volumes are changed based on this environment variable.

### Volumes

| Name | Owner | Group | Perm | Type | Mountpoint |
| --- | --- | --- | --- | --- | --- |
| appjail-263aca83a3-data | `${PUID}` | `${PGID}` | - | - | /data |

## OCI Configuration

```yaml
build:
  variants:
    - tag: 15.1
      containerfile: Containerfile
      aliases: ["latest"]
      default: true
      args:
        FREEBSD_RELEASE: "15.1"
        NO_PKGCLEAN: "1"
      cache_dirs: ["pkgcache0:/var/cache/pkg"]
```
