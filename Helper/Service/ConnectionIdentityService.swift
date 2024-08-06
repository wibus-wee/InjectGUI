//
//  ConnectionIdentityService.swift
//  InjectGUI
//
//  Created by wibus on 2024/8/6.
//

import Foundation

enum ConnectionIdentityService {
    private static func secCode(from token: Data) throws -> SecCode {
        let attributesDict = [kSecGuestAttributeAudit: token]

        var secCode: SecCode?
        try SecCodeCopyGuestWithAttributes(nil, attributesDict as CFDictionary, [], &secCode)
            .checkError("SecCodeCopyGuestWithAttributes")

        guard let secCode else {
            throw InjectError.helperConnection("Unable to get secCode from token using 'SecCodeCopyGuestWithAttributes'")
        }

        return secCode
    }
    
    static private let requirementString =
        #"anchor apple generic and identifier "\#(HelperConstants.bundleID)" and certificate leaf[subject.OU] = "\#(HelperConstants.subject)""# as CFString
    
    private static func verifySecCode(secCode: SecCode) throws {
        var secRequirements: SecRequirement?

        try SecRequirementCreateWithString(requirementString, [], &secRequirements)
            .checkError("SecRequirementCreateWithString")
        try SecCodeCheckValidity(secCode, [], secRequirements)
            .checkError("SecCodeCheckValidity")
    }
    
    private static func tokenData(in connection: NSXPCConnection) throws -> Data {
        let property = "auditToken"

        guard connection.responds(to: NSSelectorFromString(property)) else {
            throw InjectError.helperConnection("'NSXPCConnection' has no member '\(property)'")
        }
        guard let auditToken = connection.value(forKey: property) else {
            throw InjectError.helperConnection("'\(property)' from connection is 'nil'")
        }
        guard let auditTokenValue = auditToken as? NSValue else {
            throw InjectError.helperConnection("Unable to get 'NSValue' from '\(property)' in 'NSXPCConnection'")
        }
        guard var auditTokenOpaque = auditTokenValue.value(of: audit_token_t.self) else {
            throw InjectError.helperConnection("'\(property)' 'NSValue' is not of type 'audit_token_t'")
        }

        return Data(bytes: &auditTokenOpaque, count: MemoryLayout<Any>.size) }
    
    static func checkConnectionIsValid(connection: NSXPCConnection) throws {
        let tokenData = try tokenData(in: connection)
        let secCode = try secCode(from: tokenData)
        try verifySecCode(secCode: secCode)
    }
}
