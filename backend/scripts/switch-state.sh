switch-state() {
    cd "$PROJECT_DIR/backend/terraform"
    TABLE_NAME=$(terraform output --raw dynamodb_config_name)
    log TABLE_NAME $TABLE_NAME

    log UUID $UUID
    log AWS_REGION_PRIMARY $AWS_REGION_PRIMARY

    CURRENT_STATE=$(aws dynamodb get-item \
        --table-name $TABLE_NAME \
        --key '{"appId":{"S":"'$UUID'"}}' \
        --region $AWS_REGION_PRIMARY \
        | jq --raw-output '.Item.state.S')
    log CURRENT_STATE $CURRENT_STATE

    [[ $CURRENT_STATE == 'active' ]] && NEW_STATE=failover || NEW_STATE=active;
    log NEW_STATE $NEW_STATE

    aws dynamodb update-item \
        --table-name $TABLE_NAME \
        --key '{"appId":{"S":"'$UUID'"}}' \
        --update-expression "SET #sn = :sv" \
        --expression-attribute-names '{"#sn":"state"}' \
        --expression-attribute-values '{":sv":{"S":"'$NEW_STATE'"}}' \
        --return-values ALL_NEW \
        --region $AWS_REGION_PRIMARY
}

switch-state
