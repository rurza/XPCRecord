//
//  Server.swift
//  XPCRecordUIAgent
//
//  Created by Adam Różyński on 14/08/2024.
//

import Foundation
import os.log
import SecureXPC

final class Server {
    lazy var recorder = Recorder()
    private let logger = Logger(subsystem: uiAgentIdentifier, category: "Server")

    init() {

    }

    func start() {
        logger.notice("Starting server...")
        let server = try! XPCServer.forMachService(withCriteria: .forLoginItem())
        server.registerRoute(startRecordingRoute) { provider in
            self.logger.notice("Starting recording...")
            let stream = try await self.recorder.startRecording()
            for try await result in stream {
                try await provider.success(value: result)
            }
        }
        server.registerRoute(stopRecordingRoute) {
            self.recorder.stopRecording()
        }
        server.start()
        logger.notice("Server started.")
    }
}
