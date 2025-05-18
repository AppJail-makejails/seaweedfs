# SeaweedFS

 SeaweedFS is a fast distributed storage system for blobs, objects, files, and data lake, for billions of files! Blob store has O(1) disk seek, cloud tiering. Filer supports Cloud Drive, cross-DC active-active replication, Kubernetes, POSIX FUSE mount, S3 API, S3 Gateway, Hadoop, WebDAV, encryption, Erasure Coding. 

seaweedfs.com

![seaweedfs logo](https://raw.githubusercontent.com/seaweedfs/seaweedfs/master/note/seaweedfs.png)

## How to use this Makejail

```
appjail makejail -j seaweedfs -f gh+AppJail-makejails/seaweedfs
appjail cmd jexec seaweedfs -U seaweedfs ./weed -help
```

### Arguments

* `seaweedfs_ajspec` (default: `gh+AppJail-makejails/seaweedfs`): Entry point where the `appjail-ajspec(5)` file is located.
* `seaweedfs_tag` (default: `13.5`): see [#tags](#tags).

## Tags

| Tag           | Arch    | Version            | Type   |
| ------------- | --------| ------------------ | ------ |
| `13.5`    | `amd64` | `13.5-RELEASE` | `thin` |
| `14.2`    | `amd64` | `14.2-RELEASE` | `thin` |
