ui-config() {
    log START $(date "+%Y-%d-%m %H:%M:%S")
    START=$SECONDS

    cd "$PROJECT_DIR/backend/terraform"
    BACKEND_JSON=$(terraform output -json)
    # echo "$BACKEND_JSON"

    cd "$PROJECT_DIR/frontend/terraform"
    FRONTEND_JSON=$(terraform output -json)
    # echo "$FRONTEND_JSON"

    IDENTITY_POOL_ID=$(echo "$FRONTEND_JSON" | jq --raw-output '.identity_pool_id.value')
    USER_POOL_CLIENT_ID=$(echo "$FRONTEND_JSON" | jq --raw-output '.user_pool_client_id.value')
    USER_POOL_ID=$(echo "$FRONTEND_JSON" | jq --raw-output '.user_pool_id.value')
    UI_REGION=$AWS_REGION_PRIMARY
    STATE_PRIMARY=$(echo "$BACKEND_JSON" | jq --raw-output '.apigateway_config_url_primary.value')/state/$UUID
    BUCKET_PRIMARY=$(echo "$BACKEND_JSON" | jq --raw-output '.bucket_primary.value')
    PHOTOS_PRIMARY=$(echo "$BACKEND_JSON" | jq --raw-output '.apigateway_store_url_primary.value')
    REGION_PRIMARY=$AWS_REGION_PRIMARY
    STATE_SECONDARY=$(echo "$BACKEND_JSON" | jq --raw-output '.apigateway_config_url_secondary.value')/state/$UUID
    BUCKET_SECONDARY=$(echo "$BACKEND_JSON" | jq --raw-output '.bucket_secondary.value')
    PHOTOS_SECONDARY=$(echo "$BACKEND_JSON" | jq --raw-output '.apigateway_store_url_secondary.value')
    REGION_SECONDARY=$AWS_REGION_SECONDARY

    log IDENTITY_POOL_ID $IDENTITY_POOL_ID
    log USER_POOL_CLIENT_ID $USER_POOL_CLIENT_ID
    log USER_POOL_ID $USER_POOL_ID
    log UI_REGION $UI_REGION
    log STATE_PRIMARY $STATE_PRIMARY
    log BUCKET_PRIMARY $BUCKET_PRIMARY
    log PHOTOS_PRIMARY $PHOTOS_PRIMARY
    log REGION_PRIMARY $REGION_PRIMARY
    log STATE_SECONDARY $STATE_SECONDARY
    log BUCKET_SECONDARY $BUCKET_SECONDARY
    log PHOTOS_SECONDARY $PHOTOS_SECONDARY
    log REGION_SECONDARY $REGION_SECONDARY

    JSON=$(cat <<EOF
{
    "identityPoolId": "$IDENTITY_POOL_ID",
    "userPoolClientId": "$USER_POOL_CLIENT_ID",
    "userPoolId": "$USER_POOL_ID",
    "uiRegion": "$UI_REGION",
    "primary": {
        "stateUrl": "$STATE_PRIMARY",
        "objectStoreBucketName": "$BUCKET_PRIMARY",
        "photosApi": "$PHOTOS_PRIMARY",
        "region": "$REGION_PRIMARY"
    },
    "secondary": {
        "stateUrl": "$STATE_SECONDARY",
        "objectStoreBucketName": "$BUCKET_SECONDARY",
        "photosApi": "$PHOTOS_SECONDARY",
        "region": "$REGION_SECONDARY"
    }
}
EOF
)
    echo "$JSON" > "$PROJECT_DIR/frontend/website/public/uiConfig.json"

    info created file website/public/uiConfig.json
    echo "$JSON" | jq

    log END $(date "+%Y-%d-%m %H:%M:%S")
    info DURATION $(($SECONDS - $START)) seconds
}

ui-config