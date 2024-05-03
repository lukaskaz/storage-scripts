#!/bin/bash
LOCAL_MNT_POINT=/mnt/nas
NAS_CTRL=./local_nas_mgmt.sh
NAS_IP=#IPADDR#
NAS_SHARE=Linux
NAS_USER=Lukasz
NAS_WAKE_TRIES=20
NAS_WAKE_DELAY=10
RES=1

$NAS_CTRL ready
if [ $? -ne 0 ]; then
	CNT=0
	PROC_START=$(date +%s)

	echo "NAS is down, trying to wake it"
	$NAS_CTRL wake > /dev/null
	while [ $RES -ne 0 ] && [ $CNT -lt $NAS_WAKE_TRIES ]; do
		let CNT=CNT+1
		echo "NAS was triggred but still down, ping no: $CNT"	
		sleep $NAS_WAKE_DELAY
		$NAS_CTRL ready
		RES=$?
	done
	
	PROC_END=$(date +%s)
	let PROC_DURATION=PROC_END-PROC_START
	PROC_DURATION=$(date -d@$PROC_DURATION -u +%H:%M:%S)
	echo "Wake process duration: $PROC_DURATION"

	if [ $RES -ne 0 ]; then
		echo "Cannot wake NAS, aborting!"
		exit 2
	fi
fi


echo "NAS is up, trying to mount share"

mkdir -p $LOCAL_MNT_POINT > /dev/null 2>&1
umount $LOCAL_MNT_POINT > /dev/null 2>&1

RETRY=0
while true; do
	mount -t cifs -o user=$NAS_USER //$NAS_IP/$NAS_SHARE $LOCAL_MNT_POINT
	STATUS=$?
	if [ $STATUS -eq 0 ]; then
		echo "$(tput setaf 2)[SUCCESS]$(tput sgr0) NAS share is mounted under $LOCAL_MNT_POINT"
		exit 0
	else
		if [ $STATUS -eq 32 ] && [ $RETRY -lt 3 ]; then
			echo "NAS filesystem not ready yet, delaying access for few seconds"
			sleep 5
			let RETRY=RETRY+1
			echo ">> Please retry mounting attempt, retry no: $RETRY"
			continue
		else
			echo "$(tput setaf 1)[FAIL]$(tput sgr0) Unable to mount NAS share under $LOCAL_MNT_POINT (error $STATUS)"
			break
		fi	
	fi
done

exit $STATUS

