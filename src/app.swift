import Cocoa
import WebKit

class AppDelegate: NSObject, NSApplicationDelegate, WKScriptMessageHandler, NSWindowDelegate {
    var petWindow: NSWindow?
    var petWebView: WKWebView?
    var serverProcess: Process?
    var menuOpen = false

    let configDir = NSHomeDirectory() + "/.kitty-pet"
    var petSizeFile: String { configDir + "/pet-frame.plist" }

    func applicationDidFinishLaunching(_ notification: Notification) {
        try? FileManager.default.createDirectory(atPath: configDir, withIntermediateDirectories: true)

        DispatchQueue.global(qos: .background).async { self.startServer() }

        DispatchQueue.global(qos: .userInitiated).async {
            self.waitForServer {
                DispatchQueue.main.async { self.showPetWindow() }
            }
        }

        var wasTyping = false
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let elapsed = CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: .keyDown)
            let isTyping = elapsed < 1.0
            if isTyping && !wasTyping {
                self.petWebView?.evaluateJavaScript("startTyping()", completionHandler: nil)
            } else if !isTyping && wasTyping {
                self.petWebView?.evaluateJavaScript("stopTyping()", completionHandler: nil)
            }
            wasTyping = isTyping
        }

        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, let pw = self.petWindow else { return }
            let mag = self.petWebView?.magnification ?? 1.0
            if mag <= 1.0 { pw.ignoresMouseEvents = false; return }
            if self.menuOpen { pw.ignoresMouseEvents = false; return }
            let mouse = NSEvent.mouseLocation
            let wf = pw.frame
            let duckRect = NSRect(x: wf.origin.x + 10 * mag, y: wf.origin.y, width: 130 * mag, height: 170 * mag)
            pw.ignoresMouseEvents = !duckRect.contains(mouse)
        }
    }

    private func waitForServer(ready: @escaping () -> Void) {
        for _ in 0..<60 {
            let sem = DispatchSemaphore(value: 0)
            var ok = false
            let task = URLSession.shared.dataTask(with: URL(string: "http://localhost:9528")!) { _, resp, _ in
                if let http = resp as? HTTPURLResponse, http.statusCode == 200 { ok = true }
                sem.signal()
            }
            task.resume()
            _ = sem.wait(timeout: .now() + 1)
            if ok { ready(); return }
            Thread.sleep(forTimeInterval: 0.5)
        }
        ready()
    }

    func userContentController(_ uc: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String: Any],
              let action = dict["action"] as? String else { return }

        switch action {
        case "show": showPetWindow()
        case "hide": petWindow?.orderOut(nil)
        case "close": closePetWindow()
        case "quit": NSApplication.shared.terminate(nil)
        case "drag":
            if let dx = dict["dx"] as? CGFloat, let dy = dict["dy"] as? CGFloat,
               let pw = petWindow {
                var f = pw.frame
                f.origin.x += dx
                f.origin.y -= dy
                pw.setFrame(f, display: true)
            }
        case "move":
            if let dx = dict["dx"] as? Double, let pw = petWindow {
                var f = pw.frame
                f.origin.x += CGFloat(dx)
                if let screen = pw.screen ?? NSScreen.main {
                    let vis = screen.visibleFrame
                    let margin: CGFloat = 10
                    if f.origin.x < vis.origin.x + margin {
                        f.origin.x = vis.origin.x + margin
                        petWebView?.evaluateJavaScript("atEdge('left')", completionHandler: nil)
                    } else if f.maxX > vis.maxX - margin {
                        f.origin.x = vis.maxX - f.width - margin
                        petWebView?.evaluateJavaScript("atEdge('right')", completionHandler: nil)
                    }
                }
                pw.setFrame(f, display: false)
            }
        case "dragEnd":
            snapToEdgeIfNeeded()
            savePetWindowFrame()
        case "unpeek":
            unpeekPetWindow()
        case "resize":
            if let scale = dict["scale"] as? Double, let pw = petWindow {
                var finalScale = CGFloat(scale)
                if let screen = pw.screen ?? NSScreen.main {
                    let vis = screen.visibleFrame
                    let maxScaleW = vis.width / 140
                    let maxScaleH = vis.height / 280
                    finalScale = min(finalScale, maxScaleW, maxScaleH)
                }
                let newW: CGFloat = 140 * finalScale
                let newH: CGFloat = 280 * finalScale
                var f = pw.frame
                let oldBottom = f.origin.y
                f.origin.x -= (newW - f.width) / 2
                f.origin.y = oldBottom
                f.size.width = newW
                f.size.height = newH
                if let screen = pw.screen ?? NSScreen.main {
                    let vis = screen.visibleFrame
                    if f.origin.x < vis.origin.x { f.origin.x = vis.origin.x }
                    if f.maxX > vis.maxX { f.origin.x = vis.maxX - f.width }
                    if f.origin.y < vis.origin.y { f.origin.y = vis.origin.y }
                    if f.maxY > vis.maxY { f.origin.y = vis.maxY - f.height }
                }
                pw.setFrame(f, display: true)
                petWebView?.setMagnification(finalScale, centeredAt: .zero)
            }
        case "resizeBack":
            if let pw = petWindow {
                let oldBottom = pw.frame.origin.y
                var f = pw.frame
                f.origin.x += (f.width - 140) / 2
                f.origin.y = oldBottom
                f.size.width = 140
                f.size.height = 280
                pw.setFrame(f, display: true)
                petWebView?.setMagnification(1.0, centeredAt: .zero)
                pw.ignoresMouseEvents = false
            }
        case "menuOpen":
            menuOpen = true
            petWindow?.ignoresMouseEvents = false
        case "menuClose":
            menuOpen = false
        default: break
        }
    }

    func showPetWindow() {
        if petWindow == nil { createPetWindow() }
        petWindow?.orderFront(nil)
    }

    func closePetWindow() {
        if let pw = petWindow {
            savePetWindowFrame()
            pw.delegate = nil
            petWebView?.stopLoading()
            pw.contentView = nil
            pw.close()
            petWebView = nil
            petWindow = nil
        }
    }

    func createPetWindow() {
        let pw: CGFloat = 140
        let ph: CGFloat = 280
        var px: CGFloat = 200
        var py: CGFloat = 200

        if let dict = NSDictionary(contentsOfFile: petSizeFile) as? [String: CGFloat] {
            px = dict["x"] ?? px
            py = dict["y"] ?? py
        }

        let center = NSPoint(x: px + pw / 2, y: py + ph / 2)
        let onScreen = NSScreen.screens.contains(where: { $0.frame.contains(center) })
        if !onScreen, let screen = NSScreen.main {
            px = (screen.visibleFrame.origin.x + screen.visibleFrame.width - pw) / 2
            py = (screen.visibleFrame.origin.y + screen.visibleFrame.height - ph) / 2
        }

        let win = NSWindow(
            contentRect: NSRect(x: px, y: py, width: pw, height: ph),
            styleMask: [.borderless],
            backing: .buffered, defer: false
        )
        win.isOpaque = false
        win.backgroundColor = .clear
        win.hasShadow = false
        win.level = .floating
        win.collectionBehavior = [.canJoinAllSpaces, .stationary]
        win.isReleasedWhenClosed = false
        win.ignoresMouseEvents = false

        let config = WKWebViewConfiguration()
        let controller = WKUserContentController()
        controller.add(self, name: "petWindow")
        config.userContentController = controller

        let wv = WKWebView(frame: NSRect(x: 0, y: 0, width: pw, height: ph), configuration: config)
        wv.autoresizingMask = [.width, .height]
        wv.setValue(false, forKey: "drawsBackground")

        win.contentView = wv
        wv.load(URLRequest(url: URL(string: "http://localhost:9528/pet-window.html")!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 5))

        win.delegate = self
        petWindow = win
        petWebView = wv
    }

    private func savePetWindowFrame() {
        if let pw = petWindow {
            let dict: [String: CGFloat] = ["x": pw.frame.origin.x, "y": pw.frame.origin.y]
            (dict as NSDictionary).write(toFile: petSizeFile, atomically: true)
        }
    }

    private func snapToEdgeIfNeeded() {
    }

    private func unpeekPetWindow() {
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if sender == petWindow { closePetWindow(); return false }
        return true
    }

    func startServer() {
        let appDir = Bundle.main.bundlePath + "/Contents/MacOS"

        // 清理上次未正常退出时遗留的 node 进程（bash→node 链路中 terminate() 只杀 bash，node 仍占用端口）
        let cleanup = Process()
        cleanup.executableURL = URL(fileURLWithPath: "/bin/bash")
        cleanup.arguments = ["-c", "lsof -ti:9528 | xargs kill -9 2>/dev/null"]
        cleanup.standardOutput = FileHandle.nullDevice
        cleanup.standardError = FileHandle.nullDevice
        try? cleanup.run()
        cleanup.waitUntilExit()

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", "cd '\(appDir)' && node server.js"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            serverProcess = process
        } catch {
            NSLog("Failed to start server: \(error)")
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationWillTerminate(_ notification: Notification) {
        closePetWindow()
        serverProcess?.terminate()
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
