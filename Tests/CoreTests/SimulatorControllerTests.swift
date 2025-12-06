import Testing
import Foundation
@testable import Core

@Suite("SimulatorController Tests")
struct SimulatorControllerTests {

    @Test("Lists available simulators")
    func listsAvailableSimulators() async throws {
        let mockRunner = MockProcessRunner()
        let simulatorListJSON = """
        {
          "devices": {
            "com.apple.CoreSimulator.SimRuntime.iOS-17-0": [
              {
                "udid": "ABC123-DEF456",
                "name": "iPhone 15 Pro",
                "state": "Booted",
                "isAvailable": true
              },
              {
                "udid": "XYZ789-QRS012",
                "name": "iPhone 15",
                "state": "Shutdown",
                "isAvailable": true
              }
            ]
          }
        }
        """
        mockRunner.setResult(
            for: "/usr/bin/xcrun simctl list devices -j",
            result: ProcessResult(exitCode: 0, stdout: simulatorListJSON, stderr: "")
        )

        let controller = SimulatorController(processRunner: mockRunner)
        let simulators = try await controller.listSimulators()

        #expect(simulators.count == 2)
        #expect(simulators[0].name == "iPhone 15 Pro")
        #expect(simulators[0].udid == "ABC123-DEF456")
        #expect(simulators[0].state == .booted)
        #expect(simulators[1].state == .shutdown)
    }

    @Test("Boots a simulator")
    func bootsSimulator() async throws {
        let mockRunner = MockProcessRunner()
        mockRunner.setResult(
            for: "/usr/bin/xcrun simctl boot ABC123",
            result: ProcessResult(exitCode: 0, stdout: "", stderr: "")
        )

        let controller = SimulatorController(processRunner: mockRunner)
        try await controller.bootSimulator(udid: "ABC123")

        #expect(mockRunner.callHistory.count == 1)
        #expect(mockRunner.callHistory[0].arguments.contains("boot"))
        #expect(mockRunner.callHistory[0].arguments.contains("ABC123"))
    }

    @Test("Shuts down a simulator")
    func shutsDownSimulator() async throws {
        let mockRunner = MockProcessRunner()
        mockRunner.setResult(
            for: "/usr/bin/xcrun simctl shutdown ABC123",
            result: ProcessResult(exitCode: 0, stdout: "", stderr: "")
        )

        let controller = SimulatorController(processRunner: mockRunner)
        try await controller.shutdownSimulator(udid: "ABC123")

        #expect(mockRunner.callHistory.count == 1)
        #expect(mockRunner.callHistory[0].arguments.contains("shutdown"))
    }

    @Test("Launches an app")
    func launchesApp() async throws {
        let mockRunner = MockProcessRunner()
        mockRunner.setResult(
            for: "/usr/bin/xcrun simctl launch ABC123 com.example.app",
            result: ProcessResult(exitCode: 0, stdout: "com.example.app: 12345\n", stderr: "")
        )

        let controller = SimulatorController(processRunner: mockRunner)
        try await controller.launchApp(bundleId: "com.example.app", simulatorUdid: "ABC123")

        #expect(mockRunner.callHistory.count == 1)
        #expect(mockRunner.callHistory[0].arguments.contains("launch"))
        #expect(mockRunner.callHistory[0].arguments.contains("com.example.app"))
    }

    @Test("Terminates an app")
    func terminatesApp() async throws {
        let mockRunner = MockProcessRunner()
        mockRunner.setResult(
            for: "/usr/bin/xcrun simctl terminate ABC123 com.example.app",
            result: ProcessResult(exitCode: 0, stdout: "", stderr: "")
        )

        let controller = SimulatorController(processRunner: mockRunner)
        try await controller.terminateApp(bundleId: "com.example.app", simulatorUdid: "ABC123")

        #expect(mockRunner.callHistory.count == 1)
        #expect(mockRunner.callHistory[0].arguments.contains("terminate"))
    }

    @Test("Takes a screenshot")
    func takesScreenshot() async throws {
        let mockRunner = MockProcessRunner()
        let tempPath = "/tmp/screenshot-test.png"
        mockRunner.setResult(
            for: "/usr/bin/xcrun simctl io ABC123 screenshot \(tempPath)",
            result: ProcessResult(exitCode: 0, stdout: "", stderr: "")
        )

        let controller = SimulatorController(processRunner: mockRunner)
        try await controller.takeScreenshot(simulatorUdid: "ABC123", outputPath: tempPath)

        #expect(mockRunner.callHistory.count == 1)
        #expect(mockRunner.callHistory[0].arguments.contains("screenshot"))
    }

    @Test("Gets booted simulator")
    func getsBootedSimulator() async throws {
        let mockRunner = MockProcessRunner()
        let simulatorListJSON = """
        {
          "devices": {
            "com.apple.CoreSimulator.SimRuntime.iOS-17-0": [
              {
                "udid": "BOOTED-123",
                "name": "iPhone 15 Pro",
                "state": "Booted",
                "isAvailable": true
              },
              {
                "udid": "SHUTDOWN-456",
                "name": "iPhone 15",
                "state": "Shutdown",
                "isAvailable": true
              }
            ]
          }
        }
        """
        mockRunner.setResult(
            for: "/usr/bin/xcrun simctl list devices -j",
            result: ProcessResult(exitCode: 0, stdout: simulatorListJSON, stderr: "")
        )

        let controller = SimulatorController(processRunner: mockRunner)
        let booted = try await controller.getBootedSimulator()

        #expect(booted?.udid == "BOOTED-123")
    }
}
