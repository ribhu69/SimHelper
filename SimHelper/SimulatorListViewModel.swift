//
//  SimulatorListViewModel.swift
//  SimHelper
//
//  Created by Arkaprava Aniruddha Ghosh on 29/06/25.
//
import SwiftUI

class SimulatorListViewModel: ObservableObject {
    @Published var devices: [SimulatorDevice] = []
    @Published var filter: String = "All"
    @Published var selectedDevice: SimulatorDevice?
    @Published var installedApps: [InstalledApp] = []
    @Published var isAppSheetPresented: Bool = false
    @Published var isLoadingApps: Bool = false
    @Published var appFetchError: String?

    var filteredDevicesByVersion: [String: [SimulatorDevice]] {
        let filtered = devices.filter { device in
            filter == "All" || device.type == filter
        }
        return Dictionary(grouping: filtered, by: { $0.version })
            .sorted { $0.key.compare($1.key, options: .numeric) == .orderedDescending }
            .reduce(into: [String: [SimulatorDevice]]()) { $0[$1.key] = $1.value }
    }
    
    var deviceTypes: [String] {
        let types = Set(devices.map { $0.type })
        return ["All"] + types.sorted()
    }
    
    init() {
        fetchSimulators()
    }
    
    func fetchSimulators() {
        print("Running: xcrun simctl list devices")
        let task = Process()
        task.launchPath = "/usr/bin/xcrun"
        task.arguments = ["simctl", "list", "devices"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            parseSimctlOutput(output)
        }
    }
    
    func parseSimctlOutput(_ output: String) {
        var currentVersion = ""
        var foundDevices: [SimulatorDevice] = []
        for line in output.components(separatedBy: "\n") {
            if line.contains("-- iOS ") {
                if let version = line.components(separatedBy: "-- iOS ").last?.components(separatedBy: " --").first {
                    currentVersion = version.trimmingCharacters(in: .whitespaces)
                }
            } else if line.contains("(Booted)") || line.contains("(Shutdown)") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                let regex = try! NSRegularExpression(pattern: #"^(.*?) \(([\w-]+)\) \((Booted|Shutdown)\)$"#)
                if let match = regex.firstMatch(in: trimmed, range: NSRange(location: 0, length: trimmed.utf16.count)) {
                    let name = (trimmed as NSString).substring(with: match.range(at: 1))
                    let udid = (trimmed as NSString).substring(with: match.range(at: 2))
                    let state = (trimmed as NSString).substring(with: match.range(at: 3))
                    let type: String
                    if name.lowercased().contains("ipad") {
                        type = "iPad"
                    } else if name.lowercased().contains("iphone") {
                        type = "iPhone"
                    } else {
                        type = "Other"
                    }
                    foundDevices.append(SimulatorDevice(name: name, version: currentVersion, state: state, udid: udid, type: type))
                }
            }
        }
        DispatchQueue.main.async {
            self.devices = foundDevices
        }
    }
    
    func bootSimulator(_ device: SimulatorDevice) {
        print("Running: xcrun simctl boot \(device.udid)")
        let bootTask = Process()
        bootTask.launchPath = "/usr/bin/xcrun"
        bootTask.arguments = ["simctl", "boot", device.udid]
        bootTask.launch()
        bootTask.waitUntilExit()
        
        print("Running: open -a Simulator")
        let openTask = Process()
        openTask.launchPath = "/usr/bin/open"
        openTask.arguments = ["-a", "Simulator"]
        openTask.launch()
        openTask.waitUntilExit()
        
        fetchSimulators()
    }
    
    func shutdownSimulator(_ device: SimulatorDevice) {
        print("Running: xcrun simctl shutdown \(device.udid)")
        let task = Process()
        task.launchPath = "/usr/bin/xcrun"
        task.arguments = ["simctl", "shutdown", device.udid]
        task.launch()
        task.waitUntilExit()
        fetchSimulators()
    }
    
    func fetchInstalledApps(for device: SimulatorDevice) {
        isLoadingApps = true
        installedApps = []
        appFetchError = nil
        DispatchQueue.global(qos: .userInitiated).async {
            print("Running: xcrun simctl listapps \(device.udid) | plutil -convert json -o - -")
            let task = Process()
            let pipe = Pipe()
            let errorPipe = Pipe()
            
            // Use /bin/sh to run the piped command
            task.launchPath = "/bin/sh"
            task.arguments = ["-c", "xcrun simctl listapps \(device.udid) | plutil -convert json -o - -"]
            task.standardOutput = pipe
            task.standardError = errorPipe
            task.launch()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
            
            guard let output = String(data: data, encoding: .utf8), !output.isEmpty else {
                DispatchQueue.main.async {
                    self.appFetchError = "Failed to fetch apps.\n\(errorOutput)"
                    self.isLoadingApps = false
                }
                return
            }
            var apps: [InstalledApp] = []
            if let jsonData = output.data(using: .utf8) {
                do {
                    if let dict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                        for (bundleId, info) in dict {
                            let name: String
                            if let infoDict = info as? [String: Any],
                               let displayName = infoDict["CFBundleDisplayName"] as? String {
                                name = displayName
                            } else {
                                name = bundleId
                            }
                            apps.append(InstalledApp(bundleId: bundleId, name: name))
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.appFetchError = "Failed to parse app list.\nRaw output:\n\(output)"
                        self.isLoadingApps = false
                    }
                    return
                }
            }
            DispatchQueue.main.async {
                self.installedApps = apps.sorted { $0.name < $1.name }
                self.isLoadingApps = false
            }
        }
    }
    
    func launchApp(_ app: InstalledApp, on device: SimulatorDevice) {
        print("Running: xcrun simctl launch \(device.udid) \(app.bundleId)")
        let task = Process()
        task.launchPath = "/usr/bin/xcrun"
        task.arguments = ["simctl", "launch", device.udid, app.bundleId]
        task.launch()
        task.waitUntilExit()
        print("Running: open -a Simulator")
        let openTask = Process()
        openTask.launchPath = "/usr/bin/open"
        openTask.arguments = ["-a", "Simulator"]
        openTask.launch()
        openTask.waitUntilExit()
    }
}
