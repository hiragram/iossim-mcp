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
                    description: "Tap on an element in the app",
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
                    description: "Type text into an element or the focused field",
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
                    description: "Swipe in a direction on the screen or an element",
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
                    description: "Run a sequence of UI actions on an app",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "bundleId": .object([
                                "type": .string("string"),
                                "description": .string("The bundle identifier of the target app")
                            ]),
                            "actions": .object([
                                "type": .string("array"),
                                "description": .string("Array of actions to perform. Each action has 'type' and action-specific properties.")
                            ]),
                            "simulatorUdid": .object([
                                "type": .string("string"),
                                "description": .string("The UDID of the simulator (optional)")
                            ])
                        ]),
                        "required": .array([.string("bundleId"), .string("actions")])
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

                // Read the screenshot and encode as base64
                let imageData = try Data(contentsOf: tempPath)
                let base64String = imageData.base64EncodedString()

                // Clean up temp file
                try? FileManager.default.removeItem(at: tempPath)

                return CallTool.Result(content: [
                    .image(data: base64String, mimeType: "image/png", metadata: nil)
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
                    runnerAppPath: runnerAppPath
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
                    runnerAppPath: runnerAppPath
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
                    runnerAppPath: runnerAppPath
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

                // Parse actions from JSON
                let actionsData = try JSONEncoder().encode(actionsValue)
                let actions = try JSONDecoder().decode([UITestAction].self, from: actionsData)

                let driver = UITestDriver(
                    xctestrunPath: xctestrunPath,
                    runnerAppPath: runnerAppPath
                )
                let script = UITestScript(bundleId: bundleId, actions: actions)
                let result = try await driver.execute(script: script, simulatorUdid: simulatorUdid)

                let resultJson = try JSONEncoder().encode(result)
                let resultString = String(data: resultJson, encoding: .utf8) ?? "{}"
                return CallTool.Result(content: [.text(resultString)])

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
