import Foundation
// Kiểm thử engine Telex: chạy bằng ./test.sh
let cases: [(String, String)] = [
 ("os","ó"),("as","á"),("ys","ý"),("Os","Ó"),("OS","Ó"),("vieetj","việt"),("Nguwowfi","Người"),
 ("hoaf","hoà"),("quas","quá"),("quys","quý"),("duwowcj","dược"),("dduwowcj","được"),("DDuwowcj","Được"),
 ("tooi","tôi"),("giaos","giáo"),("gif","gì"),("chuyeenr","chuyển"),("muas","múa"),("khoer","khoẻ"),
 ("huongw","hương"),("huowng","hương"),("quow","quơ"),("tuw","tư"),("aw","ă"),("aws","ắ"),("ow","ơ"),("w","ư"),
 ("oss","os"),("tooss","tôs"),("asf","à"),("asz","a"),("s","s"),("xin","xin"),("mama","mama"),
 ("dd","đ"),("ddi","đi"),("Dd","Đ"),("nguwowfi","người"),("thuyr","thuỷ"),("hoawcj","hoặc"),
]
let vniCases: [(String, String)] = [
 ("o1","ó"),("Viet65","Việt"),("Nguoi7","Ngươi"), ("hoa2","hoà"),("d9i","đi"),("D9i","Đi"),("tu7","tư"),
 ("a8","ă"),("a81","ắ"),("tuong7","tương"),("to6i","tôi"),("o11","o1"),("a0","a"),("hoang5","hoạng"),
]
var fail = 0
for (input, want) in vniCases {
    var t = Telex(); t.vni = true; for c in input { t.feed(c) }
    let got = t.render()
    if got != want { fail += 1; print("FAIL VNI \(input): got \(got), want \(want)") }
}
// Digit không có tác dụng thì feed trả về false (để chuyển tiếp ký tự)
var tv = Telex(); tv.vni = true
if tv.feed("5") { fail += 1; print("FAIL VNI: số 5 đầu từ phải trả về false") }
// Tắt w -> ư
var tw = Telex(); tw.wToU = false; tw.feed("w")
if tw.render() != "w" { fail += 1; print("FAIL wToU=false: \(tw.render())") }

for (input, want) in cases {
    var t = Telex(); for c in input { t.feed(c) }
    let got = t.render()
    if got != want { fail += 1; print("FAIL \(input): got \(got), want \(want)") }
}
print(fail == 0 ? "OK: \(cases.count + vniCases.count + 2) test" : "\(fail) test lỗi")
exit(fail == 0 ? 0 : 1)
