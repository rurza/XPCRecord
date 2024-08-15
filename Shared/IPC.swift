//
//  IPC.swift
//  XPCRecord
//
//  Created by Adam Różyński on 14/08/2024.
//

import Foundation
import SecureXPC

let agentIdentifier = "software.micropixels.XPCRecordAgent"
let uiAgentIdentifier = "software.micropixels.XPCRecordUIAgent"

let startRecordingRoute = XPCRoute.named("startRecording")
    .withSequentialReplyType(String.self)
    .throwsType(RecorderError.self)

let stopRecordingRoute = XPCRoute.named("stopRecording")

enum RecorderError: String, Error, Codable {
    case noAuthorization
    case recognizerFailure
    case notAvailable
    case audioEngineFailure
}
