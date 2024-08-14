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
    var serviceRegistered: Bool = false
    private lazy var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Model")

    init() {
        registerService()
    }

    private func registerService() {
        do {
            logger.debug("Register service")
            let service = SMAppService.agent(plistName: agentIdentifier + ".plist")
            try service.register()
            if service.status == .enabled {
                serviceRegistered = true
            }
            logger.debug("Service registered")
        } catch {
            logger.error("Failed to register service: \(error)")
        }
    }

    func userDidTapRecordingButton() {
        Task {
            do {
                logger.debug("Start recording")
                let client = XPCClient.forMachService(named: agentIdentifier)
                let sequence = client.send(to: startRecordingRoute)
                isRecording = true
                for try await text in sequence {
                    
                }
                logger.debug("Recording started")
            } catch {
                logger.error("Failed to start recording: \(error)")
            }
        }
    }

    func toggleAgent() {
        let service = SMAppService.agent(plistName: agentIdentifier + ".plist")
        switch service.status {
        case .enabled:
            try? service.unregister()
            serviceRegistered = false
        case .notRegistered:
            try? service.register()
            serviceRegistered = true
        case .requiresApproval, .notFound:
            fatalError()
        @unknown default:
            fatalError()
        }
    }
}
