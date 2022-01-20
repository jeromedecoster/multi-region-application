get-comment() {
    log START $(date "+%Y-%d-%m %H:%M:%S")
    START=$SECONDS
    
    cd "$PROJECT_DIR/backend/terraform"
    JSON=$(terraform output -json)
    PHOTOS_PRIMARY=$(echo "$JSON" | jq --raw-output '.apigateway_store_url_primary.value')
    PHOTOS_SECONDARY=$(echo "$JSON" | jq --raw-output '.apigateway_store_url_secondary.value')
    log PHOTOS_PRIMARY $PHOTOS_PRIMARY
    log PHOTOS_SECONDARY $PHOTOS_SECONDARY

    BUCKET_PRIMARY=$(echo "$JSON" | jq --raw-output '.bucket_primary.value')
    BUCKET_SECONDARY=$(echo "$JSON" | jq --raw-output '.bucket_secondary.value')
    log BUCKET_PRIMARY $BUCKET_PRIMARY
    log BUCKET_SECONDARY $BUCKET_SECONDARY

    if [[ $1 == 'primary' ]];
    then
        BUCKET=$BUCKET_PRIMARY
        PHOTOS_API=$PHOTOS_PRIMARY
    else
        BUCKET=$BUCKET_SECONDARY
        PHOTOS_API=$PHOTOS_SECONDARY
    fi

    # random photo id
    RAND_PHOTO_ID=$(aws s3 ls s3://$BUCKET/public/ | \
        sort --random-sort | \
        head -n 1 | \
        awk '{ print $NF }')
    log RAND_PHOTO_ID $RAND_PHOTO_ID

    info execute curl $PHOTOS_API/comments/$RAND_PHOTO_ID
    curl --silent $PHOTOS_API/comments/$RAND_PHOTO_ID | jq

    log END $(date "+%Y-%d-%m %H:%M:%S")
    info DURATION $(($SECONDS - $START)) seconds
}

if [[ -z $1 ]];
then
    echo 'get-comment.sh <primary|secondary> required'
    echo
    echo 'usage: get-comment.sh primary'
    echo 'usage: get-comment.sh secondary'
    exit 0
fi

get-comment $1
