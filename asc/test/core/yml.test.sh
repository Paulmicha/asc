#!/usr/bin/env bash

##
# ASC YAML helper + f_yaml_parse caller tests.
#
# @requires asc/vendor/shunit2
#
# @see asc/test/core.sh
#

. asc/bootstrap.sh

oneTimeSetUp() {
  mkdir -p data/tmp/nftascymlhnc data/threads data/asc/software
}

oneTimeTearDown() {
  rm -rf data/tmp/nftascymlhnc
  rm -f data/threads/nftascymlhnc.yml
  rm -f data/asc/software/apps.manifest.local.yml
}

##
# Sample YAML matching the f_yaml_parse() docblock (maps + simple list).
#
_f_test_write_sample_yml() {
  cat > "$1" <<'EOF'
site:
  all: default-sites.txt
  new: new-sites.txt
urls:
  - preprod.example.com
  - example.com
EOF
}

##
# f_yaml_parse writes assignment text via printf -v (no caller capture).
#
test_f_yaml_parse_printf_v() {
  local f='data/tmp/nftascymlhnc/sample.yml'
  local parsed=''

  _f_test_write_sample_yml "$f"
  f_yaml_parse "$f" 'conf_' 'parsed'

  assertTrue 'printf -v should populate output var' "[[ -n \"$parsed\" ]]"
  assertTrue 'should emit prefixed scalar assignment' \
    "[[ \"$parsed\" == *'conf_site_all='* ]]"
  assertTrue 'should emit list += assignment' \
    "[[ \"$parsed\" == *'conf_urls+='* ]]"

  eval "$parsed"
  assertEquals 'site.all' 'default-sites.txt' "$conf_site_all"
  assertEquals 'urls[0]' 'preprod.example.com' "${conf_urls[0]}"
  assertEquals 'urls[1]' 'example.com' "${conf_urls[1]}"
}

##
# Omitting the output var still prints to stdout (compat).
#
test_f_yaml_parse_stdout_fallback() {
  local f='data/tmp/nftascymlhnc/sample.yml'
  local out

  _f_test_write_sample_yml "$f"
  out="$(f_yaml_parse "$f" 'conf_')"
  assertTrue 'stdout fallback should emit assignments' \
    "[[ \"$out\" == *'conf_site_all='* ]]"
}

##
# f_yaml_get_root_keys + f_yaml_get_keys (parsed string from printf -v).
#
test_f_yaml_get_keys() {
  local f='data/tmp/nftascymlhnc/sample.yml'
  local parsed=''

  _f_test_write_sample_yml "$f"

  f_yaml_get_root_keys "$f"
  assertTrue 'root key site' "[[ \" \${yaml_keys_arr[*]} \" == *' site '* ]]"
  assertTrue 'root key urls' "[[ \" \${yaml_keys_arr[*]} \" == *' urls '* ]]"

  f_yaml_parse "$f" 'conf_' 'parsed'
  f_yaml_get_keys "$parsed" 'conf_site_'
  assertEquals 'level-1 site keys' 'all' "${yaml_keys_arr[0]}"
  assertTrue 'site.new present' "[[ \" \${yaml_keys_arr[*]} \" == *' new '* ]]"
}

##
# f_yaml_escape_double + f_yaml_write round-trip through f_yaml_parse.
#
test_f_yaml_write_roundtrip() {
  local f='data/tmp/nftascymlhnc/write.yml'
  local parsed=''
  local yaml_escaped=''

  f_yaml_escape_double 'say "hi"' 'yaml_escaped'
  assertEquals 'escape double quotes' 'say \"hi\"' "$yaml_escaped"

  declare -A y_sc_dict=([entry]='nftascymlhnc' [status]='running')
  local y_keys_arr=(entry status)
  local y_tree_arr=('123:bash' '1:systemd')

  f_yaml_write "$f" y_sc_dict y_keys_arr tree y_tree_arr

  f_yaml_parse "$f" 'rt_' 'parsed'
  eval "$parsed"
  rt_entry="${rt_entry#\"}"
  rt_entry="${rt_entry%\"}"
  rt_tree[0]="${rt_tree[0]#\"}"
  rt_tree[0]="${rt_tree[0]%\"}"
  rt_tree[1]="${rt_tree[1]#\"}"
  rt_tree[1]="${rt_tree[1]%\"}"
  assertEquals 'written entry' 'nftascymlhnc' "$rt_entry"
  assertEquals 'written tree[0]' '123:bash' "${rt_tree[0]}"
  assertEquals 'written tree[1]' '1:systemd' "${rt_tree[1]}"
}

##
# No remaining $(f_yaml_parse …) capture subshells in ASC code.
#
test_f_yaml_parse_no_caller_capture_subshell() {
  local hits
  hits="$(rg -n --glob '!**/changelog/**' --glob '!**/vendor/**' --glob '!**/data/**' \
    --glob '!**/yml.test.sh' '\$\(f_yaml_parse|< <\(f_yaml_parse' . || true)"
  assertEquals 'callers must use printf -v output var, not $(f_yaml_parse)' '' "$hits"
}

##
# f_instance_yaml_config_parse consumes parse output without process substitution.
#
test_f_instance_yaml_config_parse() {
  local f='data/tmp/nftascymlhnc/env.yml'
  local yaml_parsed_sp_init=''
  local yaml_parsed_globals=''

  cat > "$f" <<'EOF'
instance_type: nftascymlhnc
host_type: local
EOF

  f_instance_yaml_config_parse "$f"
  assertTrue 'globals declarations produced' "[[ \"$yaml_parsed_globals\" == *'global INSTANCE_TYPE'* ]]"
  assertTrue 'sp_init includes instance type' \
    "[[ \"$yaml_parsed_sp_init\" == *'YAML_INSTANCE_TYPE='* ]]"
}

##
# f_thread_yml_load evals parse output into thread_* vars.
#
test_f_thread_yml_load() {
  local f='data/threads/nftascymlhnc.yml'

  cat > "$f" <<'EOF'
entry: "nftascymlhnc"
status: "idle"
pid: "1"
EOF

  unset thread_entry thread_status thread_pid
  f_thread_yml_load 'nftascymlhnc'
  assertEquals 'thread entry' 'nftascymlhnc' "$thread_entry"
  assertEquals 'thread status' 'idle' "$thread_status"
}

##
# Crontab base templates load via f_yaml_parse output var.
#
test_f_cron_load_base_templates() {
  . asc/extensions/crontab/crontab.inc.sh
  f_cron_load_base_templates
  assertEquals 'cron default enabled' 'true' "$cron_tpl_defaults_enabled"
  assertEquals 'cron default wrap' 'lt' "$cron_tpl_defaults_wrap"
}

##
# Software manifests load via f_yaml_parse output var.
#
test_f_software_load_manifests() {
  . asc/extensions/software/host/provision.opt-inc.sh

  mkdir -p data/asc/software
  cat > data/asc/software/apps.manifest.local.yml <<'EOF'
apt_arr:
  - nftascymlhnc-pkg
EOF

  f_software_load_manifests
  assertTrue 'local apt id loaded' \
    "[[ \" \${sw_apt_arr[*]} \" == *' nftascymlhnc-pkg '* ]]"
}

##
# Remote-instances parse pattern (prefix + root keys) without hook lookup.
#
test_f_yaml_parse_remote_instances_pattern() {
  local f='data/tmp/nftascymlhnc/remote_instances.yml'
  local parsed_yaml_remotes=''

  cat > "$f" <<'EOF'
dev:
  host: 1.2.3.4
  domain: dev.example.com
EOF

  f_yaml_parse "$f" 'ascri_' 'parsed_yaml_remotes'
  eval "$parsed_yaml_remotes"
  f_yaml_get_root_keys "$f"

  assertEquals 'remote id' 'dev' "${yaml_keys_arr[0]}"
  assertEquals 'host' '1.2.3.4' "$ascri_dev_host"
  assertEquals 'domain' 'dev.example.com' "$ascri_dev_domain"
}

##
# DrupalWT sites parse pattern (memoized assignment string).
#
test_f_yaml_parse_dwt_sites_pattern() {
  local f='data/tmp/nftascymlhnc/sites.yml'
  local sites_parsed_yaml_str=''
  local dwt_vars_prefix='dwt_sites_'

  cat > "$f" <<'EOF'
alpha:
  dir: web/sites/alpha
EOF

  f_yaml_parse "$f" "$dwt_vars_prefix" 'sites_parsed_yaml_str'
  eval "$sites_parsed_yaml_str"
  assertEquals 'site dir' 'web/sites/alpha' "$dwt_sites_alpha_dir"
}

##
# reinit.sh / monitor.hook.sh prefix patterns.
#
test_f_yaml_parse_reinit_and_monitor_prefixes() {
  local envf='data/tmp/nftascymlhnc/reinit-env.yml'
  local hostf='data/tmp/nftascymlhnc/host-index.yml'
  local parsed=''

  cat > "$envf" <<'EOF'
stack_version: nftascymlhnc
asc_apps: site
EOF
  f_yaml_parse "$envf" 'yaml_' 'parsed'
  eval "$parsed"
  assertEquals 'reinit stack_version' 'nftascymlhnc' "$yaml_stack_version"
  assertEquals 'reinit asc_apps' 'site' "$yaml_asc_apps"

  cat > "$hostf" <<'EOF'
docroot: /tmp/nftascymlhnc
entry: nftascymlhnc
pid: "9"
status: running
EOF
  parsed=''
  f_yaml_parse "$hostf" 'thread_host_' 'parsed'
  eval "$parsed"
  assertEquals 'monitor docroot' '/tmp/nftascymlhnc' "$thread_host_docroot"
  assertEquals 'monitor entry' 'nftascymlhnc' "$thread_host_entry"
}

. asc/vendor/shunit2/shunit2
