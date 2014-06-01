#!/bin/bash

fail () {
    if [ ! -z "${1}" ]; then
        echo $1
    fi
    exit 1
}

print_usage () {
    echo "Usage: $(basename $0) options"
    echo
    echo "Options:"
    echo "    -artifacts PATH            path to artifacts dir with ipa and dSYM file"
    echo "    -api-token VALUE           testflight api token"
    echo "    -team-token VALUE          testflight team token"
    echo "    -distribution-lists VALUE  comma separated distribution list names which will receive access to the build"
    echo "    -upload-dsym               upload dsym"
    echo
}

while [[ $# > 1 ]]
do
key="$1"
shift

case $key in
    -artifacts)
    ARTIFACTS_DIR="$1"
    shift
    ;;
    -api-token)
    API_TOKEN="$1"
    shift
    ;;
    -team-token)
    TEAM_TOKEN="$1"
    shift
    ;;
    -output-file)
    OUTPUT_FILE="$1"
    shift
    ;;
    -distribution-lists)
    DISTRIBUTION_LISTS="$1"
    shift
    ;;
    -upload-dsym)
    UPLOAD_DSYM="1"
    ;;
    *)
            # unknown option
    ;;
esac
done

if [ -z "${ARTIFACTS_DIR}" ]; then
    fail "Missing -artifacts argument"
fi

if [ -z "${API_TOKEN}" ]; then
    fail "Missing -api-token argument"
fi

if [ -z "${TEAM_TOKEN}" ]; then
    fail "Missing -team-token argument"
fi

ARTIFACTS_DIR=`cd "${ARTIFACTS_DIR}"; pwd`

IPA_FILE=$(find $ARTIFACTS_DIR -name "*.ipa")

CURL_OPTIONS="-s http://testflightapp.com/api/builds.json"
CURL_OPTIONS="$CURL_OPTIONS -F file=@\"${IPA_FILE}\""

if [ -n "${UPLOAD_DSYM}" ]; then
    DSYM_FILE=$(find $ARTIFACTS_DIR -name "*.dSYM.zip")
    CURL_OPTIONS="$CURL_OPTIONS -F dsym=@\"${DSYM_FILE}\""
fi
CURL_OPTIONS="$CURL_OPTIONS -F api_token=${API_TOKEN}"
CURL_OPTIONS="$CURL_OPTIONS -F team_token=${TEAM_TOKEN}"
CURL_OPTIONS="$CURL_OPTIONS -F notes=\"TBD\""
CURL_OPTIONS="$CURL_OPTIONS -F notify=True"
if [ -n "${DISTRIBUTION_LISTS}" ]; then
    CURL_OPTIONS="$CURL_OPTIONS -F distribution_lists=\"${DISTRIBUTION_LISTS}\""
fi

TESTFLIGHT_JSON=`curl $CURL_OPTIONS`

if [ ! -z "${OUTPUT_FILE}" ]; then
    echo $TESTFLIGHT_JSON > $OUTPUT_FILE
fi
