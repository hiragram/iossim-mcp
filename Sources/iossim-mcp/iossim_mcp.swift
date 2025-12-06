import Foundation
import MCP
import Core

@main
struct IOSSimMCP {
    static func main() async throws {
        let server = Server(
            name: "iossim-mcp",
            version: "0.1.0"
        )

        let simulatorController = SimulatorController()

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
