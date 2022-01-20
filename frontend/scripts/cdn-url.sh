cdn-url() {
    cd "$PROJECT_DIR/frontend/terraform"
    CDN_URL=$(terraform output --raw domain_name)
    log CDN_URL $CDN_URL
}

cdn-url