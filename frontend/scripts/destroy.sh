destroy() {
    log START $(date "+%Y-%d-%m %H:%M:%S")
    START=$SECONDS

    cd "$PROJECT_DIR/frontend/terraform"
    info terraform destroy
    terraform destroy -auto-approve

    cd "$PROJECT_DIR/frontend/website"
    info remove website/node_modules
    rm --force --recursive node_modules

    info remove website/public/uiConfig.json
    rm --force public/uiConfig.json

    log END $(date "+%Y-%d-%m %H:%M:%S")
    info DURATION $(($SECONDS - $START)) seconds
}

destroy
