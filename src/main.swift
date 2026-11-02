import Cocoa
import InputMethodKit

var server: IMKServer?
var statusItem: NSStatusItem?
var vietItem: NSMenuItem?
var engItem: NSMenuItem?
/// Vẽ biểu tượng khay dạng template: nền bo tròn, chữ đục rỗng (đồng bộ với icon hệ thống)
func trayIcon(_ text: String) -> NSImage {
    let size = NSSize(width: 26, height: 16)
    let img = NSImage(size: size, flipped: false) { rect in
        let path = NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), xRadius: 4.5, yRadius: 4.5)
        NSColor.black.setFill(); path.fill()
        NSGraphicsContext.current?.compositingOperation = .clear
        let str = NSAttributedString(string: text, attributes: [
            .font: NSFont.systemFont(ofSize: 11, weight: .bold), .kern: 0.3, .foregroundColor: NSColor.black])
        let sz = str.size()
        str.draw(at: NSPoint(x: (rect.width - sz.width) / 2, y: (rect.height - sz.height) / 2))
        return true
    }
    img.isTemplate = true
    return img
}
func refreshStatus() {
    statusItem?.button?.title = ""
    statusItem?.button?.image = trayIcon(vietEnabled ? "VN" : "EN")
    vietItem?.state = vietEnabled ? .on : .off
    engItem?.state = vietEnabled ? .off : .on
}
class MenuActions: NSObject {
    @objc func setViet() { vietEnabled = true }
    @objc func setEng() { vietEnabled = false }
    @objc func quit() { NSApp.terminate(nil) }
}
let menuActions = MenuActions()
var vietEnabled = true { didSet { refreshStatus() } } // dùng chung cho mọi ứng dụng

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
        guard let event = event, event.type == .keyDown else { return false }
        let f = event.modifierFlags
        // Option+Z: chuyển Việt/Anh
        if event.keyCode == 6, f.intersection([.control, .shift, .command, .option]) == [.option] {
            flush(sender as Any)
            vietEnabled.toggle()
            return true
        }
        if !vietEnabled { flush(sender as Any); return false }
        if f.contains(.command) || f.contains(.control) || f.contains(.option) { flush(sender as Any); return false }
        guard let chars = event.characters, let ch = chars.first, chars.count == 1 else { flush(sender as Any); return false }
        if event.keyCode == 51 { // backspace
            if raw.isEmpty { return false }
            raw.removeLast()
            if raw.isEmpty { // hết chữ: xoá vùng gạch chân
                client()?.setMarkedText("", selectionRange: NSRange(location: 0, length: 0), replacementRange: NSRange(location: NSNotFound, length: 0))
            } else { show(sender as Any) }
            return true
        }
        if ch.isLetter && ch.isASCII {
            raw.append(ch); show(sender as Any); return true
        }
        flush(sender as Any)
        return false
    }
    override func commitComposition(_ sender: Any!) { flush(sender as Any) }
    override func deactivateServer(_ sender: Any!) { flush(sender as Any); super.deactivateServer(sender) }
}

let name = Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String ?? "VietIME_Connection"
server = IMKServer(name: name, bundleIdentifier: Bundle.main.bundleIdentifier)
NSApplication.shared.setActivationPolicy(.accessory)
statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
let menu = NSMenu()
vietItem = NSMenuItem(title: "Tiếng Việt (VN)", action: #selector(MenuActions.setViet), keyEquivalent: "")
engItem = NSMenuItem(title: "English (EN)", action: #selector(MenuActions.setEng), keyEquivalent: "")
vietItem?.target = menuActions; engItem?.target = menuActions
menu.addItem(vietItem!); menu.addItem(engItem!)
menu.addItem(.separator())
let quitItem = NSMenuItem(title: "Thoát VNMIE", action: #selector(MenuActions.quit), keyEquivalent: "")
quitItem.target = menuActions
menu.addItem(quitItem)
statusItem?.menu = menu
refreshStatus()
NSApplication.shared.run()
