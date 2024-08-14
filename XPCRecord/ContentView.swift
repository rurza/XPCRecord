//
//  ContentView.swift
//  XPCRecord
//
//  Created by Adam Różyński on 14/08/2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var model = Model()

    var body: some View {
        VStack {
            HStack {
                Circle()
                    .frame(width: 5, height: 5)
                    .foregroundStyle(model.serviceRegistered ? Color.green : Color.red)
                Button("Toggle service") {
                    model.toggleAgent()
                }
            }
            .padding(.bottom)
            Text(model.isRecording ? "Stop recording" : "Start Recording")
            Button(
                action: {
                    model.userDidTapRecordingButton()
                },
                label: {
                    Image(systemName: "circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundStyle(.red)
                }
            )
            .buttonStyle(.plain)
            .padding()
            .opacity(model.isRecording ? 0.3 : 1)
            .animation(.linear(duration: 1).repeatForever(), value: model.isRecording)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
