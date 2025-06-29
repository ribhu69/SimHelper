//
//  InstalledApp.swift
//  SimHelper
//
//  Created by Arkaprava Aniruddha Ghosh on 29/06/25.
//
import Foundation

struct InstalledApp: Identifiable {
    let id = UUID()
    let bundleId: String
    let name: String
}
