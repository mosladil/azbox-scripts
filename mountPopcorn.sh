#!/bin/sh
#
# Auto u/mounter for Popcorn Hour A-110
#
# Checks availability of NAS share
# and remaps remote to local directories.
#
# Periodic check requires a scheduler, like Cron.
# Recording support requires an USB flashcard.
#
# Miroslav Osladil <xxlmira@gmail.com>

# Use CIFS or NFS protocol
USE=NFS

# Defaults
NAS_IP=10.0.0.102
NAS_NFS=/opt/sybhttpd/localhost.drives/HARD_DISK
NAS_CIFS=share
NAS_USER=nmt
NAS_PASS=1234
DATA=/DATA
LOCK=/tmp/nas.lock
BUFFER=8192

[ -e $LOCK ] && exit || touch $LOCK

[ -x $DATA/usb1/sda1 ] \
	&& MOUNT=$DATA/usb1/sda1 \
	|| MOUNT=/NFS

function lnShares()
{
	ln -s $MOUNT/Video      $DATA/movie
	ln -s $MOUNT/Music      $DATA/music
	ln -s $MOUNT/Photo      $DATA/picture
	ln -s $MOUNT/recordfile $DATA/recordfile
}

function mkShares()
{
	[ -x $DATA/movie ]      || mkdir $DATA/movie
	[ -x $DATA/music ]      || mkdir $DATA/music
	[ -x $DATA/picture ]    || mkdir $DATA/picture
	[ -x $DATA/recordfile ] || mkdir $DATA/recordfile
}

function rmShares()
{
	rm -rf $DATA/movie      2>/dev/null >/dev/null
	rm -rf $DATA/music      2>/dev/null >/dev/null
	rm -rf $DATA/picture    2>/dev/null >/dev/null
	rm -rf $DATA/recordfile 2>/dev/null >/dev/null
}

function setDisplay()
{
	vfd_display -td210 "$1" 2>/dev/null >/dev/null
}

ping -c 1 $NAS_IP 2>/dev/null >/dev/null
RETVAL_PING=$?

mount | grep $NAS_IP 2>/dev/null >/dev/null
RETVAL_MOUNT=$?

if [ $RETVAL_PING == 0 ]
then
	echo -n 'NAS available... '
	if ! [ $RETVAL_MOUNT == 0 ]
	then
		echo -n 're-mounting... '
		rmShares
		lnShares
		if [ $USE == 'NFS' ]
		then
			mount -t nfs -o nolock,rsize=$BUFFER,wsize=$BUFFER $NAS_IP:$NAS_NFS $MOUNT
		else
			mount.cifs //$NAS_IP/$NAS_CIFS $MOUNT -o username=$NAS_USER,password=$NAS_PASS,nolock,rsize=$BUFFER,wsize=$BUFFER
		fi
		setDisplay 'NAS ready'
	fi
else
	echo -n 'NAS unavailable...'
	if [ $RETVAL_MOUNT == 0 ]
	then
		echo -n 'umounting...'
		umount -f $MOUNT
		rmShares
		mkShares
	fi
fi

echo done.

rm $LOCK

