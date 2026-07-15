#!/usr/bin/env bash

##
# Global (env) vars for the crontab ASC extension.
#
# @see u_instance_init() in asc/instance/instance.inc.sh
#

global ASC_CRON_SYNC_ON_INIT "[default]=false [help]='When true, post_init also runs host crontab sync after regenerating scripts/asc/local/cron/*.sh.'"
