# VietIME

Bộ gõ tiếng Việt (Telex) cho macOS, viết bằng Swift với InputMethodKit. Không cần Xcode, chỉ cần Command Line Tools.

## Tính năng
- **Telex** (`s f r x j z`, `aa ee oo`, `w`, `dd`) và **VNI** (`1-5` dấu, `6` â ê ô, `7` ơ ư, `8` ă, `9` đ, `0` bỏ dấu); đặt dấu kiểu hiện đại (`hoà`). Gõ lặp phím dấu để hủy (`oss` → `os`).
- Chuyển Việt/Anh bằng phím tắt, chọn được trong menu: ⌥Z (mặc định), ⌥Space, ⌃Space, ⌃⇧Z. (⌃Space có thể trùng phím tắt đổi bàn phím của macOS.)
- Biểu tượng VN/EN trên thanh menu; menu chọn kiểu gõ, phím tắt, bật/tắt "w đầu từ thành ư" (tắt khi hay gõ tiếng Anh) và thoát.
- Cài đặt được lưu lại giữa các lần chạy.

## Cài đặt
```sh
xcode-select --install   # nếu chưa có Swift
./Cai-dat-VietIME.command   # hoặc: ./build.sh install
```
Sau đó đăng xuất/đăng nhập lại, vào Cài đặt → Bàn phím → Nguồn nhập → `+` → Tiếng Việt → VietIME.

## Cấu trúc
- `src/Telex.swift` — engine Telex
- `src/main.swift` — IMKInputController, menu, phím tắt
- `src/Info.plist`, `src/*.lproj` — cấu hình và tên hiển thị
- `build.sh` — build, ký ad-hoc, cài đặt
- `test.sh` — kiểm thử engine Telex (56 ca)

Giấy phép: MIT

## Phát hành cho máy khác
```sh
./package.sh   # tạo dist/VietIME-macOS.zip (universal arm64 + x86_64)
```
Đưa file zip lên GitHub Releases. Người dùng giải nén, bấm chuột phải `Cai-dat.command` → Mở.
Muốn không bị macOS cảnh báo: có tài khoản Apple Developer rồi chạy `./notarize.sh` (xem hướng dẫn biến môi trường đầu file).
