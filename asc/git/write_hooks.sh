#!/usr/bin/env bash

##
# (over)Writes Git hooks to use ASC hooks.
#
# When executed as a script, bootstraps ASC then writes.
# When sourced, only defines f_git_write_hooks().
#
# @see f_instance_init() in asc/instance/instance.inc.sh
# @see https://git-scm.com/docs/githooks
#
# @example
#   # After bootstrap :
#   . asc/git/write_hooks.sh
#   f_git_write_hooks
#
#   asc/git/write_hooks.sh
#   asc/git/write_hooks.sh 'pre-commit post-merge'
#   asc/git/write_hooks.sh '' /my/custom/path/to/.git/hooks
#

##
# (over)Writes Git hooks to use ASC hooks.
#
# Applies to folder "$APP_DOCROOT/.git/hooks" if it exists, otherwise to
# "$PROJECT_DOCROOT/.git/hooks".
#
# ASC hook triggers will have the following format :
# $ hook -s 'git' -a "$git_hook" -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# Git's arguments are stored before that call. git_hook_args_nb is always a
# scalar, including 0 (pre-commit passes none). git_hook_args holds the
# values. An empty array has no element 0, so ${git_hook_args+x} is empty
# after a zero-argument assignment. Listeners use the count, not that test.
#
# TODO [evol] Examine opt-in alternative to use a custom value for "git config
# core.hooksPath" (instead of just generating scripts in "$GIT_DIR/hooks").
#
# @see https://git-scm.com/docs/githooks
#
# @param 1 [optional] String : the space-separated Git hooks to (over)write.
#   Defaults to the following selection (when value is absent or empty) :
#   - 'pre-applypatch' : git am only, after the patch is applied and before
#     that command commits. Non-zero status leaves that tree uncommitted.
#     Does not run for git commit.
#   - 'pre-commit' (see post-merge) : git commit, on the index about to be
#     committed. Non-zero status aborts the commit. Bypassed with
#     'git commit --no-verify'. Also used for permissions/ownership, ACLs.
#   - 'post-checkout' : used to perform repository validity checks, auto-display
#     differences from the previous HEAD if different, or set working dir
#     metadata properties (e.g. permissions/ownership). The hook is given three
#     parameters: the ref of the previous HEAD, the ref of the new HEAD (which
#     may or may not have changed), and a flag indicating whether the checkout
#     was a branch checkout (changing branches, flag=1) or a file checkout
#     (retrieving a file from the index, flag=0).
#   - 'post-merge' (see pre-commit) : used for permissions/ownership, ACLS, etc.
#     This hook is invoked by git merge, which happens when a git pull is done
#     on a local repository. It takes a single parameter, a status flag
#     specifying whether or not the merge being done was a squash merge.
#   - 'pre-push' : can be used to prevent a push from taking place (exit with a
#     non-zero status). The hook is called with two parameters which provide the
#     name and location of the destination remote, if a named remote is not
#     being used both values will be the same.
#   - 'post-receive' : executes on the remote repository once after all the refs
#     have been updated. This hook does not affect the outcome of
#     git-receive-pack, as it is called after the real work is done.
# @param 2 [optional] String : the Git hooks folder to use. Defaults to
#   "$APP_DOCROOT/.git/hooks" if it exists, otherwise to
#   "$PROJECT_DOCROOT/.git/hooks".
#
# @example
#   f_git_write_hooks
#   f_git_write_hooks 'pre-commit post-merge'
#   f_git_write_hooks '' /my/custom/path/to/.git/hooks
#
f_git_write_hooks() {
  local p_git_hooks="$1"
  local p_git_hook_dir="$2"

  if [[ -z "$p_git_hooks" ]]; then
    p_git_hooks='pre-applypatch pre-commit post-checkout post-merge pre-push post-receive'
  fi

  if [[ -z "$p_git_hook_dir" ]]; then
    p_git_hook_dir="$PROJECT_DOCROOT/.git/hooks"

    if [[ -n "$APP_DOCROOT" ]]; then
      p_git_hook_dir="$APP_DOCROOT/.git/hooks"
    fi

    if [[ ! -d "$p_git_hook_dir" ]]; then
      echo >&2
      echo "Error in f_git_write_hooks() - $BASH_SOURCE line $LINENO: the Git hook dir '$p_git_hook_dir' is missing." >&2
      echo "-> Aborting (1)." >&2
      echo >&2
      exit 1
    fi
  fi

  # Whitelist allowed values for git hooks.
  local git_hook=''
  local git_hook_script_path=''
  local git_hooks_whitelist_arr=()

  git_hooks_whitelist_arr+=('applypatch-msg')
  git_hooks_whitelist_arr+=('pre-applypatch')
  git_hooks_whitelist_arr+=('post-applypatch')
  git_hooks_whitelist_arr+=('pre-commit')
  git_hooks_whitelist_arr+=('prepare-commit-msg')
  git_hooks_whitelist_arr+=('commit-msg')
  git_hooks_whitelist_arr+=('post-commit')
  git_hooks_whitelist_arr+=('pre-rebase')
  git_hooks_whitelist_arr+=('post-checkout')
  git_hooks_whitelist_arr+=('post-merge')
  git_hooks_whitelist_arr+=('pre-push')
  git_hooks_whitelist_arr+=('pre-receive')
  git_hooks_whitelist_arr+=('update')
  git_hooks_whitelist_arr+=('post-update')
  git_hooks_whitelist_arr+=('post-receive')
  git_hooks_whitelist_arr+=('post-update')
  git_hooks_whitelist_arr+=('push-to-checkout')
  git_hooks_whitelist_arr+=('pre-auto-gc')
  git_hooks_whitelist_arr+=('post-rewrite')
  git_hooks_whitelist_arr+=('rebase')
  git_hooks_whitelist_arr+=('sendemail-validate')
  git_hooks_whitelist_arr+=('fsmonitor-watchman')

  for git_hook in $p_git_hooks; do

    # Whitelist allowed values for git hooks.
    if f_in_array "$git_hook" 'git_hooks_whitelist_arr'; then
      git_hook_script_path="$p_git_hook_dir/$git_hook"

      relative_path=''
      f_fs_relative_path "$git_hook_script_path"

      # When Git triggers its hook, the path in which the script runs is either
      # APP_DOCROOT or PROJECT_DOCROOT.
      # -> Since ASC requires to be run from PROJECT_DOCROOT, we need to force the
      # execution path from within the generated scripts.
      echo "(over)Writing git hook $relative_path ..."

      cat > "$git_hook_script_path" <<EOF
#!/usr/bin/env bash

##
# Implements '$git_hook' git hook.
#
# This file is automatically generated during "instance init", and it will be
# entirely overwritten every time it is executed.
#
# @see f_git_write_hooks() in asc/git/write_hooks.sh
# @see f_instance_init() in asc/instance/instance.inc.sh
#

cd "$PROJECT_DOCROOT"

. asc/bootstrap.sh

# Count the number of args sent by git in this hook call.
git_hook_args_nb="\$#"

# Store all the arguments for hook implementations to read them.
git_hook_args=("\$@")

# Finally, call the ASC hook with the same git hook name (in the "git" subject).
hook -s 'git' -a "$git_hook" -v 'STACK_VERSION HOST_TYPE INSTANCE_TYPE'
EOF
      chmod +x "$git_hook_script_path"

      echo "(over)Writing git hook $relative_path : done."

    else
      echo >&2
      echo "Error in f_git_write_hooks() - $BASH_SOURCE line $LINENO: the value '$git_hook' is invalid." >&2
      echo "-> Aborting (2)." >&2
      echo >&2
      exit 2
    fi
  done
}

# Entry point (skipped when this file is sourced).
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  . asc/bootstrap.sh
  f_git_write_hooks "$@"
fi
