#!/bin/zsh
cd "$(dirname "$0")"
# Build lại từ mã nguồn nếu có Swift, nếu không dùng bản đã build sẵn
if xcrun --find swiftc >/dev/null 2>&1; then
  CLANG_MODULE_CACHE_PATH=/tmp/mcache ./build.sh || { echo "Build lỗi"; exit 1; }
fi
[ -d build/VietIME.app ] || { echo "Không tìm thấy build/VietIME.app"; exit 1; }
xattr -cr build/VietIME.app
killall VietIME 2>/dev/null
rm -rf ~/Library/Input\ Methods/VietIME.app
mkdir -p ~/Library/Input\ Methods
cp -R build/VietIME.app ~/Library/Input\ Methods/
open ~/Library/Input\ Methods/VietIME.app
open "x-apple.systempreferences:com.apple.Keyboard-Settings.extension"
echo "Đã cài. Trong Cài đặt: Nguồn nhập > + > Tiếng Việt > VNMIE. Nếu chưa thấy, đăng xuất rồi đăng nhập lại."
