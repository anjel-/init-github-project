#!/bin/bash
### file header ###############################################################
#: NAME:          init-github-project.sh
#: SYNOPSIS:      GIT_USER="username" init-github-project.sh COMMAND <project>
#: DESCRIPTION:   create a new local project and a Github repo for it
#: RETURN CODES:  0-SUCCESS, 1-FAILURE
#: RUN AS:        any user
#: AUTHOR:        anjel- <andrei.jeleznov@gmail.com>
#: VERSION:       1.0-SNAPSHOT
#: URL:           https://github.com/anjel-/init-github-project.git
#: CHANGELOG:
#: DATE:          AUTHOR:          CHANGES:
#: 27-03-2017     anjel-           start of the project
### external parameters #######################################################
set +x
declare -r GIT_USER="${GIT_USER:-unknown}"             # Github username
declare -r GIT_URL="${GIT_URL:-https://github.com}"    # Github URL
declare -r API_URL="https://api.github.com/user/repos" # Github API URL
### internal parameters #######################################################
readonly SUCCESS=0 FAILURE=1
readonly FALSE=0  TRUE=1
exitcode=$SUCCESS
### service parameters ########################################################
set +x
_TRACE="${_TRACE:-0}"       # 0-FALSE, 1-print traces
_DEBUG="${_DEBUG:-1}"       # 0-FALSE, 1-print debug messages
_FAILFAST="${_FAILFAST:-1}" # 0-run to the end, 1-stop at the first failure
_DRYRUN="${_DRYRUN:-0}"     # 0-FALSE, 1-send no changes to remote systems
_UNSET="${_UNSET:-0}"       # 0-FALSE, 1-treat unset parameters as an error
TIMEFORMAT='[TIME] %R sec %P%% util'
(( _DEBUG )) && echo "[DEBUG] _TRACE=\"$_TRACE\" _DEBUG=\"$_DEBUG\" _FAILFAST=\"$_FAILFAST\""
# set shellopts ###############################################################
(( _TRACE )) && set -x || set +x
(( _FAILFAST )) && { set -o pipefail; } || true
(( _UNSET )) && set -u || set +u
### functions #################################################################
###
function die { #@ print ERR message and exit
	(( _FAILFAST )) && printf "[ERR] %s\n" "$@" >&2 || printf "[WARN] %s\n" "$@" >&2
	(( _FAILFAST )) && exit $FAILURE || { exitcode=$FAILURE; true; }
} #die
###
function print { #@ print qualified message
  local level="INFO"
  (( _DEBUG )) && level="DEBUG"
  (( _DRYRUN )) && level="DRYRUN+$level"||true
  printf "[$level] %s\n" "$@"
} #print
###
function usage { #@ USAGE:
  echo "
  [INFO] manages the Github projects:
  [INFO] INIT \$project \$description - create a new local project and a Github repo for it
  [INFO] Usage: $_SCRIPT_NAME INIT <arguments>
  "
} #usage
###
function initialize { #@ initialization of the script
  (( _DEBUG )) && echo "[DEBUG] enter $FUNCNAME"
	(( _DEBUG )) && print "Initializing the variables"
  local ostype="$(uname -o)"
  export _LOCAL_HOSTNAME=$(hostname -s);
  case $_OS_TYPE in
  	"Cygwin")
  		_SCRIPT_DIR="${0%\\*}"
  		_SCRIPT_NAME="${0##*\\}"
  	;;
  	*)
  	local tempvar="$(readlink -e "${BASH_SOURCE[0]}")"
  	_SCRIPT_DIR="${tempvar%/*}"
  	_SCRIPT_NAME="${tempvar##/*/}"
  	;;
  esac
} #initialize
###
function checkPreconditions { #@ prerequisites for the whole script
  (( _DEBUG )) && echo "[DEBUG] enter $FUNCNAME"
  (( _DEBUG )) && print "Checking the preconditions for the whole script"
  case $CMD in
  HELP|help) return ;;
  esac
  [[ $GIT_USER == unknown ]]&& die "please, supply a GIT_USER"||true
} #checkPreconditions
###
function init_project { #@ init the github project
	(( _DEBUG )) && echo "[DEBUG] enter $FUNCNAME"
  (( _DEBUG )) && print "Initializing the Github project"
  (( $# <1 ))&& die "need a Github project name to start with";true
  local project="$1";shift
  local description="${@}";shift
  [[ -z "$description" ]] && die "please, supply a description for a project"||true
  (( _DEBUG ))&& print "Creating \"$project\" with '$description'"
  print "Check for existing Github project repo"
  if wget --spider -q $GIT_URL/$GIT_USER/${project}.git
  then
    print "project \"$project\" already exists on Github. I will initialte a local working tree"
  else
    local data="{\"name\":\"${project}\",\"description\":\"${description}\"}"
    if (( _DRYRUN ));then
      print "Creating the $project on Github"
    else
      if ! \
        curl -X POST -u "${GIT_USER}" "${API_URL}" -d "${data}"
      then die "during creation of Github repo"
      fi
    fi
  fi
  (( _DEBUG )) && print "check if current folder is a project folder"||true
  local currdir="${PWD##*/}"
  if [[ $currdir == $project ]];then
    print "the current dir is a project folder"
    if git status -s 2>/dev/null
    then
      local remote_url="$(git remote get-url --push origin)"
      if [[ $remote_url == $GIT_URL/$GIT_USER/${project}.git ]]
      then print "a folder \"$PWD\" already has a git project \"$project\" initialized"
      else die "a folder \"$PWD\" already has a git project \"$project\" initialized"
      fi
    fi
  else
    (( _DEBUG ))&&print "Making the project folder"
    [[ -d ./$project ]]&&die "a folder \"$project\" already exists"
    mkdir ./$project&&pushd ./$project>/dev/null
  fi
  print "Initiation the local git repo"
    if ! git init
  then die "initializing a git project"
  fi
  echo "# Project: $project" > README.md
  echo "# $description" >> README.md
  git add README.md
  [[ ! -f .gitignore ]] && touch .gitignore||true
  git add .gitignore
  git commit -m "initial commit for $project"
  git remote add origin $GIT_URL/$GIT_USER/${project}.git
  (( _DRYRUN )) && print "pushing to master@origin"|| git push -u origin master
} #init_project
###
function clone_project { #@ 
	(( _DEBUG )) && echo "[DEBUG] enter $FUNCNAME"
  (( _DEBUG )) && print "Cloning the Github project"
	:
} #clone_project
### function main #############################################################
function main {
  (( _DEBUG )) && echo "[DEBUG] enter $FUNCNAME"
  initialize
  checkPreconditions "$CMD"
  case $CMD in
  INIT|init)
  init_project "$@"
  ;;
  HELP|help)
  usage
  ;;
  *) die "unknown command \"$CMD\" "
  ;;
  esac
} #main
### call main #################################################################
(( $# < 1 )) && die "$(basename $0) needs a command to proceed."
declare CMD="$1" ;shift
set -- "$@"
declare VAR
main "$@"
exit $exitcode
