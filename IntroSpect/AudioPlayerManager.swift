import Foundation
import AVFoundation
import Combine

class AudioPlayerManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    private var audioPlayer: AVAudioPlayer?
    @Published var isPlaying: Bool = false

    override init() {
        super.init()
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            // .playback ensures audio plays even if the silent switch is on
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    func playBase64Audio(base64String: String) {
        // 1. Clean the string (remove data URI prefix if present)
        let cleanString = base64String.replacingOccurrences(of: "data:audio/mpeg;base64,", with: "")
        
        // 2. Convert to Data
        guard let audioData = Data(base64Encoded: cleanString, options: .ignoreUnknownCharacters) else {
            print("Error: Failed to decode Base64 audio string.")
            return
        }

        // 3. Play
        do {
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Error initializing audio player: \(error.localizedDescription)")
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        isPlaying = false
    }

    // AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
    }
}
