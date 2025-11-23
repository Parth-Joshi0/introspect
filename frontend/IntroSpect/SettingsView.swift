// SettingsView.swift

import SwiftUI

struct SettingsView: View {
    // Access the shared settings manager injected from ContentView
    @EnvironmentObject var settingsManager: SettingsManager

    // Local arrays defined once (Read-Only)
    let feedbackFormatOptions = ["Audio", "Text"]
    let feedbackContentOptions = ["Suggestions", "Facts"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                
                // --- Title (Adapted for ScrollView/Custom Header) ---
                HStack {
                    Spacer()
                    Text("Settings")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                    Spacer()
                }

                // --- 1. SHOW METRICS ---
                sectionHeader("Show Metrics")
                settingsCard {
                    // Toggles bound to manager's @Published Bools
                    toggleRow("Pulse Rate", isOn: $settingsManager.pulseRateEnabled)
                    divider()
                    toggleRow("Breath Rate", isOn: $settingsManager.breathRateEnabled)
                    divider()
                    toggleRow("Expressions", isOn: $settingsManager.expressionsEnabled)
                }

                // --- 2. FEEDBACK FORMAT (Choose 1 to 2 options) ---
                sectionHeader("Feedback Format", subtitle: "Choose 1 to 2 options")
                settingsCard {
                    ForEach(feedbackFormatOptions, id: \.self) { option in
                        selectionRow(
                            title: option,
                            // Check if option is contained in the Set
                            isSelected: settingsManager.selectedFeedbackFormats.contains(option)
                        ) {
                            // Call the 1-2 selection logic
                            toggleSelection(option: option)
                        }
                        // Add divider unless it's the last option
                        if option != feedbackFormatOptions.last { divider() }
                    }
                }

                // --- 3. FEEDBACK CONTENT (Choose 1 option only) ---
                sectionHeader("Feedback Content", subtitle: "Choose 1 option only")
                settingsCard {
                    ForEach(feedbackContentOptions, id: \.self) { option in
                        selectionRow(
                            title: option,
                            // Check if option matches the single selected String
                            isSelected: (settingsManager.selectedFeedbackContent == option)
                        ) {
                            // Mutually exclusive: Tapping sets the selection
                            settingsManager.selectedFeedbackContent = option
                        }
                        if option != feedbackContentOptions.last { divider() }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 30) // Extra padding for scroll safety
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: - Logic (Uses SettingsManager)

    func toggleSelection(option: String) {
        if settingsManager.selectedFeedbackFormats.contains(option) {
            // Prevent deselecting if it's the last selected item
            if settingsManager.selectedFeedbackFormats.count > 1 {
                settingsManager.selectedFeedbackFormats.remove(option)
            }
        } else {
            // Prevent selecting more than 2
            if settingsManager.selectedFeedbackFormats.count < 2 {
                settingsManager.selectedFeedbackFormats.insert(option)
            }
        }
    }

    // MARK: - UI Building Blocks (Your Custom Components)

    @ViewBuilder
    func sectionHeader(_ title: String, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            // Main Title (Uppercased)
            Text(title.uppercased())
                .font(.caption)
                .foregroundColor(.gray)

            // Subtitle (if provided)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.7))
            }
        }
        .padding(.leading, 4)
    }

    @ViewBuilder
    func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .padding(.vertical, 4)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }

    @ViewBuilder
    func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    func selectionRow(title: String, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    @ViewBuilder
    func divider() -> some View {
        Rectangle()
            .fill(Color.gray.opacity(0.25))
            .frame(height: 0.5)
            .padding(.leading, 16)
    }
}
