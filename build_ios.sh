#!/bin/bash
set -e

# 确保使用正确的路径
export PATH="/usr/local/bin:$PATH"

# 设置环境变量
export XCODE_PATH=$(xcode-select -p)
export IOS_SDK=$XCODE_PATH/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk
export SIM_SDK=$XCODE_PATH/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk

# 创建输出目录
OUTPUT_DIR="build-ios"
rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR

# 编译函数
compile_arch() {
    ARCH=$1
    SDK=$2
    
    BUILD_DIR="${OUTPUT_DIR}/${ARCH}"
    mkdir -p $BUILD_DIR
    pushd $BUILD_DIR > /dev/null
    
    echo "▸ 配置 $ARCH..."
    cmake ../.. \
        -DCMAKE_SYSTEM_NAME=iOS \
        -DCMAKE_OSX_ARCHITECTURES=$ARCH \
        -DCMAKE_OSX_SYSROOT=$SDK \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0 \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=OFF \
        -DENABLE_SM2=ON \
        -DENABLE_SM3=ON \
        -DENABLE_SM4=ON \
        -DENABLE_SM9=ON \
        -G Ninja
        
    echo "▸ 编译 $ARCH..."
    ninja
    
    # 关键修改：GmSSL 3.x 生成的库是 libgmssl.a
    mkdir -p lib
    cp bin/libgmssl.a lib/
    
    popd > /dev/null
}

# 编译各架构
compile_arch "arm64" "$IOS_SDK"
compile_arch "x86_64" "$SIM_SDK"

# 合并通用库
UNIVERSAL_DIR="${OUTPUT_DIR}/universal"
mkdir -p $UNIVERSAL_DIR/lib

# 合并为单个库 (GmSSL 3.x 只生成一个库)
lipo -create \
    "${OUTPUT_DIR}/arm64/lib/libgmssl.a" \
    "${OUTPUT_DIR}/x86_64/lib/libgmssl.a" \
    -output "$UNIVERSAL_DIR/lib/libgmssl.a"

# 复制头文件
if [ -d "${OUTPUT_DIR}/arm64/include" ]; then
    cp -R "${OUTPUT_DIR}/arm64/include" "$UNIVERSAL_DIR/"
elif [ -d "../../include" ]; then
    cp -R "../../include" "$UNIVERSAL_DIR/"
else
    echo "⚠️ 警告: 找不到头文件目录"
fi

echo "✅ 编译成功！"
echo "库文件位置: $UNIVERSAL_DIR/lib/libgmssl.a"
echo "头文件位置: $UNIVERSAL_DIR/include"

# 验证文件
file "$UNIVERSAL_DIR/lib"/*.a
lipo -info "$UNIVERSAL_DIR/lib/libgmssl.a"
