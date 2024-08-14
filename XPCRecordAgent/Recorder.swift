//
//  Recorder.swift
//  XPCRecordAgent
//
//  Created by Adam Różyński on 14/08/2024.
//

import Foundation
import Speech


final class Recorder {

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                switch status {
                case .denied, .restricted, .notDetermined:
                    continuation.resume(returning: false)
                case .authorized:
                    continuation.resume(returning: true)
                @unknown default:
                    continuation.resume(returning: false)
                }
            }
        }
    }

    func startRecording() async throws -> AsyncStream<String> {
        guard await requestAuthorization() else { throw RecorderError.noAuthorization }
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) else {
            throw RecorderError.recognizerFailure
        }

        return AsyncStream<String> { continuation in
            let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            recognitionRequest.shouldReportPartialResults = true
            let audioEngine = AVAudioEngine()
            let inputNode = audioEngine.inputNode
            var recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { result, error in
                if let result {
                    let text = result.bestTranscription.formattedString
                    continuation.yield(text)
                }

                if error != nil || (result?.isFinal ?? false) {
                    audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                }
            }
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
                recognitionRequest.append(buffer)
            }

            audioEngine.prepare()
        }

    }

    func stopRecording() {

    }
}
