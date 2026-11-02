#!/bin/zsh
# Đóng gói VietIME thành file .zip (universal: Apple Silicon + Intel) để phát hành trên GitHub Releases
set -e
cd "$(dirname $0)"
export CLANG_MODULE_CACHE_PATH=${CLANG_MODULE_CACHE_PATH:-/tmp/mcache}
OUT=dist; APP=$OUT/VietIME.app
rm -rf $OUT; mkdir -p $APP/Contents/MacOS $APP/Contents/Resources
for A in arm64 x86_64; do
  swiftc -O -module-name VietIME -target $A-apple-macos13.0 src/main.swift src/Telex.swift -o $OUT/VietIME-$A
done
lipo -create $OUT/VietIME-arm64 $OUT/VietIME-x86_64 -output $APP/Contents/MacOS/VietIME
rm $OUT/VietIME-arm64 $OUT/VietIME-x86_64
cp src/Info.plist $APP/Contents/
cp -R src/en.lproj src/vi.lproj src/icon.tiff $APP/Contents/Resources/
xattr -cr $APP
# Có chứng chỉ Developer ID thì đặt biến SIGN_ID="Developer ID Application: Tên (TEAMID)", không thì ký ad-hoc
codesign --force --options runtime --sign "${SIGN_ID:--}" $APP

cat > $OUT/Cai-dat.command <<'EOS'
#!/bin/zsh
cd "$(dirname "$0")"
killall VietIME 2>/dev/null
rm -rf ~/Library/Input\ Methods/VietIME.app
mkdir -p ~/Library/Input\ Methods
cp -R VietIME.app ~/Library/Input\ Methods/
xattr -dr com.apple.quarantine ~/Library/Input\ Methods/VietIME.app
open ~/Library/Input\ Methods/VietIME.app
open "x-apple.systempreferences:com.apple.Keyboard-Settings.extension"
echo "Xong. Đăng xuất/đăng nhập lại, rồi vào Cài đặt > Bàn phím > Nguồn nhập > + > Tiếng Việt > VNMIE."
EOS
chmod +x $OUT/Cai-dat.command
(cd $OUT && zip -qry VietIME-macOS.zip VietIME.app Cai-dat.command)
echo "Đã tạo $OUT/VietIME-macOS.zip"
