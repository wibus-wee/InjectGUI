//
//  HelperProtocol.swift
//  InjectGUI
//
//  Created by wibus on 2024/8/6.
//

import Foundation

@objc(HelperProtocol)
public protocol HelperProtocol {
    @objc func executeScript(at path: String) async throws -> String
}
