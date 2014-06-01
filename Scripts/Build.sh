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
    echo "    -workspace PATH           path to workspace"
    echo "    -scheme NAME              scheme to use"
    echo "    -sdk VERSION              sdk to use"
    echo "    -configuration NAME       configuration to use"
    echo "    -identity NAME            signing identity name (iPhone Developer: John Smith)"
    echo "    -profile PATH             provisioning profile to use (file will be copied to ~/Library/MobileDevice/Provisioning Profiles)"
    echo "    -artifacts PATH           dir for artifacts (tests output, ipa, dSYM files)"
    echo "    -run-tests                run tests instead of building"
    echo
}


while [[ $# > 0 ]]
do
key="$1"
shift

case $key in
    -workspace)
    PROJECT_WORKSPACE="$1"
    shift
    ;;
    -scheme)
    PROJECT_SCHEME="$1"
    shift
    ;;
    -sdk)
    BUILD_SDK="$1"
    shift
    ;;
    -configuration)
    BUILD_CONFIGURATION="$1"
    shift
    ;;
    -identity)
    CODE_SIGN_IDENTITY="$1"
    shift
    ;;
    -profile)
    PROVISIONING_PROFILE="$1"
    shift
    ;;
    -artifacts)
    ARTIFACTS_DIR="$1"
    shift
    ;;
    -help)
    HELP="1" 
    print_usage
    exit 0
    ;;
    -run-tests)
    RUN_TESTS="1"
    ;;
    *)
            # unknown option
    ;;
esac
done

if [ -z "${PROJECT_WORKSPACE}" ]; then
    fail "missing '-workspace' argument"
fi

if [ -z "${PROJECT_SCHEME}" ]; then
    fail "Missing -scheme argument"
fi

if [ -z "${BUILD_CONFIGURATION}" ]; then
    fail "Missing -configuration argument"
fi

if [ -z "${BUILD_SDK}" ]; then
    fail "Missing -sdk argument"
fi

if [ -z "${ARTIFACTS_DIR}" ]; then
    fail "Missing -artifacts argument"
fi

# --

if [ -z "${RUN_TESTS}" ]; then
    if [ -z "${CODE_SIGN_IDENTITY}" ]; then
        fail "Missing -identity argument"
    fi

    if [ -z "${PROVISIONING_PROFILE}" ]; then
        fail "Missing -profile argument"
    fi

    if [ ! -e "${PROVISIONING_PROFILE}" ]; then
        fail "Provisioning profile not found: ${PROVISIONING_PROFILE}"
    fi
fi

# --

if [ -z "${BUILD_RESULTS_DIR}" ]; then
    BUILD_RESULTS_DIR="build-tmp"
fi

# Prepare folders

rm -rf "${BUILD_RESULTS_DIR}"

if [ ! -e "${ARTIFACTS_DIR}" ]; then
    mkdir -p "${ARTIFACTS_DIR}" || fail "Can't create ${ARTIFACTS_DIR}"
fi

if [ ! -e "${BUILD_RESULTS_DIR}" ]; then
    mkdir -p "${BUILD_RESULTS_DIR}" || fail "Can't create ${BUILD_RESULTS_DIR}"
fi

# Convert folder path to absolute path

BUILD_RESULTS_DIR=`cd "${BUILD_RESULTS_DIR}"; pwd`
ARTIFACTS_DIR=`cd "${ARTIFACTS_DIR}"; pwd`

# Check required tools

MP_PARSER=`which mobileprovision-read`
if [ ! -e "${MP_PARSER}" ]; then
    fail "Install mobileprovision-read: https://github.com/0xc010d/mobileprovision-read"
fi

XCTOOL=`which xctool`
if [ ! -e "${XCTOOL}" ]; then
    fail "Install xctool: brew install xctool"
fi

# -----

if [ ! -z "${PROVISIONING_PROFILE}" ]; then
    # Get UUID from provisioning profile
    PROVISIONING_PROFILE_UUID=`mobileprovision-read -f "${PROVISIONING_PROFILE}" -o UUID`

    # Copy provisioning profile into library
    PROVISIONING_PROFILE_LIBRARY="${HOME}/Library/MobileDevice/Provisioning Profiles/${PROVISIONING_PROFILE_UUID}.mobileprovision"
    cp "${PROVISIONING_PROFILE}" "${PROVISIONING_PROFILE_LIBRARY}"
fi

# build

XCTOOL_OPTIONS="-workspace $PROJECT_WORKSPACE"
XCTOOL_OPTIONS="$XCTOOL_OPTIONS -scheme $PROJECT_SCHEME"
XCTOOL_OPTIONS="$XCTOOL_OPTIONS -configuration $BUILD_CONFIGURATION"
XCTOOL_OPTIONS="$XCTOOL_OPTIONS -sdk $BUILD_SDK"
XCTOOL_OPTIONS="$XCTOOL_OPTIONS -reporter plain"

if [ -z "${RUN_TESTS}" ]; then
    $XCTOOL $XCTOOL_OPTIONS \
            CONFIGURATION_BUILD_DIR="${BUILD_RESULTS_DIR}" \
            CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
            PROVISIONING_PROFILE="${PROVISIONING_PROFILE_UUID}" \
            CONFIGURATION_TEMP_DIR="${BUILD_RESULTS_DIR}/config-tmp-dir" \
            build || fail
else
    $XCTOOL $XCTOOL_OPTIONS \
            -reporter "junit:${ARTIFACTS_DIR}/tests.junit" \
            test || fail

    exit 0
fi 

# package

APP_DIR=$(find $BUILD_RESULTS_DIR -type d -name "*.app")
APP_DSYM_FILE=$(find $BUILD_RESULTS_DIR -type d -name "*.dSYM")

if [ ! -e "${APP_DIR}" ]; then
    fail "Failed to locate build products"
fi

APP_NAME=$(basename $APP_DIR)
APP_NAME=${APP_NAME%.*}

BUILD_NUMBER=`/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${APP_DIR}/Info.plist"`
MARKETING_VERSION=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${APP_DIR}/Info.plist"`

BUILD_CONFIGURATION=`echo ${BUILD_CONFIGURATION} | tr '[:upper:]' '[:lower:]'`

APP_DESTINATION="${ARTIFACTS_DIR}/${APP_NAME}-${BUILD_CONFIGURATION}-${MARKETING_VERSION}.${BUILD_NUMBER}.ipa"
DSYM_DESTINATION="${ARTIFACTS_DIR}/${APP_NAME}-${BUILD_CONFIGURATION}-${MARKETING_VERSION}.${BUILD_NUMBER}.dSYM.zip"

rm -rf "${APP_DESTINATION}"
rm -rf "${DSYM_DESTINATION}"

xcrun -sdk "${BUILD_SDK}" PackageApplication "${APP_DIR}" -o "${APP_DESTINATION}" --sign "${CODE_SIGN_IDENTITY}" --embed "${PROVISIONING_PROFILE_LIBRARY}" || fail "Failed to pack application"

ditto -ck --rsrc --extattr --keepParent "${APP_DSYM_FILE}" "${DSYM_DESTINATION}" || fail 'Failed to copy dSYM file'

rm -rf "${BUILD_RESULTS_DIR}"

exit 0
