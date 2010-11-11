# the unique identifier for the BTRFS partition (from /dev/disk/by-uuid)
DEVICE_UUID=7cbf9ea6-8da2-4cd3-b068-7a0f72729fcd
DEVICE=$(blkid  | grep $DEVICE_UUID | cut -d ":" -f 1)
MOUNT_POINT=/mnt/btrfs_backups
SNAPSHOTS_DIR=/mnt/btrfs_backups/snapshots
DATE=$(date +%Y%m%d-%H%M)
RSYNC=/usr/bin/rsync
RSYNC_OPTS='-av --numeric-ids --sparse --delete --human-readable'
VERSION=0.1
PATH=$PATH:/usr/local/bin
