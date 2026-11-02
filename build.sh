#!/bin/zsh
set -e
cd "$(dirname $0)"
APP=build/VietIME.app
rm -rf build; mkdir -p $APP/Contents/MacOS $APP/Contents/Resources
swiftc -O -module-name VietIME src/main.swift src/Telex.swift -o $APP/Contents/MacOS/VietIME
cp src/Info.plist $APP/Contents/
cp -R src/en.lproj src/vi.lproj $APP/Contents/Resources/
cp src/icon.tiff $APP/Contents/Resources/
xattr -cr $APP; codesign --force --sign - $APP
if [ "$1" = install ]; then
  rm -rf ~/Library/Input\ Methods/VietIME.app
  cp -R $APP ~/Library/Input\ Methods/
  killall VietIME 2>/dev/null || true
  echo "Đã cài. Vào Cài đặt > Bàn phím > Nguồn nhập > + > Tiếng Việt > VietIME (có thể cần đăng xuất/đăng nhập)."
fi
