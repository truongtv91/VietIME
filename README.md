# VietIME

Bộ gõ tiếng Việt (Telex) cho macOS, viết bằng Swift với InputMethodKit. Không cần Xcode, chỉ cần Command Line Tools.

## Tính năng
- Telex: `s f r x j z` (dấu), `aa ee oo` (â ê ô), `w` (ư ơ ă), `dd` (đ); đặt dấu kiểu hiện đại (`hoà`).
- Chuyển Việt/Anh bằng **Option + Z**.
- Biểu tượng VN/EN trên thanh menu, có menu chọn chế độ và thoát.

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

## Chưa có
VNI, hủy dấu bằng gõ lặp, tùy chỉnh phím tắt.

Giấy phép: MIT
