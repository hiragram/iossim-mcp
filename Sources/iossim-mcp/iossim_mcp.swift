import Foundation
import MCP
import Core

@main
struct IOSSimMCP {
    static func main() async throws {
        let server = Server(
            name: "iossim-mcp",
            version: "0.1.0",
            capabilities: Server.Capabilities(tools: .init())
        )

        let simulatorController = SimulatorController()

        // Get resource paths for UITest driver
        let xctestrunPath = Bundle.module.url(
            forResource: "SimDriverUITests_SimDriverUITests_iphonesimulator26.0-arm64",
            withExtension: "xctestrun"
        )!
        let runnerAppPath = Bundle.module.url(
            forResource: "SimDriverUITests-Runner",
            withExtension: "app"
        )!
        let hostAppPath = Bundle.module.url(
            forResource: "SimDriverHost",
            withExtension: "app"
        )!

        // Register tool list handler
        await server.withMethodHandler(ListTools.self) { _ in
            ListTools.Result(tools: [
                Tool(
                    name: "list_simulators",
                    description: "List all available iOS simulators",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([:]),
                        "required": .array([])
                    ])
                ),
                Tool(
                    name: "boot_simulator",
                    description: "Boot an iOS simulator",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "udid": .object([
                                "type": .string("string"),
                                "description": .string("The UDID of the simulator to boot")
                            ])
                        ]),
                        "required": .array([.string("udid")])
                    ])
                ),
                Tool(
                    name: "shutdown_simulator",
                    description: "Shutdown an iOS simulator",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "udid": .object([
                                "type": .string("string"),
                                "description": .string("The UDID of the simulator to shutdown")
                            ])
                        ]),
                        "required": .array([.string("udid")])
                    ])
                ),
                Tool(
                    name: "launch_app",
                    description: "Launch an app on a simulator",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "bundleId": .object([
                                "type": .string("string"),
                                "description": .string("The bundle identifier of the app to launch")
                            ]),
                            "simulatorUdid": .object([
                                "type": .string("string"),
                                "description": .string("The UDID of the simulator (optional, uses booted simulator if not specified)")
                            ])
                        ]),
                        "required": .array([.string("bundleId")])
                    ])
                ),
                Tool(
                    name: "terminate_app",
                    description: "Terminate an app on a simulator",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "bundleId": .object([
                                "type": .string("string"),
                                "description": .string("The bundle identifier of the app to terminate")
                            ]),
                            "simulatorUdid": .object([
                                "type": .string("string"),
                                "description": .string("The UDID of the simulator (optional, uses booted simulator if not specified)")
                            ])
                        ]),
                        "required": .array([.string("bundleId")])
                    ])
                ),
                Tool(
                    name: "take_screenshot",
                    description: "Take a screenshot of the simulator",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "simulatorUdid": .object([
                                "type": .string("string"),
                                "description": .string("The UDID of the simulator (optional, uses booted simulator if not specified)")
                            ])
                        ]),
                        "required": .array([])
                    ])
                ),
                Tool(
                    name: "tap",
                    description: "Tap on an element in the app. For multiple actions in sequence, use run_ui_script instead.",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "bundleId": .object([
                                "type": .string("string"),
                                "description": .string("The bundle identifier of the target app")
                            ]),
                            "identifier": .object([
                                "type": .string("string"),
                                "description": .string("The accessibility identifier of the element to tap")
                            ]),
                            "label": .object([
                                "type": .string("string"),
                                "description": .string("The label of the element to tap (alternative to identifier)")
                            ]),
                            "simulatorUdid": .object([
                                "type": .string("string"),
                                "description": .string("The UDID of the simulator (optional)")
                            ])
                        ]),
                        "required": .array([.string("bundleId")])
                    ])
                ),
                Tool(
                    name: "type_text",
                    description: "Type text into an element or the focused field. For multiple actions in sequence, use run_ui_script instead.",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "bundleId": .object([
                                "type": .string("string"),
                                "description": .string("The bundle identifier of the target app")
                            ]),
                            "text": .object([
                                "type": .string("string"),
                                "description": .string("The text to type")
                            ]),
                            "identifier": .object([
                                "type": .string("string"),
                                "description": .string("The accessibility identifier of the element (optional)")
                            ]),
                            "simulatorUdid": .object([
                                "type": .string("string"),
                                "description": .string("The UDID of the simulator (optional)")
                            ])
                        ]),
                        "required": .array([.string("bundleId"), .string("text")])
                    ])
                ),
                Tool(
                    name: "swipe",
                    description: "Swipe in a direction on the screen or an element. For multiple actions in sequence, use run_ui_script instead.",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "bundleId": .object([
                                "type": .string("string"),
                                "description": .string("The bundle identifier of the target app")
                            ]),
                            "direction": .object([
                                "type": .string("string"),
                                "description": .string("The swipe direction: up, down, left, right")
                            ]),
                            "identifier": .object([
                                "type": .string("string"),
                                "description": .string("The accessibility identifier of the element to swipe on (optional)")
                            ]),
                            "simulatorUdid": .object([
                                "type": .string("string"),
                                "description": .string("The UDID of the simulator (optional)")
                            ])
                        ]),
                        "required": .array([.string("bundleId"), .string("direction")])
                    ])
                ),
                Tool(
                    name: "run_ui_script",
                    description: "Run a sequence of UI actions on an app. Supports multiple actions in one call with optional video recording. Preferred over individual tap/type_text/swipe calls when performing multiple actions.",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "bundleId": .object([
                                "type": .string("string"),
                                "description": .string("The bundle identifier of the target app")
                            ]),
                            "actions": .object([
                                "type": .string("array"),
                                "description": .string("Array of actions to perform. Supported types: tap, doubleTap, typeText, swipe, longPress, pinch, rotate, drag, scrollToElement, clearText, shake, waitForElement, assertExists, screenshot, getElementValue, getElementProperties, getElementFrame. Each action requires 'type' and a 'target' object with 'type' (identifier/label/coordinate) and 'value'.")
                            ]),
                            "simulatorUdid": .object([
                                "type": .string("string"),
                                "description": .string("The UDID of the simulator (optional)")
                            ]),
                            "recordVideo": .object([
                                "type": .string("boolean"),
                                "description": .string("If true, record video of the UI actions. The video path will be returned in the result.")
                            ])
                        ]),
                        "required": .array([.string("bundleId"), .string("actions")])
                    ])
                ),
                Tool(
                    name: "long_press",
                    description: "Long press on an element in the app. For multiple actions in sequence, use run_ui_script instead.",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "bundleId": .object([
                                "type": .string("string"),
                                "description": .string("The bundle identifier of the target app")
                            ]),
                            "identifier": .object([
                                "type": .string("string"),
                                "description": .string("The accessibility identifier of the element")
                            ]),
                            "label": .object([
                                "type": .string("string"),
                                "description": .string("The label of the element (alternative to identifier)")
                            ]),
                            "duration": .object([
                                "type": .string("number"),
                                "description": .string("Duration of the press in seconds (default: 1.0)")
                            ]),
                            "simulatorUdid": .object([
                                "type": .string("string"),
                                "description": .string("The UDID of the simulator (optional)")
                            ])
                        ]),
                        "required": .array([.string("bundleId")])
                    ])
                ),
                Tool(
                    name: "double_tap",
                    description: "Double tap on an element in the app. For multiple actions in sequence, use run_ui_script instead.",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "bundleId": .object([
                                "type": .string("string"),
                                "description": .string("The bundle identifier of the target app")
                            ]),
                            "identifier": .object([
                                "type": .string("string"),
                                "description": .string("The accessibility identifier of the element")
                            ]),
                            "label": .object([
                                "type": .string("string"),
                                "description": .string("The label of the element (alternative to identifier)")
                            ]),
                            "simulatorUdid": .object([
                                "type": .string("string"),
                                "description": .string("The UDID of the simulator (optional)")
                            ])
                        ]),
                        "required": .array([.string("bundleId")])
                    ])
                ),
                Tool(
                    name: "pinch",
                    description: "Pinch gesture on an element (zoom in/out). For multiple actions in sequence, use run_ui_script instead.",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "bundleId": .object([
                                "type": .string("string"),
                                "description": .string("The bundle identifier of the target app")
                            ]),
                            "identifier": .object([
                                "type": .string("string"),
                                "description": .string("The accessibility identifier of the element")
                            ]),
                            "label": .object([
                                "type": .string("string"),
                                "description": .string("The label of the element (alternative to identifier)")
                            ]),
                            "scale": .object([
                                "type": .string("number"),
                                "description": .string("Scale factor (>1 to zoom in, <1 to zoom out)")
                            ]),
                            "velocity": .object([
                                "type": .string("number"),
                                "description": .string("Velocity of the pinch gesture")
                            ]),
                            "simulatorUdid": .object([
                                "type": .string("string"),
                                "description": .string("The UDID of the simulator (optional)")
                            ])
                        ]),
                        "required": .array([.string("bundleId"), .string("scale"), .string("velocity")])
                    ])
                ),
                Tool(
                    name: "rotate",
                    description: "Rotate gesture on an element. For multiple actions in sequence, use run_ui_script instead.",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "bundleId": .object([
                                "type": .string("string"),
                                "description": .string("The bundle identifier of the target app")
                            ]),
                            "identifier": .object([
                                "type": .string("string"),
                                "description": .string("The accessibility identifier of the element")
                            ]),
                            "label": .object([
                                "type": .string("string"),
                                "description": .string("The label of the element (alternative to identifier)")
                            ]),
                            "rotation": .object([
                                "type": .string("number"),
                                "description": .string("Rotation angle in radians")
                            ]),
                            "velocity": .object([
                                "type": .string("number"),
                                "description": .string("Velocity of the rotation gesture")
                            ]),
                            "simulatorUdid": .object([
                                "type": .string("string"),
                                "description": .string("The UDID of the simulator (optional)")
                            ])
                        ]),
                        "required": .array([.string("bundleId"), .string("rotation"), .string("velocity")])
                    ])
                ),
                Tool(
                    name: "drag",
                    description: "Drag from one element/coordinate to another. For multiple actions in sequence, use run_ui_script instead.",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "bundleId": .object([
                                "type": .string("string"),
                                "description": .string("The bundle identifier of the target app")
                            ]),
                            "fromIdentifier": .object([
                                "type": .string("string"),
                                "description": .string("The accessibility identifier of the source element")
                            ]),
                            "fromLabel": .object([
                                "type": .string("string"),
                                "description": .string("The label of the source element")
                            ]),
                            "fromX": .object([
                                "type": .string("number"),
                                "description": .string("X coordinate of the source point")
                            ]),
                            "fromY": .object([
                                "type": .string("number"),
                                "description": .string("Y coordinate of the source point")
                            ]),
                            "toIdentifier": .object([
                                "type": .string("string"),
                                "description": .string("The accessibility identifier of the destination element")
                            ]),
                            "toLabel": .object([
                                "type": .string("string"),
                                "description": .string("The label of the destination element")
                            ]),
                            "toX": .object([
                                "type": .string("number"),
                                "description": .string("X coordinate of the destination point")
                            ]),
                            "toY": .object([
                                "type": .string("number"),
                                "description": .string("Y coordinate of the destination point")
                            ]),
                            "duration": .object([
                                "type": .string("number"),
                                "description": .string("Duration of the drag in seconds (default: 0.5)")
                            ]),
                            "simulatorUdid": .object([
                                "type": .string("string"),
                                "description": .string("The UDID of the simulator (optional)")
                            ])
                        ]),
                        "required": .array([.string("bundleId")])
                    ])
                ),
                Tool(
                    name: "scroll_to_element",
                    description: "Scroll until an element becomes visible. For multiple actions in sequence, use run_ui_script instead.",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "bundleId": .object([
                                "type": .string("string"),
                                "description": .string("The bundle identifier of the target app")
                            ]),
                            "identifier": .object([
                                "type": .string("string"),
                                "description": .string("The accessibility identifier of the target element to scroll to")
                            ]),
                            "label": .object([
                                "type": .string("string"),
                                "description": .string("The label of the target element (alternative to identifier)")
                            ]),
                            "withinIdentifier": .object([
                                "type": .string("string"),
                                "description": .string("The accessibility identifier of the scroll container (optional)")
                            ]),
                            "direction": .object([
                                "type": .string("string"),
                                "description": .string("Scroll direction: up, down, left, right (default: down)")
                            ]),
                            "maxScrolls": .object([
                                "type": .string("number"),
                                "description": .string("Maximum number of scroll attempts (default: 10)")
                            ]),
                            "simulatorUdid": .object([
                                "type": .string("string"),
                                "description": .string("The UDID of the simulator (optional)")
                            ])
                        ]),
                        "required": .array([.string("bundleId")])
                    ])
                ),
                Tool(
                    name: "clear_text",
                    description: "Clear text from an input field. For multiple actions in sequence, use run_ui_script instead.",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "bundleId": .object([
                                "type": .string("string"),
                                "description": .string("The bundle identifier of the target app")
                            ]),
                            "identifier": .object([
                                "type": .string("string"),
                                "description": .string("The accessibility identifier of the text field")
                            ]),
                            "label": .object([
                                "type": .string("string"),
                                "description": .string("The label of the text field (alternative to identifier)")
                            ]),
                            "simulatorUdid": .object([
                                "type": .string("string"),
                                "description": .string("The UDID of the simulator (optional)")
                            ])
                        ]),
                        "required": .array([.string("bundleId")])
                    ])
                ),
                Tool(
                    name: "shake",
                    description: "Perform a shake gesture on the device. For multiple actions in sequence, use run_ui_script instead.",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "bundleId": .object([
                                "type": .string("string"),
                                "description": .string("The bundle identifier of the target app")
                            ]),
                            "simulatorUdid": .object([
                                "type": .string("string"),
                                "description": .string("The UDID of the simulator (optional)")
                            ])
                        ]),
                        "required": .array([.string("bundleId")])
                    ])
                ),
                Tool(
                    name: "wait_for_element",
                    description: "Wait for an element to appear. For multiple actions in sequence, use run_ui_script instead.",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "bundleId": .object([
                                "type": .string("string"),
                                "description": .string("The bundle identifier of the target app")
                            ]),
                            "identifier": .object([
                                "type": .string("string"),
                                "description": .string("The accessibility identifier of the element")
                            ]),
                            "label": .object([
                                "type": .string("string"),
                                "description": .string("The label of the element (alternative to identifier)")
                            ]),
                            "timeout": .object([
                                "type": .string("number"),
                                "description": .string("Timeout in seconds (default: 10)")
                            ]),
                            "simulatorUdid": .object([
                                "type": .string("string"),
                                "description": .string("The UDID of the simulator (optional)")
                            ])
                        ]),
                        "required": .array([.string("bundleId")])
                    ])
                ),
                Tool(
                    name: "assert_exists",
                    description: "Assert that an element exists. For multiple actions in sequence, use run_ui_script instead.",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "bundleId": .object([
                                "type": .string("string"),
                                "description": .string("The bundle identifier of the target app")
                            ]),
                            "identifier": .object([
                                "type": .string("string"),
                                "description": .string("The accessibility identifier of the element")
                            ]),
                            "label": .object([
                                "type": .string("string"),
                                "description": .string("The label of the element (alternative to identifier)")
                            ]),
                            "simulatorUdid": .object([
                                "type": .string("string"),
                                "description": .string("The UDID of the simulator (optional)")
                            ])
                        ]),
                        "required": .array([.string("bundleId")])
                    ])
                ),
                Tool(
                    name: "get_element_value",
                    description: "Get the value/text of a UI element. Returns the element's value property (e.g., text field content) or label.",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "bundleId": .object([
                                "type": .string("string"),
                                "description": .string("The bundle identifier of the target app")
                            ]),
                            "identifier": .object([
                                "type": .string("string"),
                                "description": .string("The accessibility identifier of the element")
                            ]),
                            "label": .object([
                                "type": .string("string"),
                                "description": .string("The label of the element (alternative to identifier)")
                            ]),
                            "simulatorUdid": .object([
                                "type": .string("string"),
                                "description": .string("The UDID of the simulator (optional)")
                            ])
                        ]),
                        "required": .array([.string("bundleId")])
                    ])
                ),
                Tool(
                    name: "get_element_properties",
                    description: "Get all properties of a UI element including label, value, title, identifier, isEnabled, isSelected, and placeholderValue.",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "bundleId": .object([
                                "type": .string("string"),
                                "description": .string("The bundle identifier of the target app")
                            ]),
                            "identifier": .object([
                                "type": .string("string"),
                                "description": .string("The accessibility identifier of the element")
                            ]),
                            "label": .object([
                                "type": .string("string"),
                                "description": .string("The label of the element (alternative to identifier)")
                            ]),
                            "simulatorUdid": .object([
                                "type": .string("string"),
                                "description": .string("The UDID of the simulator (optional)")
                            ])
                        ]),
                        "required": .array([.string("bundleId")])
                    ])
                ),
                Tool(
                    name: "get_element_frame",
                    description: "Get the position and size (frame) of a UI element. Returns x, y, width, and height.",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "bundleId": .object([
                                "type": .string("string"),
                                "description": .string("The bundle identifier of the target app")
                            ]),
                            "identifier": .object([
                                "type": .string("string"),
                                "description": .string("The accessibility identifier of the element")
                            ]),
                            "label": .object([
                                "type": .string("string"),
                                "description": .string("The label of the element (alternative to identifier)")
                            ]),
                            "simulatorUdid": .object([
                                "type": .string("string"),
                                "description": .string("The UDID of the simulator (optional)")
                            ])
                        ]),
                        "required": .array([.string("bundleId")])
                    ])
                )
            ])
        }

        // Register tool call handler
        await server.withMethodHandler(CallTool.self) { params in
            switch params.name {
            case "list_simulators":
                let simulators = try await simulatorController.listSimulators()
                let json = try JSONEncoder().encode(simulators)
                let jsonString = String(data: json, encoding: .utf8) ?? "[]"
                return CallTool.Result(content: [.text(jsonString)])

            case "boot_simulator":
                guard let udid = params.arguments?["udid"]?.stringValue else {
                    return CallTool.Result(content: [.text("Error: udid is required")], isError: true)
                }
                try await simulatorController.bootSimulator(udid: udid)
                // Ensure host app is installed for UI testing
                try await simulatorController.ensureHostAppInstalled(hostAppPath: hostAppPath, simulatorUdid: udid)
                return CallTool.Result(content: [.text("Simulator \(udid) booted successfully")])

            case "shutdown_simulator":
                guard let udid = params.arguments?["udid"]?.stringValue else {
                    return CallTool.Result(content: [.text("Error: udid is required")], isError: true)
                }
                try await simulatorController.shutdownSimulator(udid: udid)
                return CallTool.Result(content: [.text("Simulator \(udid) shutdown successfully")])

            case "launch_app":
                guard let bundleId = params.arguments?["bundleId"]?.stringValue else {
                    return CallTool.Result(content: [.text("Error: bundleId is required")], isError: true)
                }
                let simulatorUdid: String
                if let udid = params.arguments?["simulatorUdid"]?.stringValue {
                    simulatorUdid = udid
                } else if let booted = try await simulatorController.getBootedSimulator() {
                    simulatorUdid = booted.udid
                } else {
                    return CallTool.Result(content: [.text("Error: No booted simulator found")], isError: true)
                }
                // Ensure host app is installed for UI testing
                try await simulatorController.ensureHostAppInstalled(hostAppPath: hostAppPath, simulatorUdid: simulatorUdid)
                try await simulatorController.launchApp(bundleId: bundleId, simulatorUdid: simulatorUdid)
                return CallTool.Result(content: [.text("App \(bundleId) launched on \(simulatorUdid)")])

            case "terminate_app":
                guard let bundleId = params.arguments?["bundleId"]?.stringValue else {
                    return CallTool.Result(content: [.text("Error: bundleId is required")], isError: true)
                }
                let simulatorUdid: String
                if let udid = params.arguments?["simulatorUdid"]?.stringValue {
                    simulatorUdid = udid
                } else if let booted = try await simulatorController.getBootedSimulator() {
                    simulatorUdid = booted.udid
                } else {
                    return CallTool.Result(content: [.text("Error: No booted simulator found")], isError: true)
                }
                try await simulatorController.terminateApp(bundleId: bundleId, simulatorUdid: simulatorUdid)
                return CallTool.Result(content: [.text("App \(bundleId) terminated on \(simulatorUdid)")])

            case "take_screenshot":
                let simulatorUdid: String
                if let udid = params.arguments?["simulatorUdid"]?.stringValue {
                    simulatorUdid = udid
                } else if let booted = try await simulatorController.getBootedSimulator() {
                    simulatorUdid = booted.udid
                } else {
                    return CallTool.Result(content: [.text("Error: No booted simulator found")], isError: true)
                }

                let tempPath = FileManager.default.temporaryDirectory
                    .appendingPathComponent("screenshot-\(UUID().uuidString).png")
                try await simulatorController.takeScreenshot(simulatorUdid: simulatorUdid, outputPath: tempPath.path)

                // Resize and compress the image
                let imageProcessor = ImageProcessor(maxWidth: 500, maxFileSize: 256 * 1024)
                let jpegData = try imageProcessor.processImage(at: tempPath)

                // Clean up original temp file
                try? FileManager.default.removeItem(at: tempPath)

                // Save compressed image to /tmp
                let outputPath = "/tmp/iossim-screenshot-\(UUID().uuidString).jpg"
                try jpegData.write(to: URL(fileURLWithPath: outputPath))

                return CallTool.Result(content: [
                    .text("Screenshot saved to: \(outputPath)")
                ])

            case "tap":
                guard let bundleId = params.arguments?["bundleId"]?.stringValue else {
                    return CallTool.Result(content: [.text("Error: bundleId is required")], isError: true)
                }
                let simulatorUdid: String
                if let udid = params.arguments?["simulatorUdid"]?.stringValue {
                    simulatorUdid = udid
                } else if let booted = try await simulatorController.getBootedSimulator() {
                    simulatorUdid = booted.udid
                } else {
                    return CallTool.Result(content: [.text("Error: No booted simulator found")], isError: true)
                }

                let target: ElementTarget
                if let identifier = params.arguments?["identifier"]?.stringValue {
                    target = .identifier(identifier)
                } else if let label = params.arguments?["label"]?.stringValue {
                    target = .label(label)
                } else {
                    return CallTool.Result(content: [.text("Error: Either identifier or label is required")], isError: true)
                }

                let driver = UITestDriver(
                    xctestrunPath: xctestrunPath,
                    runnerAppPath: runnerAppPath,
                    hostAppPath: hostAppPath
                )
                let script = UITestScript(bundleId: bundleId, actions: [.tap(target: target)])
                let result = try await driver.execute(script: script, simulatorUdid: simulatorUdid)

                if result.success {
                    return CallTool.Result(content: [.text("Tap executed successfully")])
                } else {
                    return CallTool.Result(content: [.text("Tap failed: \(result.error ?? "Unknown error")")], isError: true)
                }

            case "type_text":
                guard let bundleId = params.arguments?["bundleId"]?.stringValue else {
                    return CallTool.Result(content: [.text("Error: bundleId is required")], isError: true)
                }
                guard let text = params.arguments?["text"]?.stringValue else {
                    return CallTool.Result(content: [.text("Error: text is required")], isError: true)
                }
                let simulatorUdid: String
                if let udid = params.arguments?["simulatorUdid"]?.stringValue {
                    simulatorUdid = udid
                } else if let booted = try await simulatorController.getBootedSimulator() {
                    simulatorUdid = booted.udid
                } else {
                    return CallTool.Result(content: [.text("Error: No booted simulator found")], isError: true)
                }

                let target: ElementTarget? = params.arguments?["identifier"]?.stringValue.map { .identifier($0) }

                let driver = UITestDriver(
                    xctestrunPath: xctestrunPath,
                    runnerAppPath: runnerAppPath,
                    hostAppPath: hostAppPath
                )
                let script = UITestScript(bundleId: bundleId, actions: [.typeText(text: text, target: target)])
                let result = try await driver.execute(script: script, simulatorUdid: simulatorUdid)

                if result.success {
                    return CallTool.Result(content: [.text("Type text executed successfully")])
                } else {
                    return CallTool.Result(content: [.text("Type text failed: \(result.error ?? "Unknown error")")], isError: true)
                }

            case "swipe":
                guard let bundleId = params.arguments?["bundleId"]?.stringValue else {
                    return CallTool.Result(content: [.text("Error: bundleId is required")], isError: true)
                }
                guard let directionStr = params.arguments?["direction"]?.stringValue,
                      let direction = SwipeDirection(rawValue: directionStr) else {
                    return CallTool.Result(content: [.text("Error: direction is required (up, down, left, right)")], isError: true)
                }
                let simulatorUdid: String
                if let udid = params.arguments?["simulatorUdid"]?.stringValue {
                    simulatorUdid = udid
                } else if let booted = try await simulatorController.getBootedSimulator() {
                    simulatorUdid = booted.udid
                } else {
                    return CallTool.Result(content: [.text("Error: No booted simulator found")], isError: true)
                }

                let target: ElementTarget? = params.arguments?["identifier"]?.stringValue.map { .identifier($0) }

                let driver = UITestDriver(
                    xctestrunPath: xctestrunPath,
                    runnerAppPath: runnerAppPath,
                    hostAppPath: hostAppPath
                )
                let script = UITestScript(bundleId: bundleId, actions: [.swipe(direction: direction, target: target)])
                let result = try await driver.execute(script: script, simulatorUdid: simulatorUdid)

                if result.success {
                    return CallTool.Result(content: [.text("Swipe executed successfully")])
                } else {
                    return CallTool.Result(content: [.text("Swipe failed: \(result.error ?? "Unknown error")")], isError: true)
                }

            case "run_ui_script":
                guard let bundleId = params.arguments?["bundleId"]?.stringValue else {
                    return CallTool.Result(content: [.text("Error: bundleId is required")], isError: true)
                }
                guard let actionsValue = params.arguments?["actions"] else {
                    return CallTool.Result(content: [.text("Error: actions is required")], isError: true)
                }
                let simulatorUdid: String
                if let udid = params.arguments?["simulatorUdid"]?.stringValue {
                    simulatorUdid = udid
                } else if let booted = try await simulatorController.getBootedSimulator() {
                    simulatorUdid = booted.udid
                } else {
                    return CallTool.Result(content: [.text("Error: No booted simulator found")], isError: true)
                }

                // Parse recordVideo option
                let recordVideo = params.arguments?["recordVideo"]?.boolValue ?? false

                // Parse actions from JSON
                let actionsData = try JSONEncoder().encode(actionsValue)
                let actions = try JSONDecoder().decode([UITestAction].self, from: actionsData)

                let driver = UITestDriver(
                    xctestrunPath: xctestrunPath,
                    runnerAppPath: runnerAppPath,
                    hostAppPath: hostAppPath
                )
                let script = UITestScript(bundleId: bundleId, actions: actions, recordVideo: recordVideo)
                let result = try await driver.execute(script: script, simulatorUdid: simulatorUdid)

                let resultJson = try JSONEncoder().encode(result)
                let resultString = String(data: resultJson, encoding: .utf8) ?? "{}"
                return CallTool.Result(content: [.text(resultString)])

            case "long_press":
                guard let bundleId = params.arguments?["bundleId"]?.stringValue else {
                    return CallTool.Result(content: [.text("Error: bundleId is required")], isError: true)
                }
                let simulatorUdid: String
                if let udid = params.arguments?["simulatorUdid"]?.stringValue {
                    simulatorUdid = udid
                } else if let booted = try await simulatorController.getBootedSimulator() {
                    simulatorUdid = booted.udid
                } else {
                    return CallTool.Result(content: [.text("Error: No booted simulator found")], isError: true)
                }

                let target: ElementTarget
                if let identifier = params.arguments?["identifier"]?.stringValue {
                    target = .identifier(identifier)
                } else if let label = params.arguments?["label"]?.stringValue {
                    target = .label(label)
                } else {
                    return CallTool.Result(content: [.text("Error: Either identifier or label is required")], isError: true)
                }

                let duration = params.arguments?["duration"]?.doubleValue

                let driver = UITestDriver(
                    xctestrunPath: xctestrunPath,
                    runnerAppPath: runnerAppPath,
                    hostAppPath: hostAppPath
                )
                let script = UITestScript(bundleId: bundleId, actions: [.longPress(target: target, duration: duration)])
                let result = try await driver.execute(script: script, simulatorUdid: simulatorUdid)

                if result.success {
                    return CallTool.Result(content: [.text("Long press executed successfully")])
                } else {
                    return CallTool.Result(content: [.text("Long press failed: \(result.error ?? "Unknown error")")], isError: true)
                }

            case "double_tap":
                guard let bundleId = params.arguments?["bundleId"]?.stringValue else {
                    return CallTool.Result(content: [.text("Error: bundleId is required")], isError: true)
                }
                let simulatorUdid: String
                if let udid = params.arguments?["simulatorUdid"]?.stringValue {
                    simulatorUdid = udid
                } else if let booted = try await simulatorController.getBootedSimulator() {
                    simulatorUdid = booted.udid
                } else {
                    return CallTool.Result(content: [.text("Error: No booted simulator found")], isError: true)
                }

                let target: ElementTarget
                if let identifier = params.arguments?["identifier"]?.stringValue {
                    target = .identifier(identifier)
                } else if let label = params.arguments?["label"]?.stringValue {
                    target = .label(label)
                } else {
                    return CallTool.Result(content: [.text("Error: Either identifier or label is required")], isError: true)
                }

                let driver = UITestDriver(
                    xctestrunPath: xctestrunPath,
                    runnerAppPath: runnerAppPath,
                    hostAppPath: hostAppPath
                )
                let script = UITestScript(bundleId: bundleId, actions: [.doubleTap(target: target)])
                let result = try await driver.execute(script: script, simulatorUdid: simulatorUdid)

                if result.success {
                    return CallTool.Result(content: [.text("Double tap executed successfully")])
                } else {
                    return CallTool.Result(content: [.text("Double tap failed: \(result.error ?? "Unknown error")")], isError: true)
                }

            case "pinch":
                guard let bundleId = params.arguments?["bundleId"]?.stringValue else {
                    return CallTool.Result(content: [.text("Error: bundleId is required")], isError: true)
                }
                guard let scale = params.arguments?["scale"]?.doubleValue else {
                    return CallTool.Result(content: [.text("Error: scale is required")], isError: true)
                }
                guard let velocity = params.arguments?["velocity"]?.doubleValue else {
                    return CallTool.Result(content: [.text("Error: velocity is required")], isError: true)
                }
                let simulatorUdid: String
                if let udid = params.arguments?["simulatorUdid"]?.stringValue {
                    simulatorUdid = udid
                } else if let booted = try await simulatorController.getBootedSimulator() {
                    simulatorUdid = booted.udid
                } else {
                    return CallTool.Result(content: [.text("Error: No booted simulator found")], isError: true)
                }

                let target: ElementTarget
                if let identifier = params.arguments?["identifier"]?.stringValue {
                    target = .identifier(identifier)
                } else if let label = params.arguments?["label"]?.stringValue {
                    target = .label(label)
                } else {
                    return CallTool.Result(content: [.text("Error: Either identifier or label is required")], isError: true)
                }

                let driver = UITestDriver(
                    xctestrunPath: xctestrunPath,
                    runnerAppPath: runnerAppPath,
                    hostAppPath: hostAppPath
                )
                let script = UITestScript(bundleId: bundleId, actions: [.pinch(target: target, scale: scale, velocity: velocity)])
                let result = try await driver.execute(script: script, simulatorUdid: simulatorUdid)

                if result.success {
                    return CallTool.Result(content: [.text("Pinch executed successfully")])
                } else {
                    return CallTool.Result(content: [.text("Pinch failed: \(result.error ?? "Unknown error")")], isError: true)
                }

            case "rotate":
                guard let bundleId = params.arguments?["bundleId"]?.stringValue else {
                    return CallTool.Result(content: [.text("Error: bundleId is required")], isError: true)
                }
                guard let rotation = params.arguments?["rotation"]?.doubleValue else {
                    return CallTool.Result(content: [.text("Error: rotation is required")], isError: true)
                }
                guard let velocity = params.arguments?["velocity"]?.doubleValue else {
                    return CallTool.Result(content: [.text("Error: velocity is required")], isError: true)
                }
                let simulatorUdid: String
                if let udid = params.arguments?["simulatorUdid"]?.stringValue {
                    simulatorUdid = udid
                } else if let booted = try await simulatorController.getBootedSimulator() {
                    simulatorUdid = booted.udid
                } else {
                    return CallTool.Result(content: [.text("Error: No booted simulator found")], isError: true)
                }

                let target: ElementTarget
                if let identifier = params.arguments?["identifier"]?.stringValue {
                    target = .identifier(identifier)
                } else if let label = params.arguments?["label"]?.stringValue {
                    target = .label(label)
                } else {
                    return CallTool.Result(content: [.text("Error: Either identifier or label is required")], isError: true)
                }

                let driver = UITestDriver(
                    xctestrunPath: xctestrunPath,
                    runnerAppPath: runnerAppPath,
                    hostAppPath: hostAppPath
                )
                let script = UITestScript(bundleId: bundleId, actions: [.rotate(target: target, rotation: rotation, velocity: velocity)])
                let result = try await driver.execute(script: script, simulatorUdid: simulatorUdid)

                if result.success {
                    return CallTool.Result(content: [.text("Rotate executed successfully")])
                } else {
                    return CallTool.Result(content: [.text("Rotate failed: \(result.error ?? "Unknown error")")], isError: true)
                }

            case "drag":
                guard let bundleId = params.arguments?["bundleId"]?.stringValue else {
                    return CallTool.Result(content: [.text("Error: bundleId is required")], isError: true)
                }
                let simulatorUdid: String
                if let udid = params.arguments?["simulatorUdid"]?.stringValue {
                    simulatorUdid = udid
                } else if let booted = try await simulatorController.getBootedSimulator() {
                    simulatorUdid = booted.udid
                } else {
                    return CallTool.Result(content: [.text("Error: No booted simulator found")], isError: true)
                }

                let fromTarget: ElementTarget
                if let identifier = params.arguments?["fromIdentifier"]?.stringValue {
                    fromTarget = .identifier(identifier)
                } else if let label = params.arguments?["fromLabel"]?.stringValue {
                    fromTarget = .label(label)
                } else if let x = params.arguments?["fromX"]?.intValue, let y = params.arguments?["fromY"]?.intValue {
                    fromTarget = .coordinate(x: x, y: y)
                } else {
                    return CallTool.Result(content: [.text("Error: Source (fromIdentifier, fromLabel, or fromX/fromY) is required")], isError: true)
                }

                let toTarget: ElementTarget
                if let identifier = params.arguments?["toIdentifier"]?.stringValue {
                    toTarget = .identifier(identifier)
                } else if let label = params.arguments?["toLabel"]?.stringValue {
                    toTarget = .label(label)
                } else if let x = params.arguments?["toX"]?.intValue, let y = params.arguments?["toY"]?.intValue {
                    toTarget = .coordinate(x: x, y: y)
                } else {
                    return CallTool.Result(content: [.text("Error: Destination (toIdentifier, toLabel, or toX/toY) is required")], isError: true)
                }

                let duration = params.arguments?["duration"]?.doubleValue

                let driver = UITestDriver(
                    xctestrunPath: xctestrunPath,
                    runnerAppPath: runnerAppPath,
                    hostAppPath: hostAppPath
                )
                let script = UITestScript(bundleId: bundleId, actions: [.drag(from: fromTarget, to: toTarget, duration: duration)])
                let result = try await driver.execute(script: script, simulatorUdid: simulatorUdid)

                if result.success {
                    return CallTool.Result(content: [.text("Drag executed successfully")])
                } else {
                    return CallTool.Result(content: [.text("Drag failed: \(result.error ?? "Unknown error")")], isError: true)
                }

            case "scroll_to_element":
                guard let bundleId = params.arguments?["bundleId"]?.stringValue else {
                    return CallTool.Result(content: [.text("Error: bundleId is required")], isError: true)
                }
                let simulatorUdid: String
                if let udid = params.arguments?["simulatorUdid"]?.stringValue {
                    simulatorUdid = udid
                } else if let booted = try await simulatorController.getBootedSimulator() {
                    simulatorUdid = booted.udid
                } else {
                    return CallTool.Result(content: [.text("Error: No booted simulator found")], isError: true)
                }

                let target: ElementTarget
                if let identifier = params.arguments?["identifier"]?.stringValue {
                    target = .identifier(identifier)
                } else if let label = params.arguments?["label"]?.stringValue {
                    target = .label(label)
                } else {
                    return CallTool.Result(content: [.text("Error: Either identifier or label is required")], isError: true)
                }

                let within: ElementTarget? = params.arguments?["withinIdentifier"]?.stringValue.map { .identifier($0) }
                let directionStr = params.arguments?["direction"]?.stringValue ?? "down"
                let direction = SwipeDirection(rawValue: directionStr) ?? .down
                let maxScrolls = params.arguments?["maxScrolls"]?.intValue

                let driver = UITestDriver(
                    xctestrunPath: xctestrunPath,
                    runnerAppPath: runnerAppPath,
                    hostAppPath: hostAppPath
                )
                let script = UITestScript(bundleId: bundleId, actions: [.scrollToElement(target: target, within: within, direction: direction, maxScrolls: maxScrolls)])
                let result = try await driver.execute(script: script, simulatorUdid: simulatorUdid)

                if result.success {
                    return CallTool.Result(content: [.text("Scroll to element executed successfully")])
                } else {
                    return CallTool.Result(content: [.text("Scroll to element failed: \(result.error ?? "Unknown error")")], isError: true)
                }

            case "clear_text":
                guard let bundleId = params.arguments?["bundleId"]?.stringValue else {
                    return CallTool.Result(content: [.text("Error: bundleId is required")], isError: true)
                }
                let simulatorUdid: String
                if let udid = params.arguments?["simulatorUdid"]?.stringValue {
                    simulatorUdid = udid
                } else if let booted = try await simulatorController.getBootedSimulator() {
                    simulatorUdid = booted.udid
                } else {
                    return CallTool.Result(content: [.text("Error: No booted simulator found")], isError: true)
                }

                let target: ElementTarget
                if let identifier = params.arguments?["identifier"]?.stringValue {
                    target = .identifier(identifier)
                } else if let label = params.arguments?["label"]?.stringValue {
                    target = .label(label)
                } else {
                    return CallTool.Result(content: [.text("Error: Either identifier or label is required")], isError: true)
                }

                let driver = UITestDriver(
                    xctestrunPath: xctestrunPath,
                    runnerAppPath: runnerAppPath,
                    hostAppPath: hostAppPath
                )
                let script = UITestScript(bundleId: bundleId, actions: [.clearText(target: target)])
                let result = try await driver.execute(script: script, simulatorUdid: simulatorUdid)

                if result.success {
                    return CallTool.Result(content: [.text("Clear text executed successfully")])
                } else {
                    return CallTool.Result(content: [.text("Clear text failed: \(result.error ?? "Unknown error")")], isError: true)
                }

            case "shake":
                guard let bundleId = params.arguments?["bundleId"]?.stringValue else {
                    return CallTool.Result(content: [.text("Error: bundleId is required")], isError: true)
                }
                let simulatorUdid: String
                if let udid = params.arguments?["simulatorUdid"]?.stringValue {
                    simulatorUdid = udid
                } else if let booted = try await simulatorController.getBootedSimulator() {
                    simulatorUdid = booted.udid
                } else {
                    return CallTool.Result(content: [.text("Error: No booted simulator found")], isError: true)
                }

                let driver = UITestDriver(
                    xctestrunPath: xctestrunPath,
                    runnerAppPath: runnerAppPath,
                    hostAppPath: hostAppPath
                )
                let script = UITestScript(bundleId: bundleId, actions: [.shake])
                let result = try await driver.execute(script: script, simulatorUdid: simulatorUdid)

                if result.success {
                    return CallTool.Result(content: [.text("Shake executed successfully")])
                } else {
                    return CallTool.Result(content: [.text("Shake failed: \(result.error ?? "Unknown error")")], isError: true)
                }

            case "wait_for_element":
                guard let bundleId = params.arguments?["bundleId"]?.stringValue else {
                    return CallTool.Result(content: [.text("Error: bundleId is required")], isError: true)
                }
                let simulatorUdid: String
                if let udid = params.arguments?["simulatorUdid"]?.stringValue {
                    simulatorUdid = udid
                } else if let booted = try await simulatorController.getBootedSimulator() {
                    simulatorUdid = booted.udid
                } else {
                    return CallTool.Result(content: [.text("Error: No booted simulator found")], isError: true)
                }

                let target: ElementTarget
                if let identifier = params.arguments?["identifier"]?.stringValue {
                    target = .identifier(identifier)
                } else if let label = params.arguments?["label"]?.stringValue {
                    target = .label(label)
                } else {
                    return CallTool.Result(content: [.text("Error: Either identifier or label is required")], isError: true)
                }

                let timeout = params.arguments?["timeout"]?.doubleValue

                let driver = UITestDriver(
                    xctestrunPath: xctestrunPath,
                    runnerAppPath: runnerAppPath,
                    hostAppPath: hostAppPath
                )
                let script = UITestScript(bundleId: bundleId, actions: [.waitForElement(target: target, timeout: timeout)])
                let result = try await driver.execute(script: script, simulatorUdid: simulatorUdid)

                if result.success {
                    return CallTool.Result(content: [.text("Element found")])
                } else {
                    return CallTool.Result(content: [.text("Wait for element failed: \(result.error ?? "Element not found")")], isError: true)
                }

            case "assert_exists":
                guard let bundleId = params.arguments?["bundleId"]?.stringValue else {
                    return CallTool.Result(content: [.text("Error: bundleId is required")], isError: true)
                }
                let simulatorUdid: String
                if let udid = params.arguments?["simulatorUdid"]?.stringValue {
                    simulatorUdid = udid
                } else if let booted = try await simulatorController.getBootedSimulator() {
                    simulatorUdid = booted.udid
                } else {
                    return CallTool.Result(content: [.text("Error: No booted simulator found")], isError: true)
                }

                let target: ElementTarget
                if let identifier = params.arguments?["identifier"]?.stringValue {
                    target = .identifier(identifier)
                } else if let label = params.arguments?["label"]?.stringValue {
                    target = .label(label)
                } else {
                    return CallTool.Result(content: [.text("Error: Either identifier or label is required")], isError: true)
                }

                let driver = UITestDriver(
                    xctestrunPath: xctestrunPath,
                    runnerAppPath: runnerAppPath,
                    hostAppPath: hostAppPath
                )
                let script = UITestScript(bundleId: bundleId, actions: [.assertExists(target: target)])
                let result = try await driver.execute(script: script, simulatorUdid: simulatorUdid)

                if result.success {
                    return CallTool.Result(content: [.text("Element exists")])
                } else {
                    return CallTool.Result(content: [.text("Assert exists failed: \(result.error ?? "Element does not exist")")], isError: true)
                }

            case "get_element_value":
                guard let bundleId = params.arguments?["bundleId"]?.stringValue else {
                    return CallTool.Result(content: [.text("Error: bundleId is required")], isError: true)
                }
                let simulatorUdid: String
                if let udid = params.arguments?["simulatorUdid"]?.stringValue {
                    simulatorUdid = udid
                } else if let booted = try await simulatorController.getBootedSimulator() {
                    simulatorUdid = booted.udid
                } else {
                    return CallTool.Result(content: [.text("Error: No booted simulator found")], isError: true)
                }

                let target: ElementTarget
                if let identifier = params.arguments?["identifier"]?.stringValue {
                    target = .identifier(identifier)
                } else if let label = params.arguments?["label"]?.stringValue {
                    target = .label(label)
                } else {
                    return CallTool.Result(content: [.text("Error: Either identifier or label is required")], isError: true)
                }

                let driver = UITestDriver(
                    xctestrunPath: xctestrunPath,
                    runnerAppPath: runnerAppPath,
                    hostAppPath: hostAppPath
                )
                let script = UITestScript(bundleId: bundleId, actions: [.getElementValue(target: target)])
                let result = try await driver.execute(script: script, simulatorUdid: simulatorUdid)

                if result.success {
                    let value = result.results.first?.value ?? "null"
                    return CallTool.Result(content: [.text(value)])
                } else {
                    return CallTool.Result(content: [.text("Get element value failed: \(result.error ?? "Unknown error")")], isError: true)
                }

            case "get_element_properties":
                guard let bundleId = params.arguments?["bundleId"]?.stringValue else {
                    return CallTool.Result(content: [.text("Error: bundleId is required")], isError: true)
                }
                let simulatorUdid: String
                if let udid = params.arguments?["simulatorUdid"]?.stringValue {
                    simulatorUdid = udid
                } else if let booted = try await simulatorController.getBootedSimulator() {
                    simulatorUdid = booted.udid
                } else {
                    return CallTool.Result(content: [.text("Error: No booted simulator found")], isError: true)
                }

                let target: ElementTarget
                if let identifier = params.arguments?["identifier"]?.stringValue {
                    target = .identifier(identifier)
                } else if let label = params.arguments?["label"]?.stringValue {
                    target = .label(label)
                } else {
                    return CallTool.Result(content: [.text("Error: Either identifier or label is required")], isError: true)
                }

                let driver = UITestDriver(
                    xctestrunPath: xctestrunPath,
                    runnerAppPath: runnerAppPath,
                    hostAppPath: hostAppPath
                )
                let script = UITestScript(bundleId: bundleId, actions: [.getElementProperties(target: target)])
                let result = try await driver.execute(script: script, simulatorUdid: simulatorUdid)

                if result.success {
                    if let properties = result.results.first?.properties {
                        let encoder = JSONEncoder()
                        encoder.outputFormatting = .prettyPrinted
                        let json = try encoder.encode(properties)
                        return CallTool.Result(content: [.text(String(data: json, encoding: .utf8) ?? "{}")])
                    } else {
                        return CallTool.Result(content: [.text("{}")], isError: true)
                    }
                } else {
                    return CallTool.Result(content: [.text("Get element properties failed: \(result.error ?? "Unknown error")")], isError: true)
                }

            case "get_element_frame":
                guard let bundleId = params.arguments?["bundleId"]?.stringValue else {
                    return CallTool.Result(content: [.text("Error: bundleId is required")], isError: true)
                }
                let simulatorUdid: String
                if let udid = params.arguments?["simulatorUdid"]?.stringValue {
                    simulatorUdid = udid
                } else if let booted = try await simulatorController.getBootedSimulator() {
                    simulatorUdid = booted.udid
                } else {
                    return CallTool.Result(content: [.text("Error: No booted simulator found")], isError: true)
                }

                let target: ElementTarget
                if let identifier = params.arguments?["identifier"]?.stringValue {
                    target = .identifier(identifier)
                } else if let label = params.arguments?["label"]?.stringValue {
                    target = .label(label)
                } else {
                    return CallTool.Result(content: [.text("Error: Either identifier or label is required")], isError: true)
                }

                let driver = UITestDriver(
                    xctestrunPath: xctestrunPath,
                    runnerAppPath: runnerAppPath,
                    hostAppPath: hostAppPath
                )
                let script = UITestScript(bundleId: bundleId, actions: [.getElementFrame(target: target)])
                let result = try await driver.execute(script: script, simulatorUdid: simulatorUdid)

                if result.success {
                    if let frame = result.results.first?.frame {
                        let encoder = JSONEncoder()
                        encoder.outputFormatting = .prettyPrinted
                        let json = try encoder.encode(frame)
                        return CallTool.Result(content: [.text(String(data: json, encoding: .utf8) ?? "{}")])
                    } else {
                        return CallTool.Result(content: [.text("{}")], isError: true)
                    }
                } else {
                    return CallTool.Result(content: [.text("Get element frame failed: \(result.error ?? "Unknown error")")], isError: true)
                }

            default:
                return CallTool.Result(content: [.text("Unknown tool: \(params.name)")], isError: true)
            }
        }

        // Start the server with stdio transport
        let transport = StdioTransport()
        try await server.start(transport: transport)
        await server.waitUntilCompleted()
    }
}
