//
//  InstalledAppsSheet.swift
//  SimHelper
//
//  Created by Arkaprava Aniruddha Ghosh on 29/06/25.
//
import SwiftUI

struct InstalledAppsSheet: View {
    let device: SimulatorDevice
    let apps: [InstalledApp]
    let isLoading: Bool
    let error: String?
    let onLaunch: (InstalledApp) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Installed Apps on \(device.name)")
                    .font(.headline)
                Spacer()
                Button("Close") { onDismiss() }
            }
            .padding(.bottom)
            if isLoading {
                ProgressView("Loading apps...")
                    .padding()
            } else if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else if apps.isEmpty {
                Text("No apps found.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List(apps) { app in
                    HStack {
                        Text(app.name)
                        Spacer()
                        Text(app.bundleId)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button("Open") {
                            onLaunch(app)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(width: 500, height: 400)
    }
}
