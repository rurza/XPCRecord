//
//  Model.swift
//  XPCRecord
//
//  Created by Adam Różyński on 14/08/2024.
//

import Foundation
import os.log
import SecureXPC
import ServiceManagement

final class Model: ObservableObject {
    @Published
    var isRecording: Bool = false

    @Published
    var text: String?

    lazy var recorder = Recorder()

    @Published
    var serviceRegistered: Bool = false
    private lazy var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Model")

    init() {
        serviceRegistered = service.status == .enabled
    }

    func userDidTapRecordingButton() {
        Task { @MainActor in
            let client = XPCClient.forMachService(named: agentIdentifier)
            if !isRecording {
                do {
                    logger.debug("Start recording")
                    let sequence = client.send(to: startRecordingRoute)
                    isRecording = true
                    for try await text in sequence {
                        self.text = text
                    }
                    logger.debug("Recording started")
                } catch {
                    logger.error("Failed to start recording: \(error)")
                }
            } else {
                try await client.send(to: stopRecordingRoute)
                isRecording = false
                text = nil
            }
        }
    }

    func toggleAgent() {
        do {
            switch service.status {
            case .enabled:
                try service.unregister()
                serviceRegistered = false
            case .notRegistered, .notFound:
                try service.register()
                serviceRegistered = true
            case .requiresApproval:
                logger.debug("Required approval.")
            @unknown default:
                fatalError()
            }
        } catch {
            logger.error("Failed to toggle agent: \(error)")
        }
    }

    var service: SMAppService {
        SMAppService.agent(plistName: agentIdentifier + ".plist")
        //loginItem(identifier: uiAgentIdentifier)
    }
}
