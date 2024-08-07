//
//  ExecutionService.swift
//  InjectGUI
//
//  Created by wibus on 2024/8/6.
//


import Foundation

// MARK: - ExecutionService

/// Execute a script.
enum ExecutionService {

    // MARK: Constants

    static let programURL = URL(fileURLWithPath: "/usr/bin/env")

    // MARK: Execute

    /// Execute the script at the provided URL.
    static func executeScript(at path: String) async throws -> String {
        let process = Process()
        process.executableURL = programURL
        process.arguments = [path]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        try process.run()

        return try await Task {
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()

            guard let output = String(data: outputData, encoding: .utf8) else {
                throw InjectError.unknown
            }

            return output
        }
        .value
    }
}
