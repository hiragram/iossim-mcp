import XCTest

// MARK: - Script Models

struct Script: Codable {
    let bundleId: String
    let actions: [Action]
}

enum Action: Codable {
    case tap(TapAction)
    case typeText(TypeTextAction)
    case swipe(SwipeAction)
    case longPress(LongPressAction)
    case waitForElement(WaitForElementAction)
    case assertExists(AssertExistsAction)
    case screenshot(ScreenshotAction)

    private enum CodingKeys: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "tap":
            self = .tap(try TapAction(from: decoder))
        case "typeText":
            self = .typeText(try TypeTextAction(from: decoder))
        case "swipe":
            self = .swipe(try SwipeAction(from: decoder))
        case "longPress":
            self = .longPress(try LongPressAction(from: decoder))
        case "waitForElement":
            self = .waitForElement(try WaitForElementAction(from: decoder))
        case "assertExists":
            self = .assertExists(try AssertExistsAction(from: decoder))
        case "screenshot":
            self = .screenshot(try ScreenshotAction(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown action type: \(type)"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .tap(let action):
            try action.encode(to: encoder)
        case .typeText(let action):
            try action.encode(to: encoder)
        case .swipe(let action):
            try action.encode(to: encoder)
        case .longPress(let action):
            try action.encode(to: encoder)
        case .waitForElement(let action):
            try action.encode(to: encoder)
        case .assertExists(let action):
            try action.encode(to: encoder)
        case .screenshot(let action):
            try action.encode(to: encoder)
        }
    }
}

// MARK: - Element Target

struct ElementTarget: Codable {
    enum TargetType: String, Codable {
        case identifier
        case label
        case coordinate
    }

    let type: TargetType
    let value: String?
    let x: Int?
    let y: Int?

    func findElement(in app: XCUIApplication) -> XCUIElement? {
        switch type {
        case .identifier:
            guard let value = value else { return nil }
            return app.descendants(matching: .any).matching(identifier: value).firstMatch
        case .label:
            guard let value = value else { return nil }
            return app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", value)).firstMatch
        case .coordinate:
            return nil // Coordinates are handled differently
        }
    }

    func getCoordinate(in app: XCUIApplication) -> XCUICoordinate? {
        guard type == .coordinate, let x = x, let y = y else { return nil }
        let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        return normalized.withOffset(CGVector(dx: x, dy: y))
    }
}

// MARK: - Action Types

struct TapAction: Codable {
    let type: String
    let target: ElementTarget
}

struct TypeTextAction: Codable {
    let type: String
    let text: String
    let target: ElementTarget?
}

struct SwipeAction: Codable {
    let type: String
    let direction: String // up, down, left, right
    let target: ElementTarget?
}

struct LongPressAction: Codable {
    let type: String
    let target: ElementTarget
    let duration: Double?
}

struct WaitForElementAction: Codable {
    let type: String
    let target: ElementTarget
    let timeout: Double?
}

struct AssertExistsAction: Codable {
    let type: String
    let target: ElementTarget
}

struct ScreenshotAction: Codable {
    let type: String
    let outputPath: String?
}

// MARK: - Result Models

struct ScriptResult: Codable {
    let success: Bool
    let results: [ActionResult]
    let error: String?
}

struct ActionResult: Codable {
    let actionIndex: Int
    let success: Bool
    let error: String?
    let screenshotPath: String?
}

// MARK: - Driver Tests

final class DriverTests: XCTestCase {

    private var app: XCUIApplication!
    private var results: [ActionResult] = []

    override func setUp() {
        super.setUp()
        continueAfterFailure = true
    }

    func testScript() throws {
        // Get script path from environment
        guard let scriptPath = ProcessInfo.processInfo.environment["UI_TEST_SCRIPT_PATH"] else {
            XCTFail("UI_TEST_SCRIPT_PATH is not set")
            return
        }

        // Get result path from environment
        let resultPath = ProcessInfo.processInfo.environment["UI_TEST_RESULT_PATH"]

        // Read and parse script
        let data = try Data(contentsOf: URL(fileURLWithPath: scriptPath))
        let script = try JSONDecoder().decode(Script.self, from: data)

        // Launch app
        app = XCUIApplication(bundleIdentifier: script.bundleId)
        app.launch()

        // Execute actions
        results = []
        for (index, action) in script.actions.enumerated() {
            let result = executeAction(action, at: index)
            results.append(result)

            if !result.success {
                // Stop on first failure
                break
            }
        }

        // Write results
        if let resultPath = resultPath {
            let success = results.allSatisfy { $0.success }
            let lastError = results.last(where: { !$0.success })?.error
            let scriptResult = ScriptResult(success: success, results: results, error: lastError)
            let resultData = try JSONEncoder().encode(scriptResult)
            try resultData.write(to: URL(fileURLWithPath: resultPath))
        }

        // Assert overall success
        XCTAssertTrue(results.allSatisfy { $0.success }, "Some actions failed")
    }

    private func executeAction(_ action: Action, at index: Int) -> ActionResult {
        do {
            switch action {
            case .tap(let tapAction):
                try executeTap(tapAction)
            case .typeText(let typeTextAction):
                try executeTypeText(typeTextAction)
            case .swipe(let swipeAction):
                try executeSwipe(swipeAction)
            case .longPress(let longPressAction):
                try executeLongPress(longPressAction)
            case .waitForElement(let waitAction):
                try executeWaitForElement(waitAction)
            case .assertExists(let assertAction):
                try executeAssertExists(assertAction)
            case .screenshot(let screenshotAction):
                let path = try executeScreenshot(screenshotAction)
                return ActionResult(actionIndex: index, success: true, error: nil, screenshotPath: path)
            }
            return ActionResult(actionIndex: index, success: true, error: nil, screenshotPath: nil)
        } catch {
            return ActionResult(actionIndex: index, success: false, error: error.localizedDescription, screenshotPath: nil)
        }
    }

    private func executeTap(_ action: TapAction) throws {
        if let coordinate = action.target.getCoordinate(in: app) {
            coordinate.tap()
        } else if let element = action.target.findElement(in: app) {
            guard element.waitForExistence(timeout: 5) else {
                throw DriverError.elementNotFound(action.target)
            }
            element.tap()
        } else {
            throw DriverError.invalidTarget(action.target)
        }
    }

    private func executeTypeText(_ action: TypeTextAction) throws {
        if let target = action.target, let element = target.findElement(in: app) {
            guard element.waitForExistence(timeout: 5) else {
                throw DriverError.elementNotFound(target)
            }
            element.tap()
            element.typeText(action.text)
        } else {
            // Type into focused element
            app.typeText(action.text)
        }
    }

    private func executeSwipe(_ action: SwipeAction) throws {
        let element: XCUIElement
        if let target = action.target, let found = target.findElement(in: app) {
            guard found.waitForExistence(timeout: 5) else {
                throw DriverError.elementNotFound(target)
            }
            element = found
        } else {
            element = app
        }

        switch action.direction.lowercased() {
        case "up":
            element.swipeUp()
        case "down":
            element.swipeDown()
        case "left":
            element.swipeLeft()
        case "right":
            element.swipeRight()
        default:
            throw DriverError.invalidSwipeDirection(action.direction)
        }
    }

    private func executeLongPress(_ action: LongPressAction) throws {
        guard let element = action.target.findElement(in: app) else {
            throw DriverError.invalidTarget(action.target)
        }
        guard element.waitForExistence(timeout: 5) else {
            throw DriverError.elementNotFound(action.target)
        }
        let duration = action.duration ?? 1.0
        element.press(forDuration: duration)
    }

    private func executeWaitForElement(_ action: WaitForElementAction) throws {
        guard let element = action.target.findElement(in: app) else {
            throw DriverError.invalidTarget(action.target)
        }
        let timeout = action.timeout ?? 10.0
        guard element.waitForExistence(timeout: timeout) else {
            throw DriverError.elementNotFound(action.target)
        }
    }

    private func executeAssertExists(_ action: AssertExistsAction) throws {
        guard let element = action.target.findElement(in: app) else {
            throw DriverError.invalidTarget(action.target)
        }
        guard element.exists else {
            throw DriverError.elementNotFound(action.target)
        }
    }

    private func executeScreenshot(_ action: ScreenshotAction) throws -> String {
        let screenshot = app.screenshot()
        let path: String
        if let outputPath = action.outputPath {
            path = outputPath
        } else {
            path = NSTemporaryDirectory() + "screenshot-\(UUID().uuidString).png"
        }
        try screenshot.pngRepresentation.write(to: URL(fileURLWithPath: path))
        return path
    }

    enum DriverError: LocalizedError {
        case elementNotFound(ElementTarget)
        case invalidTarget(ElementTarget)
        case invalidSwipeDirection(String)

        var errorDescription: String? {
            switch self {
            case .elementNotFound(let target):
                return "Element not found: \(target)"
            case .invalidTarget(let target):
                return "Invalid target: \(target)"
            case .invalidSwipeDirection(let direction):
                return "Invalid swipe direction: \(direction)"
            }
        }
    }
}
