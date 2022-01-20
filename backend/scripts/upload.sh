upload() {
    log START $(date "+%Y-%d-%m %H:%M:%S")
    START=$SECONDS
    
    cd "$PROJECT_DIR/backend/terraform"
    JSON=$(terraform output -json)
    BUCKET_PRIMARY=$(terraform output --raw bucket_primary)
    BUCKET_SECONDARY=$(terraform output --raw bucket_secondary)
    
    log BUCKET_PRIMARY $BUCKET_PRIMARY
    log BUCKET_SECONDARY $BUCKET_SECONDARY
    
    if [[ $1 == 'primary' ]];
    then
        UPLOAD_BUCKET=$BUCKET_PRIMARY
        WATCH_BUCKET=$BUCKET_SECONDARY
    else
        # not used finally ... only 1 direction replication
        UPLOAD_BUCKET=$BUCKET_SECONDARY
        WATCH_BUCKET=$BUCKET_PRIMARY
    fi

    cd "$PROJECT_DIR/backend"

    # https://legacy.imagemagick.org/Usage/color_mods/#duotone
    # https://legacy.imagemagick.org/script/color.php#color_names
    COLORS='aqua black blue chartreuse chocolate coral cyan fuchsia gray green lime magenta'
    COLORS="$COLORS maroon navy olive orange orchid purple red silver teal white yellow"
    COLOR=$(echo "$COLORS" | tr ' ' '\n' | sort --random-sort | head -n 1)
    log COLOR $COLOR
    
    TINT=$(echo '60 80 100 120 140' | tr ' ' '\n' | sort --random-sort | head -n 1)
    log TINT $TINT

    convert avatar.jpg -fill $COLOR -tint $TINT converted.jpg

    # https://serverfault.com/a/103366
    UUID=$(uuidgen)
    log UUID $UUID

    # https://serverfault.com/a/529319
    # UUID=$(cat /proc/sys/kernel/random/uuid)

    aws s3 cp converted.jpg s3://$UPLOAD_BUCKET/public/$UUID

    log WATCH_START $(date "+%Y-%d-%m %H:%M:%S")
    # aws s3 ls --recursive --human-readable s3://$WATCH_BUCKET
    
    #
    # wait replication to secondary bucket
    #

    COUNT=0
    while true;
    do
        COUNT=$((COUNT + 1))

        # IMPORTANT WARN : a replication rule can take several minutes (up to 5 or more minutes) to setup
        # if you upload a file just after the S3 bucket and the replication created, you can wait a
        # long time before the first replication is done. No file is skipped or forgotten, but the
        # first replicated file can time time. After that, it take less than 1 minute for each file
        # to be replicated
        LS=$(aws s3 ls --recursive --human-readable s3://$WATCH_BUCKET/public/ | grep $UUID)
        if [[ -n "$LS" ]];
        then
            info FOUND file replicated found after $COUNT calls
            break
        else
            log NOT_FOUND file not replicated after $COUNT calls
        fi

        if [[ $COUNT -eq 20 ]];
        then
            warn ABORT after 20 calls
            break
        fi
    done 
    log WATCH_END $(date "+%Y-%d-%m %H:%M:%S")

    log END $(date "+%Y-%d-%m %H:%M:%S")
    info DURATION $(($SECONDS - $START)) seconds
}

if [[ -z $1 ]];
then
    echo 'upload.sh <primary|secondary> required'
    echo
    echo 'usage: upload.sh primary'
    echo 'usage: upload.sh secondary'
    exit 0
fi

upload $1
