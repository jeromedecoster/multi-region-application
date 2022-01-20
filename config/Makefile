.SILENT:

help:
	{ grep --extended-regexp '^[a-zA-Z0-9._-]+:.*#[[:space:]].*$$' $(MAKEFILE_LIST) || true; } \
	| awk 'BEGIN { FS = ":.*#[[:space:]]*" } { printf "\033[1;32m%-18s\033[0m%s\n", $$1, $$2 }'

setup: # setup config + terraform remote state S3 bucket
	./make.sh setup

destroy: # destroy config + terraform remote state S3 bucket
	./make.sh destroy
