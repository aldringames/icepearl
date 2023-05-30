Glibc FS
========

Icepearl FS are most importantly on Alpine Linux. Glibc FS uses SystemD init system.

Table of Contents
-----------------

- [Partitions](#partitions)
  - [BIOS](#bios)
  - [UEFI](#uefi)

### Partitions

#### BIOS

The only way you can mount and format BIOS partitions.

| Disk      | Mount Point | Size       | RFS type |
| --------- | ----------- | ---------- | -------- |
| /dev/sda1 | /boot       | 1G         | ext2     |
| /dev/sda2 | none        | 2G         | swap     |
| /dev/sda3 | /           | Free space | ext4     |

Format all of the partitions:

```bash
mkfs.ext2 /dev/sda1
mkswap /dev/sda2
mkfs.ext4 /dev/sda3
```

Mount all of the partitions in the `/mnt/icepearl` directory:

```bash
export ICEPEARL_FS=/mnt/icepearl
mkdir -p "${ICEPEARL_FS}"
mount /dev/sda3 "${ICEPEARL_FS}"
mkdir "${ICEPEARL_FS}/boot"
mount /dev/sda1 "${ICEPEARL_FS}/boot"
swapon /dev/sda2
```

#### UEFI

The only way you can mount and format BIOS partitions.

| Disk      | Mount Point | Size       | RFS type |
| --------- | ----------- | ---------- | -------- |
| /dev/sda1 | /boot/efi   | 512M       | fat32    |
| /dev/sda2 | /boot       | 1G         | ext2     |
| /dev/sda3 | none        | 2G         | swap     |
| /dev/sda4 | /           | Free space | ext4     |

Format all of the partitions:
                                                                                ```bash
mkfs.vfat -F32 /dev/sda1
mkfs.ext2 /dev/sda2
mkswap /dev/sda3
mkfs.ext4 /dev/sda4
```

Mount all of the partitions in the `/mnt/icepearl` directory:

```bash
export ICEPEARL_FS=/mnt/icepearl
mkdir -p "${ICEPEARL_FS}"
mount /dev/sda4 "${ICEPEARL_FS}"
mkdir "{$ICEPEARL_FS}/boot"
mount /dev/sda2 "${ICEPEARL_FS}/boot"
mkdir "{$ICEPEARL_FS}/boot/efi"
mount /dev/sda1 "${ICEPEARL_FS}/boot/efi"
swapon /dev/sda3
```
