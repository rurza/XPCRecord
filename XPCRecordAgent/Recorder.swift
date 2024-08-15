//
//  Recorder.swift
//  XPCRecordAgent
//
//  Created by Adam Różyński on 14/08/2024.
//

import Foundation
import os.log
import Speech

final class Recorder {
    private lazy var logger = Logger(subsystem: "software.micropixels.XPCRecord", category: "Recorder")
    private let speechRecogniser = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    func startRecording() async throws -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                logger.notice("Starting speech recognition task.")

                guard speechRecogniser.isAvailable else {
                    logger.notice("Speech recognizer not available.")
                    continuation.finish(throwing: RecorderError.notAvailable)
                    return
                }
                logger.notice("Speech recognizer is available.")

                if SFSpeechRecognizer.authorizationStatus() != .authorized {
                    logger.notice("Requesting speech recognition authorization.")
                    let status = await withCheckedContinuation { continuation in
                        SFSpeechRecognizer.requestAuthorization { status in
                            continuation.resume(returning: status)
                        }
                    }
                    guard status == .authorized else {
                        logger.notice("Authorization denied for speech recognition.")
                        continuation.finish(throwing: RecorderError.noAuthorization)
                        return
                    }
                    logger.notice("Authorization granted for speech recognition.")
                }

                recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
                guard let recognitionRequest = recognitionRequest else {
                    logger.notice("Failed to create recognition request.")
                    continuation.finish(throwing: RecorderError.recognizerFailure)
                    return
                }
                logger.notice("Recognition request created successfully.")

                let inputNode = audioEngine.inputNode
                recognitionTask = speechRecogniser.recognitionTask(with: recognitionRequest) { result, error in
                    self.logger.notice("recognitionTask callback")
                    if let result = result {
                        let spokenText = result.bestTranscription.formattedString
                        self.logger.notice("Recognized spoken text: \(spokenText, privacy: .public)")
                        continuation.yield(spokenText)
                    }

                    if result?.isFinal ?? (error != nil) {
                        self.logger.notice("Final recognition result received or error occurred.")
                        inputNode.removeTap(onBus: 0)
                    }
                }

                let recordingFormat = inputNode.outputFormat(forBus: 0)
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
                    self.recognitionRequest?.append(buffer)
                }
                logger.notice("Audio tap installed on input node.")

                audioEngine.prepare()
                do {
                    try audioEngine.start()
                    logger.notice("Audio engine started successfully.")
                } catch {
                    logger.notice("Failed to start audio engine.")
                    continuation.finish(throwing: RecorderError.audioEngineFailure)
                }

                continuation.onTermination = { [weak self] termination in
                    self?.logger.notice("Termination of speech recognition task detected.")
                    self?.audioEngine.stop()
                    recognitionRequest.endAudio()
                }
            }
        }
    }

    func stopRecording() {
        recognitionTask?.finish()
        audioEngine.stop()
        recognitionRequest?.endAudio()
    }
}
