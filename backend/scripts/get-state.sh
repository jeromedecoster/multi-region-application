get-state() {
    cd "$PROJECT_DIR/backend/terraform"
    JSON=$(terraform output -json)
    URL_PRIMARY=$(echo "$JSON" | jq --raw-output '.apigateway_config_url_primary.value')
    log URL_PRIMARY $URL_PRIMARY

    URL_SECONDARY=$(echo "$JSON" | jq --raw-output '.apigateway_config_url_secondary.value')
    log URL_SECONDARY $URL_SECONDARY

    if [[ $1 == 'primary' ]];
    then
        INVOKE_URL=$URL_PRIMARY
    else
        INVOKE_URL=$URL_SECONDARY
    fi

    STATE_URL=$INVOKE_URL/state/$UUID
    log STATE_URL $STATE_URL

    curl --silent $STATE_URL | jq
}

if [[ -z $1 ]];
then
    echo 'get-state.sh <primary|secondary> required'
    echo
    echo 'usage: get-state.sh primary'
    echo 'usage: get-state.sh secondary'
    exit 0
fi

get-state $1
