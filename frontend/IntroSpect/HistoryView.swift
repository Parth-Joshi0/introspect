import SwiftUI
import Foundation

// NOTE: Session and SessionDetailView should be defined in HistoryManager.swift or its own file.

// MARK: - History Card View (Base unchanged)

struct HistoryCardView: View {
    let session: Session

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                // Top Row: Date and Arrow
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                    Text(session.date, style: .date)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.black)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }

                // Middle Row: Time and Duration
                HStack {
                    Text(session.date, style: .time)
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                    
                    Text("•")
                        .foregroundColor(Color.gray)
                    
                    Text("\(session.durationMinutes) min")
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                }
                
                // Bottom Row: Summary Text
                Text(session.summary)
                    .font(.callout)
                    .foregroundColor(Color.black)
                    .lineLimit(2)
            }
            .padding(16)
        }
        // Styling the card to match your design
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - History View (Reads from Manager)

struct HistoryView: View {
    // Read sessions from the environment object
    @EnvironmentObject var historyManager: HistoryManager
    
    @State private var selectedSession: Session?

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                // Title: "Session History"
                Text("Session History")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                Spacer()
            }
            
            // Scrollable List of Cards
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(historyManager.sessions) { session in
                        HistoryCardView(session: session)
                            .onTapGesture {
                                selectedSession = session
                            }
                    }
                }
                .padding(.vertical)
                .padding(.horizontal)
            }
        }
        .background(Color(red: 249/255, green: 250/255, blue: 251/255).ignoresSafeArea())
        
        // Present the sheet based on the state
        .sheet(item: $selectedSession) { session in
            SessionDetailView(session: session)
        }
    }
}

struct SessionDetailView: View {
    let session: Session
    @Environment(\.dismiss) var dismiss // Used to close the sheet

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Header Information
                    VStack(alignment: .leading, spacing: 8) {
                        Text(session.date, style: .date)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        HStack {
                            Text(session.date, style: .time)
                            Text("•")
                            Text("\(session.durationMinutes) min")
                        }
                        .font(.title3)
                        .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Key Metrics
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Key Metrics")
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: "heart.fill").foregroundColor(.red)
                            Text("Avg. Heart Rate:")
                            Spacer()
                            Text("**\(session.averageHeartRate) bpm**")
                        }
                    }
                    
                    Divider()
                    
                    // Full Detailed Notes
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Detailed Analysis")
                            .font(.headline)
                        
                        Text(session.detailedNotes)
                            .font(.body)
                    }
                }
                .padding()
            }
            .navigationTitle("Session Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss() // Dismisses the sheet
                    }
                }
            }
        }
    }
}
