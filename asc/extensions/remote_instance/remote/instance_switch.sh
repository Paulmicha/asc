#!/usr/bin/env bash

##
# ASC remote instance switch action.
#
# Remotely executes asc/instance/switch_type.sh and restarts all stack services.
#
# @param 1 [optional] String : the remote instance ID. Defaults to 'prod'.
# @param 2 [optional] String : the new instance type. Defaults to 'prod'.
#
# @example
#   # Switches the 'prod' remote instance to type 'prod'.
#   make remote-instance-switch
#   # Or :
#   asc/extensions/remote_asc/remote/instance_switch.sh
#
#   # Switches the 'stage' remote instance to type 'prod'.
#   make remote-instance-switch 'stage'
#   # Or :
#   asc/extensions/remote_asc/remote/instance_switch.sh 'stage'
#
#   # Switches the 'dev' remote instance to type 'stage'.
#   make remote-instance-switch 'dev' 'stage'
#   # Or :
#   asc/extensions/remote_asc/remote/instance_switch.sh 'dev' 'stage'
#

. asc/bootstrap.sh

a_remote_id="$1"
a_new_type="$2"

if [[ -z "$a_remote_id" ]]; then
  a_remote_id='prod'
fi

f_remote_check_id "$a_remote_id"

if [[ -z "$a_new_type" ]]; then
  a_new_type='prod'
fi

. asc/extensions/remote_asc/remote/exec.sh "$a_remote_id" \
  "asc/instance/switch_type.sh $a_new_type && asc/instance/restart.sh"
