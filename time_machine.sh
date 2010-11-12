#!/bin/bash
VERSION=0.2

if [ -e config.sh ]; then
  source config.sh
else 
  echo "btrfs-time-machine is not configured. Copy config.sh.template and configure."
fi

DEVICE=$(blkid | grep $DEST_DEVICE_UUID | cut -d ":" -f 1)
SNAPSHOTS_DIR="$BACKUP_MOUNT_POINT/snapshots"
DATE=$(date +%Y%m%d-%H%M%S)
PATH=$PATH:/usr/local/bin

function log {
  # TODO 
  # Need to make function cope with multiline input like what rsync sends

  DATE_NOW=`date +%b\ %d\ %H:%m:%S` 
  PREFIX="$DATE_NOW BTRFS Time Machine: "
  OUT=`echo $1 | sed "s/^/$PREFIX/g"`
  echo $OUT >> $LOG_FILE
}

# setup rsync vars.
RSYNC=`which rsync`
if [ ! -n "${RSYNC:+1}" ]; then log "rsync command is not available"; fi
RSYNC_OPTS='-av --numeric-ids --sparse --delete --human-readable'

# make sure src directory always has a trailing slash otherwise rsync will complain.
if [ -d $SOURCE_DIR ]; then
  SOURCE_DIR=`echo $SOURCE_DIR | sed 's/\/\?$/\//'`
else
  log "SOURCE_DIR '$SOURCE_DIR' is not a directory"
  exit 1
fi

log "BTRFS time machine version $VERSION running."

# make sure the backup drive is mounted...
if [ $(grep -c "$BACKUP_MOUNT_POINT" /proc/mounts) -ne "1" ]; then
	log "Backup device not mounted; attempting..."
	mount -o rw $DEVICE $BACKUP_MOUNT_POINT 2> /dev/null
	if [ "$?" -ne "0" ]; then
		log "Failed to mount backup device."
		exit 1
	fi
fi

# make sure that there is a subvolume for the latest rdiff. This way it keeps the snapshots tidy.
if [ $(btrfs subvolume list $BACKUP_MOUNT_POINT | grep -c 'latest$') -ne "1" ]; then
  btrfs subvolume create /mnt/btrfs_backups/latest >> $LOG_FILE 2>&1
fi

DESTINATION="$BACKUP_MOUNT_POINT/latest/$SOURCE_DIR"

# make sure the mount point is RW
log "Remounting mount point as RW"
mount -o remount,rw $DEVICE $BACKUP_MOUNT_POINT

# make sure the destination directories exists
mkdir -p $DESTINATION
mkdir -p $SNAPSHOTS_DIR

# start the backup
log "Starting the backup."
$RSYNC $RSYNC_OPTS $SOURCE_DIR $DESTINATION >> $LOG_FILE 2>&1

log "Creating file system snapshot."
btrfs subvolume snapshot $BACKUP_MOUNT_POINT/latest $SNAPSHOTS_DIR/$DATE >> $LOG_FILE 2>&1

# make sure the mount point is RO
log "Remounting mount point as RO"
mount -o remount,ro $DEVICE $BACKUP_MOUNT_POINT >> $LOG_FILE 2>&1

log "Done!"

exit 0
