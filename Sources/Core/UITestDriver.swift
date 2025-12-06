import Foundation

/// Script to be executed by the UITest driver
public struct UITestScript: Codable, Sendable {
    public let bundleId: String
    public let actions: [UITestAction]
    public let recordVideo: Bool

    public init(bundleId: String, actions: [UITestAction], recordVideo: Bool = false) {
        self.bundleId = bundleId
        self.actions = actions
        self.recordVideo = recordVideo
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
    case doubleTap(target: ElementTarget)
    case pinch(target: ElementTarget, scale: Double, velocity: Double)
    case rotate(target: ElementTarget, rotation: Double, velocity: Double)
    case drag(from: ElementTarget, to: ElementTarget, duration: Double?)
    case scrollToElement(target: ElementTarget, within: ElementTarget?, direction: SwipeDirection, maxScrolls: Int?)
    case clearText(target: ElementTarget)
    case shake

    private enum CodingKeys: String, CodingKey {
        case type
        case target
        case text
        case direction
        case duration
        case timeout
        case outputPath
        case scale
        case velocity
        case rotation
        case from
        case to
        case within
        case maxScrolls
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
        case "doubleTap":
            let target = try container.decode(ElementTarget.self, forKey: .target)
            self = .doubleTap(target: target)
        case "pinch":
            let target = try container.decode(ElementTarget.self, forKey: .target)
            let scale = try container.decode(Double.self, forKey: .scale)
            let velocity = try container.decode(Double.self, forKey: .velocity)
            self = .pinch(target: target, scale: scale, velocity: velocity)
        case "rotate":
            let target = try container.decode(ElementTarget.self, forKey: .target)
            let rotation = try container.decode(Double.self, forKey: .rotation)
            let velocity = try container.decode(Double.self, forKey: .velocity)
            self = .rotate(target: target, rotation: rotation, velocity: velocity)
        case "drag":
            let from = try container.decode(ElementTarget.self, forKey: .from)
            let to = try container.decode(ElementTarget.self, forKey: .to)
            let duration = try container.decodeIfPresent(Double.self, forKey: .duration)
            self = .drag(from: from, to: to, duration: duration)
        case "scrollToElement":
            let target = try container.decode(ElementTarget.self, forKey: .target)
            let within = try container.decodeIfPresent(ElementTarget.self, forKey: .within)
            let direction = try container.decode(SwipeDirection.self, forKey: .direction)
            let maxScrolls = try container.decodeIfPresent(Int.self, forKey: .maxScrolls)
            self = .scrollToElement(target: target, within: within, direction: direction, maxScrolls: maxScrolls)
        case "clearText":
            let target = try container.decode(ElementTarget.self, forKey: .target)
            self = .clearText(target: target)
        case "shake":
            self = .shake
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
        case .doubleTap(let target):
            try container.encode("doubleTap", forKey: .type)
            try container.encode(target, forKey: .target)
        case .pinch(let target, let scale, let velocity):
            try container.encode("pinch", forKey: .type)
            try container.encode(target, forKey: .target)
            try container.encode(scale, forKey: .scale)
            try container.encode(velocity, forKey: .velocity)
        case .rotate(let target, let rotation, let velocity):
            try container.encode("rotate", forKey: .type)
            try container.encode(target, forKey: .target)
            try container.encode(rotation, forKey: .rotation)
            try container.encode(velocity, forKey: .velocity)
        case .drag(let from, let to, let duration):
            try container.encode("drag", forKey: .type)
            try container.encode(from, forKey: .from)
            try container.encode(to, forKey: .to)
            try container.encodeIfPresent(duration, forKey: .duration)
        case .scrollToElement(let target, let within, let direction, let maxScrolls):
            try container.encode("scrollToElement", forKey: .type)
            try container.encode(target, forKey: .target)
            try container.encodeIfPresent(within, forKey: .within)
            try container.encode(direction, forKey: .direction)
            try container.encodeIfPresent(maxScrolls, forKey: .maxScrolls)
        case .clearText(let target):
            try container.encode("clearText", forKey: .type)
            try container.encode(target, forKey: .target)
        case .shake:
            try container.encode("shake", forKey: .type)
        }
    }
}

/// Result from UITest driver execution
public struct UITestResult: Codable, Sendable {
    public let success: Bool
    public let results: [ActionResult]
    public let error: String?
    public let videoPath: String?

    public init(success: Bool, results: [ActionResult], error: String?, videoPath: String? = nil) {
        self.success = success
        self.results = results
        self.error = error
        self.videoPath = videoPath
    }

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
    private let simulatorController: SimulatorController
    private let xctestrunPath: URL
    private let runnerAppPath: URL
    private let hostAppPath: URL

    public init(
        processRunner: ProcessRunner = DefaultProcessRunner(),
        simulatorController: SimulatorController = SimulatorController(),
        xctestrunPath: URL,
        runnerAppPath: URL,
        hostAppPath: URL
    ) {
        self.processRunner = processRunner
        self.simulatorController = simulatorController
        self.xctestrunPath = xctestrunPath
        self.runnerAppPath = runnerAppPath
        self.hostAppPath = hostAppPath
    }

    /// Executes a script on the specified simulator
    public func execute(
        script: UITestScript,
        simulatorUdid: String,
        timeout: TimeInterval = 300
    ) async throws -> UITestResult {
        // Create temporary directory structure that matches .xctestrun expectations
        let sessionId = UUID().uuidString
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("simdriver-\(sessionId)")
        let testProductsDir = tempDir.appendingPathComponent("Debug-iphonesimulator")

        try FileManager.default.createDirectory(at: testProductsDir, withIntermediateDirectories: true)

        // Copy runner app and host app to expected locations
        let destRunnerPath = testProductsDir.appendingPathComponent("SimDriverUITests-Runner.app")
        let destHostAppPath = testProductsDir.appendingPathComponent("SimDriverHost.app")
        try FileManager.default.copyItem(at: runnerAppPath, to: destRunnerPath)
        try FileManager.default.copyItem(at: hostAppPath, to: destHostAppPath)

        // Write script to temp file first (needed for xctestrun)
        let scriptPath = tempDir.appendingPathComponent("script.json")
        let resultPath = tempDir.appendingPathComponent("result.json")

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let scriptData = try encoder.encode(script)
        try scriptData.write(to: scriptPath)

        // Create modified .xctestrun file with absolute paths and environment variables
        let modifiedXctestrunPath = tempDir.appendingPathComponent("SimDriverUITests.xctestrun")
        try createModifiedXctestrun(
            from: xctestrunPath,
            to: modifiedXctestrunPath,
            testRoot: tempDir.path,
            scriptPath: scriptPath.path,
            resultPath: resultPath.path
        )

        // Start video recording if requested
        var recordingSession: RecordingSession? = nil
        var videoOutputPath: String? = nil

        if script.recordVideo {
            videoOutputPath = "/tmp/iossim-mcp-recording-\(sessionId).mov"
            recordingSession = try simulatorController.startRecording(
                simulatorUdid: simulatorUdid,
                outputPath: videoOutputPath!
            )
            try await recordingSession?.waitForRecordingToStart()
        }

        defer {
            // Stop recording if active
            recordingSession?.stop()
            // Clean up temp directory (but not the video file which is in /tmp)
            try? FileManager.default.removeItem(at: tempDir)
        }

        // Run xcodebuild test-without-building
        let result = try await processRunner.run(
            executable: "/usr/bin/xcrun",
            arguments: [
                "xcodebuild",
                "test-without-building",
                "-xctestrun", modifiedXctestrunPath.path,
                "-destination", "platform=iOS Simulator,id=\(simulatorUdid)",
                "-only-testing:SimDriverUITests/DriverTests/testScript"
            ]
        )

        // Read result if available
        if FileManager.default.fileExists(atPath: resultPath.path) {
            let resultData = try Data(contentsOf: resultPath)
            var testResult = try JSONDecoder().decode(UITestResult.self, from: resultData)
            // Add video path to result if recording was enabled
            if script.recordVideo {
                testResult = UITestResult(
                    success: testResult.success,
                    results: testResult.results,
                    error: testResult.error,
                    videoPath: videoOutputPath
                )
            }
            return testResult
        }

        // If no result file, construct result from process output
        if result.success {
            return UITestResult(success: true, results: [], error: nil, videoPath: videoOutputPath)
        } else {
            return UITestResult(success: false, results: [], error: result.stderr, videoPath: videoOutputPath)
        }
    }

    /// Creates a modified .xctestrun file with placeholders replaced by actual paths
    private func createModifiedXctestrun(
        from source: URL,
        to destination: URL,
        testRoot: String,
        scriptPath: String,
        resultPath: String
    ) throws {
        var content = try String(contentsOf: source, encoding: .utf8)
        content = content.replacingOccurrences(of: "__TESTROOT__", with: testRoot)

        // Inject environment variables into TestingEnvironmentVariables
        let envVarsToInject = """
                        <key>UI_TEST_SCRIPT_PATH</key>
                        <string>\(scriptPath)</string>
                        <key>UI_TEST_RESULT_PATH</key>
                        <string>\(resultPath)</string>
        """

        // Insert after <key>TestingEnvironmentVariables</key>\n\t\t\t\t\t<dict>
        if let range = content.range(of: "<key>TestingEnvironmentVariables</key>\n\t\t\t\t\t<dict>\n") {
            content.insert(contentsOf: envVarsToInject + "\n", at: range.upperBound)
        }

        try content.write(to: destination, atomically: true, encoding: .utf8)
    }
}
