@echo off

# echo ==================== Android ====================
# cmake --preset android-arm64-v8a
# cmake --build build/android-arm64-v8a --config Release
# 
# cmake --preset android-armeabi-v7a
# cmake --build build/android-armeabi-v7a --config Release
# 
# cmake --preset android-x86_64
# cmake --build build/android-x86_64 --config Release
# 
# cmake --preset android-x86
# cmake --build build/android-x86 --config Release


echo ==================== Windows ====================
cmake --preset windows-x64
cmake --build build/windows-x64 --config Release

cmake --preset windows-x86
cmake --build build/windows-x86 --config Release


# echo ==================== Linux ====================
# cmake --preset linux-x64
# cmake --build build/linux-x64 --config Release
# 
# cmake --preset linux-x86
# cmake --build build/linux-x86 --config Release
# 
# cmake --preset linux-arm64
# cmake --build build/linux-arm64 --config Release
# 


# echo ==================== MacOS ====================
# cmake --preset macos-x64
# cmake --build build/macos-x64 --config Release
# 
# cmake --preset macos-arm64
# cmake --build build/macos-arm64 --config Release
# 
# cmake --preset macos-universal
# cmake --build build/macos-universal --config Release
# 