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
    case doubleTap(DoubleTapAction)
    case pinch(PinchAction)
    case rotate(RotateAction)
    case drag(DragAction)
    case scrollToElement(ScrollToElementAction)
    case clearText(ClearTextAction)
    case shake(ShakeAction)
    case getElementValue(GetElementValueAction)
    case getElementProperties(GetElementPropertiesAction)
    case getElementFrame(GetElementFrameAction)

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
        case "doubleTap":
            self = .doubleTap(try DoubleTapAction(from: decoder))
        case "pinch":
            self = .pinch(try PinchAction(from: decoder))
        case "rotate":
            self = .rotate(try RotateAction(from: decoder))
        case "drag":
            self = .drag(try DragAction(from: decoder))
        case "scrollToElement":
            self = .scrollToElement(try ScrollToElementAction(from: decoder))
        case "clearText":
            self = .clearText(try ClearTextAction(from: decoder))
        case "shake":
            self = .shake(try ShakeAction(from: decoder))
        case "getElementValue":
            self = .getElementValue(try GetElementValueAction(from: decoder))
        case "getElementProperties":
            self = .getElementProperties(try GetElementPropertiesAction(from: decoder))
        case "getElementFrame":
            self = .getElementFrame(try GetElementFrameAction(from: decoder))
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
        case .doubleTap(let action):
            try action.encode(to: encoder)
        case .pinch(let action):
            try action.encode(to: encoder)
        case .rotate(let action):
            try action.encode(to: encoder)
        case .drag(let action):
            try action.encode(to: encoder)
        case .scrollToElement(let action):
            try action.encode(to: encoder)
        case .clearText(let action):
            try action.encode(to: encoder)
        case .shake(let action):
            try action.encode(to: encoder)
        case .getElementValue(let action):
            try action.encode(to: encoder)
        case .getElementProperties(let action):
            try action.encode(to: encoder)
        case .getElementFrame(let action):
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

struct DoubleTapAction: Codable {
    let type: String
    let target: ElementTarget
}

struct PinchAction: Codable {
    let type: String
    let target: ElementTarget
    let scale: Double
    let velocity: Double
}

struct RotateAction: Codable {
    let type: String
    let target: ElementTarget
    let rotation: Double
    let velocity: Double
}

struct DragAction: Codable {
    let type: String
    let from: ElementTarget
    let to: ElementTarget
    let duration: Double?
}

struct ScrollToElementAction: Codable {
    let type: String
    let target: ElementTarget
    let within: ElementTarget?
    let direction: String
    let maxScrolls: Int?
}

struct ClearTextAction: Codable {
    let type: String
    let target: ElementTarget
}

struct ShakeAction: Codable {
    let type: String
}

struct GetElementValueAction: Codable {
    let type: String
    let target: ElementTarget
}

struct GetElementPropertiesAction: Codable {
    let type: String
    let target: ElementTarget
}

struct GetElementFrameAction: Codable {
    let type: String
    let target: ElementTarget
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
    let value: String?
    let properties: ElementProperties?
    let frame: ElementFrame?

    init(
        actionIndex: Int,
        success: Bool,
        error: String?,
        screenshotPath: String?,
        value: String? = nil,
        properties: ElementProperties? = nil,
        frame: ElementFrame? = nil
    ) {
        self.actionIndex = actionIndex
        self.success = success
        self.error = error
        self.screenshotPath = screenshotPath
        self.value = value
        self.properties = properties
        self.frame = frame
    }
}

struct ElementProperties: Codable {
    let label: String?
    let value: String?
    let title: String?
    let identifier: String?
    let isEnabled: Bool
    let isSelected: Bool
    let placeholderValue: String?
}

struct ElementFrame: Codable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
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

        // Activate app (or launch if not running)
        app = XCUIApplication(bundleIdentifier: script.bundleId)
        if app.state == .runningForeground || app.state == .runningBackground {
            app.activate()
        } else {
            app.launch()
        }

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
            case .doubleTap(let doubleTapAction):
                try executeDoubleTap(doubleTapAction)
            case .pinch(let pinchAction):
                try executePinch(pinchAction)
            case .rotate(let rotateAction):
                try executeRotate(rotateAction)
            case .drag(let dragAction):
                try executeDrag(dragAction)
            case .scrollToElement(let scrollAction):
                try executeScrollToElement(scrollAction)
            case .clearText(let clearTextAction):
                try executeClearText(clearTextAction)
            case .shake(_):
                try executeShake()
            case .getElementValue(let action):
                let value = try executeGetElementValue(action)
                return ActionResult(actionIndex: index, success: true, error: nil, screenshotPath: nil, value: value)
            case .getElementProperties(let action):
                let properties = try executeGetElementProperties(action)
                return ActionResult(actionIndex: index, success: true, error: nil, screenshotPath: nil, properties: properties)
            case .getElementFrame(let action):
                let frame = try executeGetElementFrame(action)
                return ActionResult(actionIndex: index, success: true, error: nil, screenshotPath: nil, frame: frame)
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

    private func executeDoubleTap(_ action: DoubleTapAction) throws {
        if let coordinate = action.target.getCoordinate(in: app) {
            coordinate.doubleTap()
        } else if let element = action.target.findElement(in: app) {
            guard element.waitForExistence(timeout: 5) else {
                throw DriverError.elementNotFound(action.target)
            }
            element.doubleTap()
        } else {
            throw DriverError.invalidTarget(action.target)
        }
    }

    private func executePinch(_ action: PinchAction) throws {
        guard let element = action.target.findElement(in: app) else {
            throw DriverError.invalidTarget(action.target)
        }
        guard element.waitForExistence(timeout: 5) else {
            throw DriverError.elementNotFound(action.target)
        }
        element.pinch(withScale: action.scale, velocity: action.velocity)
    }

    private func executeRotate(_ action: RotateAction) throws {
        guard let element = action.target.findElement(in: app) else {
            throw DriverError.invalidTarget(action.target)
        }
        guard element.waitForExistence(timeout: 5) else {
            throw DriverError.elementNotFound(action.target)
        }
        element.rotate(action.rotation, withVelocity: action.velocity)
    }

    private func executeDrag(_ action: DragAction) throws {
        let duration = action.duration ?? 0.5

        // Get source element or coordinate
        let sourceElement: XCUIElement?
        let sourceCoordinate: XCUICoordinate?

        if let coord = action.from.getCoordinate(in: app) {
            sourceElement = nil
            sourceCoordinate = coord
        } else if let element = action.from.findElement(in: app) {
            guard element.waitForExistence(timeout: 5) else {
                throw DriverError.elementNotFound(action.from)
            }
            sourceElement = element
            sourceCoordinate = nil
        } else {
            throw DriverError.invalidTarget(action.from)
        }

        // Get destination element or coordinate
        let destCoordinate: XCUICoordinate

        if let coord = action.to.getCoordinate(in: app) {
            destCoordinate = coord
        } else if let element = action.to.findElement(in: app) {
            guard element.waitForExistence(timeout: 5) else {
                throw DriverError.elementNotFound(action.to)
            }
            destCoordinate = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        } else {
            throw DriverError.invalidTarget(action.to)
        }

        // Perform drag
        if let element = sourceElement {
            element.press(forDuration: duration, thenDragTo: destCoordinate.referencedElement)
        } else if let coord = sourceCoordinate {
            coord.press(forDuration: duration, thenDragTo: destCoordinate)
        }
    }

    private func executeScrollToElement(_ action: ScrollToElementAction) throws {
        guard let targetElement = action.target.findElement(in: app) else {
            throw DriverError.invalidTarget(action.target)
        }

        let scrollContainer: XCUIElement
        if let within = action.within, let container = within.findElement(in: app) {
            scrollContainer = container
        } else {
            scrollContainer = app
        }

        let maxScrolls = action.maxScrolls ?? 10

        for _ in 0..<maxScrolls {
            if targetElement.exists && targetElement.isHittable {
                return // Found and hittable
            }

            switch action.direction.lowercased() {
            case "up":
                scrollContainer.swipeUp()
            case "down":
                scrollContainer.swipeDown()
            case "left":
                scrollContainer.swipeLeft()
            case "right":
                scrollContainer.swipeRight()
            default:
                throw DriverError.invalidSwipeDirection(action.direction)
            }
        }

        // Final check
        guard targetElement.exists else {
            throw DriverError.elementNotFound(action.target)
        }
    }

    private func executeClearText(_ action: ClearTextAction) throws {
        guard let element = action.target.findElement(in: app) else {
            throw DriverError.invalidTarget(action.target)
        }
        guard element.waitForExistence(timeout: 5) else {
            throw DriverError.elementNotFound(action.target)
        }

        // Select all text and delete
        element.tap()
        if let value = element.value as? String, !value.isEmpty {
            // Triple tap to select all (works for most text fields)
            element.tap(withNumberOfTaps: 3, numberOfTouches: 1)
            // Small delay to ensure selection
            Thread.sleep(forTimeInterval: 0.1)
            // Type delete key
            element.typeText(XCUIKeyboardKey.delete.rawValue)
        }
    }

    private func executeShake() throws {
        // XCUIDevice shake is available through XCUIDevice.shared
        XCUIDevice.shared.perform(NSSelectorFromString("shake"))
    }

    private func executeGetElementValue(_ action: GetElementValueAction) throws -> String? {
        guard let element = action.target.findElement(in: app) else {
            throw DriverError.invalidTarget(action.target)
        }
        guard element.waitForExistence(timeout: 5) else {
            throw DriverError.elementNotFound(action.target)
        }

        // Try to get the value - could be String or other types
        if let stringValue = element.value as? String {
            return stringValue
        } else if let value = element.value {
            return String(describing: value)
        }
        // Fall back to label if no value
        return element.label.isEmpty ? nil : element.label
    }

    private func executeGetElementProperties(_ action: GetElementPropertiesAction) throws -> ElementProperties {
        guard let element = action.target.findElement(in: app) else {
            throw DriverError.invalidTarget(action.target)
        }
        guard element.waitForExistence(timeout: 5) else {
            throw DriverError.elementNotFound(action.target)
        }

        return ElementProperties(
            label: element.label.isEmpty ? nil : element.label,
            value: element.value as? String,
            title: element.title.isEmpty ? nil : element.title,
            identifier: element.identifier.isEmpty ? nil : element.identifier,
            isEnabled: element.isEnabled,
            isSelected: element.isSelected,
            placeholderValue: element.placeholderValue
        )
    }

    private func executeGetElementFrame(_ action: GetElementFrameAction) throws -> ElementFrame {
        guard let element = action.target.findElement(in: app) else {
            throw DriverError.invalidTarget(action.target)
        }
        guard element.waitForExistence(timeout: 5) else {
            throw DriverError.elementNotFound(action.target)
        }

        let frame = element.frame
        return ElementFrame(
            x: Double(frame.origin.x),
            y: Double(frame.origin.y),
            width: Double(frame.size.width),
            height: Double(frame.size.height)
        )
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
