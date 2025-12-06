import Foundation

/// Script to be executed by the UITest driver
public struct UITestScript: Codable, Sendable {
    public let bundleId: String
    public let actions: [UITestAction]

    public init(bundleId: String, actions: [UITestAction]) {
        self.bundleId = bundleId
        self.actions = actions
    }
}

/// Action to be executed by the UITest driver
public enum UITestAction: Codable, Sendable {
    case tap(target: ElementTarget)
    case typeText(text: String, target: ElementTarget?)
    case swipe(direction: SwipeDirection, target: ElementTarget?)
    case longPress(target: ElementTarget, duration: Double?)
    case waitForElement(target: ElementTarget, timeout: Double?)
    case assertExists(target: ElementTarget)
    case screenshot(outputPath: String?)

    private enum CodingKeys: String, CodingKey {
        case type
        case target
        case text
        case direction
        case duration
        case timeout
        case outputPath
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "tap":
            let target = try container.decode(ElementTarget.self, forKey: .target)
            self = .tap(target: target)
        case "typeText":
            let text = try container.decode(String.self, forKey: .text)
            let target = try container.decodeIfPresent(ElementTarget.self, forKey: .target)
            self = .typeText(text: text, target: target)
        case "swipe":
            let direction = try container.decode(SwipeDirection.self, forKey: .direction)
            let target = try container.decodeIfPresent(ElementTarget.self, forKey: .target)
            self = .swipe(direction: direction, target: target)
        case "longPress":
            let target = try container.decode(ElementTarget.self, forKey: .target)
            let duration = try container.decodeIfPresent(Double.self, forKey: .duration)
            self = .longPress(target: target, duration: duration)
        case "waitForElement":
            let target = try container.decode(ElementTarget.self, forKey: .target)
            let timeout = try container.decodeIfPresent(Double.self, forKey: .timeout)
            self = .waitForElement(target: target, timeout: timeout)
        case "assertExists":
            let target = try container.decode(ElementTarget.self, forKey: .target)
            self = .assertExists(target: target)
        case "screenshot":
            let outputPath = try container.decodeIfPresent(String.self, forKey: .outputPath)
            self = .screenshot(outputPath: outputPath)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown action type: \(type)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .tap(let target):
            try container.encode("tap", forKey: .type)
            try container.encode(target, forKey: .target)
        case .typeText(let text, let target):
            try container.encode("typeText", forKey: .type)
            try container.encode(text, forKey: .text)
            try container.encodeIfPresent(target, forKey: .target)
        case .swipe(let direction, let target):
            try container.encode("swipe", forKey: .type)
            try container.encode(direction, forKey: .direction)
            try container.encodeIfPresent(target, forKey: .target)
        case .longPress(let target, let duration):
            try container.encode("longPress", forKey: .type)
            try container.encode(target, forKey: .target)
            try container.encodeIfPresent(duration, forKey: .duration)
        case .waitForElement(let target, let timeout):
            try container.encode("waitForElement", forKey: .type)
            try container.encode(target, forKey: .target)
            try container.encodeIfPresent(timeout, forKey: .timeout)
        case .assertExists(let target):
            try container.encode("assertExists", forKey: .type)
            try container.encode(target, forKey: .target)
        case .screenshot(let outputPath):
            try container.encode("screenshot", forKey: .type)
            try container.encodeIfPresent(outputPath, forKey: .outputPath)
        }
    }
}

/// Result from UITest driver execution
public struct UITestResult: Codable, Sendable {
    public let success: Bool
    public let results: [ActionResult]
    public let error: String?

    public struct ActionResult: Codable, Sendable {
        public let actionIndex: Int
        public let success: Bool
        public let error: String?
        public let screenshotPath: String?
    }
}

/// Executes UI tests using xcodebuild test-without-building
public struct UITestDriver: Sendable {
    private let processRunner: ProcessRunner
    private let xctestrunPath: URL
    private let runnerAppPath: URL

    public init(
        processRunner: ProcessRunner = DefaultProcessRunner(),
        xctestrunPath: URL,
        runnerAppPath: URL
    ) {
        self.processRunner = processRunner
        self.xctestrunPath = xctestrunPath
        self.runnerAppPath = runnerAppPath
    }

    /// Executes a script on the specified simulator
    public func execute(
        script: UITestScript,
        simulatorUdid: String,
        timeout: TimeInterval = 300
    ) async throws -> UITestResult {
        // Write script to temp file
        let sessionId = UUID().uuidString
        let scriptPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("simdriver-\(sessionId)-script.json")
        let resultPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("simdriver-\(sessionId)-result.json")

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let scriptData = try encoder.encode(script)
        try scriptData.write(to: scriptPath)

        defer {
            try? FileManager.default.removeItem(at: scriptPath)
            try? FileManager.default.removeItem(at: resultPath)
        }

        // Run xcodebuild test-without-building
        let result = try await processRunner.run(
            executable: "/usr/bin/xcrun",
            arguments: [
                "xcodebuild",
                "test-without-building",
                "-xctestrun", xctestrunPath.path,
                "-destination", "platform=iOS Simulator,id=\(simulatorUdid)",
                "-only-testing:SimDriverUITests/DriverTests/testScript"
            ]
        )

        // Read result if available
        if FileManager.default.fileExists(atPath: resultPath.path) {
            let resultData = try Data(contentsOf: resultPath)
            return try JSONDecoder().decode(UITestResult.self, from: resultData)
        }

        // If no result file, construct result from process output
        if result.success {
            return UITestResult(success: true, results: [], error: nil)
        } else {
            return UITestResult(success: false, results: [], error: result.stderr)
        }
    }
}
