#!/bin/sh
#
# NFS auto u/mounter for Popcorn Hour A-110
#
# Checks availability of NAS share
# and remaps remote to local directories.
#
# Periodic check requires a scheduler, like Cron.
# Recording support requires an USB flashcard.
#
# Miroslav Osladil <xxlmira@gmail.com>
 
NAS_IP=10.0.0.102
NAS_SHARE=/opt/sybhttpd/localhost.drives/HARD_DISK
DATA=/DATA
LOCK=/tmp/nas.lock
BUFFER=8192

[ -e $LOCK ] && exit || touch $LOCK

[ -x $DATA/usb1/sda1 ] \
	&& MOUNT=$DATA/usb1/sda1 \
	|| MOUNT=/NFS

function lnShares()
{
	ln -s $MOUNT/Video $DATA/movie
	ln -s $MOUNT/Music $DATA/music
	ln -s $MOUNT/Photo $DATA/picture
}

function mkShares()
{
	[ -x $DATA/movie ]   || mkdir $DATA/movie
	[ -x $DATA/music ]   || mkdir $DATA/music
	[ -x $DATA/picture ] || mkdir $DATA/picture
}

function rmShares()
{
	rm -rf $DATA/movie   2>/dev/null >/dev/null
	rm -rf $DATA/music   2>/dev/null >/dev/null
	rm -rf $DATA/picture 2>/dev/null >/dev/null
}

ping -c 1 $NAS_IP 2>/dev/null >/dev/null
RETVAL_NAS=$?

mount | grep $NAS_IP 2>/dev/null >/dev/null
RETVAL_MOUNT=$?

if [ $RETVAL_NAS == 0 ]
then
	if ! [ $RETVAL_MOUNT == 0 ]
	then
		echo NAS available, re-mounting...
		mount -t nfs -o nolock,rsize=$BUFFER,wsize=$BUFFER $NAS_IP:$NAS_SHARE $MOUNT
		rmShares
		lnShares
	fi
else
	if [ $RETVAL_MOUNT == 0 ]
	then
		echo NAS unavailable, force umounting...
		umount -f $MOUNT
		rmShares
		mkShares
	fi
fi

rm $LOCK

