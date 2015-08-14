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

BUILD_OS_DIR="build/Release-iphoneos"
BUILD_SIM_DIR="build/Release-iphonesimulator"
PROJ_EXT=".xcodeproj"
PROJ_NAME=""
SCHEME=""
SDKS="iphonesimulator iphoneos"

validate_project()
{
	if ! [[ $1 =~ ".xcodeproj" ]];then
		echo "Inavlid xcode project!"
		exit 0
	fi
}

build_lib()
{
	xcodebuild -target "${PROJ_NAME}" -scheme "${SCHEME}" -configuration Release -sdk $1 BUILD_DIR=$2 clean build
}

build_fat_lib()
{
	lipo -create $1 $2 -output $3
}

# 获取工程名称
PROJ_NAME=${1##*/}
# 进入工程目录
CURRENT_WORK_DIR=`echo ${1%/*}`

# 当前目录
if [[ ${CURRENT_WORK_DIR} != $1 ]];then
	echo "Not equal"
	cd ${CURRENT_WORK_DIR}
fi

PROJ_DIR=`pwd`

# 截取名称
SCHEME=${PROJ_NAME%.*}
LIB_NAME="lib${SCHEME}.a"
LIB_SIM_PATH="${PROJ_DIR}/${BUILD_SIM_DIR}/${LIB_NAME}"
LIB_OS_PATH="${PROJ_DIR}/${BUILD_OS_DIR}/${LIB_NAME}"

# 校验
validate_project ${PROJ_NAME}
# build
for SDK in ${SDKS}
do
	build_lib "${SDK}" "${PROJ_DIR}/build"
done

TARGET_PATH="${HOME}/Desktop/${SCHEME}"
mkdir -p "${TARGET_PATH}/include"
LIB_FAT_PATH="${TARGET_PATH}/${LIB_NAME}"
# 合并lib
build_fat_lib "${LIB_SIM_PATH}" "${LIB_OS_PATH}" "${LIB_FAT_PATH}"
# 移动include
cp -a "${PROJ_DIR}/${BUILD_OS_DIR}/include/${SCHEME}/" "${TARGET_PATH}/include"
# 删除build目录
rm -R "${PROJ_DIR}/build"
