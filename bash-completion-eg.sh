#
# bash completion support for easy Git.
#
# Copyright (C) 2006,2007 Shawn O. Pearce <spearce@spearce.org>
# Copyright (C) 2008-2010 Elijah Newren <newren@gmail.com>
# *Heavily* based on git-completion.sh
# Distributed under the GNU General Public License, version 2.0.
#
# *** IMPORTANT USAGE NOTE ***
# If you are using an old copy of git-completion.sh and you try to complete
# eg commands that the old version of git-completion.sh did not support, you
# may get errors like:
#   bash: _git_fetch: command not found
#
# Reasons/rationale:
#   This could be fixed by pulling all of git-completion.sh into this file,
#   but this would be a heavy maintainence burden.  Also, I like common
#   bugs being fixed in one place...  This only affects a few subcommands,
#   so I don't think the trade-off is harsh.  Besides, you can always
#   download a recent copy of git and just install the git-completion.sh
#   file all by itself to fix any such issues.
# *** END USAGE NOTE ***
#
# The contained completion routines provide support for completing:
#
#    *) local and remote branch names
#    *) local and remote tag names
#    *) .git/remotes file names
#    *) git 'subcommands'
#    *) tree paths within 'ref:path/to/file' expressions
#    *) common --long-options
#
# To use these routines (s/git-completion.sh/bash-completion-eg.sh/ in
# instructions below, but make sure git-completion.sh from the 
# contrib/completion/ directory of git sources is also in use):
#
#    1) Copy this file to somewhere (e.g. ~/.git-completion.sh).
#    2) Added the following line to your .bashrc:
#        source ~/.git-completion.sh
#
#    3) You may want to make sure the git executable is available
#       in your PATH before this script is sourced, as some caching
#       is performed while the script loads.  If git isn't found
#       at source time then all lookups will be done on demand,
#       which may be slightly slower.
#
#    4) Consider changing your PS1 to also show the current branch:
#        PS1='[\u@\h \W$(__git_ps1 " (%s)")]\$ '
#
#       The argument to __git_ps1 will be displayed only if you
#       are currently in a git repository.  The %s token will be
#       the name of the current branch.
#
# *** Maintainence Note ***
# Since this is so heavily based on git-completion.sh, it can be useful
# to run
#   diff -u --ignore-space-change bash-completion-eg.sh git-completion.bash
# against a new version of git-completion.bash (under contrib/completion/
# in a copy of the git sources) in order to pick up any new completion
# commands that should be added to this file.  The main thing to check in
# such a diff are the differences between the _eg() and _git() functions,
# particularly completion support that exists for subcommands in the latter
# but has no corresponding support in the former.
# *** End Note ***

__eg_commands ()
{
  if [ -n "$__eg_commandlist" ]; then
    echo "$__eg_commandlist"
    return
  fi
  local i IFS=" "$'\n'
  eg help --all | egrep "^  eg" | awk '{print $2}' | sort | uniq
}
__eg_commandlist=
__eg_commandlist="$(__eg_commands 2>/dev/null)"

__eg_topics ()
{
  if [ -n "$__eg_topiclist" ]; then
    echo "$__eg_topiclist"
    return
  fi
  local i IFS=" "$'\n'
  eg help topic | egrep "^[A-Za-z]" | awk '{print $1}' | grep -v "^Topics"
}
__eg_topiclist=
__eg_topiclist="$(__eg_topics 2>/dev/null)"

_eg_commit ()
{
        case "$prev" in
        -c|-C)
                __gitcomp_nl "$(__git_refs)" "" "${cur}"
                return
                ;;
        esac

	case "$cur" in
	--cleanup=*)
		__gitcomp "default strip verbatim whitespace
			" "" "${cur##--cleanup=}"
		return
		;;
        --reuse-message=*|--reedit-message=*|\
        --fixup=*|--squash=*)
                __gitcomp_nl "$(__git_refs)" "" "${cur#*=}"
                return
                ;;
	--untracked-files=*)
		__gitcomp "all no normal" "" "${cur##--untracked-files=}"
		return
		;;
	--*)
		__gitcomp "
			--all-tracked --bypass-untracked-check --staged --dirty
			--author= --signoff --verify --no-verify
			--amend --include --only --interactive
			--dry-run --reuse-message= --reedit-message=
			--reset-author --file= --message= --template=
			--cleanup= --untracked-files --untracked-files=
			--verbose --quiet --fixup= --squash=
			"
		return
	esac

        if git rev-parse --verify --quiet HEAD >/dev/null; then
                __git_complete_index_file "--committable"
        else
                # This is the first commit
                __git_complete_index_file "--cached"
        fi
}

_eg_diff ()
{
  local cur="${COMP_WORDS[COMP_CWORD]}"
  case "$cur" in
  --*)
    __gitcomp "--staged --unstaged
      --cached --stat --numstat --shortstat --summary
      --patch-with-stat --name-only --name-status --color
      --no-color --color-words --no-renames --check
      --full-index --binary --abbrev --diff-filter
      --find-copies-harder --pickaxe-all --pickaxe-regex
      --text --ignore-space-at-eol --ignore-space-change
      --ignore-all-space --exit-code --quiet --ext-diff
      --no-ext-diff"
    return
    ;;
  esac
  __git_complete_file
}

_eg_help ()
{
  local i c=1 command

  while [ $c -lt $cword ]; do
    i="${words[c]}"
    case "$i" in
    topic) command="$i"; break ;;
    esac
    ((c++))
  done

  if [ -n "$command" ]; then
    __gitcomp "$(__eg_topics)"
    return
  fi

  case "$cur" in
  --*)
      __gitcomp "--all"
      return
      ;;
  *)
    __gitcomp "$(__eg_commands) topic"  # 'eg help' followed by <cmd> or 'topic'
    ;;
  esac
}

_eg_reset ()
{
	__git_has_doubledash && return

	local cur="${COMP_WORDS[COMP_CWORD]}"
	case "$cur" in
	--*)
		__gitcomp "--working-copy --no-unstaging --merge --mixed --hard --soft --patch"
		return
		;;
	esac
	__gitcomp "$(__git_refs)"
}

_eg_revert ()
{
  local cur="${COMP_WORDS[COMP_CWORD]}"
  case "$cur" in
  --*)
    __gitcomp "--commit --no-commit --staged --in --since"
    return
    ;;
  esac
  __git_complete_file
}

_eg_track ()
{
  local cur="${COMP_WORDS[COMP_CWORD]}"
  case "$cur" in
  --*)
    __gitcomp "--show --show-all --unset"
    return
    ;;
  esac
  __git_complete_remote_or_refspec
}

__eg_main ()
{
  local i c=1 command __git_dir

  while [ $c -lt $cword ]; do
    i="${words[c]}"
    case "$i" in
    --git-dir=*) __git_dir="${i#--git-dir=}" ;;
    --git-dir)   ((c++)) ; __git_dir="${words[c]}" ;;
    --bare)      __git_dir="." ;;
    --version|-p|--paginate) ;;
    --help)      command="help"; break ;;
    --translate|--debug) ;;
    -*) ;;
    *) command="$i"; break ;;
    esac
    ((c++))
  done

  if [ -z "$command" ]; then
    case "$cur" in
    --*)   __gitcomp "
      --debug
      --translate
      --paginate
      --no-pager
      --git-dir=
      --bare
      --version
      --exec-path=
      --work-tree=
      --namespace=
      --no-replace-objects
      --help
      "
      ;;
    *)     __gitcomp "$(__eg_commands) $(__git_aliases)" ;;
    esac
    return
  fi

  local completion_func="_eg_${command//-/_}"
  declare -f $completion_func >/dev/null && $completion_func && return

  completion_func="_git_${command//-/_}"
  declare -f $completion_func >/dev/null && $completion_func && return

  local expansion=$(__git_aliased_command "$command")
  if [ -n "$expansion" ]; then
    completion_func="_git_${expansion//-/_}"
    declare -f $completion_func >/dev/null && $completion_func
  fi
}

# wrapper for backwards compatibility
_eg ()
{
  __git_wrap__eg_main
}

__git_complete eg __eg_main
