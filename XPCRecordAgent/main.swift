//
//  main.swift
//  XPCRecordAgent
//
//  Created by Adam Różyński on 14/08/2024.
//

import os.log
import SecureXPC

func main() throws {
    let logger = Logger(subsystem: agentIdentifier, category: "main")
    logger.notice("Start agent")
    let server = try XPCServer.forMachService(withCriteria: .forAgent(named: agentIdentifier))
    logger.notice("Server started")
    let recorder = Recorder()
    server.registerRoute(startRecordingRoute) { provider in
        let stream = try await recorder.startRecording()
        for await result in stream {
            try await provider.success(value: result)
        }
    }
    server.registerRoute(stopRecordingRoute) {
        recorder.stopRecording()
    }
    server.startAndBlock()
}

try main()
