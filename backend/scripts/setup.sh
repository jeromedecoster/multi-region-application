setup() {

    log AWS_REGION_CONFIG $AWS_REGION_CONFIG
    log PROJECT_NAME $PROJECT_NAME

    # if the S3 bucket $PROJECT_NAME does not exists
    # https://docs.aws.amazon.com/cli/latest/reference/s3api/head-bucket.html
    if [[ -n $(aws s3api head-bucket --bucket $PROJECT_NAME 2>&1 ) ]];
    then
        error FAIL bucket $PROJECT_NAME not found
        exit
    fi

    cd "$PROJECT_DIR/backend/terraform"
    # https://www.terraform.io/cli/commands/init
    terraform init \
        -input=false \
        -backend=true \
        -backend-config="region=$AWS_REGION_CONFIG" \
        -backend-config="bucket=$PROJECT_NAME" \
        -backend-config="key=backend.tfstate" \
        -reconfigure
}

setup
