import Foundation

/// Simulator state
public enum SimulatorState: String, Codable, Sendable {
    case booted = "Booted"
    case shutdown = "Shutdown"
    case shuttingDown = "Shutting Down"
    case unknown

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = SimulatorState(rawValue: rawValue) ?? .unknown
    }
}

/// Simulator device information
public struct Simulator: Codable, Sendable {
    public let udid: String
    public let name: String
    public let state: SimulatorState
    public let isAvailable: Bool

    public init(udid: String, name: String, state: SimulatorState, isAvailable: Bool) {
        self.udid = udid
        self.name = name
        self.state = state
        self.isAvailable = isAvailable
    }
}

/// Controls iOS Simulators via simctl
public struct SimulatorController: Sendable {
    private let processRunner: ProcessRunner
    private let xcrunPath: String

    public init(processRunner: ProcessRunner = DefaultProcessRunner(), xcrunPath: String = "/usr/bin/xcrun") {
        self.processRunner = processRunner
        self.xcrunPath = xcrunPath
    }

    /// Lists all available simulators
    public func listSimulators() async throws -> [Simulator] {
        let result = try await processRunner.run(
            executable: xcrunPath,
            arguments: ["simctl", "list", "devices", "-j"]
        )

        guard result.success else {
            throw SimulatorError.commandFailed(result.stderr)
        }

        let data = Data(result.stdout.utf8)
        let response = try JSONDecoder().decode(SimctlDevicesResponse.self, from: data)

        var simulators: [Simulator] = []
        for (_, devices) in response.devices {
            simulators.append(contentsOf: devices.filter { $0.isAvailable })
        }
        return simulators
    }

    /// Gets the currently booted simulator, if any
    public func getBootedSimulator() async throws -> Simulator? {
        let simulators = try await listSimulators()
        return simulators.first { $0.state == .booted }
    }

    /// Boots a simulator
    public func bootSimulator(udid: String) async throws {
        let result = try await processRunner.run(
            executable: xcrunPath,
            arguments: ["simctl", "boot", udid]
        )

        guard result.success else {
            throw SimulatorError.commandFailed(result.stderr)
        }
    }

    /// Shuts down a simulator
    public func shutdownSimulator(udid: String) async throws {
        let result = try await processRunner.run(
            executable: xcrunPath,
            arguments: ["simctl", "shutdown", udid]
        )

        guard result.success else {
            throw SimulatorError.commandFailed(result.stderr)
        }
    }

    /// Launches an app on the simulator
    public func launchApp(bundleId: String, simulatorUdid: String) async throws {
        let result = try await processRunner.run(
            executable: xcrunPath,
            arguments: ["simctl", "launch", simulatorUdid, bundleId]
        )

        guard result.success else {
            throw SimulatorError.commandFailed(result.stderr)
        }
    }

    /// Terminates an app on the simulator
    public func terminateApp(bundleId: String, simulatorUdid: String) async throws {
        let result = try await processRunner.run(
            executable: xcrunPath,
            arguments: ["simctl", "terminate", simulatorUdid, bundleId]
        )

        guard result.success else {
            throw SimulatorError.commandFailed(result.stderr)
        }
    }

    /// Takes a screenshot of the simulator
    public func takeScreenshot(simulatorUdid: String, outputPath: String) async throws {
        let result = try await processRunner.run(
            executable: xcrunPath,
            arguments: ["simctl", "io", simulatorUdid, "screenshot", outputPath]
        )

        guard result.success else {
            throw SimulatorError.commandFailed(result.stderr)
        }
    }

    /// Checks if an app is installed on the simulator
    public func isAppInstalled(bundleId: String, simulatorUdid: String) async throws -> Bool {
        let result = try await processRunner.run(
            executable: xcrunPath,
            arguments: ["simctl", "get_app_container", simulatorUdid, bundleId]
        )
        return result.success
    }

    /// Installs an app on the simulator
    public func installApp(appPath: String, simulatorUdid: String) async throws {
        let result = try await processRunner.run(
            executable: xcrunPath,
            arguments: ["simctl", "install", simulatorUdid, appPath]
        )

        guard result.success else {
            throw SimulatorError.commandFailed(result.stderr)
        }
    }

    /// Ensures the host app is installed on the simulator
    public func ensureHostAppInstalled(hostAppPath: URL, simulatorUdid: String) async throws {
        let hostBundleId = "app.hiragram.SimDriverHost"
        let isInstalled = try await isAppInstalled(bundleId: hostBundleId, simulatorUdid: simulatorUdid)
        if !isInstalled {
            try await installApp(appPath: hostAppPath.path, simulatorUdid: simulatorUdid)
        }
    }

    /// Starts video recording on the simulator
    /// - Returns: A RecordingSession that can be used to stop the recording
    public func startRecording(simulatorUdid: String, outputPath: String) throws -> RecordingSession {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: xcrunPath)
        process.arguments = ["simctl", "io", simulatorUdid, "recordVideo", "--codec=h264", "--force", outputPath]

        let stderrPipe = Pipe()
        process.standardError = stderrPipe

        try process.run()

        return RecordingSession(process: process, outputPath: outputPath)
    }

    public enum SimulatorError: Error, Sendable {
        case commandFailed(String)
        case noBootedSimulator
    }
}

/// Represents an active video recording session
public final class RecordingSession: @unchecked Sendable {
    private let process: Process
    public let outputPath: String

    init(process: Process, outputPath: String) {
        self.process = process
        self.outputPath = outputPath
    }

    /// Waits for recording to actually start (checks for "Recording started" in stderr)
    public func waitForRecordingToStart(timeout: TimeInterval = 5.0) async throws {
        // Give the recording process time to initialize
        try await Task.sleep(for: .milliseconds(500))
    }

    /// Stops the recording by sending SIGINT
    public func stop() {
        process.interrupt()
        process.waitUntilExit()
    }

    /// Whether the recording process is still running
    public var isRunning: Bool {
        process.isRunning
    }
}

// MARK: - Private types for JSON decoding

private struct SimctlDevicesResponse: Codable {
    let devices: [String: [Simulator]]
}
