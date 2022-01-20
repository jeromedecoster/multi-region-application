.SILENT:

help:
	{ grep --extended-regexp '^[a-zA-Z0-9._-]+:.*#[[:space:]].*$$' $(MAKEFILE_LIST) || true; } \
	| awk 'BEGIN { FS = ":.*#[[:space:]]*" } { printf "\033[1;32m%-23s\033[0m%s\n", $$1, $$2 }'

setup: # terraform setup
	./make.sh setup

validate: # terraform validation
	./make.sh validate

apply: # terraform plan + apply (deploy)
	./make.sh apply

upload: # upload an image to the primary region (with aws cli)
	./make.sh upload

get-state-primary: # get application current state from primary region (with apigateway)
	./make.sh get-state-primary

get-state-secondary: # get application current state from primary region (with apigateway)
	./make.sh get-state-secondary

switch-state: # switch application current state (with aws cli)
	./make.sh switch-state

add-comment-primary: # add a comment to a random photo at primary region (with apigateway)
	./make.sh add-comment-primary

add-comment-secondary: # add a comment to a random photo at secondary region (with apigateway)
	./make.sh add-comment-secondary

get-comment-primary: # get comments of a random photo from primary region (with apigateway)
	./make.sh get-comment-primary

get-comment-secondary: # get comments of a random photo from secondary region (with apigateway)
	./make.sh get-comment-secondary

destroy: # destroy all resources
	./make.sh destroy
