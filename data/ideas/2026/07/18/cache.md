# ASC core concept : Cache

TODO data/asc/cache ideal structure :

- `data/asc/cache/$subject/$action/$file_name`
- `data/asc/cache/$subject/$action/$args/$file_name`

The args transformation is like :

`hook -s 'instance' -p 'stage2' -a 'setup' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'`

Currently :

`data/asc/cache/hook._w_s_instance_p_stage2_a_setup_v_v1_asc_local_dev.sh`

Target : 

`data/asc/cache/instance/setup/v1.asc.local.dev.inc.sh`

Inside those cache files, which are raw bash script files that are sourced, we must be able to get the following information :

- $subject/$action (action by subject)
- cache file write triggered from which path = immediate extension point :
  - ./asc
  - ./asc/extensions/$extension
  - ./scripts/asc/contrib/$extension
  - ./scripts/asc/extend
