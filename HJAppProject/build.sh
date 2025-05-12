#!/bin/bash
buildPlatform=$1
echo build $buildPlatform
# 定义主版本号
MAJOR_VERSION="1.0.3"

# 动态生成构建号（日期+时间戳）
BUILD_NUMBER=$(date +%Y%m%d%H%M)

line=$( cat pubspec.yaml | grep -Eo "version: .*#😁😈")
echo $line
# 执行替换
sed -i '' "s/$line/version: ${MAJOR_VERSION}+${BUILD_NUMBER} #😁😈/g" pubspec.yaml

echo "✅ 版本号已更新为: ${MAJOR_VERSION}+${BUILD_NUMBER}"

if [[ $buildPlatform = "android" ]] 
then
    echo "✅ 构建 Android 版本"
    flutter build apk --release
else [[ $buildPlatform = "ios" ]]
    echo "✅ 构建 iOS 版本"
    flutter build ios --release --no-codesign
fi