# iOS Frontend Implementation Plan: Simple Surveys

## 1. System Overview & Architectural Objectives
This document establishes the architectural, technical, and user interface specification for the **Simple Surveys iOS Mobile Application**, implemented natively using **Swift**, **SwiftUI**, and modern Apple frameworks (Xcode 16+, iOS 17+).

The iOS client is a **lightweight participant-facing mobile app** designed exclusively to receive experience sampling method (ESM) prompts scheduled for the day, render dynamic surveys, record GPS coordinates, capture an optional surroundings photo, enforce expiration windows, and anonymously submit responses to the [Simple Surveys Backend](file:///C:/Users/Jayle/Developer/Projects/Simple-Surveys-Backend/docs/BACKEND_IMPLEMENTATION_PLAN.md).

> [!IMPORTANT]
> **Strict Participant Scope (No Admin Functionality)**:
> The iOS client contains **no administrative operations**. Administrative tasks—such as creating surveys, modifying survey questions, deleting surveys or responses, managing sampling schedules, or inspecting participant lists—are handled separately by researchers via the backend API or future admin dashboard. The iOS application communicates with only three participant endpoints:
> 1. `POST /api/notifications/devices`: Register anonymous push notification token on initial onboarding or token rotation.
> 2. `GET /api/surveys/{survey_id}`: Fetch the survey definition triggered by the day's sampling schedule.
> 3. `POST /api/responses`: Submit answers, GPS coordinates, timestamps, and optional surroundings photo (via multipart/form-data).

### 1.1. Core Architectural Goals & Boundaries
- **Frontend Exclusivity**: Focuses purely on iOS app architecture, UI/UX screens, Apple framework integrations (UserNotifications, CoreLocation, AVFoundation / PhotosUI), local offline buffering, and HTTP communication with the backend.
- **Strict Anonymity (Zero Participant Tracking)**: The client does not collect or store user accounts, logins, advertising IDs (IDFA), phone numbers, or hardware serial numbers. The app registers an anonymous APNs device token with the server and treats each response as an isolated event.
- **First-Launch Onboarding & Permission Gate**:
  - When the app is opened for the first time, a dedicated **Onboarding / Welcome Screen** explains the study:
    > *"To participate in this study, Simple Surveys needs permission to send scheduled prompts, verify survey locations, and capture surroundings photos."*
  - An **"Enable Permissions"** action orchestrates all three required system authorizations:
    1. **Push Notifications** (`UNUserNotificationCenter.requestAuthorization(options: [.alert, .sound, .badge])`)
    2. **CoreLocation GPS** (`locationService.requestAuthorization()`, transitioning to `.authorizedWhenInUse`)
    3. **Camera Capture** (`AVCaptureDevice.requestAccess(for: .video)`)
  - Once all permissions are granted, the device registers its APNs push token with `POST /api/notifications/devices`. Once registered, the onboarding flow is completed and will not display again.
  - **Dynamic Permission Re-Check / Fallback**: If the participant revokes *any* required permission later in iOS Settings, the app displays a modal lockout screen requiring permissions to be restored before scheduled surveys can be opened or completed.
- **Brand Visual System & Color Scheme**: The app UI strictly adheres to the official study palette:
  - **NAVY**: `#00205b` / RGB: `(0, 32, 91)` / CMYK: `(36, 23, 0, 64)` / Pantone PMS 281 C (Primary headers, accent buttons, navigation titles)
  - **LIGHT BLUE**: `#13b5ea` / RGB: `(19, 181, 234)` / CMYK: `(69, 7, 0, 0)` / Pantone PMS 298 C (Active badges, highlights, timer clocks, selection states)
  - **GOLD**: `#8B634B` / RGB: `(139, 99, 75)` / CMYK: `(100, 72, 0, 32)` / Pantone PMS 876 Metallic (Secondary accents, study banners, status borders)
  - **WHITE**: `#FFFFFF` / RGB: `(255, 255, 255)` / CMYK: `(0, 0, 0, 0)` (Card backgrounds, contrasting text, screen canvases)
- **Minimalist Endpoint Footprint**: The client only communicates with the 3 participant endpoints required to complete scheduled surveys.
- **Dynamic Survey Rendering**: UI components are generated dynamically from the backend's JSON survey configurations (`rating_scale`, `single_choice`, `multiple_choice`, `text`, `numeric`) without requiring hardcoded question layouts.
- **Live Expiration Clock ("Time to Complete")**: The app displays a live countdown timer based on the server's configured `time_to_complete_minutes` (e.g., 5 minutes from prompt receipt). If the countdown reaches zero before submission, the UI shifts to an expired state and submits an empty audit record per the backend contract (`200 OK` with `status: "EXPIRED"`).
- **Push Notification Lifecycle**: Connects to the Apple Push Notification service (APNs). (See [Section 9](#9-apple-developer-account--apns-notification-setup) for the required Apple Developer program setup).

---

## 2. iOS Architectural Patterns & OOP Best Practices

The iOS frontend adopts the **MVVM (Model-View-ViewModel)** architectural pattern augmented with **Repository and Service layers**, strictly enforcing the **Four Pillars of OOP** and **SOLID Design Principles**.

```
┌────────────────────────────────────────────────────────┐
│                   Views (SwiftUI)                      │
│   (OnboardingView, HomeView, SurveyView, CameraView)   │
└──────────────────────────▲─────────────────────────────┘
                            │ Observation / Binding (@Observable)
┌──────────────────────────┴─────────────────────────────┐
│                      ViewModels                        │
│    (OnboardingViewModel, SurveyViewModel, HomeVM)      │
└───────────────▲────────────────────────▲───────────────┘
                │                        │
┌───────────────┴───────────────┐ ┌──────┴───────────────┐
│     Hardware Services         │ │  Repository Layer    │
│  (Location, Camera, APNs)     │ │  (SurveyRepository)  │
└───────────────────────────────┘ └──────▲───────────────┘
                                         │
                                  ┌──────┴───────────────┐
                                  │   Networking Engine  │
                                  │  (APIClient, URLSession)
                                  └──────────────────────┘
```

### 2.1. The Four Pillars of OOP in Swift

1. **Encapsulation**:
   - Networking details (HTTP headers, URLSession tasks, multipart boundary assembly, status code evaluations) are encapsulated entirely inside `APIClient`.
   - Hardware mechanics (`CLLocationManager` delegate callbacks, `AVCaptureDevice` permissions, `UNUserNotificationCenter` requests) are encapsulated behind clean service interfaces (`LocationService`, `CameraService`, `NotificationService`).
   - ViewModels expose only read-only or published state (`@Observable`) to SwiftUI views, preventing views from manipulating internal service state directly.
2. **Abstraction**:
   - Swift protocols (`SurveyRepositoryProtocol`, `APIClientProtocol`, `LocationServiceProtocol`, `CameraServiceProtocol`, `NotificationServiceProtocol`) define pure behavioral contracts.
   - ViewModels depend exclusively on these protocols, decoupling business and presentation logic from external dependencies and third-party APIs.
3. **Inheritance**:
   - Used selectively where idiomatic in Apple's SDKs (e.g., subclasses of `NSObject` required for `CLLocationManagerDelegate` or `UNUserNotificationCenterDelegate`).
   - Domain errors inherit from Swift's standard `Error` and `LocalizedError` protocols.
4. **Polymorphism**:
   - **Protocol-Oriented Polymorphism**: Different network clients (production `LiveAPIClient` vs. offline `MockAPIClient`) conform to `APIClientProtocol`.
   - **Dynamic Question Views**: SwiftUI question views dynamically adapt presentation logic by conforming to a polymorphic `QuestionRenderer` protocol, selecting appropriate input controls based on question type enums.

### 2.2. SOLID Principles in Practice

- **S - Single Responsibility Principle (SRP)**:
  - `Network/APIClient.swift`: Handles exclusively raw HTTP requests and serialization.
  - `Repositories/SurveyRepository.swift`: Handles participant data operations, orchestrating network requests and caching.
  - `ViewModels/OnboardingViewModel.swift`: Manages permission states, system requests, and post-onboarding token dispatch.
  - `ViewModels/SurveyViewModel.swift`: Manages survey presentation state, answer validation, and countdown timers.
  - `Views/`: Pure declarative rendering of the current ViewModel state.
- **O - Open/Closed Principle (OCP)**:
  - New question types (e.g., `date_picker` or `slider`) can be introduced by adding a new Question View conforming to `QuestionViewProtocol` without refactoring existing question views or ViewModels.
- **L - Liskov Substitution Principle (LSP)**:
  - Any protocol implementation (e.g., `MockSurveyRepository`) can substitute `LiveSurveyRepository` in SwiftUI Previews or unit environments without altering ViewModel code.
- **I - Interface Segregation Principle (ISP)**:
  - Fine-grained protocols (`LocationProviding`, `CameraProviding`, `TokenRegistering`, `SurveyFetching`, `ResponseSubmitting`) ensure classes only implement members relevant to their purpose.
- **D - Dependency Inversion Principle (DIP)**:
  - High-level ViewModels inject dependencies via Swift initializers conforming to protocols:
    ```swift
    @Observable
    final class SurveyViewModel {
        private let repository: SurveyRepositoryProtocol
        private let locationService: LocationServiceProtocol
        
        init(repository: SurveyRepositoryProtocol, locationService: LocationServiceProtocol) {
            self.repository = repository
            self.locationService = locationService
        }
    }
    ```

---

## 3. Technology Stack & Design System

### 3.1. Frameworks
| Layer | Framework / Library | Rationale |
|---|---|---|
| **Language** | **Swift 5.10 / Swift 6** | Strict type safety, structured concurrency (`async`/`await`), Swift Modern Concurrency. |
| **UI Framework** | **SwiftUI** | Modern declarative UI, native animations, seamless state bindings with `@Observable`. |
| **Networking** | **Foundation (`URLSession`)** | Native HTTP/HTTPS networking, non-blocking async streaming, zero external package bloat. |
| **Push Notifications** | **UserNotifications (`UNUserNotificationCenter`)** | Native APNs handling, foreground banner presentation, badge management. |
| **Location** | **CoreLocation (`CLLocationManager`)** | High-precision GPS coordinates, horizontal accuracy, altitude capture. |
| **Camera & Photo** | **AVFoundation / PhotosUI** | Native camera hardware permissions, viewfinder controllers, and JPEG image compression. |
| **State Management** | **Observation Framework (`@Observable`)** | Modern iOS 17+ state binding with minimal boilerplate and granular view re-renders. |
| **Serialization** | **Foundation (`Codable`)** | Native Swift JSON decoding and encoding conforming to backend schema contracts. |

---

### 3.2. Color Scheme & Design Palette (`Theme.swift`)

The application adopts a dedicated brand color system matching the project's official palette:

```swift
import SwiftUI

public enum AppTheme {
    /// NAVY - PMS 281 C: Primary headers, navigation titles, prominent buttons
    public static let navy = Color(red: 0.0 / 255.0, green: 32.0 / 255.0, blue: 91.0 / 255.0) // #00205B
    
    /// LIGHT BLUE - PMS 298 C: Active icons, countdown timer badges, highlights, selection rings
    public static let lightBlue = Color(red: 19.0 / 255.0, green: 181.0 / 255.0, blue: 234.0 / 255.0) // #13B5EA
    
    /// GOLD - PMS 876 Metallic: Accents, warning badges, card borders, study status
    public static let gold = Color(red: 139.0 / 255.0, green: 99.0 / 255.0, blue: 75.0 / 255.0) // #8B634B
    
    /// WHITE: Card backgrounds, dark button labels, pure contrasts
    public static let pureWhite = Color.white // #FFFFFF
    
    /// Background Canvas Color
    public static let canvasBackground = Color(UIColor.systemGroupedBackground)
}
```

---

## 4. Xcode Project Directory Structure

```
SimpleSurveys/
├── App/
│   ├── SimpleSurveysApp.swift           # Application entrypoint & root window router
│   ├── AppDelegate.swift                # APNs token registration & notification handling
│   ├── AppConfiguration.swift          # Backend URLs, timeout intervals, study constants
│   └── Theme.swift                      # Navy, Light Blue, Gold, and White color definitions
│
├── Models/                              # Codable Domain DTOs (Participant-Only)
│   ├── SurveyConfig.swift               # Survey definition, question list, notification prompt
│   ├── Question.swift                   # Question model, type enums, validation rule models
│   ├── SurveyResponse.swift             # Response submission payload, answers, receipt models
│   ├── LocationData.swift               # GPS coordinates & accuracy model
│   ├── DeviceRegistration.swift         # APNs token registration payload & response models
│   └── AnyCodableValue.swift            # Polymorphic JSON value serializer
│
├── Repositories/                        # Data Abstraction Layer
│   ├── SurveyRepositoryProtocol.swift   # Abstract participant data contract
│   └── SurveyRepository.swift           # Concrete repository orchestrating APIClient
│
├── Services/                            # Hardware & Infrastructure Services
│   ├── Network/
│   │   ├── APIClientProtocol.swift      # URLSession abstraction (GET, POST, multipart)
│   │   ├── APIClient.swift              # Async/await HTTP engine & multipart builder
│   │   └── APIEndpoint.swift            # Participant endpoints (/api/surveys/{id}, /api/responses, /api/notifications/devices)
│   ├── Location/
│   │   ├── LocationServiceProtocol.swift
│   │   └── LocationService.swift        # CLLocationManager delegate wrapper & permission query
│   ├── Notifications/
│   │   ├── NotificationServiceProtocol.swift
│   │   └── NotificationService.swift    # UNUserNotificationCenter delegate & token registration
│   ├── Camera/
│   │   ├── CameraServiceProtocol.swift
│   │   └── CameraService.swift          # Camera hardware permissions & JPEG compression
│   └── Permissions/
│       ├── PermissionManagerProtocol.swift
│       └── PermissionManager.swift      # Central permission aggregation & revocation watcher
│
├── ViewModels/                          # MVVM Presentation Logic (@Observable)
│   ├── OnboardingViewModel.swift        # First-launch explanation, 3-permission sequencer, token trigger
│   ├── HomeViewModel.swift              # Active prompt status, scheduled check-in reminders, permission gate
│   ├── SurveyViewModel.swift            # Survey answering, question stepping, countdown timer, validation
│   └── CameraViewModel.swift            # Photo capture, preview, retake logic
│
├── Views/                               # Declarative SwiftUI Screens & Components
│   ├── Onboarding/
│   │   ├── OnboardingView.swift         # First-time welcome card, explanation text, enable button
│   │   └── PermissionRevokedView.swift  # Modal lockout banner if permission is revoked in Settings
│   ├── Home/
│   │   ├── HomeView.swift               # Scheduled check-in dashboard & prompt alert
│   │   └── ExpirationBannerView.swift   # Warning banner if an active prompt is ticking down
│   ├── Survey/
│   │   ├── SurveyContainerView.swift    # Top-level survey flow, timer header, submit button
│   │   ├── TimerHeaderView.swift        # Live remaining countdown clock (Navy & Light Blue badge)
│   │   ├── ExpiredSurveyView.swift      # Lockout screen shown when countdown reaches zero
│   │   └── SurveyCompletedView.swift    # Thank you / submission success acknowledgment
│   ├── Questions/                       # Dynamic Question Component Views
│   │   ├── RatingScaleQuestionView.swift
│   │   ├── SingleChoiceQuestionView.swift
│   │   ├── MultipleChoiceQuestionView.swift
│   │   ├── TextQuestionView.swift
│   │   └── NumericQuestionView.swift
│   ├── Camera/
│   │   ├── CameraCaptureView.swift      # Custom camera shutter or PhotosUI picker
│   │   └── PhotoPreviewCard.swift       # Thumbnail display with delete/retake action
│   └── Common/
│       ├── LoadingView.swift
│       └── ErrorBannerView.swift
│
└── Resources/
    ├── Assets.xcassets                  # App icons, colors, symbols
    └── Info.plist                       # Camera & Location privacy permission descriptions
```

---

## 5. Models & Data Structures (Swift Codable DTOs)

The iOS models directly match the participant-facing backend schemas defined in [BACKEND_IMPLEMENTATION_PLAN.md](file:///C:/Users/Jayle/Developer/Projects/Simple-Surveys-Backend/docs/BACKEND_IMPLEMENTATION_PLAN.md).

### 5.1. Survey Definition Models (`SurveyConfig.swift`, `Question.swift`)

```swift
import Foundation

// MARK: - Survey Configuration
public struct SurveyConfig: Codable, Identifiable {
    public var id: String { surveyId }
    public let surveyId: String
    public let title: String
    public let description: String?
    public let notificationPrompt: NotificationPrompt?
    public let weight: Double
    public let isActive: Bool
    public let questions: [Question]

    enum CodingKeys: String, CodingKey {
        case surveyId = "survey_id"
        case title
        case description
        case notificationPrompt = "notification_prompt"
        case weight
        case isActive = "is_active"
        case questions
    }
}

public struct NotificationPrompt: Codable {
    public let title: String
    public let body: String
}

// MARK: - Polymorphic Question Model
public struct Question: Codable, Identifiable {
    public var id: String { questionId }
    public let questionId: String
    public let prompt: String
    public let type: QuestionType
    public let isRequired: Bool
    public let validationRules: ValidationRules?

    enum CodingKeys: String, CodingKey {
        case questionId = "question_id"
        case prompt
        case type
        case isRequired = "is_required"
        case validationRules = "validation_rules"
    }
}

public enum QuestionType: String, Codable {
    case ratingScale = "rating_scale"
    case singleChoice = "single_choice"
    case multipleChoice = "multiple_choice"
    case text = "text"
    case numeric = "numeric"
}

public struct ValidationRules: Codable {
    public let minValue: Double?
    public let maxValue: Double?
    public let step: Double?
    public let minLabel: String?
    public let maxLabel: String?
    public let options: [String]?
    public let minSelections: Int?
    public let maxSelections: Int?
    public let minLength: Int?
    public let maxLength: Int?
    public let placeholder: String?
    public let allowDecimals: Bool?

    enum CodingKeys: String, CodingKey {
        case minValue = "min_value"
        case maxValue = "max_value"
        case step
        case minLabel = "min_label"
        case maxLabel = "max_label"
        case options
        case minSelections = "min_selections"
        case maxSelections = "max_selections"
        case minLength = "min_length"
        case maxLength = "max_length"
        case placeholder
        case allowDecimals = "allow_decimals"
    }
}
```

---

### 5.2. Survey Response Models (`SurveyResponse.swift`, `LocationData.swift`)

```swift
import Foundation

// MARK: - Ingress Submission Payload (Client -> Server)
public struct SurveyResponseSubmission: Codable {
    public let responseId: String?
    public let surveyId: String
    public let notificationSentAt: Date?
    public let startedAt: Date
    public let completedAt: Date
    public let location: LocationData?
    public let answers: [QuestionAnswer]

    enum CodingKeys: String, CodingKey {
        case responseId = "response_id"
        case surveyId = "survey_id"
        case notificationSentAt = "notification_sent_at"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case location
        case answers
    }
}

public struct QuestionAnswer: Codable {
    public let questionId: String
    public let value: AnyCodableValue

    enum CodingKeys: String, CodingKey {
        case questionId = "question_id"
        case value
    }
}

public struct LocationData: Codable {
    public let latitude: Double
    public let longitude: Double
    public let accuracyMeters: Double?
    public let altitudeMeters: Double?

    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case accuracyMeters = "accuracy_meters"
        case altitudeMeters = "altitude_meters"
    }
}

// MARK: - Server Response Receipt
public struct SurveySubmissionReceipt: Codable {
    public let responseId: String
    public let surveyId: String
    public let status: String           // "COMPLETED" or "EXPIRED"
    public let message: String?
    public let imageStored: Bool
    public let imageFilename: String?
    public let receivedAt: Date

    enum CodingKeys: String, CodingKey {
        case responseId = "response_id"
        case surveyId = "survey_id"
        case status
        case message
        case imageStored = "image_stored"
        case imageFilename = "image_filename"
        case receivedAt = "received_at"
    }
}
```

---

### 5.3. Device Registration Models (`DeviceRegistration.swift`)

```swift
import Foundation

public enum DevicePlatform: String, Codable {
    case ios = "ios"
    case android = "android"
}

public struct DeviceRegistration: Codable {
    public let deviceToken: String
    public let platform: DevicePlatform
    public let timezone: String
    public let registeredAt: Date

    enum CodingKeys: String, CodingKey {
        case deviceToken = "device_token"
        case platform
        case timezone
        case registeredAt = "registered_at"
    }
}

public struct DeviceRegistrationResponse: Codable {
    public let status: String
    public let deviceToken: String

    enum CodingKeys: String, CodingKey {
        case status
        case deviceToken = "device_token"
    }
}
```

---

### 5.4. AnyCodable Value Helper (`AnyCodableValue.swift`)

Because question values can be integers (`8`), strings (`"Home"`), arrays of strings (`["Alone", "Family"]`), or floating-point numbers (`7.5`), an `AnyCodableValue` enum handles type-safe JSON serialization:

```swift
import Foundation

public enum AnyCodableValue: Codable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case stringArray([String])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let val = try? container.decode(Int.self) {
            self = .int(val)
        } else if let val = try? container.decode(Double.self) {
            self = .double(val)
        } else if let val = try? container.decode(Bool.self) {
            self = .bool(val)
        } else if let val = try? container.decode(String.self) {
            self = .string(val)
        } else if let val = try? container.decode([String].self) {
            self = .stringArray(val)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported AnyCodable value")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .int(let i): try container.encode(i)
        case .double(let d): try container.encode(d)
        case .bool(let b): try container.encode(b)
        case .stringArray(let arr): try container.encode(arr)
        case .null: try container.encodeNil()
        }
    }
}
```

---

## 6. Networking & Repository Layer

Communication with the backend uses native `URLSession` with async/await. Submissions containing camera photos are uploaded as standard `multipart/form-data` with two form fields:
1. `data`: The JSON-serialized `SurveyResponseSubmission` string.
2. `image`: Binary JPEG data captured by the camera.

### 6.1. API Client Protocol & Implementation

```swift
import Foundation

public protocol APIClientProtocol: Sendable {
    func get<T: Decodable>(_ path: String) async throws -> T
    func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T
    func uploadMultipart<T: Decodable>(
        _ path: String,
        jsonData: Data,
        imageBytes: Data?,
        imageFilename: String?
    ) async throws -> T
}

public final class APIClient: APIClientProtocol {
    private let baseURL: URL
    private let session: URLSession
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder

    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        
        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.dateEncodingStrategy = .iso8601
        
        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.dateDecodingStrategy = .iso8601
    }

    public func get<T: Decodable>(_ path: String) async throws -> T {
        let requestURL = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        try validateHTTP(response: response, data: data)
        return try jsonDecoder.decode(T.self, from: data)
    }

    public func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        let requestURL = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try jsonEncoder.encode(body)

        let (data, response) = try await session.data(for: request)
        try validateHTTP(response: response, data: data)
        return try jsonDecoder.decode(T.self, from: data)
    }

    public func uploadMultipart<T: Decodable>(
        _ path: String,
        jsonData: Data,
        imageBytes: Data?,
        imageFilename: String?
    ) async throws -> T {
        let requestURL = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        var body = Data()

        // 1. Append JSON data field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"data\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
        body.append(jsonData)
        body.append("\r\n".data(using: .utf8)!)

        // 2. Append image file field if present
        if let imageBytes = imageBytes {
            let filename = imageFilename ?? "surroundings.jpg"
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageBytes)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        try validateHTTP(response: response, data: data)
        return try jsonDecoder.decode(T.self, from: data)
    }

    private func validateHTTP(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200...299).contains(http.statusCode) else {
            let serverErrorMsg = String(data: data, encoding: .utf8) ?? "Unknown Server Error"
            throw NetworkError.serverError(code: http.statusCode, message: serverErrorMsg)
        }
    }
}

public enum NetworkError: LocalizedError {
    case serverError(code: Int, message: String)
    public var errorDescription: String? {
        switch self {
        case .serverError(let code, let msg): return "Server error (\(code)): \(msg)"
        }
    }
}
```

---

### 6.2. Survey Repository Protocol & Concrete Implementation

```swift
import Foundation

public protocol SurveyRepositoryProtocol: Sendable {
    func fetchScheduledSurvey(id: String) async throws -> SurveyConfig
    func submitResponse(
        submission: SurveyResponseSubmission,
        imageData: Data?
    ) async throws -> SurveySubmissionReceipt
    func registerDevice(token: String, timezone: String) async throws -> DeviceRegistrationResponse
}

public final class SurveyRepository: SurveyRepositoryProtocol {
    private let apiClient: APIClientProtocol
    private let jsonEncoder: JSONEncoder

    public init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.dateEncodingStrategy = .iso8601
    }

    /// Fetches the specific survey configuration scheduled at the given time (e.g., prompted via notification)
    public func fetchScheduledSurvey(id: String) async throws -> SurveyConfig {
        return try await apiClient.get("/api/surveys/\(id)")
    }

    /// Submits a completed or expired survey response with optional surroundings photo
    public func submitResponse(
        submission: SurveyResponseSubmission,
        imageData: Data?
    ) async throws -> SurveySubmissionReceipt {
        if let imageData = imageData {
            let jsonData = try jsonEncoder.encode(submission)
            return try await apiClient.uploadMultipart(
                "/api/responses",
                jsonData: jsonData,
                imageBytes: imageData,
                imageFilename: "surroundings.jpg"
            )
        } else {
            return try await apiClient.post("/api/responses", body: submission)
        }
    }

    /// Registers the anonymous APNs device token to receive daily scheduled survey notifications
    public func registerDevice(token: String, timezone: String) async throws -> DeviceRegistrationResponse {
        let payload = DeviceRegistration(
            deviceToken: token,
            platform: .ios,
            timezone: timezone,
            registeredAt: Date()
        )
        return try await apiClient.post("/api/notifications/devices", body: payload)
    }
}
```

---

## 7. Hardware & Device Services

### 7.1. Location Service (`CoreLocation`)
Acquires anonymous coordinates upon survey completion. Requests `authorizationWhenInUse`.

```swift
import Foundation
import CoreLocation

public protocol LocationServiceProtocol: AnyObject, Sendable {
    var isAuthorized: Bool { get }
    func requestAuthorization() async -> Bool
    func getCurrentLocation() async -> LocationData?
}

public final class LocationService: NSObject, LocationServiceProtocol, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<LocationData?, Never>?
    private var authContinuation: CheckedContinuation<Bool, Never>?

    public var isAuthorized: Bool {
        manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways
    }

    public override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    public func requestAuthorization() async -> Bool {
        if isAuthorized { return true }
        guard manager.authorizationStatus == .notDetermined else { return false }
        
        return await withCheckedContinuation { continuation in
            self.authContinuation = continuation
            self.manager.requestWhenInUseAuthorization()
        }
    }

    public func getCurrentLocation() async -> LocationData? {
        guard isAuthorized else { return nil }

        return await withCheckedContinuation { continuation in
            self.locationContinuation = continuation
            self.manager.requestLocation()
        }
    }

    // MARK: - CLLocationManagerDelegate
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if let cont = authContinuation {
            cont.resume(returning: isAuthorized)
            authContinuation = nil
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else {
            locationContinuation?.resume(returning: nil)
            locationContinuation = nil
            return
        }
        let data = LocationData(
            latitude: loc.coordinate.latitude,
            longitude: loc.coordinate.longitude,
            accuracyMeters: loc.horizontalAccuracy,
            altitudeMeters: loc.altitude
        )
        locationContinuation?.resume(returning: data)
        locationContinuation = nil
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(returning: nil)
        locationContinuation = nil
    }
}
```

---

### 7.2. Camera Capture Service (`AVFoundation` / PhotosUI)
Manages camera hardware authorization and compresses captured images to research resolution (1080p max dimension JPEG at 0.8 quality).

```swift
import UIKit
import AVFoundation

public struct CapturedImage {
    public let data: Data
    public let previewImage: UIImage
}

public protocol CameraServiceProtocol: Sendable {
    var isAuthorized: Bool { get }
    func requestAuthorization() async -> Bool
    func compressImage(_ image: UIImage) -> CapturedImage?
}

public final class CameraService: CameraServiceProtocol {
    public init() {}

    public var isAuthorized: Bool {
        AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    public func requestAuthorization() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .authorized { return true }
        if status == .notDetermined {
            return await AVCaptureDevice.requestAccess(for: .video)
        }
        return false
    }

    public func compressImage(_ image: UIImage) -> CapturedImage? {
        // Normalize orientation & downscale if needed
        let maxDimension: CGFloat = 1920
        let size = image.size
        var targetSize = size

        if size.width > maxDimension || size.height > maxDimension {
            let ratio = min(maxDimension / size.width, maxDimension / size.height)
            targetSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        }

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let scaledImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        guard let jpegData = scaledImage.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        return CapturedImage(data: jpegData, previewImage: scaledImage)
    }
}
```

---

### 7.3. Unified Permission Manager (`PermissionManager.swift`)

Orchestrates all 3 permissions on the welcome screen and verifies that none have been revoked when the app is active:

```swift
import Foundation
import UserNotifications
import UIKit

public protocol PermissionManagerProtocol: AnyObject, Sendable {
    var areAllPermissionsGranted: Bool { get }
    func checkPermissionStatus() async -> Bool
    func requestAllPermissions() async -> Bool
}

public final class PermissionManager: PermissionManagerProtocol {
    private let locationService: LocationServiceProtocol
    private let cameraService: CameraServiceProtocol

    public init(locationService: LocationServiceProtocol, cameraService: CameraServiceProtocol) {
        self.locationService = locationService
        self.cameraService = cameraService
    }

    public var areAllPermissionsGranted: Bool {
        // Synchronous fast check for location & camera; notification checked asynchronously
        locationService.isAuthorized && cameraService.isAuthorized
    }

    public func checkPermissionStatus() async -> Bool {
        let notifSettings = await UNUserNotificationCenter.current().notificationSettings()
        let notifAuthorized = (notifSettings.authorizationStatus == .authorized || notifSettings.authorizationStatus == .provisional)
        return notifAuthorized && locationService.isAuthorized && cameraService.isAuthorized
    }

    public func requestAllPermissions() async -> Bool {
        // 1. Push Notifications
        let notifGranted: Bool = await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
        if notifGranted {
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }

        // 2. CoreLocation GPS
        let locGranted = await locationService.requestAuthorization()

        // 3. Camera Capture
        let camGranted = await cameraService.requestAuthorization()

        return notifGranted && locGranted && camGranted
    }
}
```

---

## 8. ViewModels & UI Screen Specifications (SwiftUI)

### 8.1. First-Launch Onboarding & Welcome Flow (`OnboardingView.swift`, `OnboardingViewModel.swift`)

#### Onboarding ViewModel
```swift
import SwiftUI
import Observation

@Observable
public final class OnboardingViewModel {
    public var isRequesting: Bool = false
    public var errorMessage: String?
    public var hasCompletedOnboarding: Bool = false

    private let permissionManager: PermissionManagerProtocol
    private let repository: SurveyRepositoryProtocol

    public init(permissionManager: PermissionManagerProtocol, repository: SurveyRepositoryProtocol) {
        self.permissionManager = permissionManager
        self.repository = repository
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }

    public func enablePermissions() async {
        isRequesting = true
        errorMessage = nil

        let allGranted = await permissionManager.requestAllPermissions()
        if allGranted {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            hasCompletedOnboarding = true
        } else {
            errorMessage = "All permissions (Notifications, Location, Camera) are required to participate in this study. Please enable them to continue."
        }
        isRequesting = false
    }
}
```

#### Onboarding Screen (`OnboardingView.swift`)
Styled in **NAVY** (`#00205b`), **LIGHT BLUE** (`#13b5ea`), **GOLD** (`#8B634B`), and **WHITE** (`#FFFFFF`):

```swift
import SwiftUI

public struct OnboardingView: View {
    @Bindable public var viewModel: OnboardingViewModel

    public var body: some View {
        ZStack {
            AppTheme.canvasBackground.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                // Header Icon
                ZStack {
                    Circle()
                        .fill(AppTheme.navy.opacity(0.1))
                        .frame(width: 100, height: 100)
                    Image(systemName: "checklist.checked")
                        .font(.system(size: 48))
                        .foregroundColor(AppTheme.navy)
                }

                // Welcome Title
                VStack(spacing: 8) {
                    Text("Simple Surveys")
                        .font(.largeTitle.bold())
                        .foregroundColor(AppTheme.navy)

                    Text("Experience Sampling Study")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppTheme.gold)
                        .textCase(.uppercase)
                }

                // Onboarding Explanation Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Study Participation Requirements")
                        .font(.headline)
                        .foregroundColor(AppTheme.navy)

                    Text("To participate in this study, Simple Surveys needs permission to send scheduled prompts, verify survey locations, and capture surroundings photos.")
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineSpacing(4)

                    Divider()

                    // Permissions list items
                    permissionRow(icon: "bell.badge.fill", title: "Push Notifications", detail: "Alerts you during active survey sampling windows.")
                    permissionRow(icon: "location.fill", title: "GPS Location", detail: "Attaches approximate coordinates at the moment of submission.")
                    permissionRow(icon: "camera.fill", title: "Camera Access", detail: "Allows you to capture an image of your immediate surroundings.")
                }
                .padding(24)
                .background(AppTheme.pureWhite)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.gold.opacity(0.3), lineWidth: 1))
                .shadow(color: AppTheme.navy.opacity(0.08), radius: 10, x: 0, y: 4)
                .padding(.horizontal, 20)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer()

                // Enable Permissions Button
                Button(action: {
                    Task { await viewModel.enablePermissions() }
                }) {
                    HStack {
                        if viewModel.isRequesting {
                            ProgressView().tint(AppTheme.pureWhite)
                        } else {
                            Text("Enable Permissions")
                                .font(.headline.bold())
                                .foregroundColor(AppTheme.pureWhite)
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.headline)
                                .foregroundColor(AppTheme.lightBlue)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(AppTheme.navy)
                    .cornerRadius(14)
                }
                .disabled(viewModel.isRequesting)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
    }

    private func permissionRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppTheme.lightBlue)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(AppTheme.navy)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

---

### 8.2. Permission Revoked Lockout Banner (`PermissionRevokedView.swift`)

If a participant revokes any permission in iOS Settings after onboarding:

```swift
import SwiftUI

public struct PermissionRevokedView: View {
    public let onRecheck: () -> Void

    public var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundColor(AppTheme.gold)

            Text("Permissions Required")
                .font(.title2.bold())
                .foregroundColor(AppTheme.navy)

            Text("One or more required permissions (Push Notifications, Location, or Camera) were revoked in Settings. Please restore all permissions to continue participating in today's surveys.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)

            Button("Open iOS Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.navy)
            .controlSize(.large)

            Button("Check Status Again") {
                onRecheck()
            }
            .font(.subheadline)
            .foregroundColor(AppTheme.lightBlue)
        }
        .padding()
    }
}
```

---

### 8.3. Live Expiration Timer & Survey Flow (`SurveyViewModel.swift`)

The ViewModel coordinates question rendering, enforces required fields, and maintains a 1-second countdown clock against `time_to_complete_minutes`.

```swift
import SwiftUI
import Observation

@Observable
public final class SurveyViewModel {
    // State
    public var survey: SurveyConfig
    public var answers: [String: AnyCodableValue] = [:]
    public var capturedImage: CapturedImage?
    public var isSubmitting: Bool = false
    public var isExpired: Bool = false
    public var remainingSeconds: Int = 0
    public var errorMessage: String?
    public var submissionCompleted: Bool = false

    private let notificationSentAt: Date?
    private let startedAt: Date
    private let timeToCompleteMinutes: Int
    private var timerTask: Task<Void, Never>?

    private let repository: SurveyRepositoryProtocol
    private let locationService: LocationServiceProtocol

    public init(
        survey: SurveyConfig,
        notificationSentAt: Date?,
        timeToCompleteMinutes: Int = 5,
        repository: SurveyRepositoryProtocol,
        locationService: LocationServiceProtocol
    ) {
        self.survey = survey
        self.notificationSentAt = notificationSentAt
        self.startedAt = Date()
        self.timeToCompleteMinutes = timeToCompleteMinutes
        self.repository = repository
        self.locationService = locationService

        calculateInitialRemainingTime()
        startCountdownTimer()
    }

    private func calculateInitialRemainingTime() {
        let referenceDate = notificationSentAt ?? startedAt
        let deadline = referenceDate.addingTimeInterval(Double(timeToCompleteMinutes * 60))
        let remaining = Int(deadline.timeIntervalSince(Date()))
        self.remainingSeconds = max(0, remaining)
        if self.remainingSeconds == 0 {
            self.isExpired = true
        }
    }

    private func startCountdownTimer() {
        timerTask?.cancel()
        timerTask = Task { @MainActor in
            while remainingSeconds > 0 && !isExpired && !submissionCompleted {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                remainingSeconds -= 1
                if remainingSeconds <= 0 {
                    isExpired = true
                    handleExpiration()
                }
            }
        }
    }

    private func handleExpiration() {
        // Automatically submit expired audit record with empty answers
        Task {
            await submitResponse(isForcedExpired: true)
        }
    }

    public func submitResponse(isForcedExpired: Bool = false) async {
        guard !isSubmitting else { return }
        isSubmitting = true
        errorMessage = nil

        let location = await locationService.getCurrentLocation()
        let completedAt = Date()

        // Per backend plan: if expired, answers must be autofilled empty []
        let answersPayload: [QuestionAnswer]
        if isForcedExpired || isExpired {
            answersPayload = []
        } else {
            answersPayload = survey.questions.compactMap { q in
                guard let val = answers[q.questionId] else { return nil }
                return QuestionAnswer(questionId: q.questionId, value: val)
            }
        }

        let submission = SurveyResponseSubmission(
            responseId: nil,
            surveyId: survey.surveyId,
            notificationSentAt: notificationSentAt,
            startedAt: startedAt,
            completedAt: completedAt,
            location: location,
            answers: answersPayload
        )

        do {
            _ = try await repository.submitResponse(
                submission: submission,
                imageData: capturedImage?.data
            )
            submissionCompleted = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }

    deinit {
        timerTask?.cancel()
    }
}
```

---

### 8.4. Declarative Dynamic Question Views (SwiftUI)

#### Rating Scale Question (`RatingScaleQuestionView.swift`)
Styled with Navy & Light Blue circle selections:

```swift
import SwiftUI

public struct RatingScaleQuestionView: View {
    public let question: Question
    @Binding public var answer: AnyCodableValue?

    private var minValue: Int { Int(question.validationRules?.minValue ?? 1) }
    private var maxValue: Int { Int(question.validationRules?.maxValue ?? 10) }
    private var step: Int { Int(question.validationRules?.step ?? 1) }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(question.prompt)
                .font(.headline)
                .foregroundColor(AppTheme.navy)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(stride(from: minValue, through: maxValue, by: step)), id: \.self) { value in
                        Button(action: { answer = .int(value) }) {
                            Text("\(value)")
                                .font(.body.bold())
                                .frame(width: 44, height: 44)
                                .background(selectedInt == value ? AppTheme.navy : Color(.secondarySystemBackground))
                                .foregroundColor(selectedInt == value ? AppTheme.pureWhite : AppTheme.navy)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(selectedInt == value ? AppTheme.lightBlue : Color.clear, lineWidth: 2)
                                )
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            if let minLabel = question.validationRules?.minLabel,
               let maxLabel = question.validationRules?.maxLabel {
                HStack {
                    Text(minLabel).font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Text(maxLabel).font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(AppTheme.pureWhite)
        .cornerRadius(12)
        .shadow(color: AppTheme.navy.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private var selectedInt: Int? {
        if case .int(let v) = answer { return v }
        return nil
    }
}
```

---

#### Single Choice Question (`SingleChoiceQuestionView.swift`)
Presents radio-style choices with Light Blue and Navy accents:

```swift
import SwiftUI

public struct SingleChoiceQuestionView: View {
    public let question: Question
    @Binding public var answer: AnyCodableValue?

    private var options: [String] { question.validationRules?.options ?? [] }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.prompt)
                .font(.headline)
                .foregroundColor(AppTheme.navy)

            ForEach(options, id: \.self) { option in
                Button(action: { answer = .string(option) }) {
                    HStack {
                        Image(systemName: selectedOption == option ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(selectedOption == option ? AppTheme.lightBlue : .secondary)
                        Text(option)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(AppTheme.pureWhite)
        .cornerRadius(12)
    }

    private var selectedOption: String? {
        if case .string(let s) = answer { return s }
        return nil
    }
}
```

---

#### Multiple Choice Question (`MultipleChoiceQuestionView.swift`)
Presents checkbox-style options:

```swift
import SwiftUI

public struct MultipleChoiceQuestionView: View {
    public let question: Question
    @Binding public var answer: AnyCodableValue?

    private var options: [String] { question.validationRules?.options ?? [] }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.prompt)
                .font(.headline)
                .foregroundColor(AppTheme.navy)

            ForEach(options, id: \.self) { option in
                Button(action: { toggle(option) }) {
                    HStack {
                        Image(systemName: selectedOptions.contains(option) ? "checkmark.square.fill" : "square")
                            .foregroundColor(selectedOptions.contains(option) ? AppTheme.lightBlue : .secondary)
                        Text(option)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(AppTheme.pureWhite)
        .cornerRadius(12)
    }

    private var selectedOptions: [String] {
        if case .stringArray(let arr) = answer { return arr }
        return []
    }

    private func toggle(_ option: String) {
        var current = selectedOptions
        if current.contains(option) {
            current.removeAll { $0 == option }
        } else {
            current.append(option)
        }
        answer = .stringArray(current)
    }
}
```

---

#### Text Question (`TextQuestionView.swift`)
Free-form text input with character counter:

```swift
import SwiftUI

public struct TextQuestionView: View {
    public let question: Question
    @Binding public var answer: AnyCodableValue?

    private var placeholder: String { question.validationRules?.placeholder ?? "Enter text here..." }
    private var maxLength: Int { question.validationRules?.maxLength ?? 500 }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question.prompt)
                .font(.headline)
                .foregroundColor(AppTheme.navy)

            TextEditor(text: textBinding)
                .frame(minHeight: 100)
                .padding(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.separator), lineWidth: 1))

            HStack {
                Spacer()
                Text("\(currentText.count)/\(maxLength)")
                    .font(.caption)
                    .foregroundColor(currentText.count > maxLength ? .red : .secondary)
            }
        }
        .padding()
        .background(AppTheme.pureWhite)
        .cornerRadius(12)
    }

    private var currentText: String {
        if case .string(let s) = answer { return s }
        return ""
    }

    private var textBinding: Binding<String> {
        Binding(
            get: { self.currentText },
            set: { val in
                if val.count <= maxLength {
                    self.answer = .string(val)
                }
            }
        )
    }
}
```

---

#### Numeric Question (`NumericQuestionView.swift`)
Number input field supporting integers or floating-point values:

```swift
import SwiftUI

public struct NumericQuestionView: View {
    public let question: Question
    @Binding public var answer: AnyCodableValue?

    @State private var textValue: String = ""

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question.prompt)
                .font(.headline)
                .foregroundColor(AppTheme.navy)

            TextField("0", text: $textValue)
                .keyboardType(question.validationRules?.allowDecimals == true ? .decimalPad : .numberPad)
                .textFieldStyle(.roundedBorder)
                .onChange(of: textValue) { _, newValue in
                    if let d = Double(newValue) {
                        answer = .double(d)
                    } else {
                        answer = nil
                    }
                }
        }
        .padding()
        .background(AppTheme.pureWhite)
        .cornerRadius(12)
    }
}
```

---

### 8.5. Survey Container Screen (`SurveyContainerView.swift`)

Binds the live timer header, list of questions, surroundings camera preview, and submission button:

```swift
import SwiftUI

public struct SurveyContainerView: View {
    @Bindable public var viewModel: SurveyViewModel
    @State private var showingCamera = false

    public var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isExpired {
                    ExpiredSurveyView()
                } else if viewModel.submissionCompleted {
                    SurveyCompletedView()
                } else {
                    surveyContent
                }
            }
            .navigationTitle(viewModel.survey.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    TimerBadgeView(remainingSeconds: viewModel.remainingSeconds)
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraCaptureView { captured in
                viewModel.capturedImage = captured
            }
        }
    }

    private var surveyContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Description header
                if let desc = viewModel.survey.description {
                    Text(desc)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }

                // Dynamic questions
                ForEach(viewModel.survey.questions) { question in
                    questionView(for: question)
                        .padding(.horizontal)
                }

                // Photo capture card
                SurroundingsPhotoCard(
                    image: viewModel.capturedImage?.previewImage,
                    onTapCapture: { showingCamera = true },
                    onTapRemove: { viewModel.capturedImage = nil }
                )
                .padding(.horizontal)

                // Error message
                if let err = viewModel.errorMessage {
                    Text(err)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                // Submit button
                Button(action: { Task { await viewModel.submitResponse() } }) {
                    if viewModel.isSubmitting {
                        ProgressView().tint(AppTheme.pureWhite)
                    } else {
                        Text("Submit Survey")
                            .font(.headline)
                            .foregroundColor(AppTheme.pureWhite)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 50)
                .background(AppTheme.navy)
                .cornerRadius(12)
                .padding()
                .disabled(viewModel.isSubmitting)
            }
            .padding(.vertical)
        }
    }

    @ViewBuilder
    private func questionView(for q: Question) -> some View {
        switch q.type {
        case .ratingScale:
            RatingScaleQuestionView(question: q, answer: binding(for: q.questionId))
        case .singleChoice:
            SingleChoiceQuestionView(question: q, answer: binding(for: q.questionId))
        case .multipleChoice:
            MultipleChoiceQuestionView(question: q, answer: binding(for: q.questionId))
        case .text:
            TextQuestionView(question: q, answer: binding(for: q.questionId))
        case .numeric:
            NumericQuestionView(question: q, answer: binding(for: q.questionId))
        }
    }

    private func binding(for id: String) -> Binding<AnyCodableValue?> {
        Binding(
            get: { viewModel.answers[id] },
            set: { val in
                if let val = val {
                    viewModel.answers[id] = val
                } else {
                    viewModel.answers.removeValue(forKey: id)
                }
            }
        )
    }
}

// MARK: - Expiration Screen
public struct ExpiredSurveyView: View {
    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.xmark.fill")
                .font(.system(size: 64))
                .foregroundColor(AppTheme.gold)

            Text("Survey Window Expired")
                .font(.title2.bold())
                .foregroundColor(AppTheme.navy)

            Text("This experience sampling prompt was not completed within the allotted time. An audit record has been recorded.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
        }
        .padding()
    }
}

// MARK: - Completed Screen
public struct SurveyCompletedView: View {
    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(AppTheme.lightBlue)

            Text("Check-In Submitted")
                .font(.title2.bold())
                .foregroundColor(AppTheme.navy)

            Text("Thank you! Your survey response has been saved anonymously.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
        }
        .padding()
    }
}

// MARK: - Live Timer Badge Component
public struct TimerBadgeView: View {
    public let remainingSeconds: Int

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "timer")
            Text(timeString(from: remainingSeconds))
                .monospacedDigit()
                .bold()
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(remainingSeconds < 60 ? Color.red.opacity(0.15) : AppTheme.lightBlue.opacity(0.15))
        .foregroundColor(remainingSeconds < 60 ? .red : AppTheme.navy)
        .clipShape(Capsule())
    }

    private func timeString(from secs: Int) -> String {
        let mins = secs / 60
        let s = secs % 60
        return String(format: "%02d:%02d", mins, s)
    }
}
```

---

## 9. Apple Developer Account & APNs Notification Setup

> [!IMPORTANT]
> Real remote push notifications through the Apple Push Notification service (APNs) cannot run in the iOS Simulator or without a paid Apple Developer Program account ($99/year). This integration must be completed once the initial Xcode project is created and provisioned.

### 9.1. Prerequisites & Apple Developer Portal Setup
1. **Enrollment**: Ensure an active team membership in the [Apple Developer Program](https://developer.apple.com/programs/).
2. **App ID & Capabilities**:
   - In Apple Developer Portal $\rightarrow$ *Certificates, Identifiers & Profiles* $\rightarrow$ *Identifiers*.
   - Register an explicit App ID (e.g., `com.simplesurveys.ios`).
   - Enable the **Push Notifications** capability.
3. **APNs Authentication Key (`.p8`)**:
   - In *Keys*, generate a new Apple Push Notifications service (APNs) key.
   - Note the **Key ID** (10-character string) and the team's **Team ID**.
   - Download the private key file (`AuthKey_XXXXXXXXXX.p8`). This `.p8` key is placed on the backend server to authenticate push dispatches to APNs.

### 9.2. Xcode Project Capabilities
In the Xcode project target settings:
1. Navigate to **Signing & Capabilities**.
2. Select your Apple Developer Team.
3. Click **+ Capability** and add:
   - **Push Notifications**
   - **Background Modes** $\rightarrow$ Check **Remote notifications** (enables background wakes).

### 9.3. Device Token Registration Lifecycle

When the app launches on a physical iPhone:
1. The user goes through the **Onboarding Screen** and taps "Enable Permissions", calling:
   - `UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])`
   - `locationService.requestAuthorization()`
   - `cameraService.requestAuthorization()`
2. Once granted, calls `UIApplication.shared.registerForRemoteNotifications()`.
3. iOS returns the 64-character hexadecimal device token via `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`.
4. The app asynchronously posts the token to `POST /api/notifications/devices`. Once registered, the user is never prompted for onboarding again.
5. When the user taps a notification banner, the push payload (`survey_id`, `notification_sent_at`) is received and routes the participant directly to complete that scheduled survey.

```swift
import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private let apiClient: APIClientProtocol = APIClient(baseURL: AppConfiguration.apiBaseURL)

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        // Post anonymous token to backend
        Task {
            let payload = DeviceRegistration(
                deviceToken: tokenString,
                platform: .ios,
                timezone: TimeZone.current.identifier,
                registeredAt: Date()
            )

            let _: DeviceRegistrationResponse? = try? await apiClient.post("/api/notifications/devices", body: payload)
        }
    }

    // Handle incoming notification when user taps banner
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let surveyId = userInfo["survey_id"] as? String else { return }
        
        let sentAtString = userInfo["notification_sent_at"] as? String
        let isoFormatter = ISO8601DateFormatter()
        let sentAtDate = sentAtString.flatMap { isoFormatter.date(from: $0) }

        // Route app to survey screen with temporal marker
        NotificationCenter.default.post(
            name: .openSurveyFromNotification,
            object: nil,
            userInfo: [
                "survey_id": surveyId,
                "notification_sent_at": sentAtDate as Any
            ]
        )
    }
}
```

---

## 10. End-to-End Data Flow & Sequence Diagram

The interaction flow below illustrates the participant lifecycle from onboarding through prompt delivery, survey answering, and submission:

```
┌──────┐        ┌─────────────┐       ┌──────────┐        ┌───────────┐
│ APNs │        │ iOS App     │       │ CoreLoc  │        │ Backend   │
└──┬───┘        └──────┬──────┘       └────┬─────┘        └─────┬─────┘
   │                   │                   │                    │
   │                   │ [First Launch Only]                    │
   │                   │ 0a. Display Onboarding Card            │
   │                   │     "Enable Permissions" tapped        │
   │                   │     Request APNs + GPS + Camera        │
   │                   │ 0b. Post Device Token                  │
   │                   │     POST /api/notifications/devices    │
   │                   │───────────────────────────────────────>│
   │                   │<───────────────────────────────────────│
   │                   │     (Device Registered)                │
   │                   │                                        │
   │ 1. Scheduled Push │                                        │
   │    Survey Prompt  │                                        │
   │──────────────────>│                                        │
   │                   │ 2. User Taps                           │
   │                   │    Start Timer                         │
   │                   │                                        │
   │                   │ 3. Fetch Scheduled Survey              │
   │                   │    GET /api/surveys/{survey_id}        │
   │                   │───────────────────────────────────────>│
   │                   │<───────────────────────────────────────│
   │                   │    (Returns Survey JSON Definition)    │
   │                   │                                        │
   │                   │ 4. User completes answers              │
   │                   │    & snaps surroundings photo          │
   │                   │                                        │
   │                   │ 5. Request GPS    │                    │
   │                   │──────────────────>│                    │
   │                   │<──────────────────│                    │
   │                   │    (Lat, Long, Alt)                    │
   │                   │                                        │
   │                   │ 6. Submit Multipart (JSON + Image)     │
   │                   │    POST /api/responses                 │
   │                   │───────────────────────────────────────>│
   │                   │                                        │ 7. Validate Time
   │                   │                                        │    & Persist JSON
   │                   │ 8. Return Receipt                      │    (201 Created if valid,
   │                   │<───────────────────────────────────────│     200 OK if expired)
   │                   │                                        │
```

---

## 11. Implementation Roadmap

### Phase 1: Xcode Setup, Theme & Core Architecture
- Initialize new Xcode project (`SimpleSurveys`) targeting iOS 17+.
- Configure package dependencies and directory structure (`Models`, `Services`, `Repositories`, `ViewModels`, `Views`).
- Implement `Theme.swift` with Navy (`#00205B`), Light Blue (`#13B5EA`), Gold (`#8B634B`), and White (`#FFFFFF`).
- Implement `AppConfiguration` and `APIClient` supporting GET, POST, and multipart form uploads.
- Implement `SurveyRepositoryProtocol` and `SurveyRepository` with participant-only operations:
  - `registerDevice(token:timezone:)`
  - `fetchScheduledSurvey(id:)`
  - `submitResponse(submission:imageData:)`

### Phase 2: First-Launch Onboarding & Permission Manager
- Build `PermissionManager` to check and request Push Notifications, CoreLocation GPS, and Camera Capture in a single sequenced flow.
- Implement `OnboardingViewModel` and `OnboardingView` with the study explanation card, permissions checklist, and Navy/Gold brand styling.
- Store `hasCompletedOnboarding` in `UserDefaults` once the device token is registered so the screen never displays again.
- Implement `PermissionRevokedView` to lock out the app and prompt users to Settings if any permission is later revoked.

### Phase 3: Domain Models & Dynamic Question Renderers
- Implement `SurveyConfig`, `Question`, `ValidationRules`, and polymorphic `AnyCodableValue` DTOs.
- Implement response submission and receipt models (`SurveyResponseSubmission`, `QuestionAnswer`, `LocationData`, `SurveySubmissionReceipt`).
- Build individual SwiftUI question views (`RatingScaleQuestionView`, `SingleChoiceQuestionView`, `MultipleChoiceQuestionView`, `TextQuestionView`, `NumericQuestionView`) styled with brand palette colors.
- Test dynamic rendering using local JSON previews.

### Phase 4: Hardware Integrations (Camera & Location)
- Configure `Info.plist` with required privacy strings:
  - `NSCameraUsageDescription`: *"Simple Surveys uses the camera to capture your immediate surroundings during check-ins."*
  - `NSLocationWhenInUseUsageDescription`: *"Simple Surveys logs your approximate GPS coordinates upon survey submission for environmental sampling."*
- Implement `LocationService` with async continuation wrapper over `CLLocationManager`.
- Implement `CameraService` and `CameraCaptureView` with compression downscaling to 1080p JPEG.

### Phase 5: Live Countdown, Expiration & Submission Engine
- Implement `SurveyViewModel` with dynamic answer dictionary, 1-second interval timer, and expiration detection against `time_to_complete_minutes`.
- Implement `TimerBadgeView`, `ExpiredSurveyView`, and `SurveyCompletedView`.
- Build submission pipeline that automatically empties answers if the timer reaches zero before submission, handling `201 Created` vs `200 OK (EXPIRED)` receipt responses.

### Phase 6: APNs Push Notification Integration
- Register explicit App ID and APNs key in the Apple Developer Portal.
- Configure Xcode **Push Notifications** and **Background Modes** capabilities.
- Implement `AppDelegate` with device token retrieval and dispatch to `POST /api/notifications/devices`.
- Wire deep-link notification opening to `SurveyContainerView` using the prompted `survey_id` and `notification_sent_at` timestamp.
