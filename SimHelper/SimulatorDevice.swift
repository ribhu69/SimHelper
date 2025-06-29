//
//  SimulatorDevice.swift
//  SimHelper
//
//  Created by Arkaprava Aniruddha Ghosh on 29/06/25.
//
import Foundation

struct SimulatorDevice: Identifiable {
    let id = UUID()
    let name: String
    let version: String
    let state: String
    let udid: String
    let type: String // "iPhone", "iPad", etc.
}
