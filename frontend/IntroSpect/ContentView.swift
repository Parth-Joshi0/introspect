import SwiftUI
import SmartSpectraSwiftSDK

enum MainTab {
    case home
    case history
}

@available(iOS 16.0, *)
struct ContentView: View {
    @ObservedObject var sdk = SmartSpectraSwiftSDK.shared

    @StateObject var settingsManager = SettingsManager()
    @StateObject var historyManager = HistoryManager() // Create History Manager
    
    init() {
        sdk.setApiKey("ENTER API KEY HERE")
    }

    @State private var selectedTab: MainTab = .home
    @State private var isRecording: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {

            // --- 1. Main Page Content ---
            Group {
                switch selectedTab {
                case .home:
                    // Inject both managers
                    MonitorView(isRecording: $isRecording)
                        .environmentObject(settingsManager)
                        .environmentObject(historyManager)

                case .history:
                    // Inject both managers
                    HistoryView()
                        .environmentObject(settingsManager)
                        .environmentObject(historyManager)
                }
            }
            .padding(.bottom, 0)
            
            // --- 2. Floating Tab Bar (Assuming CustomTabBar exists) ---
            CustomTabBar(
                selectedTab: $selectedTab,
                isRecording: $isRecording
            )
        }
        // No .onChange required here, as MonitorView handles saving to the manager.
        .background(
            Color(red: 249/255, green: 250/255, blue: 251/255)
                .ignoresSafeArea()
        )
    }
}
