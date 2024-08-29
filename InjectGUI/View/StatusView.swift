//
//  StatusView.swift
//  InjectGUI
//
//  Created by wibus on 2024/7/30.
//

import Foundation
import SwiftUI

struct StatusView: View {
    @Environment(\.dismiss) var dismiss // dismiss the sheet

    @StateObject var injector = Injector.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if self.injector.appDetail?.name == nil {
                Text("Why you are seeing this?")
                    .font(.title)
                    .bold()
                    .foregroundColor(.secondary)
                    .padding()
                VStack(alignment: .leading, spacing: 4) {
                    Text("This is a status view for the injector.")
                        .font(.headline)
                    Text("It will only show when the injector is running.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Please contact the developer if you see this view without running the injector.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                Text("Click here to close this view.")
                    .font(.subheadline)
                    .underline()
                    .foregroundColor(.secondary)
                    .onTapGesture {
                        dismiss()
                    }
                    .padding()
            } else {
                // MARK: - App Info Display Box

                HStack(spacing: 20) {
                    Image(nsImage: self.injector.appDetail!.icon)
                        .resizable()
                        .frame(width: 64, height: 64)
                        .cornerRadius(4)
                    // Spacer()
                    VStack(alignment: .leading, spacing: 4) {
                        Text(self.injector.appDetail!.name)
                            .font(.headline)
                        Text(self.injector.appDetail!.identifier)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Version: \(self.injector.appDetail!.version)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: 260)
                Divider()

                // MARK: - Inject Stage Display box

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(InjectStage.allCases, id: \.self) { stage in
                            HStack(spacing: 10) {
                                if let index = injector.stage.stages.firstIndex(where: { $0.stage == stage }) {
                                    switch injector.stage.stages[index].status {
                                    case .none:
                                        Image(systemName: "questionmark.circle")
                                            .foregroundColor(.secondary)
                                    case .running:
                                        Image(systemName: "circle.dotted")
                                    case .finished:
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    case .error:
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                    Text("\(stage.description)")
                                        .fontDesignAndWeight(
                                            font: .rounded,
                                            weight: injector.stage.stages[index].status == .running ? .bold : .regular
                                        )
                                    // Text(injector.stage.stages[index].message)
                                    //     .font(.subheadline)
                                    //     .foregroundColor(.secondary)
                                    if injector.stage.stages[index].error != nil {
                                        Text("Error: \(injector.stage.stages[index].error!.error)")
                                            .font(.subheadline)
                                            .foregroundColor(.red)
                                    }
                                    Spacer()
                                    Text("\(Int(injector.stage.stages[index].progress * 100))%")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                } else {
                                    Image(systemName: "questionmark.circle.fill")
                                        .foregroundColor(.secondary)
                                    Text("\(stage.description)")
                                        .fontDesignAndWeight(font: .rounded, weight: .regular)
                                }
                            }
                        }
                    }
                }
                Spacer()

                // MARK: - Progress Bar

                ProgressBar(value: $injector.stage.progress)
                    .frame(height: 10)
                HStack {
                    Text("Progress: \(Int(injector.stage.progress * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    if let error = injector.stage.error {
                        Text("Error: \(error.error)")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }

                // MARK: - Buttons

                Button(injector.stage.progress == 1 ? "Finished. Close" : "Stop Injecting") {
                    if injector.stage.progress == 1 {
                        injector.stopInjectApp()
                        dismiss()
                        return
                    }
                    let alert = NSAlert()
                    alert.messageText = String(localized: "Are you sure you want to stop injecting?")
                    alert.informativeText = String(localized: "The app may not work properly if you stop injecting.")
                    alert.addButton(withTitle: String(localized: "Stop"))
                    alert.addButton(withTitle: String(localized: "Cancel"))
                    alert.beginSheetModal(for: NSApp.keyWindow!) { response in
                        if response == .alertFirstButtonReturn {
                            injector.stopInjectApp()
                            dismiss()
                        }
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
                .frame(maxWidth: .infinity)
            }
        }
//        .onChange(of: injector.isRunning) { _ in
//            let appId = injector.stage.appId
//            guard let self.injector.appDetail = softwareManager.appListCache[appId] else {
//                return
//            }
//            self.self.injector.appDetail = self.injector.appDetail
//        }
        .frame(minWidth: 350, minHeight: 400)
        .padding()
        .background(Color(.windowBackgroundColor))
    }
}

struct ProgressBar: View {
    @Binding var value: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(Color(.systemGray))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .cornerRadius(geometry.size.height / 2)
                Rectangle()
                    .foregroundColor(.accentColor)
                    .frame(width: min(CGFloat(value) * geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .cornerRadius(geometry.size.height / 2)
            }
        }
    }
}
