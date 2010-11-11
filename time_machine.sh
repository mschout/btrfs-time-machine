#!/bin/bash
VERSION=0.2

if [ -e config.sh ]; then
  source config.sh
else 
  echo "btrfs-time-machine is not configured. Copy config.sh.template and configure."
fi


DEVICE=$(blkid | grep $DEST_DEVICE_UUID | cut -d ":" -f 1)
SNAPSHOTS_DIR="$BACKUP_MOUNT_POINT/snapshots"
DATE=$(date +%Y%m%d-%H%M)
PATH=$PATH:/usr/local/bin

# setup rsync vars.
RSYNC=`which rsync`
if [ ! -n "${RSYNC:+1}" ]; then echo "rsync command is not available"; fi
RSYNC_OPTS='-av --numeric-ids --sparse --delete --human-readable'

# make sure src directory always has a trailing slash otherwise rsync will complain.
if [ -d $SOURCE_DIR ]; then
  SOURCE_DIR=`echo $SOURCE_DIR | sed 's/\/\?$/\//'`
else
  echo "$DATE: SOURCE_DIR '$SOURCE_DIR' is not a directory"
  exit 1
fi


echo "$DATE: BTRFS time machine version $VERSION running."

# make sure the backup drive is mounted...
if [ $(grep -c "$BACKUP_MOUNT_POINT" /proc/mounts) -ne "1" ]; then
	echo "$DATE: Backup device not mounted; attempting..."
	mount -o rw $DEVICE $BACKUP_MOUNT_POINT 2> /dev/null
	if [ "$?" -ne "0" ]; then
		echo "$DATE: Failed to mount backup device."
		exit 1
	fi
fi

# make sure that there is a subvolume for the latest rdiff. This way it keeps the snapshots tidy.
if [ $(btrfs subvolume list $BACKUP_MOUNT_POINT | grep -c 'latest$') -ne "1" ]; then
  btrfs subvolume create /mnt/btrfs_backups/latest
fi

DESTINATION="$BACKUP_MOUNT_POINT/latest/$SOURCE_DIR"

# make sure the mount point is RW
echo "$DATE: Remounting mount point as RW"
mount -o remount,rw $DEVICE $BACKUP_MOUNT_POINT

# make sure the destination directories exists
mkdir -p $DESTINATION
mkdir -p $SNAPSHOTS_DIR

# start the backup
echo "$DATE: Starting the backup."
echo "$RSYNC $RSYNC_OPTS $SOURCE_DIR $DESTINATION"
$RSYNC $RSYNC_OPTS $SOURCE_DIR $DESTINATION

echo "$DATE: Creating file system snapshot."
btrfs subvolume snapshot $BACKUP_MOUNT_POINT/latest $SNAPSHOTS_DIR/$DATE

# make sure the mount point is RO
echo "$DATE: Remounting mount point as RO"
mount -o remount,ro $DEVICE $BACKUP_MOUNT_POINT

echo "$DATE: Done!"
echo

exit 0
