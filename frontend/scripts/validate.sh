validate() {
    log START $(date "+%Y-%d-%m %H:%M:%S")
    START=$SECONDS

    log validate frontend
    cd "$PROJECT_DIR/frontend/terraform"
    terraform fmt -recursive
    terraform validate

    log END $(date "+%Y-%d-%m %H:%M:%S")
    info DURATION $(($SECONDS - $START)) seconds
}

validate
