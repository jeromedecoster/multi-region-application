.SILENT:

help:
	{ grep --extended-regexp '^[a-zA-Z0-9._-]+:.*#[[:space:]].*$$' $(MAKEFILE_LIST) || true; } \
	| awk 'BEGIN { FS = ":.*#[[:space:]]*" } { printf "\033[1;32m%-18s\033[0m%s\n", $$1, $$2 }'

setup: # terraform setup + npm install the website
	./make.sh setup

validate: # terraform validation
	./make.sh validate

apply: # terraform plan + apply (deploy)
	./make.sh apply

ui-config: # generate the uiConfig.json file
	./make.sh ui-config

website-local: # browse the website in localhost 
	./make.sh website-local

website-deploy: # deploy the static website to the S3 bucket
	./make.sh website-deploy

cdn-url: # get the cloudfront URL
	./make.sh cdn-url

destroy: # destroy all resources
	./make.sh destroy
