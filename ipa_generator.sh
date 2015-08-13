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

# pull_from_repo_if_needed()
# {
#     echo "pulling ...."
# }
#
# param1: project name
# param2: scheme
# param3: archive path
archive_project()
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
build_project()
{
    xcodebuild -project $1 \
    -target $2 \
    -configuration Release \
    -sdk iphoneos \
    BUILD_DIR=$3 \
    clean \
    build | tee xcodebuild.log
}

# param1 : .app file path
# param2 : ipa target path
# param3 : .dSYM file path
# param4 : target .dSYM file path
package_app()
{
    # 暂时不用签名 --sign $x --embed $y
    xcrun -sdk iphoneos PackageApplication -v $1 -o $2
    if [ $? != 0 ]; then
        echo "archive failed!!!!!!!!!!!!!!!!"
        exit 110
    fi

    # zipping dSYM
    ( cd $3 ; zip -r -X $4 "${PRODUCT_NAME}.app.dSYM" )
}

echo "Package beigin at ${CURRENT_DATE} ..."

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

# Build path
BUILD_DIR="${PROJ_PATH}/build"

# Archive path
ARCHIVE_PATH="${PROJ_PATH}/archive"
PROJECT_BUILDDIR="${ARCHIVE_PATH}/${PRODUCT_NAME}.xcarchive/Products/Applications"

# Source path
APP_FILE_PATH=""

# IPA path
IPA_FOLDER="${PROJ_PATH}/output"
IPA_PATH="${IPA_FOLDER}/${PRODUCT_NAME}.ipa"
DSYM_ZIP_OUTPUT_PATH="${IPA_FOLDER}/${PRODUCT_NAME}.dSYM.zip"

if [ "${BUILD_TO_PACKAGE}" == "1" ];then
    build_project "${PROJECT_NAME}" "${SCHEME}" "${BUILD_DIR}"
    # generate compile_commands.json
    # oclint-xcodebuild xcodebuild.log
    # Package params
    APP_FILE_PATH="${BUILD_DIR}/Release-iphoneos/${PRODUCT_NAME}.app"
    DSYM_INPUT_PATH="${BUILD_DIR}/Release-iphoneos/"
else
    archive_project "${PROJECT_NAME}" "${SCHEME}" "${ARCHIVE_PATH}/${PRODUCT_NAME}"
    # Package params
    APP_FILE_PATH="${ARCHIVE_PATH}/${PRODUCT_NAME}.xcarchive/Products/Applications/${PRODUCT_NAME}.app"
    DSYM_INPUT_PATH="${ARCHIVE_PATH}/${PRODUCT_NAME}.xcarchive/dSYMs"
fi

mkdir -p "${IPA_FOLDER}"

# pakcage
package_app "${APP_FILE_PATH}" "${IPA_PATH}" "${DSYM_INPUT_PATH}" "${DSYM_ZIP_OUTPUT_PATH}"

BUILD_FINISH_DATE=`date +%Y%m%d%H%M%S`
echo "Packaging finish at ${BUILD_FINISH_DATE}"
