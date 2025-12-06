import Foundation

/// Result of running a process
public struct ProcessResult: Sendable {
    public let exitCode: Int32
    public let stdout: String
    public let stderr: String

    public var success: Bool { exitCode == 0 }

    public init(exitCode: Int32, stdout: String, stderr: String) {
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
    }
}

/// Protocol for running external processes (allows mocking in tests)
public protocol ProcessRunner: Sendable {
    func run(executable: String, arguments: [String]) async throws -> ProcessResult
    func run(executable: String, arguments: [String], environment: [String: String]) async throws -> ProcessResult
}

/// Default implementation using Foundation.Process
public struct DefaultProcessRunner: ProcessRunner {
    public init() {}

    public func run(executable: String, arguments: [String]) async throws -> ProcessResult {
        try await run(executable: executable, arguments: arguments, environment: [:])
    }

    public func run(executable: String, arguments: [String], environment: [String: String]) async throws -> ProcessResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        // Merge custom environment with current process environment
        var env = ProcessInfo.processInfo.environment
        for (key, value) in environment {
            env[key] = value
        }
        process.environment = env

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

        let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""

        return ProcessResult(
            exitCode: process.terminationStatus,
            stdout: stdout,
            stderr: stderr
        )
    }
}

/// Mock process runner for testing
public final class MockProcessRunner: ProcessRunner, @unchecked Sendable {
    public var results: [String: ProcessResult] = [:]
    public var callHistory: [(executable: String, arguments: [String], environment: [String: String])] = []

    public init() {}

    public func run(executable: String, arguments: [String]) async throws -> ProcessResult {
        try await run(executable: executable, arguments: arguments, environment: [:])
    }

    public func run(executable: String, arguments: [String], environment: [String: String]) async throws -> ProcessResult {
        callHistory.append((executable, arguments, environment))

        let key = "\(executable) \(arguments.joined(separator: " "))"
        if let result = results[key] {
            return result
        }

        // Default to success with empty output
        return ProcessResult(exitCode: 0, stdout: "", stderr: "")
    }

    public func setResult(for command: String, result: ProcessResult) {
        results[command] = result
    }
}
