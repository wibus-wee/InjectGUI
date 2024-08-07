//
//  Extension+OSStatus.swift
//  InjectGUI
//
//  Created by wibus on 2024/8/6.
//

import Foundation

// MARK: - Check error

extension OSStatus {

    /// If the status is not a success, get the error out of it and throw it.
    func checkError(_ functionName: String) throws {
        if self == errSecSuccess { return }
        throw SecurityError(status: self, functionName: functionName)
    }
}

// MARK: - SecError

extension OSStatus {

    /// An error that might be thrown by the /// [Security Framework](https://developer.apple.com/documentation/security/1542001-security_framework_result_codes)
    struct SecurityError: Error {

        // MARK: Properties

        let localizedDescription: String

        // MARK: Init

        init(status: OSStatus, functionName: String) {
            let statusMessage = SecCopyErrorMessageString(status, nil) as String? ?? "Unknown sec error"
            localizedDescription = "[\(functionName)] \(statusMessage)"
        }
    }
}
