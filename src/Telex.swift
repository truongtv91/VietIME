import Foundation

struct Letter { var b: Character; var upper: Bool; var m: Int } // m:1 ^ ,2 horn,3 breve,4 stroke

func isV(_ c: Character) -> Bool { "aeiouy".contains(c) }

struct Telex {
    var letters: [Letter] = []
    var tone = 0 // 0 none,1 sac,2 huyen,3 hoi,4 nga,5 nang
    var toneBlocked = false // đã hủy dấu bằng gõ lặp: các phím dấu sau đó là chữ thường

    static let toneKeys: [Character: Int] = ["s": 1, "f": 2, "r": 3, "x": 4, "j": 5]

    mutating func feed(_ ch: Character) {
        let lc = ch.lowercased().first ?? ch
        let up = ch.isUppercase
        let hasVowel = letters.contains { isV($0.b) }
        if let t = Telex.toneKeys[lc], hasVowel, !toneBlocked {
            if tone == t { // gõ lặp phím dấu: hủy dấu, giữ ký tự vừa gõ (os + s -> oss)
                tone = 0; toneBlocked = true
                letters.append(Letter(b: lc, upper: up, m: 0)); return
            }
            tone = t; return
        }
        if lc == "z", hasVowel, tone != 0 { tone = 0; return }
        if lc == "w" {
            if let i = letters.lastIndex(where: { isV($0.b) }), i >= 1,
               letters.suffix(from: i+1).allSatisfy({ !isV($0.b) }),
               letters[i].b == "o", letters[i-1].b == "u", letters[i].m == 0, letters[i-1].m == 0,
               !(i >= 2 && letters[i-2].b == "q") {
                letters[i].m = 2; letters[i-1].m = 2; return
            }
            if let i = letters.lastIndex(where: { isV($0.b) }), letters.suffix(from: i+1).allSatisfy({ !isV($0.b) }) {
                let l = letters[i]
                if l.m == 0 || l.m == 1 {
                    if l.b == "a" { letters[i].m = 3; return }
                    if l.b == "o" || l.b == "u" { letters[i].m = 2; return }
                }
            }
            letters.append(Letter(b: "u", upper: up, m: 2)); return
        }
        if lc == "a" || lc == "e" || lc == "o" {
            if let l = letters.last, l.b == lc, l.m == 0 {
                letters[letters.count-1].m = 1; return
            }
        }
        if lc == "d", let l = letters.last, l.b == "d", l.m == 0 { letters[letters.count-1].m = 4; return }
        letters.append(Letter(b: lc, upper: up, m: 0))
    }

    func render() -> String {
        var idx: [Int] = []
        for (i, l) in letters.enumerated() where isV(l.b) {
            if l.b == "u", i > 0, letters[i-1].b == "q" { continue }
            if l.b == "i", i > 0, letters[i-1].b == "g", i+1 < letters.count, isV(letters[i+1].b) { continue }
            idx.append(i)
        }
        // last contiguous cluster
        var cluster: [Int] = []
        for i in idx.reversed() { if cluster.isEmpty || cluster.last! - 1 == i { cluster.append(i) } else { break } }
        cluster.reverse()
        var target: Int? = nil
        if tone != 0, !cluster.isEmpty {
            if let m = cluster.last(where: { letters[$0].m == 1 || letters[$0].m == 2 && letters[$0].b == "o" }) { target = m }
            else if let m = cluster.first(where: { letters[$0].m != 0 }) { target = m }
            else if cluster.count == 1 { target = cluster[0] }
            else if cluster.count == 2 {
                let closed = cluster[1] + 1 < letters.count
                let pair = String([letters[cluster[0]].b, letters[cluster[1]].b])
                target = (closed || ["oa", "oe", "uy"].contains(pair)) ? cluster[1] : cluster[0]
            } else { target = cluster[1] }
        }
        let marks: [Int: String] = [1: "\u{301}", 2: "\u{300}", 3: "\u{309}", 4: "\u{303}", 5: "\u{323}"]
        var out = ""
        for (i, l) in letters.enumerated() {
            var s: String
            if l.m == 4 { s = "đ" } else {
                s = String(l.b)
                if l.m == 1 { s += "\u{302}" } else if l.m == 2 { s += "\u{31B}" } else if l.m == 3 { s += "\u{306}" }
                if i == target { s += marks[tone]! }
            }
            out += l.upper ? s.uppercased() : s
        }
        return out.precomposedStringWithCanonicalMapping
    }
}
