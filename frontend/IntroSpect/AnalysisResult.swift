import Foundation

// MARK: - API Request/Response Models

// Used for collecting the real-time data history in MonitorView
struct AnalysisData: Codable {
    let analysis: String?
    let expression: String?
    let timestamp: Double
    let error: String?
    // Added to align with the backend's expected structure for metric values
    let metrics: MetricsPayload?
}

// Sub-struct to mirror the backend payload when sending to /summary
struct MetricsPayload: Codable {
    let heartRate: Int?
    let breathRate: Int?
}

// Used for the final summary response from the /summary endpoint
struct SummaryResponse: Codable {
    let summary: String
    let sessionStats: SessionStats?
}

struct SessionStats: Codable {
    let totalInsights: Int
    let duration: String
    let mostCommonEmotion: String
    let emotionDistribution: [String: Int]
}

// Used for the real-time /analyze endpoint response
struct AnalyzeResponse: Codable {
    let results: [AnalysisResult]
    let totalProcessed: Int?
}

struct AnalysisResult: Codable {
    let analysis: String?
    let expression: String?
    let timestamp: Double
    let error: String?
}


// MARK: - API Service Class

class APIService {
    
    // NOTE: Replace this IP with your actual server IP/port if it changes
    private static let apiBaseURL = "http://172.20.10.12:8787"
    
    private static let analyzeURL = URL(string: "\(apiBaseURL)/analyze")!
    private static let summaryURL = URL(string: "\(apiBaseURL)/summary")!
    
    // Core function for real-time analysis
    static func analyzeMetrics(metrics: [Metric], contentMode: String) async throws -> AnalyzeResponse {
        var components = URLComponents(url: analyzeURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "contentMode", value: contentMode)
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(metrics)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(AnalyzeResponse.self, from: data)
    }

    // Core function to generate the final session summary.
    static func generateSummary(analyses: [AnalysisData]) async throws -> SummaryResponse {
        
        var request = URLRequest(url: summaryURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // The body must be the array of AnalysisData objects
        let finalRequestBody = try JSONEncoder().encode(analyses)
        request.httpBody = finalRequestBody
        
        print("Sending Summary API request...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            let responseString = String(data: data, encoding: .utf8) ?? "No response body."
            print("Summary API Error - Status Code: \(statusCode), Body: \(responseString)")
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(SummaryResponse.self, from: data)
    }
}

// MARK: - Global Helper Functions

func analyzeMetrics(metrics: [Metric], contentMode: String) async throws -> AnalyzeResponse {
    return try await APIService.analyzeMetrics(metrics: metrics, contentMode: contentMode)
}

func generateSessionSummary(analyses: [AnalysisData]) async throws -> SummaryResponse {
    return try await APIService.generateSummary(analyses: analyses)
}

// MARK: - TTS API Models

struct TTSRequestItem: Codable {
    let text: String
    let voice: String?
}

struct TTSBatchResponse: Codable {
    let results: [TTSResult]
}

struct TTSResult: Codable {
    let audio: String? // This is the Base64 string
    let error: String?
}

// MARK: - APIService Extension

extension APIService {
    
    private static let ttsURL = URL(string: "\(apiBaseURL)/tts")!
    
    static func generateSpeech(text: String, voiceId: String = "pNInz6obpgDQGcFmaJgB") async throws -> String? {
        var request = URLRequest(url: ttsURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // We send an array to trigger the "Batch" logic in your backend,
        // which returns JSON + Base64 (instead of raw binary)
        let payload = [TTSRequestItem(text: text, voice: voiceId)]
        
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let decodedResponse = try JSONDecoder().decode(TTSBatchResponse.self, from: data)
        
        // Return the Base64 audio string from the first result
        return decodedResponse.results.first?.audio
    }
}
