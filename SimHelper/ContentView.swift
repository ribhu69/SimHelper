import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SimulatorListViewModel()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Available iOS Simulators")
                .font(.title)
                .padding(.bottom)
            
            Picker("Device Type", selection: $viewModel.filter) {
                ForEach(viewModel.deviceTypes, id: \.self) { type in
                    Text(type).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.bottom)
            
            List {
                ForEach(Array(viewModel.filteredDevicesByVersion.keys.sorted(by: { $0.compare($1, options: .numeric) == .orderedDescending })), id: \.self) { version in
                    Section(header: Text("iOS \(version)").font(.headline)) {
                        ForEach(viewModel.filteredDevicesByVersion[version] ?? []) { device in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(device.name)
                                    Text(device.udid)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Label(device.state == "Booted" ? "Running" : "Stopped",
                                      systemImage: device.state == "Booted" ? "play.circle.fill" : "pause.circle")
                                    .foregroundColor(device.state == "Booted" ? .green : .gray)
                                    .font(.caption)
                                Button("Start") {
                                    viewModel.bootSimulator(device)
                                }
                                .disabled(device.state == "Booted")
                                Button("Terminate") {
                                    viewModel.shutdownSimulator(device)
                                }
                                .disabled(device.state != "Booted")
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                            .background(device.state == "Booted" ? Color.green.opacity(0.15) : Color.clear)
                            .onTapGesture {
                                viewModel.selectedDevice = device
                                viewModel.isAppSheetPresented = true
                                viewModel.fetchInstalledApps(for: device)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $viewModel.isAppSheetPresented) {
            if let device = viewModel.selectedDevice {
                InstalledAppsSheet(
                    device: device,
                    apps: viewModel.installedApps,
                    isLoading: viewModel.isLoadingApps,
                    error: viewModel.appFetchError,
                    onLaunch: { app in
                        viewModel.launchApp(app, on: device)
                    },
                    onDismiss: {
                        viewModel.isAppSheetPresented = false
                    }
                )
            }
        }
    }
}



