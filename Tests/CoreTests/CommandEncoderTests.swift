import Testing
import Foundation
@testable import Core

@Suite("CommandEncoder Tests")
struct CommandEncoderTests {

    @Test("Writes command to JSON file")
    func writesCommandToJSONFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let sessionId = UUID().uuidString
        let encoder = CommandEncoder(sessionId: sessionId, directory: tempDir)

        let command = TapCommand(target: .identifier("test_button"))
        try encoder.write(command)

        let expectedPath = tempDir.appendingPathComponent("iossim-mcp-\(sessionId)-command.json")
        #expect(FileManager.default.fileExists(atPath: expectedPath.path))

        let data = try Data(contentsOf: expectedPath)
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("\"command\""))
        #expect(json.contains("\"tap\""))
        #expect(json.contains("\"test_button\""))

        // Cleanup
        try? FileManager.default.removeItem(at: expectedPath)
    }

    @Test("Returns correct command file path")
    func returnsCorrectCommandFilePath() {
        let tempDir = FileManager.default.temporaryDirectory
        let sessionId = "test-session-123"
        let encoder = CommandEncoder(sessionId: sessionId, directory: tempDir)

        let path = encoder.commandFilePath
        #expect(path.lastPathComponent == "iossim-mcp-test-session-123-command.json")
    }

    @Test("Returns correct result file path")
    func returnsCorrectResultFilePath() {
        let tempDir = FileManager.default.temporaryDirectory
        let sessionId = "test-session-123"
        let encoder = CommandEncoder(sessionId: sessionId, directory: tempDir)

        let path = encoder.resultFilePath
        #expect(path.lastPathComponent == "iossim-mcp-test-session-123-result.json")
    }

    @Test("Uses /tmp by default")
    func usesTmpByDefault() {
        let sessionId = "default-test"
        let encoder = CommandEncoder(sessionId: sessionId)

        #expect(encoder.commandFilePath.path.hasPrefix("/tmp/") || encoder.commandFilePath.path.hasPrefix("/var/folders/"))
    }

    @Test("Overwrites existing command file")
    func overwritesExistingCommandFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let sessionId = UUID().uuidString
        let encoder = CommandEncoder(sessionId: sessionId, directory: tempDir)

        // Write first command
        let command1 = TapCommand(target: .identifier("first_button"))
        try encoder.write(command1)

        // Write second command
        let command2 = TapCommand(target: .identifier("second_button"))
        try encoder.write(command2)

        // Should contain only second command
        let data = try Data(contentsOf: encoder.commandFilePath)
        let json = String(data: data, encoding: .utf8)!
        #expect(!json.contains("first_button"))
        #expect(json.contains("second_button"))

        // Cleanup
        try? FileManager.default.removeItem(at: encoder.commandFilePath)
    }
}
