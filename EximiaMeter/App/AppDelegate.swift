import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private var changelogWindow: NSWindow?
    private var eventMonitor: Any?

    let appViewModel = AppViewModel()
    private var sizeObserver: Any?
    private var menuBarStyleObserver: Any?

    /// Shared reference accessible from views
    static weak var shared: AppDelegate?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        AppDelegate.shared = self

        setupStatusItem()
        setupPopover()
        setupEventMonitor()
        setupSizeObserver()
        setupMenuBarStyleObserver()

        if !appViewModel.settingsViewModel.hasCompletedOnboarding {
            showOnboarding()
        }

        appViewModel.start()

        // Show changelog popup if version changed since last launch
        checkForVersionChange()
    }

    // MARK: - Dock Visibility

    /// Show app in Dock (for windows like Settings/Onboarding)
    private func showInDock() {
        NSApp.setActivationPolicy(.regular)
    }

    /// Hide from Dock (menu bar only mode)
    private func hideFromDock() {
        // Only hide if no windows are visible
        let hasVisibleWindows = (settingsWindow?.isVisible == true) || (onboardingWindow?.isVisible == true) || (changelogWindow?.isVisible == true)
        if !hasVisibleWindows {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    // MARK: - Version Change Detection

    private func checkForVersionChange() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let lastSeenVersion = UserDefaults.standard.string(forKey: "ExApp.lastSeenVersion") ?? ""

        guard !currentVersion.isEmpty else { return }

        if !lastSeenVersion.isEmpty && lastSeenVersion != currentVersion {
            // Version changed — show changelog
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.showChangelogPopup(version: currentVersion)
            }
        }

        UserDefaults.standard.set(currentVersion, forKey: "ExApp.lastSeenVersion")
    }

    private func showChangelogPopup(version: String) {
        if let changelogWindow, changelogWindow.isVisible {
            changelogWindow.makeKeyAndOrderFront(self)
            NSApp.activate()
            return
        }

        let entry = Changelog.entry(for: version) ?? Changelog.latest
        guard let entry else { return }

        showInDock()

        let changelogView = ChangelogPopupView(
            version: entry.version,
            items: entry.items,
            onDismiss: { [weak self] in
                self?.changelogWindow?.close()
                self?.changelogWindow = nil
                self?.hideFromDock()
            }
        )
        .preferredColorScheme(.dark)

        let hostingController = NSHostingController(rootView: changelogView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "What's New"
        window.setContentSize(NSSize(width: 380, height: 400))
        window.styleMask = [.titled, .closable]
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.makeKeyAndOrderFront(self)
        NSApp.activate()

        self.changelogWindow = window
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        let style = appViewModel.settingsViewModel.menuBarStyle
        statusItem = NSStatusBar.system.statusItem(
            withLength: style == .logoOnly ? NSStatusItem.squareLength : NSStatusItem.variableLength
        )

        if let button = statusItem?.button {
            button.image = createMenuBarIcon()
            button.image?.size = NSSize(width: 18, height: 18)
            button.imagePosition = style == .logoOnly ? .imageOnly : .imageLeading
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    /// Update the menu bar icon with usage indicators (called after each refresh)
    func updateMenuBarIndicators() {
        guard let button = statusItem?.button else { return }
        let style = appViewModel.settingsViewModel.menuBarStyle

        if style == .withIndicators {
            statusItem?.length = NSStatusItem.variableLength
            button.imagePosition = .imageLeading

            let session = appViewModel.usageViewModel.sessionUsage
            let weekly = appViewModel.usageViewModel.weeklyUsage

            let sessionPct = Int(session * 100)
            let weeklyPct = Int(weekly * 100)

            let title = NSMutableAttributedString()

            // Session percentage
            let sessionColor = usageColor(session)
            title.append(NSAttributedString(string: " \(sessionPct)", attributes: [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .medium),
                .foregroundColor: sessionColor
            ]))

            // Separator
            title.append(NSAttributedString(string: " ", attributes: [
                .font: NSFont.systemFont(ofSize: 4)
            ]))

            // Weekly percentage
            let weeklyColor = usageColor(weekly)
            title.append(NSAttributedString(string: "\(weeklyPct)", attributes: [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .medium),
                .foregroundColor: weeklyColor
            ]))

            button.attributedTitle = title
        } else {
            statusItem?.length = NSStatusItem.squareLength
            button.imagePosition = .imageOnly
            button.title = ""
            button.attributedTitle = NSAttributedString(string: "")
        }
    }

    private func usageColor(_ usage: Double) -> NSColor {
        if usage >= 0.8 { return NSColor.systemRed }
        if usage >= 0.5 { return NSColor.systemOrange }
        return NSColor.systemGreen
    }

    private func setupMenuBarStyleObserver() {
        menuBarStyleObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("MenuBarStyleChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateMenuBarIndicators()
        }
    }

    private func createMenuBarIcon() -> NSImage {
        let size = NSSize(width: 16, height: 16)
        let image = NSImage(size: size, flipped: true) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

            let vw: CGFloat = 120.4
            let vh: CGFloat = 136.01
            let scale = min(rect.width / vw, rect.height / vh)
            let ox = (rect.width - vw * scale) / 2
            let oy = (rect.height - vh * scale) / 2

            ctx.translateBy(x: ox, y: oy)
            ctx.scaleBy(x: scale, y: scale)

            // Right path
            let r = CGMutablePath()
            r.move(to: CGPoint(x: 58.88, y: 132.06))
            r.addCurve(to: CGPoint(x: 64.41, y: 135.56), control1: CGPoint(x: 58.88, y: 134.9), control2: CGPoint(x: 61.84, y: 136.78))
            r.addLine(to: CGPoint(x: 115.41, y: 111.47))
            r.addCurve(to: CGPoint(x: 120.39, y: 103.58), control1: CGPoint(x: 118.45, y: 110.03), control2: CGPoint(x: 120.4, y: 106.96))
            r.addLine(to: CGPoint(x: 120.37, y: 79.71))
            r.addLine(to: CGPoint(x: 120.37, y: 77.9))
            r.addLine(to: CGPoint(x: 120.31, y: 16.95))
            r.addCurve(to: CGPoint(x: 114.59, y: 9.14), control1: CGPoint(x: 120.31, y: 13.38), control2: CGPoint(x: 118.0, y: 10.22))
            r.addLine(to: CGPoint(x: 87.3, y: 0.46))
            r.addCurve(to: CGPoint(x: 76.61, y: 8.29), control1: CGPoint(x: 82.01, y: -1.22), control2: CGPoint(x: 76.6, y: 2.73))
            r.addLine(to: CGPoint(x: 76.65, y: 46.8))
            r.addCurve(to: CGPoint(x: 94.28, y: 71.12), control1: CGPoint(x: 76.66, y: 57.87), control2: CGPoint(x: 83.77, y: 67.68))
            r.addLine(to: CGPoint(x: 117.89, y: 78.9))
            r.addLine(to: CGPoint(x: 64.61, y: 100.28))
            r.addCurve(to: CGPoint(x: 58.86, y: 108.79), control1: CGPoint(x: 61.13, y: 101.67), control2: CGPoint(x: 58.86, y: 105.05))
            r.addLine(to: CGPoint(x: 58.88, y: 132.06))
            r.closeSubpath()

            // Left path
            let l = CGMutablePath()
            l.move(to: CGPoint(x: 61.33, y: 3.85))
            l.addCurve(to: CGPoint(x: 55.77, y: 0.38), control1: CGPoint(x: 61.31, y: 1.01), control2: CGPoint(x: 58.34, y: -0.85))
            l.addLine(to: CGPoint(x: 4.93, y: 24.8))
            l.addCurve(to: CGPoint(x: 0.0, y: 32.73), control1: CGPoint(x: 1.9, y: 26.27), control2: CGPoint(x: -0.02, y: 29.35))
            l.addLine(to: CGPoint(x: 0.18, y: 56.6))
            l.addLine(to: CGPoint(x: 0.18, y: 58.41))
            l.addLine(to: CGPoint(x: 0.65, y: 119.35))
            l.addCurve(to: CGPoint(x: 6.42, y: 127.12), control1: CGPoint(x: 0.68, y: 122.92), control2: CGPoint(x: 3.01, y: 126.06))
            l.addLine(to: CGPoint(x: 33.77, y: 135.63))
            l.addCurve(to: CGPoint(x: 44.41, y: 127.74), control1: CGPoint(x: 39.07, y: 137.28), control2: CGPoint(x: 44.45, y: 133.3))
            l.addLine(to: CGPoint(x: 44.12, y: 89.23))
            l.addCurve(to: CGPoint(x: 26.33, y: 65.02), control1: CGPoint(x: 44.04, y: 78.16), control2: CGPoint(x: 36.86, y: 68.4))
            l.addLine(to: CGPoint(x: 2.67, y: 57.4))
            l.addLine(to: CGPoint(x: 55.81, y: 35.67))
            l.addCurve(to: CGPoint(x: 61.5, y: 27.12), control1: CGPoint(x: 59.28, y: 34.25), control2: CGPoint(x: 61.53, y: 30.87))
            l.addLine(to: CGPoint(x: 61.33, y: 3.85))
            l.closeSubpath()

            ctx.setFillColor(NSColor.white.cgColor)
            ctx.addPath(r)
            ctx.fillPath()
            ctx.addPath(l)
            ctx.fillPath()

            return true
        }

        image.isTemplate = true
        return image
    }

    // MARK: - Popover

    private func setupPopover() {
        let popover = NSPopover()
        let size = appViewModel.settingsViewModel.popoverSize.dimensions
        popover.contentSize = size
        popover.behavior = .transient
        popover.animates = true

        let contentView = PopoverContentView()
            .environmentObject(appViewModel)
            .preferredColorScheme(.dark)

        popover.contentViewController = NSHostingController(rootView: contentView)
        self.popover = popover
    }

    private func setupSizeObserver() {
        sizeObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("PopoverSizeChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, let popover = self.popover else { return }
            let newSize = self.appViewModel.settingsViewModel.popoverSize.dimensions
            popover.contentSize = newSize
        }
    }

    func getPopover() -> NSPopover? {
        popover
    }

    @objc private func togglePopover() {
        guard let popover, let button = statusItem?.button else { return }

        if popover.isShown {
            popover.performClose(self)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    // MARK: - Onboarding Window

    private func showOnboarding() {
        if let onboardingWindow, onboardingWindow.isVisible {
            onboardingWindow.makeKeyAndOrderFront(self)
            NSApp.activate()
            return
        }

        showInDock()

        let onboardingView = OnboardingWindowView { [weak self] in
            self?.onboardingWindow?.close()
            self?.onboardingWindow = nil
            self?.hideFromDock()
        }
        .environmentObject(appViewModel)
        .preferredColorScheme(.dark)

        let hostingController = NSHostingController(rootView: onboardingView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Welcome to exímIA Meter"
        window.setContentSize(NSSize(width: 520, height: 520))
        window.styleMask = NSWindow.StyleMask([.titled, .closable])
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.makeKeyAndOrderFront(self)
        NSApp.activate()

        self.onboardingWindow = window
    }

    // MARK: - Settings Window

    func openSettings() {
        // Close the popover if it's open
        if let popover, popover.isShown {
            popover.performClose(self)
        }

        if let settingsWindow, settingsWindow.isVisible {
            settingsWindow.makeKeyAndOrderFront(self)
            NSApp.activate()
            return
        }

        showInDock()

        let settingsView = SettingsWindowView()
            .environmentObject(appViewModel)
            .preferredColorScheme(.dark)

        let hostingController = NSHostingController(rootView: settingsView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "exímIA Meter Settings"
        window.setContentSize(NSSize(width: 680, height: 520))
        window.styleMask = NSWindow.StyleMask([.titled, .closable, .miniaturizable])
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.makeKeyAndOrderFront(self)
        NSApp.activate()

        self.settingsWindow = window
    }

    // MARK: - Uninstall

    func uninstallApp() {
        let alert = NSAlert()
        alert.messageText = "Uninstall exímIA Meter?"
        alert.informativeText = "This will remove the app and all saved preferences. This action cannot be undone."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Uninstall")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            // Clean up preferences
            let defaults = UserDefaults.standard
            for key in defaults.dictionaryRepresentation().keys {
                defaults.removeObject(forKey: key)
            }

            // Remove app bundle via shell script
            let appPath = Bundle.main.bundlePath
            let script = """
            sleep 1
            rm -rf "\(appPath)"
            """

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = ["-c", script]
            try? process.run()

            // Quit the app
            NSApp.terminate(self)
        }
    }

    // MARK: - Event Monitor

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let popover = self?.popover, popover.isShown {
                popover.performClose(self)
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        if let sizeObserver {
            NotificationCenter.default.removeObserver(sizeObserver)
        }
        if let menuBarStyleObserver {
            NotificationCenter.default.removeObserver(menuBarStyleObserver)
        }
        appViewModel.stop()
    }
}

// MARK: - NSWindowDelegate

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let closingWindow = notification.object as? NSWindow else { return }

        if closingWindow === settingsWindow {
            settingsWindow = nil
        } else if closingWindow === onboardingWindow {
            onboardingWindow = nil
        } else if closingWindow === changelogWindow {
            changelogWindow = nil
        }

        // Delay to let the window finish closing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.hideFromDock()
        }
    }
}
