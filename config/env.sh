#!/bin/bash

#
# variables
#

# the ROOT directory (parent of this script file)
export PROJECT_DIR="$(cd "$(dirname "$0")/.."; pwd)"

# source config/func.sh
source $PROJECT_DIR/config/func.sh

[[ ! -f "$PROJECT_DIR/config/uuid" ]] && { error abort config/uuid not found. config setup is required; exit; } || true
[[ ! -f "$PROJECT_DIR/config/rand" ]] && { error abort config/rand not found. config setup is required; exit; } || true

# AWS variables
export AWS_PROFILE=default
export AWS_REGION_PRIMARY=us-east-1 # us-east-2
export AWS_REGION_SECONDARY=ap-northeast-1 # eu-west-2
export AWS_REGION_CONFIG=eu-west-3
export COGNITO_USERNAME=jerome

# use your email to receive the email sent by AWS Cognito
export COGNITO_EMAIL=CHANGE_EMAIL_HERE@gmail.com

if [[ "$COGNITO_EMAIL" == 'CHANGE_EMAIL_HERE@gmail.com' ]];
then
    error abort COGNITO_EMAIL variable must be defined in config/env.sh
    exit
fi


export UUID=$(cat "$PROJECT_DIR/config/uuid")
# log UUID $UUID

export RAND=$(cat "$PROJECT_DIR/config/rand")
# log RAND $RAND

# project name
export PROJECT_NAME=multi-region-app-$RAND

#
# overwrite TF variables
#
export TF_VAR_project_name=$PROJECT_NAME
export TF_VAR_primary_region=$AWS_REGION_PRIMARY
export TF_VAR_secondary_region=$AWS_REGION_SECONDARY
export TF_VAR_app_state_uuid=$UUID
export TF_VAR_cognito_username=$COGNITO_USERNAME
export TF_VAR_cognito_email=$COGNITO_EMAIL
