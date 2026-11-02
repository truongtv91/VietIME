#!/bin/zsh
# Ký Developer ID + notarize để máy khác mở không bị cảnh báo. Cần tài khoản Apple Developer.
# Dùng: SIGN_ID="Developer ID Application: Tên (TEAMID)" APPLE_ID=email TEAM_ID=TEAMID APP_PASSWORD=app-specific-password ./notarize.sh
set -e
cd "$(dirname $0)"
: ${SIGN_ID:?cần SIGN_ID} ${APPLE_ID:?cần APPLE_ID} ${TEAM_ID:?cần TEAM_ID} ${APP_PASSWORD:?cần APP_PASSWORD}
./package.sh
xcrun notarytool submit dist/VietIME-macOS.zip --apple-id "$APPLE_ID" --team-id "$TEAM_ID" --password "$APP_PASSWORD" --wait
xcrun stapler staple dist/VietIME.app
(cd dist && rm VietIME-macOS.zip && zip -qry VietIME-macOS.zip VietIME.app Cai-dat.command)
echo "Đã notarize: dist/VietIME-macOS.zip"
