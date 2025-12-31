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

/// Errors that can occur when running processes
public enum ProcessRunnerError: Error, LocalizedError {
    case timeout(TimeInterval)
    case processTerminatedAbnormally(Int32)

    public var errorDescription: String? {
        switch self {
        case .timeout(let seconds):
            return "Process timed out after \(Int(seconds)) seconds"
        case .processTerminatedAbnormally(let code):
            return "Process terminated with code \(code)"
        }
    }
}

/// Protocol for running external processes (allows mocking in tests)
public protocol ProcessRunner: Sendable {
    func run(executable: String, arguments: [String]) async throws -> ProcessResult
    func run(executable: String, arguments: [String], environment: [String: String]) async throws -> ProcessResult
    func run(executable: String, arguments: [String], environment: [String: String], timeout: TimeInterval) async throws -> ProcessResult
}

/// Default implementation using Foundation.Process with proper async handling
public struct DefaultProcessRunner: ProcessRunner {
    /// Default timeout for process execution (60 seconds)
    public static let defaultTimeout: TimeInterval = 60

    public init() {}

    public func run(executable: String, arguments: [String]) async throws -> ProcessResult {
        try await run(executable: executable, arguments: arguments, environment: [:], timeout: Self.defaultTimeout)
    }

    public func run(executable: String, arguments: [String], environment: [String: String]) async throws -> ProcessResult {
        try await run(executable: executable, arguments: arguments, environment: environment, timeout: Self.defaultTimeout)
    }

    public func run(executable: String, arguments: [String], environment: [String: String], timeout: TimeInterval) async throws -> ProcessResult {
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

        // Accumulators for stdout/stderr data
        let stdoutAccumulator = DataAccumulator()
        let stderrAccumulator = DataAccumulator()

        // Set up non-blocking read handlers BEFORE starting the process
        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty {
                stdoutAccumulator.append(data)
            }
        }

        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty {
                stderrAccumulator.append(data)
            }
        }

        try process.run()

        // Wait for process with timeout
        let result = await withTaskGroup(of: ProcessWaitResult.self) { group in
            // Task 1: Wait for process to exit
            group.addTask {
                await withCheckedContinuation { (continuation: CheckedContinuation<ProcessWaitResult, Never>) in
                    process.terminationHandler = { _ in
                        continuation.resume(returning: ProcessWaitResult.completed)
                    }
                }
                return ProcessWaitResult.completed
            }

            // Task 2: Timeout
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                return ProcessWaitResult.timeout
            }

            // Return first result
            let firstResult = await group.next() ?? ProcessWaitResult.timeout
            group.cancelAll()
            return firstResult
        }

        // Clean up readability handlers
        stdoutPipe.fileHandleForReading.readabilityHandler = nil
        stderrPipe.fileHandleForReading.readabilityHandler = nil

        // Handle timeout
        if result == .timeout {
            // Terminate the process gracefully first
            process.terminate()

            // Give it a moment to terminate
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            // Force kill if still running
            if process.isRunning {
                process.interrupt()
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                if process.isRunning {
                    kill(process.processIdentifier, SIGKILL)
                }
            }

            throw ProcessRunnerError.timeout(timeout)
        }

        // Read any remaining data from pipes
        // This is safe now because the process has exited
        let remainingStdout = stdoutPipe.fileHandleForReading.availableData
        let remainingStderr = stderrPipe.fileHandleForReading.availableData

        if !remainingStdout.isEmpty {
            stdoutAccumulator.append(remainingStdout)
        }
        if !remainingStderr.isEmpty {
            stderrAccumulator.append(remainingStderr)
        }

        // Close the pipes
        try? stdoutPipe.fileHandleForReading.close()
        try? stderrPipe.fileHandleForReading.close()

        let stdout = String(data: stdoutAccumulator.data, encoding: .utf8) ?? ""
        let stderr = String(data: stderrAccumulator.data, encoding: .utf8) ?? ""

        return ProcessResult(
            exitCode: process.terminationStatus,
            stdout: stdout,
            stderr: stderr
        )
    }
}

/// Result type for process waiting
private enum ProcessWaitResult {
    case completed
    case timeout
}

/// Thread-safe data accumulator for collecting pipe output
private final class DataAccumulator: @unchecked Sendable {
    private var _data = Data()
    private let lock = NSLock()

    var data: Data {
        lock.lock()
        defer { lock.unlock() }
        return _data
    }

    func append(_ newData: Data) {
        lock.lock()
        defer { lock.unlock() }
        _data.append(newData)
    }
}

/// Mock process runner for testing
public final class MockProcessRunner: ProcessRunner, @unchecked Sendable {
    public var results: [String: ProcessResult] = [:]
    public var callHistory: [(executable: String, arguments: [String], environment: [String: String])] = []

    public init() {}

    public func run(executable: String, arguments: [String]) async throws -> ProcessResult {
        try await run(executable: executable, arguments: arguments, environment: [:], timeout: 60)
    }

    public func run(executable: String, arguments: [String], environment: [String: String]) async throws -> ProcessResult {
        try await run(executable: executable, arguments: arguments, environment: environment, timeout: 60)
    }

    public func run(executable: String, arguments: [String], environment: [String: String], timeout: TimeInterval) async throws -> ProcessResult {
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
