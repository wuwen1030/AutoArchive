#!/bin/bash

#################################################################
#
#                  Created and owned by Ben
#                Contact me: wuwen1030@126.com
#                https://github.com/wuwen1030
#
#################################################################
set -e
set -x

PROJ_EXT=".xcodeproj"
CURRENT_DATE=`date +%Y%m%d%H%M%S`
CFG_FILE_NAME="config.cfg"

pull_repo_if_needed()
{
    echo "Pull from remote ..."
    if [[ $1 == 1 ]]; then
        git pull --rebase
    fi
    git submodule update --remote
}

# param1: project name
# param2: scheme
# param3: archive path
xctool_archive()
{
    xctool -project $1 \
    -scheme $2 \
    -reporter json-compilation-database:compile_commands.json \
    -sdk iphoneos \
    archive \
    -archivePath $3
}

# param1: project name
# param2: scheme
# param3: build path
xcodebuild_archive()
{
    xcodebuild -project $1 \
    -scheme $2 \
    -sdk iphoneos \
    archive \
    -archivePath $3 \
    | tee xcodebuild.log
}

# param1 : archive path
# param2 : product name
# param3 : ipa target path
package_app()
{
    APP_PATH=$1/$2.xcarchive/Products/Applications/$2.app
    DSYM_INPUT_PATH=$1/$2.xcarchive/dSYMs
    WATCH_KIT_PATH=$1/$2.xcarchive/WatchKitSupport/WK

    SLIM_IPA_PATH=$3/$2_slim.ipa
    DSYM_ZIP_OUTPUT_PATH=$3/$2.dSYM.zip

    # package
    xcrun -sdk iphoneos PackageApplication -v ${APP_PATH} -o ${SLIM_IPA_PATH}
    if [ $? != 0 ]; then
        echo "archive failed!!!!!!!!!!!!!!!!"
        exit 110
    fi

    # Add watch kit support
    cd $3
    unzip $2_slim.ipa
    mkdir WatchKitSupport
    cp ${WATCH_KIT_PATH} WatchKitSupport/WK
    zip -qr $2.ipa Payload WatchKitSupport
    # clear
    rm $2_slim.ipa
    rm -R WatchKitSupport
    rm -R Payload

    # zipping dSYM
    ( cd ${DSYM_INPUT_PATH} ; zip -r -X ${DSYM_ZIP_OUTPUT_PATH} ${PRODUCT_NAME}.app.dSYM )
}

echo "Package begin at ${CURRENT_DATE} ..."

# To project path
CURRENT_WORK_DIR=`echo ${0%/*}`

if [ -d ${CURRENT_WORK_DIR} ];then
    cd ${CURRENT_WORK_DIR}
fi

SCRIPT_PATH=`pwd`
cd "${SCRIPT_PATH}/.."
PROJ_PATH=`pwd`

# import config
. "${SCRIPT_PATH}/${CFG_FILE_NAME}"

# Archive path
ARCHIVE_PATH="${PROJ_PATH}/archive"

# IPA path
IPA_DIR="${PROJ_PATH}/output"

# Update source code
pull_repo_if_needed ${UPDATE_FIRST}

# Build
if [ "${USE_XCTOOL}" == "0" ];then
    xcodebuild_archive "${PROJECT_NAME}" "${SCHEME}" "${ARCHIVE_PATH}/${PRODUCT_NAME}"
else
    xctool_archive "${PROJECT_NAME}" "${SCHEME}" "${ARCHIVE_PATH}/${PRODUCT_NAME}"
fi

# package
mkdir -p "${IPA_DIR}"
package_app "${ARCHIVE_PATH}" "${PRODUCT_NAME}" "${IPA_DIR}"

BUILD_FINISH_DATE=`date +%Y%m%d%H%M%S`
echo "Packaging finish at ${BUILD_FINISH_DATE}"
