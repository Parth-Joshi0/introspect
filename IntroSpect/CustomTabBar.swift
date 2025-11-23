import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: MainTab
    @Binding var isRecording: Bool

    var body: some View {
        ZStack {
            // Background bar
            HStack {
                // Home Button
                Button(action: {
                    selectedTab = .home
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: "video.fill")
                        Text("Home")
                            .font(.caption2)
                    }
                    .foregroundColor(selectedTab == .home ? .blue : .gray)
                }

                Spacer()

                // History Button
                Button(action: {
                    selectedTab = .history
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("History")
                            .font(.caption2)
                    }
                    .foregroundColor(selectedTab == .history ? .blue : .gray)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
            )
            .padding(.horizontal)

            // Center record button (floats above slightly)
            RecordButton(isRecording: $isRecording)
                .offset(y: -6)
        }
        .padding(.bottom, 6)
    }
}
