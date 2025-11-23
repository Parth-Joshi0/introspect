//
//  SettingsManager.swift
//  IntroSpect
//
//  Created by Parth Joshi on 2025-11-23.
//


// SettingsManager.swift

import SwiftUI
import Combine

class SettingsManager: ObservableObject {
    // MARK: Show Metrics (Toggles)
    @Published var pulseRateEnabled: Bool = true
    @Published var breathRateEnabled: Bool = true
    @Published var expressionsEnabled: Bool = true

    // MARK: Feedback Content (Choose 1 Only)
    // The MonitorView uses this to show Live Insights (Gemini) vs. Quantitative data
    @Published var selectedFeedbackContent: String? = "Insight Provided by Gemini" 
    let feedbackContentOptions = ["Insight Provided by Gemini", "Quantitative"]
    
    // MARK: Feedback Format (Choose 1-2) - Included for completeness
    @Published var selectedFeedbackFormats: Set<String> = ["Audio", "Text"]
    let feedbackFormatOptions = ["Audio", "Text"]
}
