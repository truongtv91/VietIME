import Cocoa
import InputMethodKit

func dlog(_ m: String) {
    let line = "\(Date()) \(m)\n"
    if let h = FileHandle(forWritingAtPath: "/tmp/vietime.log") { h.seekToEndOfFile(); h.write(line.data(using: .utf8)!); h.closeFile() }
    else { try? line.write(toFile: "/tmp/vietime.log", atomically: false, encoding: .utf8) }
}

var server: IMKServer?
var vietEnabled = true // dùng chung cho mọi ứng dụng

class VietController: IMKInputController {
    var raw: [Character] = []
    override func recognizedEvents(_ sender: Any!) -> Int {
        Int(NSEvent.EventTypeMask([.keyDown, .flagsChanged]).rawValue)
    }

    func compose() -> String {
        var t = Telex(); for c in raw { t.feed(c) }; return t.render()
    }
    func show(_ c: Any) {
        guard let client = self.client() else { return }
        let s = compose()
        let attr = NSAttributedString(string: s, attributes: [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .markedClauseSegment: 0])
        client.setMarkedText(attr, selectionRange: NSRange(location: s.utf16.count, length: 0), replacementRange: NSRange(location: NSNotFound, length: 0))
    }
    func flush(_ c: Any) {
        guard let client = self.client() else { return }
        if !raw.isEmpty {
            client.insertText(compose(), replacementRange: NSRange(location: NSNotFound, length: 0))
            raw = []
        }
    }
    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        dlog("handle keyCode=\(event?.keyCode ?? 0) chars=\(event?.characters ?? "")")
        guard let event = event, event.type == .keyDown else { return false }
        let f = event.modifierFlags
        guard event.type == .keyDown else { return false }
        // Option+Z: chuyển Việt/Anh
        if event.keyCode == 6, f.intersection([.control, .shift, .command, .option]) == [.option] {
            flush(sender as Any)
            vietEnabled.toggle()
            return true
        }
        if !vietEnabled { flush(sender as Any); return false }
        if f.contains(.command) || f.contains(.control) || f.contains(.option) { flush(sender); return false }
        guard let chars = event.characters, let ch = chars.first, chars.count == 1 else { flush(sender); return false }
        if event.keyCode == 51 { // backspace
            if raw.isEmpty { return false }
            raw.removeLast(); show(sender); return true
        }
        if ch.isLetter && ch.isASCII {
            raw.append(ch); show(sender); return true
        }
        flush(sender)
        return false
    }
    override func commitComposition(_ sender: Any!) { flush(sender as Any) }
    override func deactivateServer(_ sender: Any!) { flush(sender as Any); super.deactivateServer(sender) }
}

let name = Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String ?? "VietIME_Connection"
server = IMKServer(name: name, bundleIdentifier: Bundle.main.bundleIdentifier)
NSApplication.shared.setActivationPolicy(.accessory)
NSApplication.shared.run()
