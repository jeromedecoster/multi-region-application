validate() {
    log validate backend
    cd "$PROJECT_DIR/backend/terraform"
    terraform fmt -recursive
    terraform validate
}

validate
