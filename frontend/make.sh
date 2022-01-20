#!/bin/bash

# the ROOT directory (parent of this script file)
export PROJECT_DIR="$(cd "$(dirname "$0")/.."; pwd)"

# source config/env.sh
source $PROJECT_DIR/config/env.sh

# source config/func.sh
source $PROJECT_DIR/config/func.sh


# log $1 in underline then $@ then a newline
under() {
    local arg=$1
    shift
    echo -e "\033[0;4m${arg}\033[0m ${@}"
    echo
}

usage() {
    under usage 'call the Makefile directly: make dev
      or invoke this file directly: ./make.sh dev'
}

setup() {
    bash scripts/setup.sh
}

validate() {
    bash scripts/validate.sh
}

apply() {
    bash scripts/apply.sh
}

ui-config() {
    bash scripts/ui-config.sh
}

website-local() {
    bash scripts/website-local.sh
}

website-deploy() {
    bash scripts/website-deploy.sh
}

cdn-url() {
    bash scripts/cdn-url.sh
}

destroy() {
    bash scripts/destroy.sh
}

# if `$1` is a function, execute it. Otherwise, print usage
# compgen -A 'function' list all declared functions
# https://stackoverflow.com/a/2627461
FUNC=$(compgen -A 'function' | grep $1)
[[ -n $FUNC ]] && { info execute $1; eval $1; } || usage;
exit 0
