🧠 Introspect: Real-time Social Cue Guidance

✨ Overview

Introspect is an iOS-only, specialized, real-time assistive technology designed to help neurodivergent users interpret and respond to non-verbal social cues and microexpressions. This project originated as a successful hackathon entry, where it was honored with the minor prize in Presage for its innovative application of their technology.

By leveraging cutting-edge Presage technology for visual analysis of facial and body language, generating conversational context via the Gemini API, and providing immediate, non-intrusive guidance via synchronized audio feedback powered by Eleven Labs, the application processes complex social information. Beyond social cues, Introspect now offers real-time physiological monitoring to help users track their own internal state (pulse and breathing rate) during interactions. Our mission is to bridge communication gaps and facilitate smoother, more confident social interactions.

----------------------------

🌟 Core Features

Real-time Audio Guidance: Immediate, synthesized audio output (via Eleven Labs) offers private feedback to the user, translating complex visual cues into actionable, understandable instructions (e.g., "The speaker appears stressed; pause and listen," or "They show a sign of pleasure; maintain topic").

Gemini Contextualization: Integration with the Gemini API for advanced, contextual understanding of the interaction, providing more nuanced and helpful social prompts based on the flow of conversation.

Microexpression Analysis: Utilizes Presage technology alonge with Gemini API to analyze subtle facial shifts and non-verbal cues in real-time, providing an objective interpretation of the speaker's emotional state.

Physiological Monitoring: Real-time, non-contact measurement of pulse and breathing rate (using computer vision), displayed with an accompanying trend graph for immediate user feedback on internal stress/calm levels.

Historical Data & Progress: Dedicated History Feature that securely stores and displays logs of social interactions, cue detection rates, and physiological trends over time for review and progress analysis.

Customizable Feedback & Visibility: Users can adjust the verbosity, tone, and latency of the audio feedback, and selectively enable/disable UI elements (e.g., hiding pulse data or cue text) via the settings page to prevent sensory overload.

Focus on Non-Verbal Communication: Specifically targets high-speed, non-verbal signals that are often challenging for neurodivergent individuals to process synchronously.

----------------------------

💻 Technologies Used

Presage Technology

Real-time computer vision and machine learning for identifying and classifying microexpressions, body language, and non-contact physiological data (pulse, respiration).

Google Gemini API

  Advanced conversational AI for context generation and refining social guidance responses.

Eleven Labs API

  High-quality, low-latency text-to-speech (TTS) generation for natural and clear audio guidance.

Swift / SwiftUI

  Native iOS programming language and modern UI framework.

Core Data / Firebase

  For secure user settings, history storage, and physiological data logging.

----------------------------

🛠 Getting Started

Due to the reliance on proprietary and specialized APIs, setting up Introspect requires specific configuration for computer vision analysis, audio synthesis, and physiological monitoring in an iOS environment.

Prerequisites

Xcode 14+ (Required for building and running the iOS application)

Swift / iOS SDK

Camera Access (Required for real-time visual analysis and physiological monitoring)

API Keys (Presage Technology, Eleven Labs, and Google Gemini)

Installation

Clone the repository:

```bash
git clone [https://github.com/Parth-Joshi0/introspect.git](https://github.com/Parth-Joshi0/introspect.git)
cd introspect
```


Install dependencies (CocoaPods/SPM):

If using CocoaPods, navigate to the project root and run:

```bash
pod install
```

If using Swift Package Manager (SPM), dependencies will resolve automatically upon opening the project.


Setup API Keys:

Insert your API keys into the designated location within the project (e.g., in a `Secrets.swift` file or environment configuration):

```swift
// Example of keys needed in your secrets file
let geminiAPIKey = "YOUR_GEMINI_API_KEY"
let elevenLabsAPIKey = "YOUR_ELEVEN_LABS_KEY"
let presageAPIEndpoint = "YOUR_PRESAGE_ENDPOINT"
let presageAPIKey = "YOUR_PRESAGE_KEY"
```


Run the application:

Open the project in Xcode, select a simulator or connected iOS device, and click **Run** (Cmd + R).

----------------------------

📸 Video

https://www.youtube.com/shorts/RWReOJqGrOM

----------------------------

📞 Authors

Parth Joshi

Roah Cho

Nathatneal Foster

Parth Kathria
