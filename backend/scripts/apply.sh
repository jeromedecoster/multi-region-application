apply() {
    log START $(date "+%Y-%d-%m %H:%M:%S")
    START=$SECONDS

    log PROJECT_NAME $PROJECT_NAME
    
    # first test if the S3 bucket for the remote config still exists 
    # created with : terraform init ... -backend-config="bucket=$PROJECT_NAME" with `make setup`
    # sometimes, a resource failed to create just because the remote state was not found

    # if the S3 bucket $PROJECT_NAME does not exists
    # https://docs.aws.amazon.com/cli/latest/reference/s3api/head-bucket.html
    if [[ -n $(aws s3api head-bucket --bucket $PROJECT_NAME 2>&1 ) ]];
    then
        error FAIL bucket $PROJECT_NAME not found
        exit
    fi

    cd "$PROJECT_DIR/backend/terraform"
    # terraform plan 
    terraform plan -out=terraform.plan
    terraform apply -auto-approve terraform.plan

    log END $(date "+%Y-%d-%m %H:%M:%S")
    info DURATION $(($SECONDS - $START)) seconds
}

apply
