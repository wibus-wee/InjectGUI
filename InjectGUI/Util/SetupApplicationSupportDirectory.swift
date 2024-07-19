//
//  SetupApplicationSupportDirectory.swift
//  InjectGUI
//
//  Created by wibus on 2024/7/19.
//

import Foundation

func setupApplicationSupportDirectory() {
        let fileManager = FileManager.default
        let applicationSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appSpecificDirectory = applicationSupportDirectory.appendingPathComponent(Constants.appName, isDirectory: true)

        do {
            try fileManager.createDirectory(at: appSpecificDirectory, withIntermediateDirectories: true, attributes: nil)
            print("Application Support directory created at \(appSpecificDirectory)")
        } catch {
            print("Failed to create Application Support directory: \(error)")
        }
}


func getApplicationSupportDirectory() -> URL {
    let fileManager = FileManager.default
    let applicationSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let appSpecificDirectory = applicationSupportDirectory.appendingPathComponent(Constants.appName, isDirectory: true)
    return appSpecificDirectory
}
