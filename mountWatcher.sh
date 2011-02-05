#!/bin/sh
#
# A Cron alternative for
# Popcorn Hour A-110 NFS auto u/mounter

TIMEOUT=60

while [ 1 ]
do
	/PLUGINS/mountPopcorn.sh
	sleep $TIMEOUT
done

