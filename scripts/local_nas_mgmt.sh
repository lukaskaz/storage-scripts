#!/bin/bash
NAS_IP=#IPADDR#
NAS_MAC=#PHYADDR#
NAS_WOL_PORT=9
NAS_CHK_PORT=80
VERS="v=2.3"
REQ=""
OPER=$1

function _is_ready()
{
    local RETVAL=1

	nc -zw 1 $NAS_IP $NAS_CHK_PORT
	if [ $? -eq 0 ]; then
		echo "NAS is: $(tput setaf 2)[ONLINE]$(tput sgr0)"
        RETVAL=0
	else
		echo "NAS is: $(tput setaf 1)[OFFLINE]$(tput sgr0)"
	fi
    return $RETVAL
}

function _wake()
{
    wakeonlan -p $NAS_WOL_PORT $NAS_MAC
    return $?
}

function _system_cmd()
{
    CMD=${1^}
    RETVAL=1

    if [ -n "$CMD" ]; then
        RET=$(curl "http://$NAS_IP/cp/System$CMD?$VERS" -s --insecure -u admin)
	    if [ -n "$RET" ]; then
		    echo "$RET" | sed -r "s/.*\"text\"\:\"([^\"]*).*/\1/g"
            RETVAL=0
	    fi
    fi
    return $RETVAL
}

function _alert_cmd()
{
    CMD=$1
    RETVAL=1

    RET=$(curl "http://$NAS_IP/cp/AlertSend?$VERS&id=$CMD" -s --insecure -u admin)
    if [ "$RET" == '""' ]; then RETVAL=0; fi
    return $RETVAL
}

case $OPER in
	ready) _is_ready;;
	wake) _$OPER;;
	ledblink) _alert_cmd $OPER;;
	reboot) ;&
	shutdown) _system_cmd $OPER;;
	*) echo "Unsupported operation '$OPER'";;
esac

exit $?

