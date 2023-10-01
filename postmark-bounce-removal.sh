#!/bin/bash

log_debug() {
    if $DEBUG; then
        echo "[DEBUG] $1"
    fi
}

log_main() {
    echo "$1"
}

process_domain() {
    log_debug "Processing domain: $DOMAIN"
    OFFSET=0

    while true; do
        type_query=""
        if [ "$bounce_type" != "All" ]; then
            type_query="&type=$bounce_type"
        fi

        log_debug "Fetching bounces for domain: $DOMAIN at offset: $OFFSET"
        response=$(curl -s -H "Accept: application/json" -H "X-Postmark-Server-Token: $API_TOKEN" "https://api.postmarkapp.com/bounces?inactive=true&count=500&offset=$OFFSET$type_query")

        if ! echo "$response" | jq -e '.Bounces' > /dev/null || [[ $(echo "$response" | jq '.Bounces | length') -eq 0 ]]; then
            log_debug "No more bounces found for domain: $DOMAIN at offset: $OFFSET"
            break
        fi

        if [ "$headers_set" = false ]; then
            headers="DeletionStatus,"$(echo "$response" | jq -r ".Bounces[0] | del(.Tag, .Details) | keys_unsorted[]" | tr '\n' ',')
            echo "$headers" > $OUTPUT_FILE
            headers_set=true
        fi

        if [ "$DOMAIN" != "all" ]; then
            emails_data=$(echo "$response" | jq -r ".Bounces[] | select(.Email | endswith(\"@$DOMAIN\")) | del(.Tag, .Details) | [.[]] | @csv")
        else
            emails_data=$(echo "$response" | jq -r ".Bounces[] | del(.Tag, .Details) | [.[]] | @csv")
        fi

        IFS=$'\n'
        for email_data in $emails_data; do
            if $DRY_RUN; then
                log_main "DRY RUN - Would remove bounce for email: $(echo "$email_data" | cut -d',' -f11) (bounceId: $(echo "$email_data" | cut -d',' -f2))"
                echo "DRY_RUN,$email_data" >> $OUTPUT_FILE
            else
                email=$(echo "$email_data" | cut -d',' -f11)
                bounceId=$(echo "$email_data" | cut -d',' -f2)
                delete_response=$(curl -s -X PUT -H "Accept: application/json" -H "Content-Type: application/json" -H "X-Postmark-Server-Token: $API_TOKEN" -d "" "https://api.postmarkapp.com/bounces/$bounceId/activate")

                status="Failed"
                if [[ "$delete_response" == *'"Message":"OK"'* ]]; then
                    status="Success"
                fi

                log_debug "Deletion response for $email: $delete_response"
                log_main "Removing bounce for email: $email - $status"
                echo "$status,$email_data" >> $OUTPUT_FILE
            fi
        done

        OFFSET=$((OFFSET+500))
    done
}

API_TOKEN_FILE="api_token.conf"

if [ ! -f "$API_TOKEN_FILE" ]; then
    log_main "API token file ($API_TOKEN_FILE) not found!"
    exit 1
fi

API_TOKEN=$(cat "$API_TOKEN_FILE")

DEBUG=false
DRY_RUN=false
DOMAINS=""
FILE=""
OUTPUT_FILE="result.csv"
headers_set=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --domains=*) DOMAINS="${1#*=}" ;;
        --file=*) FILE="${1#*=}" ;;
        --dry-run) DRY_RUN=true ;;
        --debug) DEBUG=true ;;
        *) log_main "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

log_debug "Starting the script."
log_debug "Using API Token starting with: ${API_TOKEN:0:4}..."

if [ -z "$DOMAINS" ] && [ -z "$FILE" ]; then
    log_main "Please provide a domain or a file containing domains."
    exit 1
fi

if [ ! -z "$FILE" ]; then
    if [ "$FILE" == "domains.conf" ]; then
        log_debug "Reading domains from file: $FILE"
        DOMAINS=$(cat $FILE | tr '\n' ',')
    else
        log_main "The domain file should be named domains.conf."
        exit 1
    fi
fi

declare -A bounce_types
bounce_types=(
    [1]="AddressChange"
    [2]="AutoResponder"
    [3]="BadEmailAddress"
    [4]="Blocked"
    [5]="ChallengeVerification"
    [6]="DMARCPolicy"
    [7]="DnsError"
    [8]="HardBounce"
    [9]="InboundError"
    [10]="ManuallyDeactivated"
    [11]="OpenRelayTest"
    [12]="SMTPApiError"
    [13]="SoftBounce"
    [14]="SpamComplaint"
    [15]="SpamNotification"
    [16]="Subscribe"
    [17]="TemplateRenderingFailed"
    [18]="Transient"
    [19]="Undeliverable"
    [20]="Unconfirmed"
    [21]="Unsubscribe"
    [22]="Unknown"
    [23]="VirusNotification"
    [24]="All"
)

log_main "Select a bounce type:"
for i in "${!bounce_types[@]}"; do
    log_main "$i) ${bounce_types[$i]}"
done

read -p "Enter bounce type number: " bounce_choice
bounce_type=${bounce_types[$bounce_choice]}

if [ -z "$bounce_type" ]; then
    log_main "Invalid bounce type number."
    exit 1
fi

if [ "$DOMAINS" == "all" ]; then
    PROCESS_ALL_DOMAINS=true
else
    PROCESS_ALL_DOMAINS=false
    IFS=',' read -ra ADDR <<< "$DOMAINS"
fi

if $PROCESS_ALL_DOMAINS; then
    DOMAIN="all"
    process_domain
else
    for DOMAIN in "${ADDR[@]}"; do
        process_domain
    done
fi

log_debug "Script execution completed."
