//
//  Constants.swift
//  InjectGUI
//
//  Created by wibus on 2024/7/19.
//

import Foundation

enum Constants {
    static let appName = "InjectGUI"
    static let authorHomepageUrl = URL(string: "https://github.com/wibus-wee")!
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    static let appBuildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
    static let projectUrl = URL(string: "https://github.com/wibus-wee/InjectGUI")!
    static let appKey = "dev.wibus.InjectGUI"
}
