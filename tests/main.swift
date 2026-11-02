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
var fail = 0
for (input, want) in cases {
    var t = Telex(); for c in input { t.feed(c) }
    let got = t.render()
    if got != want { fail += 1; print("FAIL \(input): got \(got), want \(want)") }
}
print(fail == 0 ? "OK: \(cases.count) test" : "\(fail) test lỗi")
exit(fail == 0 ? 0 : 1)
