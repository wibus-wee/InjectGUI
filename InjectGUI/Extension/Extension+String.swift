//
//  Extension+String.swift
//  InjectGUI
//
//  Created by wibus on 2024/8/3.
//

import Foundation

extension String {
    func transformTo(to targetType: Injector.GenScriptType) -> String {
        let original = self.replacing("\\\\ ", with: " ").replacing("\\ ", with: " ")
        
        print(original)
        
        // 再根据目标类型进行转换
        switch targetType {
        case .none:
            return original
        case .appleScript:
            return original.replacing(" ", with: "\\\\ ")
        case .bash:
            return original.replacing(" ", with: "\\ ")
        }
    }
}
