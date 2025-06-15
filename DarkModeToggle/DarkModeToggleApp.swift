import SwiftUI
import ServiceManagement
import os.log
import Cocoa

public enum LaunchAtLogin {
    public static var isEnabled: Bool {
        get {
            SMAppService.mainApp.status == .enabled
        }
        set {
            do {
                if newValue {
                    if SMAppService.mainApp.status == .enabled {
                        try? SMAppService.mainApp.unregister()
                    }

                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to \(newValue ? "enable" : "disable") launch at login: \(error.localizedDescription)")
            }
        }
    }
}

func isDark() -> Bool {
    let s = NSAppleScript(source: "tell application \"System Events\" to tell appearance preferences to get dark mode")!
    var errorDict : NSDictionary? = nil
    let res = s.executeAndReturnError(&errorDict)
    return res.booleanValue
}

func setDark(value: Bool) -> Bool {
    let script = NSAppleScript(source: "tell application \"System Events\" to tell appearance preferences to set dark mode to \(value)")!
    var errorDict : NSDictionary? = nil
    script.executeAndReturnError(&errorDict)
    if errorDict != nil {
        print(errorDict as AnyObject)
    }
    return isDark()
}

class StatusBarController: ObservableObject {
    private var statusBar: NSStatusBar
    private var statusItem: NSStatusItem
    private var menu: NSMenu
    @Published var dark = isDark()
    @Published var launch = LaunchAtLogin.isEnabled
    
    init() {
        statusBar = NSStatusBar.system
        statusItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        menu = NSMenu()
        
        setupStatusItem()
        setupMenu()
    }
    
    private func setupStatusItem() {
        if let button = statusItem.button {
            updateButtonImage()
            button.action = #selector(statusBarButtonClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    private func updateButtonImage() {
        if let button = statusItem.button {
            let imageName = dark ? "moon" : "sun"
            if let image = NSImage(named: imageName) {
                image.isTemplate = true
                button.image = image
            }
        }
    }
    
    @objc private func statusBarButtonClicked() {
        guard let event = NSApp.currentEvent else { 
            toggleDarkMode()
            return 
        }
        
        // Right-click or Control + Left-click shows menu
        if event.type == .rightMouseUp || 
           (event.type == .leftMouseUp && event.modifierFlags.contains(.control)) {
            updateMenuItems()
            statusItem.menu = menu
            statusItem.menu?.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
            statusItem.menu = nil
        } else {
            // Regular left-click toggles dark mode
            toggleDarkMode()
        }
    }
    
    private func toggleDarkMode() {
        DispatchQueue.global(qos: .userInitiated).async {
            let newValue = setDark(value: !self.dark)
            DispatchQueue.main.async {
                self.dark = newValue
                self.updateButtonImage()
            }
        }
    }
    
    private func setupMenu() {
        let lightItem = NSMenuItem(title: "Go Light", action: #selector(goLight), keyEquivalent: "")
        lightItem.target = self
        let darkItem = NSMenuItem(title: "Go Dark", action: #selector(goDark), keyEquivalent: "")
        darkItem.target = self
        let launchItem = NSMenuItem(title: "Launch at login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchItem.target = self
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "")
        quitItem.target = self
        
        menu.addItem(lightItem)
        menu.addItem(darkItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(launchItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quitItem)
        
        updateMenuItems()
    }
    
    private func updateMenuItems() {
        if let lightItem = menu.item(withTitle: "Go Light") {
            // lightItem.isEnabled = dark
            lightItem.state = dark ? .off : .on
        }
        if let darkItem = menu.item(withTitle: "Go Dark") {
            // darkItem.isEnabled = !dark
            darkItem.state = dark ? .on : .off
        }
        if let launchItem = menu.item(withTitle: "Launch at login") {
            launchItem.state = launch ? .on : .off
        }
    }
    
    @objc private func goLight() {
        DispatchQueue.global(qos: .userInitiated).async {
            let newValue = setDark(value: false)
            DispatchQueue.main.async {
                self.dark = newValue
                self.updateButtonImage()
                self.updateMenuItems()
            }
        }
    }
    
    @objc private func goDark() {
        DispatchQueue.global(qos: .userInitiated).async {
            let newValue = setDark(value: true)
            DispatchQueue.main.async {
                self.dark = newValue
                self.updateButtonImage()
                self.updateMenuItems()
            }
        }
    }
    
    @objc private func toggleLaunchAtLogin() {
        launch = !launch
        LaunchAtLogin.isEnabled = launch
        updateMenuItems()
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

@main
struct DarkModeToggleApp: App {
    @StateObject private var statusBarController = StatusBarController()
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
