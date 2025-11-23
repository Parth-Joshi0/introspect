//
//  HistoryManager.swift
//  IntroSpect
//
//  Created by Parth Joshi on 2025-11-23.
//

import SwiftUI
import Foundation
import Combine

// MARK: - 1. Session Model (Used in the Manager and History View)

struct Session: Identifiable, Codable { // Added Codable for potential future persistence
    let id = UUID()
    let date: Date
    let durationMinutes: Int
    let summary: String
    let detailedNotes: String
    let averageHeartRate: Int
    
    // Static sample data to preview the UI
    static let samples: [Session] = [
        Session(date: Calendar.current.date(from: DateComponents(year: 2025, month: 11, day: 22, hour: 14, minute: 30))!, durationMinutes: 45, summary: "Client experienced elevated heart rate during discussion. HR increased from 72 to 95 bpm....", detailedNotes: "Detailed notes for Session 1: The client showed clear signs of stress when discussing the upcoming deadline. Heart rate spiked from 72 to 95 and remained elevated for 15 minutes before dropping to 80.", averageHeartRate: 85),
        
        Session(date: Calendar.current.date(from: DateComponents(year: 2025, month: 11, day: 20, hour: 10, minute: 0))!, durationMinutes: 50, summary: "Calm session overall. Heart rate averaged 68 bpm. Client maintained neutral to calm...", detailedNotes: "Detailed notes for Session 2: A very calm and productive session. No significant physiological fluctuations observed. The client appeared relaxed and engaged. HR was stable throughout.", averageHeartRate: 68),
        
        Session(date: Calendar.current.date(from: DateComponents(year: 2025, month: 11, day: 18, hour: 15, minute: 15))!, durationMinutes: 40, summary: "Client showed increased anxiety...", detailedNotes: "Detailed notes for Session 3: Initial anxiety noted during the first 10 minutes, with breathing rate showing variability. Client responded well to grounding techniques.", averageHeartRate: 75)
    ]
}

// MARK: - 2. History Manager

class HistoryManager: ObservableObject {
    // Publish the session array so the HistoryView updates automatically
    @Published var sessions: [Session] = Session.samples
    
    func addSession(_ session: Session) {
        // Insert new session at the start (most recent first)
        sessions.insert(session, at: 0)
    }
}
