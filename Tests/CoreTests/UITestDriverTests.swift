import Testing
import Foundation
@testable import Core

@Suite("UITestDriver Tests")
struct UITestDriverTests {

    @Suite("UITestScript")
    struct UITestScriptTests {

        @Test("Encodes with recordVideo false by default")
        func encodesWithRecordVideoFalseByDefault() throws {
            let script = UITestScript(
                bundleId: "com.example.app",
                actions: [.tap(target: .identifier("button"))]
            )

            let encoder = JSONEncoder()
            let data = try encoder.encode(script)
            let json = String(data: data, encoding: .utf8)!

            #expect(json.contains("\"bundleId\":\"com.example.app\""))
            #expect(json.contains("\"recordVideo\":false"))
        }

        @Test("Encodes with recordVideo true")
        func encodesWithRecordVideoTrue() throws {
            let script = UITestScript(
                bundleId: "com.example.app",
                actions: [.tap(target: .identifier("button"))],
                recordVideo: true
            )

            let encoder = JSONEncoder()
            let data = try encoder.encode(script)
            let json = String(data: data, encoding: .utf8)!

            #expect(json.contains("\"recordVideo\":true"))
        }

        @Test("Decodes with recordVideo true")
        func decodesWithRecordVideoTrue() throws {
            let json = """
            {
                "bundleId": "com.example.app",
                "actions": [
                    {
                        "type": "tap",
                        "target": {
                            "type": "identifier",
                            "value": "button"
                        }
                    }
                ],
                "recordVideo": true
            }
            """

            let data = json.data(using: .utf8)!
            let script = try JSONDecoder().decode(UITestScript.self, from: data)

            #expect(script.bundleId == "com.example.app")
            #expect(script.recordVideo == true)
            #expect(script.actions.count == 1)
        }

        @Test("Decodes with recordVideo false")
        func decodesWithRecordVideoFalse() throws {
            let json = """
            {
                "bundleId": "com.example.app",
                "actions": [],
                "recordVideo": false
            }
            """

            let data = json.data(using: .utf8)!
            let script = try JSONDecoder().decode(UITestScript.self, from: data)

            #expect(script.recordVideo == false)
        }
    }

    @Suite("UITestResult")
    struct UITestResultTests {

        @Test("Encodes with videoPath nil")
        func encodesWithVideoPathNil() throws {
            let result = UITestResult(
                success: true,
                results: [],
                error: nil,
                videoPath: nil
            )

            let encoder = JSONEncoder()
            let data = try encoder.encode(result)
            let json = String(data: data, encoding: .utf8)!

            #expect(json.contains("\"success\":true"))
            // videoPath is optional, so nil values may be omitted or encoded as null
            // Either is acceptable behavior
        }

        @Test("Encodes with videoPath present")
        func encodesWithVideoPathPresent() throws {
            let result = UITestResult(
                success: true,
                results: [],
                error: nil,
                videoPath: "/tmp/recording.mov"
            )

            let encoder = JSONEncoder()
            let data = try encoder.encode(result)
            let json = String(data: data, encoding: .utf8)!

            // JSON encoder escapes forward slashes, so check for the path in decoded form
            #expect(json.contains("videoPath"))
            #expect(json.contains("recording.mov"))
        }

        @Test("Decodes with videoPath present")
        func decodesWithVideoPathPresent() throws {
            let json = """
            {
                "success": true,
                "results": [],
                "error": null,
                "videoPath": "/tmp/test-recording.mov"
            }
            """

            let data = json.data(using: .utf8)!
            let result = try JSONDecoder().decode(UITestResult.self, from: data)

            #expect(result.success == true)
            #expect(result.videoPath == "/tmp/test-recording.mov")
        }

        @Test("Decodes with videoPath null")
        func decodesWithVideoPathNull() throws {
            let json = """
            {
                "success": true,
                "results": [],
                "error": null,
                "videoPath": null
            }
            """

            let data = json.data(using: .utf8)!
            let result = try JSONDecoder().decode(UITestResult.self, from: data)

            #expect(result.videoPath == nil)
        }

        @Test("Decodes without videoPath field (backwards compatibility)")
        func decodesWithoutVideoPathField() throws {
            let json = """
            {
                "success": true,
                "results": [],
                "error": null
            }
            """

            let data = json.data(using: .utf8)!
            let result = try JSONDecoder().decode(UITestResult.self, from: data)

            #expect(result.videoPath == nil)
        }

        @Test("Encodes and decodes ActionResult with screenshotPath")
        func encodesAndDecodesActionResult() throws {
            let actionResult = UITestResult.ActionResult(
                actionIndex: 0,
                success: true,
                error: nil,
                screenshotPath: "/tmp/screenshot.png"
            )
            let result = UITestResult(
                success: true,
                results: [actionResult],
                error: nil,
                videoPath: "/tmp/video.mov"
            )

            let encoder = JSONEncoder()
            let data = try encoder.encode(result)
            let decoded = try JSONDecoder().decode(UITestResult.self, from: data)

            #expect(decoded.results.count == 1)
            #expect(decoded.results[0].actionIndex == 0)
            #expect(decoded.results[0].screenshotPath == "/tmp/screenshot.png")
            #expect(decoded.videoPath == "/tmp/video.mov")
        }
    }
}
