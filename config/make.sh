#!/bin/bash

# the ROOT directory (parent of this script file)
export PROJECT_DIR="$(cd "$(dirname "$0")/.."; pwd)"

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
    log PROJECT_DIR $PROJECT_DIR

    # if file config/uuid does not exists
    if [[ ! -f "$PROJECT_DIR/config/uuid" ]];
    then
        
        uuidgen --random | tr -d '\n' > $PROJECT_DIR/config/uuid
        info created file ./config/uuid
    fi

    # if file config/rand does not exists
    if [[ ! -f "$PROJECT_DIR/config/rand" ]];
    then
        uuidgen --random | head --bytes 5 > $PROJECT_DIR/config/rand
        info created file ./config/rand
    fi

    # source config/env.sh (build new variables using config/uuid + config/rand)
    source $PROJECT_DIR/config/env.sh

    log UUID $UUID
    log RAND $RAND
    log PROJECT_NAME $PROJECT_NAME
    log AWS_REGION_CONFIG $AWS_REGION_CONFIG

    # if the S3 bucket $PROJECT_NAME does not exists
    # https://docs.aws.amazon.com/cli/latest/reference/s3api/head-bucket.html
    if [[ -n $(aws s3api head-bucket --bucket $PROJECT_NAME 2>&1 ) ]];
    then
        info CREATE config bucket $PROJECT_NAME
        # https://awscli.amazonaws.com/v2/documentation/api/latest/reference/s3/mb.html
        aws s3 mb s3://$PROJECT_NAME --region $AWS_REGION_CONFIG
    fi
}


destroy() {
    log PROJECT_DIR $PROJECT_DIR
    
    # source config/env.sh
    source $PROJECT_DIR/config/env.sh

    log PROJECT_NAME $PROJECT_NAME

    #
    # destroy config
    #

    # if the S3 bucket $PROJECT_NAME exists
    if [[ -z $(aws s3api head-bucket --bucket $PROJECT_NAME 2>&1 ) ]];
    then
    echo
        # https://awscli.amazonaws.com/v2/documentation/api/latest/reference/s3/rb.html
        aws s3 rb s3://$PROJECT_NAME --force
    fi
    rm --force "$PROJECT_DIR/config/uuid"
    rm --force "$PROJECT_DIR/config/rand"
}

# if `$1` is a function, execute it. Otherwise, print usage
# compgen -A 'function' list all declared functions
# https://stackoverflow.com/a/2627461
FUNC=$(compgen -A 'function' | grep $1)
[[ -n $FUNC ]] && { info execute $1; eval $1; } || usage;
exit 0
