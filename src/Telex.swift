import Foundation

struct Letter { var b: Character; var upper: Bool; var m: Int } // m:1 ^ ,2 horn,3 breve,4 stroke

func isV(_ c: Character) -> Bool { "aeiouy".contains(c) }

struct Telex {
    var letters: [Letter] = []
    var tone = 0 // 0 none,1 sac,2 huyen,3 hoi,4 nga,5 nang
    var toneBlocked = false // đã hủy dấu bằng gõ lặp: các phím dấu sau đó là chữ thường

    static let toneKeys: [Character: Int] = ["s": 1, "f": 2, "r": 3, "x": 4, "j": 5]

    var vni = false      // false: Telex, true: VNI
    var wToU = true      // Telex: w đứng một mình thành ư

    /// Cụm nguyên âm cuối từ (có thể theo sau là phụ âm cuối)
    private func lastCluster() -> [Int] {
        guard let end = letters.lastIndex(where: { isV($0.b) }),
              letters.suffix(from: end+1).allSatisfy({ !isV($0.b) }) else { return [] }
        var c = [end]; var i = end - 1
        while i >= 0, isV(letters[i].b) { c.insert(i, at: 0); i -= 1 }
        return c
    }

    private mutating func applyHorn() -> Bool { // ơ, ư, ươ
        let c = lastCluster()
        for k in 0..<max(0, c.count - 1) {
            let u = c[k], o = c[k+1]
            if letters[u].b == "u", letters[o].b == "o", letters[u].m == 0, letters[o].m == 0,
               !(u >= 1 && letters[u-1].b == "q") {
                letters[u].m = 2; letters[o].m = 2; return true
            }
        }
        if let j = c.last, "ou".contains(letters[j].b), letters[j].m == 0 || letters[j].m == 1,
           !(letters[j].b == "u" && j >= 1 && letters[j-1].b == "q") {
            letters[j].m = 2; return true
        }
        return false
    }
    private mutating func applyBreve() -> Bool { // ă
        guard let j = lastCluster().last, letters[j].b == "a", letters[j].m == 0 || letters[j].m == 1 else { return false }
        letters[j].m = 3; return true
    }
    private mutating func applyCircumflex(_ v: Character?) -> Bool { // â ê ô (VNI)
        guard let j = lastCluster().last(where: { "aeo".contains(letters[$0].b) && letters[$0].m == 0 && (v == nil || letters[$0].b == v!) }) else { return false }
        letters[j].m = 1; return true
    }
    private mutating func setTone(_ t: Int, _ lc: Character, _ up: Bool) -> Bool {
        guard letters.contains(where: { isV($0.b) }), !toneBlocked else { return false }
        if tone == t { // gõ lặp: hủy dấu, giữ ký tự vừa gõ (os + s -> oss)
            tone = 0; toneBlocked = true
            letters.append(Letter(b: lc, upper: up, m: 0)); return true
        }
        tone = t; return true
    }

    /// Nhận một phím. Trả về false nếu phím không có tác dụng với từ hiện tại (VNI: số thường).
    @discardableResult
    mutating func feed(_ ch: Character) -> Bool {
        let lc = ch.lowercased().first ?? ch
        let up = ch.isUppercase
        if vni { return feedVNI(ch, lc, up) }
        if let t = Telex.toneKeys[lc], setTone(t, lc, up) { return true }
        if lc == "z", letters.contains(where: { isV($0.b) }), tone != 0 { tone = 0; return true }
        if lc == "w" {
            if applyHorn() || applyBreve() { return true }
            if wToU { letters.append(Letter(b: "u", upper: up, m: 2)); return true }
            letters.append(Letter(b: "w", upper: up, m: 0)); return true
        }
        if lc == "a" || lc == "e" || lc == "o" {
            if let l = letters.last, l.b == lc, l.m == 0 { letters[letters.count-1].m = 1; return true }
        }
        if lc == "d", let l = letters.last, l.b == "d", l.m == 0 { letters[letters.count-1].m = 4; return true }
        letters.append(Letter(b: lc, upper: up, m: 0)); return true
    }

    private mutating func feedVNI(_ ch: Character, _ lc: Character, _ up: Bool) -> Bool {
        switch ch {
        case "1", "2", "3", "4", "5": return setTone(Int(String(ch))!, ch, false)
        case "0":
            guard tone != 0 else { return false }
            tone = 0; return true
        case "6": return applyCircumflex(nil)
        case "7": return applyHorn()
        case "8": return applyBreve()
        case "9":
            guard let i = letters.firstIndex(where: { $0.b == "d" && $0.m == 0 }) else { return false }
            letters[i].m = 4; return true
        default:
            guard ch.isLetter else { return false }
            letters.append(Letter(b: lc, upper: up, m: 0)); return true
        }
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
