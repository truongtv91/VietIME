#!/bin/zsh
cd "$(dirname "$0")"
if [ ! -d build/VietIME.app ]; then
  CLANG_MODULE_CACHE_PATH=/tmp/mcache ./build.sh || exit 1
fi
xattr -cr build/VietIME.app
killall VietIME 2>/dev/null
rm -rf ~/Library/Input\ Methods/VietIME.app
cp -R build/VietIME.app ~/Library/Input\ Methods/
open ~/Library/Input\ Methods/VietIME.app
open "x-apple.systempreferences:com.apple.Keyboard-Settings.extension"
echo "Đã cài VietIME. Trong Cài đặt: Nguồn nhập > Chỉnh sửa > + > Tiếng Việt > VietIME."
echo "Nếu chưa thấy, hãy đăng xuất rồi đăng nhập lại."
