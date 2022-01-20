website-deploy() {
    log START $(date "+%Y-%d-%m %H:%M:%S")
    START=$SECONDS

    cd "$PROJECT_DIR/frontend/website"

    if [[ ! -d "$PROJECT_DIR/frontend/website" ]];
    then
        # take a long time !
        info npm run build
        npm run build
    fi

    info copy public/uiConfig.json to build/uiConfig.json
    cp "$PROJECT_DIR/frontend/website/public/uiConfig.json" "$PROJECT_DIR/frontend/website/build/uiConfig.json"

    cd "$PROJECT_DIR/frontend/terraform"
    BUCKET_WEBSITE=$(terraform output --raw bucket_website)
    log BUCKET_WEBSITE $BUCKET_WEBSITE

    cd "$PROJECT_DIR/frontend/website/build"
    info UPLOAD files to bucket
    aws s3 cp --recursive . s3://$BUCKET_WEBSITE/console/

    log END $(date "+%Y-%d-%m %H:%M:%S")
    info DURATION $(($SECONDS - $START)) seconds
}

website-deploy