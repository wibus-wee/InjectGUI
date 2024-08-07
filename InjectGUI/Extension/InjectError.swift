//
//  InjectError.swift
//  InjectGUI
//
//  Created by wibus on 2024/8/6.
//


import Foundation

enum InjectError {

    case helperInstallation(String)
    case helperConnection(String)
    case unknown
}

// MARK: - LocalizedError

extension InjectError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .helperInstallation(let description): return "Helper installation error. \(description)"
        case .helperConnection(let description): return "Helper connection error. \(description)"
        case .unknown: return "Unknown error"
        }
    }
}
