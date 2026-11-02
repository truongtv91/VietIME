import Cocoa
import InputMethodKit

// MARK: - Cài đặt (lưu trong UserDefaults, dùng chung mọi ứng dụng)

struct Hotkey { let title: String; let keyCode: UInt16; let flags: NSEvent.ModifierFlags }
let hotkeys: [Hotkey] = [
    Hotkey(title: "⌥ Z (Option + Z)", keyCode: 6, flags: [.option]),
    Hotkey(title: "⌥ Space (Option + Space)", keyCode: 49, flags: [.option]),
    Hotkey(title: "⌃ Space (Control + Space)", keyCode: 49, flags: [.control]),
    Hotkey(title: "⌃⇧ Z (Control + Shift + Z)", keyCode: 6, flags: [.control, .shift]),
]
let modifierMask: NSEvent.ModifierFlags = [.control, .shift, .command, .option]

enum Settings {
    static let d = UserDefaults.standard
    static var vni: Bool { get { d.bool(forKey: "vni") } set { d.set(newValue, forKey: "vni") } }
    static var wToU: Bool { get { d.object(forKey: "wToU") as? Bool ?? true } set { d.set(newValue, forKey: "wToU") } }
    static var hotkeyIndex: Int {
        get { min(max(d.integer(forKey: "hotkey"), 0), hotkeys.count - 1) }
        set { d.set(newValue, forKey: "hotkey") }
    }
}

// MARK: - Biểu tượng và menu trên thanh menu

var server: IMKServer?
var statusItem: NSStatusItem?
var vietEnabled = true { didSet { refreshStatus() } }

/// Biểu tượng dạng template: nền bo tròn, chữ đục rỗng (đồng bộ với icon hệ thống)
func trayIcon(_ text: String) -> NSImage {
    let img = NSImage(size: NSSize(width: 26, height: 16), flipped: false) { rect in
        NSColor.black.setFill()
        NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), xRadius: 4.5, yRadius: 4.5).fill()
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

final class MenuController: NSObject, NSMenuDelegate {
    let menu = NSMenu()
    @objc func setViet() { vietEnabled = true }
    @objc func setEng() { vietEnabled = false }
    @objc func setTelex() { Settings.vni = false }
    @objc func setVNI() { Settings.vni = true }
    @objc func toggleW() { Settings.wToU.toggle() }
    @objc func pickHotkey(_ s: NSMenuItem) { Settings.hotkeyIndex = s.tag }
    @objc func quit() { NSApp.terminate(nil) }

    func item(_ title: String, _ action: Selector, tag: Int = 0) -> NSMenuItem {
        let i = NSMenuItem(title: title, action: action, keyEquivalent: ""); i.target = self; i.tag = tag; return i
    }
    func build() {
        menu.removeAllItems()
        let v = item("Tiếng Việt (VN)", #selector(setViet)); v.state = vietEnabled ? .on : .off
        let e = item("English (EN)", #selector(setEng)); e.state = vietEnabled ? .off : .on
        menu.addItem(v); menu.addItem(e); menu.addItem(.separator())

        let mode = NSMenu()
        let t = item("Telex", #selector(setTelex)); t.state = Settings.vni ? .off : .on
        let n = item("VNI", #selector(setVNI)); n.state = Settings.vni ? .on : .off
        mode.addItem(t); mode.addItem(n)
        let modeItem = NSMenuItem(title: "Kiểu gõ", action: nil, keyEquivalent: ""); modeItem.submenu = mode
        menu.addItem(modeItem)

        let hk = NSMenu()
        for (i, h) in hotkeys.enumerated() {
            let it = item(h.title, #selector(pickHotkey(_:)), tag: i); it.state = i == Settings.hotkeyIndex ? .on : .off
            hk.addItem(it)
        }
        let hkItem = NSMenuItem(title: "Phím tắt chuyển Việt/Anh", action: nil, keyEquivalent: ""); hkItem.submenu = hk
        menu.addItem(hkItem)

        let w = item("Telex: gõ w đầu từ thành ư", #selector(toggleW)); w.state = Settings.wToU ? .on : .off
        menu.addItem(w)
        menu.addItem(.separator())
        menu.addItem(item("Thoát VNMIE", #selector(quit)))
    }
    func menuNeedsUpdate(_ menu: NSMenu) { build() }
}
let menuController = MenuController()

func refreshStatus() {
    statusItem?.button?.title = ""
    statusItem?.button?.image = trayIcon(vietEnabled ? "VN" : "EN")
}

// MARK: - Bộ gõ

class VietController: IMKInputController {
    var raw: [Character] = []

    override func recognizedEvents(_ sender: Any!) -> Int {
        Int(NSEvent.EventTypeMask.keyDown.rawValue)
    }

    func engine() -> Telex {
        var t = Telex(); t.vni = Settings.vni; t.wToU = Settings.wToU
        for c in raw { t.feed(c) }
        return t
    }
    func compose() -> String { engine().render() }

    func show() {
        guard let client = self.client() else { return }
        let s = compose()
        let attr = NSAttributedString(string: s, attributes: [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .markedClauseSegment: 0])
        client.setMarkedText(attr, selectionRange: NSRange(location: s.utf16.count, length: 0),
                             replacementRange: NSRange(location: NSNotFound, length: 0))
    }
    func flush() {
        guard !raw.isEmpty else { return }
        let s = compose()
        raw = []
        client()?.insertText(s, replacementRange: NSRange(location: NSNotFound, length: 0))
    }

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        guard let event = event, event.type == .keyDown else { return false }
        let f = event.modifierFlags.intersection(modifierMask)

        // Phím tắt chuyển Việt/Anh
        let hk = hotkeys[Settings.hotkeyIndex]
        if event.keyCode == hk.keyCode, f == hk.flags {
            flush(); vietEnabled.toggle(); return true
        }
        if !vietEnabled { flush(); return false }
        if f.contains(.command) || f.contains(.control) || f.contains(.option) { flush(); return false }
        guard let chars = event.characters, chars.count == 1, let ch = chars.first else { flush(); return false }

        if event.keyCode == 51 { // Backspace
            guard !raw.isEmpty else { return false }
            raw.removeLast()
            if raw.isEmpty {
                client()?.setMarkedText("", selectionRange: NSRange(location: 0, length: 0),
                                        replacementRange: NSRange(location: NSNotFound, length: 0))
            } else { show() }
            return true
        }

        let isDigitKey = Settings.vni && ch.isASCII && ch.isNumber
        if (ch.isLetter && ch.isASCII) || isDigitKey {
            if isDigitKey { // số chỉ là dấu nếu có tác dụng với từ đang gõ, nếu không thì gõ số bình thường
                var t = engine()
                if !t.feed(ch) { flush(); return false }
            }
            raw.append(ch); show(); return true
        }
        flush()
        return false
    }
    override func commitComposition(_ sender: Any!) { flush() }
    override func deactivateServer(_ sender: Any!) { flush(); super.deactivateServer(sender) }
}

// MARK: - Khởi động

let connectionName = Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String ?? "VietIME_Connection"
server = IMKServer(name: connectionName, bundleIdentifier: Bundle.main.bundleIdentifier)
NSApplication.shared.setActivationPolicy(.accessory)
statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
menuController.build()
menuController.menu.delegate = menuController
statusItem?.menu = menuController.menu
refreshStatus()
NSApplication.shared.run()
