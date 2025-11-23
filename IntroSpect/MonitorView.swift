import SwiftUI
import SmartSpectraSwiftSDK
import AVFoundation
import Charts
import UIKit

// MARK: - ⚠️ DATA MODELS (Used in API calls) ⚠️
// These models are specific to the SDK/API interaction in this view.

// Matches the expected metric payload structure for the /analyze endpoint
struct Metric: Codable {
    let Pulse: Int
    let Breath: Int
    let Time: Double
    let Image: String?
}

// MARK: - FRONTEND DATA MODELS (Charts)
// These define the structure for displaying data points in the Charts framework.

protocol ChartDataPoint {
    var time: Float { get }
    var value: Int { get }
}

struct PulsePoint: Identifiable, ChartDataPoint {
    let id = UUID()
    let time: Float
    let value: Int
    
    static func negativeZero(at index: Int) -> PulsePoint {
        PulsePoint(time: -Float(1 - index), value: 0)
    }
}

struct BreathPoint: Identifiable, ChartDataPoint {
    let id = UUID()
    let time: Float
    let value: Int
    
    static func negativeZero(at index: Int) -> BreathPoint {
        BreathPoint(time: -Float(1 - index), value: 0)
    }
}

// MARK: - MAIN VIEW (MonitorView)

@available(iOS 16.0, *)
struct MonitorView: View {

    @Binding var isRecording: Bool
    
    // --- ACCESS SHARED MANAGERS ---
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var historyManager: HistoryManager // Access the History Manager
    
    @StateObject private var audioManager = AudioPlayerManager()
    @State private var lastSpokenInsight: String = ""
    
    @ObservedObject var sdk = SmartSpectraSwiftSDK.shared
    @ObservedObject var vitals = SmartSpectraVitalsProcessor.shared
    
    @State private var timer: Timer?

    @State private var pulseRate: Int = 0
    @State private var breathingRate: Int = 0
    @State private var timeStamp: Float = 0
    
    // History array for all metric data + analysis for summary API call
    @State private var analysisHistory: [AnalysisData] = []
    
    @State private var geminiInsights: String = "Waiting for live analysis..."
    @State private var expression: String = "Neutral"
    
    @State private var showSettings: Bool = false

    // History arrays filled with zeros initially (size 1)
    @State private var pulseHistory: [PulsePoint] =
        (0..<1).map { PulsePoint.negativeZero(at: $0) }

    @State private var breathHistory: [BreathPoint] =
        (0..<1).map { BreathPoint.negativeZero(at: $0) }

    init(isRecording: Binding<Bool>) {
        self._isRecording = isRecording

        // Initialize SDK settings
        sdk.setSmartSpectraMode(.continuous)
        sdk.setCameraPosition(.front)
        sdk.setImageOutputEnabled(true)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                HeaderView {
                    showSettings = true
                }
                .padding(.top, 8)

                CameraBox(image: vitals.imageOutput)
                    .padding(.horizontal)

                // --- FEEDBACK CONTENT SECTION (Conditional) ---
                if settingsManager.selectedFeedbackFormats.contains("Text") || settingsManager.selectedFeedbackFormats.contains("Facts") || settingsManager.selectedFeedbackFormats.contains("Suggestions") {
                    InsightsCard(geminiInsights: geminiInsights)
                        .padding(.horizontal)
                }

                // --- CHARTS SECTION (Conditional) ---
                if settingsManager.pulseRateEnabled || settingsManager.breathRateEnabled {
                    HStack(spacing: 16) {

                        // Pulse Rate Chart: Only show if enabled
                        if settingsManager.pulseRateEnabled {
                            VitalsChartCard(
                                title: "Pulse Rate",
                                value: "\(pulseRate) bpm",
                                history: pulseHistory,
                                color: .red
                            )
                        }

                        // Breath Rate Chart: Only show if enabled
                        if settingsManager.breathRateEnabled {
                            VitalsChartCard(
                                title: "Breath Rate",
                                value: "\(breathingRate) bpm",
                                history: breathHistory,
                                color: .blue
                            )
                        }
                    }
                    .padding(.horizontal)
                }

                // --- EXPRESSION CARD (Conditional) ---
                if settingsManager.expressionsEnabled {
                    ExpressionCard(expression: expression)
                        .padding(.horizontal)
                }

                Spacer(minLength: 40)
            }
        }
        .background(
            Color(red: 249/255, green: 250/255, blue: 251/255)
                .ignoresSafeArea()
        )
        // Ensure cleanup if the view disappears unexpectedly
        .onDisappear { stopSession() }
        .onChange(of: vitals.imageOutput) {
            updateVitals()
        }

        .onChange(of: isRecording) { oldValue, newValue in
            if newValue {
                startSession()
                // Assuming StartTimer() initiates periodic callApi()
                StartTimer()
            } else {
                // Pause/Stop event
                stopTimer()
                stopSession()
            }
        }

        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(settingsManager)
        }
    }

    // MARK: - Start / Stop Logic
    
    func startSession() {
        vitals.startProcessing()
        vitals.startRecording()
        // Reset history when starting a new session
        analysisHistory = []
        print("Session started. History reset.")
    }

    func stopSession() {
        vitals.stopRecording()
        vitals.stopProcessing()
        print("Session stopped. Total insights collected: \(analysisHistory.count)")
        
        // When session stops, trigger summary creation
        Task { @MainActor in
            self.geminiInsights = "Session stopped. Generating summary..."
            self.expression = "Neutral"
            
            await generateSessionSummaryAndSave()
        }
    }

    func updateVitals() {
        pulseRate = Int(sdk.metricsBuffer?.pulse.rate.last?.value.rounded() ?? 0)
        breathingRate = Int(sdk.metricsBuffer?.breathing.rate.last?.value.rounded() ?? 0)
        timeStamp = sdk.metricsBuffer?.pulse.rate.last?.time ?? 0
        
        // Limit history size to prevent memory overload and keep the chart relevant
        let maxHistorySize = 60
        
        pulseHistory.append(PulsePoint(time: timeStamp, value: pulseRate))
        if pulseHistory.count > maxHistorySize {
            pulseHistory.removeFirst()
        }
        
        breathHistory.append(BreathPoint(time: timeStamp, value: breathingRate))
        if breathHistory.count > maxHistorySize {
            breathHistory.removeFirst()
        }
    }
    
    // MARK: - API Helpers
    
    func buildVitalsPayload(base64Image: String, timeStamp: Double) -> [Metric] {
        let metric = Metric(
            Pulse: pulseRate,
            Breath: breathingRate,
            Time: timeStamp,
            Image: base64Image
        )
        return [metric]
    }
    
    @MainActor
        func callApi() async {
            let currentContentMode = (settingsManager.selectedFeedbackContent ?? "").lowercased()
            guard let imageToProcess = vitals.imageOutput else { return }
            let base64Image = imageToBase64(image: imageToProcess) ?? ""
            let currentTimeStamp = Double(timeStamp)
            let metricsPayload = buildVitalsPayload(base64Image: base64Image, timeStamp: currentTimeStamp)
            
            guard !metricsPayload.isEmpty else { return }
            
            do {
                // 1. Call Analyze API
                let response = try await APIService.analyzeMetrics(metrics: metricsPayload, contentMode: currentContentMode)
                
                if let result = response.results.first {
                    
                    let currentAnalysisData = AnalysisData(
                        analysis: result.analysis,
                        expression: result.expression,
                        timestamp: result.timestamp,
                        error: result.error,
                        metrics: MetricsPayload(heartRate: pulseRate, breathRate: breathingRate)
                    )
                    analysisHistory.append(currentAnalysisData)

                    if let error = result.error {
                        self.geminiInsights = "Analysis Error: \(error)"
                        self.expression = "Error"
                    } else {
                        let analysisText = result.analysis ?? "No insights available."
                        self.geminiInsights = analysisText
                        self.expression = result.expression?.capitalized ?? "Neutral"

                        // 2. Handle TTS Logic

                        let audioEnabled = settingsManager.selectedFeedbackFormats.contains("Audio")

                        // CRITICAL CHECK: Only proceed if Audio is enabled AND the insight text is new/different
                        guard audioEnabled,
                              !analysisText.isEmpty,
                              analysisText != lastSpokenInsight else {
                            return // Exit the TTS block if the conditions are not met
                        }

                        // If we reach here, Audio is enabled and the text is fresh.
                        do {
                            print("Fetching TTS for: \(analysisText)")
                            if let base64Audio = try await APIService.generateSpeech(text: analysisText) {
                                audioManager.playBase64Audio(base64String: base64Audio)
                                lastSpokenInsight = analysisText // Mark this text as spoken
                            }
                        } catch {
                            print("TTS Error: \(error)")
                        }
                    }
                }
            } catch {
                print("API Request Failed: \(error.localizedDescription)")
                self.geminiInsights = "Connection Error..."
                self.expression = "Error"
            }
        }

    @MainActor
    func generateSessionSummaryAndSave() async {
        guard !analysisHistory.isEmpty else {
            self.analysisHistory = []
            self.geminiInsights = "Session stopped. No data collected."
            return
        }

        do {
            let summaryResponse = try await generateSessionSummary(analyses: analysisHistory)
            
            let stats = summaryResponse.sessionStats
            let durationSeconds = Double(stats?.duration ?? "0") ?? 0
            
            // Calculate Average Heart Rate from stored history (safely)
            let totalPulse = analysisHistory.reduce(0.0) { $0 + Double($1.metrics?.heartRate ?? 0) }
            let avgHR = analysisHistory.count > 0 ? totalPulse / Double(analysisHistory.count) : 0.0
            
            // Create the final Session object
            let newSession = Session(
                date: Date(),
                durationMinutes: Int(durationSeconds / 60.0),
                summary: summaryResponse.summary.split(separator: "\n").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? summaryResponse.summary,
                detailedNotes: summaryResponse.summary,
                averageHeartRate: Int(avgHR.rounded())
            )
            
            // Save the new session directly to the History Manager
            historyManager.addSession(newSession)
            
            // Clear history for next session
            self.analysisHistory = []
            
            // Update display to confirm save
            self.geminiInsights = "Summary saved to History: \(newSession.summary)"

        } catch {
            print("Failed to generate session summary: \(error.localizedDescription)")
            self.geminiInsights = "Summary Error: \(error.localizedDescription.prefix(50))."
            self.analysisHistory = []
        }
    }
    
    func imageToBase64(image: UIImage, quality: CGFloat = 0.4, maxDimension: CGFloat = 480.0) -> String? {
        
        // --- STEP 1: RESIZE THE IMAGE ---
        let size = image.size
        var newSize: CGSize
        
        if size.width > size.height {
            let ratio = maxDimension / size.width
            newSize = CGSize(width: maxDimension, height: size.height * ratio)
        } else {
            let ratio = maxDimension / size.height
            newSize = CGSize(width: size.width * ratio, height: maxDimension)
        }
        
        UIGraphicsBeginImageContext(newSize)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let finalImage = scaledImage else {
            print("Error: Could not scale UIImage.")
            return nil
        }

        // --- STEP 2: COMPRESS (JPEG) AND ENCODE ---
        guard let imageData = finalImage.jpegData(compressionQuality: quality) else {
            print("Error: Could not convert UIImage to Data after scaling.")
            return nil
        }
        
        let base64String = imageData.base64EncodedString()
        
        return base64String
    }
    
    private func StartTimer() {
        timer?.invalidate()
        
        // Fire every 1.0 second
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            Task {
                await callApi()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}


// MARK: - SUBVIEWS (Reusable Components)


struct HeaderView: View {
    var onSettingsTapped: () -> Void

    var body: some View {
        HStack {
            Text("IntroSpect")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)
            Spacer()
            Button(action: onSettingsTapped) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
    }
}

struct InsightsCard: View {
    let geminiInsights: String

    var body: some View {
        RoundedCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Live Insights:")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(geminiInsights)
                    .font(.body)
                    .foregroundColor(.black.opacity(0.85))
            }
        }
    }
}

struct ExpressionCard: View {
    let expression: String

    var body: some View {
        RoundedCard {
            HStack {
                Text("Detected Expression:")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
                Text(expression)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.black.opacity(0.85))
            }
        }
    }
}

// Chart card reused for pulse & breath
struct VitalsChartCard<T: Identifiable & ChartDataPoint>: View {
    let title: String
    let value: String
    let history: [T]
    let color: Color

    var body: some View {
        RoundedCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(title):")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.black.opacity(0.85))
                    .frame(height: 30, alignment: .topLeading)

                Chart(history) { item in
                    LineMark(
                        x: .value("Time", item.time),
                        y: .value(title, item.value)
                    )
                    .foregroundStyle(color)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartPlotStyle { plotContent in
                    plotContent.background(Color.clear)
                }
                .frame(height: 80)
            }
        }
    }
}

struct RoundedCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)

            content
                .padding(16)
        }
    }
}
