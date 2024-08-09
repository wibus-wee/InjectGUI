//
//  ViewKit.swift
//  InjectGUI
//
//  Created by wibus on 2024/7/19.
//

import SwiftUI

enum ViewKit {
    typealias IsClickPrimaryButton = Bool
    
    struct AnySheetView: View {
        @Environment(\.dismiss) var dismiss // dismiss the sheet
        let title: String
        let secondaryButton: String
        let primaryButton: String
        let toolbar: (() -> (AnyView))?
        let content: () -> (AnyView)
        let action: (IsClickPrimaryButton) -> Void
        
        init(
            title: String,
            secondaryButton: String,
            primaryButton: String,
            toolbar: (() -> (AnyView))? = nil,
            content: @escaping () -> AnyView,
            action: @escaping (IsClickPrimaryButton) -> Void
        ) {
            self.title = title
            self.secondaryButton = secondaryButton
            self.primaryButton = primaryButton
            self.toolbar = toolbar
            self.content = content
            self.action = action
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                if title.isEmpty, toolbar == nil {
                } else {
                    HStack {
                        Text(title).font(.headline)
                        Spacer()
                        if let toolbar { toolbar() }
                    }
                    Divider()
                }
                content()
                Divider()
                HStack {
                    if !secondaryButton.isEmpty {
                        Button {
                            action(false)
                            dismiss()
                        } label: { Text(secondaryButton) }
                    }
                    Spacer()
                    if !primaryButton.isEmpty {
                        Button {
                            action(true)
                            dismiss()
                        } label: { Text(primaryButton) }
                            .buttonStyle(.borderedProminent)
                    }
                }
                .background(
                    Button("") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                        .opacity(0)
                )
            }
            .padding()
        }
    }
    
    static func useSheet(
        title: String,
        secondaryButton: String = String(localized: "Cancel"),
        primaryButton: String = String(localized: "OK"),
        toolbar: (() -> (AnyView))? = nil,
        content: @escaping () -> AnyView,
        action: @escaping (IsClickPrimaryButton) -> Void?
    ) -> some View {
        AnySheetView(
            title: title,
            secondaryButton: secondaryButton,
            primaryButton: primaryButton,
            toolbar: toolbar,
            content: content,
            action: { isClickPrimaryButton in
                action(isClickPrimaryButton)
            }
        )
    }
    
    static func useAlert(
        title: String,
        message: String,
        primaryButton: String = String(localized: "OK"),
        secondaryButton: String = String(localized: "Cancel"),
        action: @escaping (IsClickPrimaryButton) -> Void?
    ) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: primaryButton)
        alert.addButton(withTitle: secondaryButton)
        alert.alertStyle = .informational
        alert.beginSheetModal(for: NSApp.mainWindow!) { response in
            action(response == .alertFirstButtonReturn)
        }
    }

    static func eazyAlert(
        title: String,
        message: String
    ) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.beginSheetModal(for: NSApp.mainWindow!) { _ in
        }
    }
    
    static func useFilePanel(
        title: String,
        message: String,
        primaryButton: String = String(localized: "OK"),
        secondaryButton: String = String(localized: "Cancel"),
        action: @escaping (URL?) -> Void
    ) {
        let panel = NSOpenPanel()
        panel.title = title
        panel.message = message
        panel.prompt = primaryButton
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.beginSheetModal(for: NSApp.mainWindow!) { _ in
            action(panel.url)
        }
    }

    static func useDirectoryPanel(
        title: String,
        message: String,
        primaryButton: String = String(localized: "OK"),
        secondaryButton: String = String(localized: "Cancel"),
        action: @escaping (URL?) -> Void
    ) {
        let panel = NSOpenPanel()
        panel.title = title
        panel.message = message
        panel.prompt = primaryButton
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.beginSheetModal(for: NSApp.mainWindow!) { _ in
            action(panel.url)
        }
    }
    
    static func saveFilePanel(
        title: String,
        message: String,
        primaryButton: String = String(localized: "OK"),
        secondaryButton: String = String(localized: "Cancel"),
        action: @escaping (URL?) -> Void
    ) {
        let panel = NSSavePanel()
        panel.title = title
        panel.message = message
        panel.prompt = primaryButton
        panel.canCreateDirectories = true
        panel.beginSheetModal(for: NSApp.mainWindow!) { _ in
            action(panel.url)
        }
    }
}
