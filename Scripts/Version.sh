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
    echo "Examples:"
    echo "    $(basename $0) -plist project.plist -output version.h"
    echo "    $(basename $0) -workspace project.xcworkspace -scheme Project"
    echo
    echo "Options:"
    echo "    -output PATH              output file, content will be replaced with BUILD_NUMBER and BUILD_HASH defines"
    echo "    -plist PATH               path to plist"
    echo "    -workspace PATH           path to workspace"
    echo "    -scheme NAME              scheme to use"
    echo "    -project-dir PATH         path to project dir [default: current dir]"
    echo "    -prefix NAME              prefix to use [default: none]"
    echo
}

is_git() {
    if [ -d "${PROJECT_DIR}/.git" ]; then
        return 0
    else
        return 1
    fi
}

is_svn() {
    if [ -d "${PROJECT_DIR}/.svn" ]; then
        return 0
    else
        return 1
    fi
}

build_number() {
    if is_git; then
        build_number_git
    elif is_svn; then   
        build_number_svn
    else
        build_number_other
    fi
}

build_hash() {
   if is_git; then
        build_hash_git
    elif is_svn; then   
        build_hash_svn
    else
        build_hash_other
    fi 
}

build_number_git() {
    git rev-list $(build_hash_git) | wc -l | tr -d ' '
}

build_number_svn() {
    svnversion -nc "${PROJECT_DIR}" | sed -e 's/^[^:]*://;s/[A-Za-z]//' | tr -d ' '
}

build_number_other() {
    echo "1"
}

build_hash_git() {
	git log --pretty=format:%h -n1 --abbrev-commit | tr -d ' '
}

build_hash_svn() {
    build_number_svn
}

build_hash_other() {
    echo "1"
}

# --------

while [[ $# > 1 ]]
do
key="$1"
shift

case $key in
    -project-dir)
    PROJECT_DIR="$1"
    shift
    ;;
    -workspace)
    PROJECT_WORKSPACE="$1"
    shift
    ;;
    -scheme)
    PROJECT_SCHEME="$1"
    shift
    ;;
    -output)
    OUTPUT_FILE="$1"
    shift
    ;;
    -plist)
    PLIST_PATH="$1"
    shift
    ;;
    -prefix)
    PREFIX="$1"
    shift
    ;;
    *)
            # unknown option
    ;;
esac
done

if [ -z "${PROJECT_DIR}" ]; then
    PROJECT_DIR=`pwd`
fi

if [ -z "${PLIST_PATH}" ]; then
    XCTOOL=`which xctool`
    if [ ! -e "${XCTOOL}" ]; then
        fail "Install xctool: brew install xctool"
    fi

    XCTOOL_OPTIONS=""

    if [ ! -z "${PROJECT_WORKSPACE}" ]; then
        XCTOOL_OPTIONS="$XCTOOL_OPTIONS -workspace $PROJECT_WORKSPACE"
    fi

    if [ ! -z "${PROJECT_SCHEME}" ]; then
        XCTOOL_OPTIONS="$XCTOOL_OPTIONS -scheme $PROJECT_SCHEME"
    fi

    XCTOOL_OPTIONS="$XCTOOL_OPTIONS -showBuildSettings"
    PLIST_PATH=`$XCTOOL $XCTOOL_OPTIONS | grep INFOPLIST_FILE | awk -F'=' '{print $2}' | tr -d ' '`
fi

if [ -z "${PLIST_PATH}" ]; then
    fail "Use must use either 'plist' or 'workspace' + 'scheme'"
fi

# ------

if [ -z "${OUTPUT_FILE}" ]; then
    MARKETING_VERSION=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${PLIST_PATH}"`
    if [ "$?" -ne 0 ] ; then fail; fi

    echo "${MARKETING_VERSION}.$(build_number)"
else
    if [ -z "${PREFIX}" ]; then
        PREFIX=""
    fi

    echo "#define ${PREFIX}BUILD_NUMBER $(build_number)" > $OUTPUT_FILE
    echo "#define ${PREFIX}BUILD_HASH @\"$(build_hash)\"" >> $OUTPUT_FILE

    touch "${PLIST_PATH}"
fi
