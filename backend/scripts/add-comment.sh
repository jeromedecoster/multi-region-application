add-comment() {
    log START $(date "+%Y-%d-%m %H:%M:%S")
    START=$SECONDS
    
    cd "$PROJECT_DIR/backend/terraform"
    JSON=$(terraform output -json)
    PHOTOS_PRIMARY=$(echo "$JSON" | jq --raw-output '.apigateway_store_url_primary.value')
    PHOTOS_SECONDARY=$(echo "$JSON" | jq --raw-output '.apigateway_store_url_secondary.value')
    log PHOTOS_PRIMARY $PHOTOS_PRIMARY
    log PHOTOS_SECONDARY $PHOTOS_SECONDARY

    PRIMARY_BUCKET=$(echo "$JSON" | jq --raw-output '.bucket_primary.value')
    SECONDARY_BUCKET=$(echo "$JSON" | jq --raw-output '.bucket_secondary.value')
    log PRIMARY_BUCKET $PRIMARY_BUCKET
    log SECONDARY_BUCKET $SECONDARY_BUCKET

    if [[ $1 == 'primary' ]];
    then
        BUCKET=$PRIMARY_BUCKET
        PHOTOS_API=$PHOTOS_PRIMARY
    else
        BUCKET=$SECONDARY_BUCKET
        PHOTOS_API=$PHOTOS_SECONDARY
    fi

    # random photo id
    RAND_PHOTO_ID=$(aws s3 ls s3://$BUCKET/public/ | \
        sort --random-sort | \
        head -n 1 | \
        awk '{ print $NF }')
    log RAND_PHOTO_ID $RAND_PHOTO_ID

    # https://serverfault.com/a/103366
    UUID=$(uuidgen)
    log UUID $UUID

    DATA='{"commentId":"'$UUID'", "message":"message '$RANDOM'", "photoId":"'$RAND_PHOTO_ID'", "user":"'$COGNITO_USERNAME'"}'
    log DATA $DATA

    PHOTO_URL=$PHOTOS_API/comments/$RAND_PHOTO_ID
    log PHOTO_URL $PHOTO_URL

    info execute curl $PHOTOS_API/comments/$RAND_PHOTO_ID --header "Content-Type: application/json" --data "$DATA"
    curl $PHOTOS_API/comments/$RAND_PHOTO_ID \
        --header "Content-Type: application/json" \
        --data "$DATA"

    # force new line
    echo

    log END $(date "+%Y-%d-%m %H:%M:%S")
    info DURATION $(($SECONDS - $START)) seconds
}

if [[ -z $1 ]];
then
    echo 'add-comment.sh <primary|secondary> required'
    echo
    echo 'usage: add-comment.sh primary'
    echo 'usage: add-comment.sh secondary'
    exit 0
fi

add-comment $1
