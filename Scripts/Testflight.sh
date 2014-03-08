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
    echo "    -artifacts PATH           path to artifacts dir with ipa and dSYM file"
    echo "    -api-token VALUE          testflight api token"
    echo "    -team-token VALUE         testflight team token"
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
DSYM_FILE=$(find $ARTIFACTS_DIR -name "*.dSYM.zip")

TESTFLIGHT_JSON=`curl -s http://testflightapp.com/api/builds.json -F "file=@${IPA_FILE}" -F "dsym=@${DSYM_FILE}" -F "api_token=${API_TOKEN}" -F "team_token=${TEAM_TOKEN}" -F "notes=TBD" -F "notify=True" -F "distribution_lists=Internal"`

if [ ! -z "${OUTPUT_FILE}" ]; then
    echo $TESTFLIGHT_JSON > $OUTPUT_FILE
fi
