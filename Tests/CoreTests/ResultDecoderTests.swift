import Testing
import Foundation
@testable import Core

@Suite("ResultDecoder Tests")
struct ResultDecoderTests {

    @Test("Decodes successful result")
    func decodesSuccessfulResult() throws {
        let json = """
        {
            "success": true,
            "result": {
                "elementFound": true,
                "frame": {"x": 100, "y": 200, "width": 50, "height": 30}
            },
            "error": null
        }
        """

        let tempDir = FileManager.default.temporaryDirectory
        let sessionId = UUID().uuidString
        let resultPath = tempDir.appendingPathComponent("iossim-mcp-\(sessionId)-result.json")
        try json.data(using: .utf8)!.write(to: resultPath)

        let decoder = ResultDecoder(sessionId: sessionId, directory: tempDir)
        let result = try decoder.read()

        #expect(result.success == true)
        #expect(result.error == nil)

        // Cleanup
        try? FileManager.default.removeItem(at: resultPath)
    }

    @Test("Decodes failed result with error")
    func decodesFailedResultWithError() throws {
        let json = """
        {
            "success": false,
            "result": null,
            "error": "Element not found"
        }
        """

        let tempDir = FileManager.default.temporaryDirectory
        let sessionId = UUID().uuidString
        let resultPath = tempDir.appendingPathComponent("iossim-mcp-\(sessionId)-result.json")
        try json.data(using: .utf8)!.write(to: resultPath)

        let decoder = ResultDecoder(sessionId: sessionId, directory: tempDir)
        let result = try decoder.read()

        #expect(result.success == false)
        #expect(result.error == "Element not found")

        // Cleanup
        try? FileManager.default.removeItem(at: resultPath)
    }

    @Test("Throws when result file does not exist")
    func throwsWhenResultFileDoesNotExist() {
        let tempDir = FileManager.default.temporaryDirectory
        let sessionId = "nonexistent-\(UUID().uuidString)"
        let decoder = ResultDecoder(sessionId: sessionId, directory: tempDir)

        #expect(throws: Error.self) {
            _ = try decoder.read()
        }
    }

    @Test("Waits for result file with timeout")
    func waitsForResultFileWithTimeout() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let sessionId = UUID().uuidString
        let decoder = ResultDecoder(sessionId: sessionId, directory: tempDir)

        // File doesn't exist, should timeout
        do {
            _ = try await decoder.waitForResult(timeout: 0.1)
            Issue.record("Should have thrown timeout error")
        } catch {
            // Expected to throw
            #expect(error is ResultDecoder.Error)
        }
    }

    @Test("Successfully reads result when file appears")
    func successfullyReadsResultWhenFileAppears() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let sessionId = UUID().uuidString
        let decoder = ResultDecoder(sessionId: sessionId, directory: tempDir)
        let resultPath = tempDir.appendingPathComponent("iossim-mcp-\(sessionId)-result.json")

        // Write result file immediately (simulating test driver completion)
        let json = """
        {
            "success": true,
            "result": {},
            "error": null
        }
        """
        try json.data(using: .utf8)!.write(to: resultPath)

        let result = try await decoder.waitForResult(timeout: 1.0)
        #expect(result.success == true)

        // Cleanup
        try? FileManager.default.removeItem(at: resultPath)
    }
}
