import SwiftUI
import ServiceManagement
import os.log

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

@main
struct DarkModeToggleApp: App {
    @State var dark = isDark()
    @State var launch = LaunchAtLogin.isEnabled
    
    var body: some Scene {
        MenuBarExtra() {
            Button() {
                DispatchQueue.global(qos: .userInitiated).async {
                    dark = setDark(value: false)
                }
            } label: {
                HStack {
                    Image("sun").renderingMode(.template)
                    Text("Go Light")
                }
            }.disabled(!dark)
            
        
            Button() {
                DispatchQueue.global(qos: .userInitiated).async {
                    dark = setDark(value: true)
                }
            } label: {
                HStack {
                    Image("moon").renderingMode(.template)
                    Text("Go Dark")
                }
            }.disabled(dark)
            
            Divider()
                        
            Button() {
                launch = !launch
                LaunchAtLogin.isEnabled = launch
            } label: {
                HStack {
                    if launch {
                        Image("checkmark").renderingMode(.template)
                    }
                    Text("Launch at login")
                }
            }

            Divider()
            
            Button("Quit") {
               NSApplication.shared.terminate(nil)
           }
        } label: {
            Image(dark ? "moon" : "sun").renderingMode(.template)
        }
    }
}
