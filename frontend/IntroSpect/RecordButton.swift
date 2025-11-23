// RecordButton.swift

import SwiftUI

struct RecordButton: View {
    @Binding var isRecording: Bool

    var body: some View {
        Button {
            isRecording.toggle()
        } label: {
            ZStack {
                Circle()
                    .fill(isRecording ? Color.red : Color.blue)
                    .frame(width: 70, height: 70)
                    .shadow(radius: 10)

                Image(systemName: isRecording ? "stop.fill" : "record.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
    }
}
