//
//  ExecutionService.swift
//  InjectGUI
//
//  Created by wibus on 2024/8/6.
//

import Foundation

// MARK: - Execution

/// Execute a script.
enum Execution {

    // MARK: Constants

    static let programURL = URL(fileURLWithPath: "/usr/bin/env")

    // MARK: Execute

    /// Execute the script at the provided URL.
    static func executeScript(at path: String) async throws -> String {
        return try await HelperRemoteProvider.remote().executeScript(at: path)
    }
}
