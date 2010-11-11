#!/bin/bash
source config.sh

# rsync's source argument syntax is important,
# make sure to use a trailing slash if if our
# destination already exists
if [ -d ${MOUNT_POINT}/backups/aorth ]
then
	SOURCE=/home/aorth/
else
	SOURCE=/home/aorth
fi
DESTINATION=${MOUNT_POINT}/backups/aorth

echo "${DATE}: BTRFS time machine version $VERSION running."

# make sure the backup drive is mounted...
if [ $(grep -c "$MOUNT_POINT" /proc/mounts) -ne "1" ]
then
	echo "${DATE}: Backup device not mounted; attempting..."
	mount -o rw $DEVICE $MOUNT_POINT 2> /dev/null
	if [ "$?" -ne "0" ]
	then
		echo "${DATE}: Failed to mount backup device."
		exit 1
	fi
fi

# make sure the mount point is RW
echo "${DATE}: Remounting mount point as RW"
mount -o remount,rw $DEVICE $MOUNT_POINT

# start the backup
echo "${DATE}: Starting the backup."
$RSYNC $RSYNC_OPTS $SOURCE $DESTINATION

echo "${DATE}: Creating file system snapshot."
btrfs subvolume snapshot $MOUNT_POINT /mnt/btrfs_backups/snapshots/aorth_${DATE}

# make sure the mount point is RO
echo "${DATE}: Remounting mount point as RO"
mount -o remount,ro $DEVICE $MOUNT_POINT

echo "${DATE}: Done!"
echo

exit 0
