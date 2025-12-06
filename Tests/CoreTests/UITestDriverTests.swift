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

    @Suite("UITestAction")
    struct UITestActionTests {

        // MARK: - doubleTap

        @Test("doubleTap action encodes correctly")
        func doubleTapEncodesCorrectly() throws {
            let action = UITestAction.doubleTap(target: .identifier("button"))

            let encoder = JSONEncoder()
            let data = try encoder.encode(action)
            let json = String(data: data, encoding: .utf8)!

            #expect(json.contains("\"type\":\"doubleTap\""))
            #expect(json.contains("\"type\":\"identifier\""))
            #expect(json.contains("\"value\":\"button\""))
        }

        @Test("doubleTap action decodes correctly")
        func doubleTapDecodesCorrectly() throws {
            let json = """
            {
                "type": "doubleTap",
                "target": {
                    "type": "identifier",
                    "value": "zoomableImage"
                }
            }
            """

            let data = json.data(using: .utf8)!
            let action = try JSONDecoder().decode(UITestAction.self, from: data)

            if case .doubleTap(let target) = action {
                if case .identifier(let value) = target {
                    #expect(value == "zoomableImage")
                } else {
                    Issue.record("Expected identifier target")
                }
            } else {
                Issue.record("Expected doubleTap action")
            }
        }

        // MARK: - pinch

        @Test("pinch action encodes correctly")
        func pinchEncodesCorrectly() throws {
            let action = UITestAction.pinch(target: .identifier("image"), scale: 2.0, velocity: 1.0)

            let encoder = JSONEncoder()
            let data = try encoder.encode(action)
            let json = String(data: data, encoding: .utf8)!

            #expect(json.contains("\"type\":\"pinch\""))
            #expect(json.contains("\"scale\":2"))
            #expect(json.contains("\"velocity\":1"))
        }

        @Test("pinch action decodes correctly")
        func pinchDecodesCorrectly() throws {
            let json = """
            {
                "type": "pinch",
                "target": {
                    "type": "identifier",
                    "value": "mapView"
                },
                "scale": 0.5,
                "velocity": -1.0
            }
            """

            let data = json.data(using: .utf8)!
            let action = try JSONDecoder().decode(UITestAction.self, from: data)

            if case .pinch(let target, let scale, let velocity) = action {
                if case .identifier(let value) = target {
                    #expect(value == "mapView")
                } else {
                    Issue.record("Expected identifier target")
                }
                #expect(scale == 0.5)
                #expect(velocity == -1.0)
            } else {
                Issue.record("Expected pinch action")
            }
        }

        // MARK: - rotate

        @Test("rotate action encodes correctly")
        func rotateEncodesCorrectly() throws {
            let action = UITestAction.rotate(target: .identifier("image"), rotation: 1.57, velocity: 0.5)

            let encoder = JSONEncoder()
            let data = try encoder.encode(action)
            let json = String(data: data, encoding: .utf8)!

            #expect(json.contains("\"type\":\"rotate\""))
            #expect(json.contains("\"rotation\""))
            #expect(json.contains("\"velocity\""))
        }

        @Test("rotate action decodes correctly")
        func rotateDecodesCorrectly() throws {
            let json = """
            {
                "type": "rotate",
                "target": {
                    "type": "identifier",
                    "value": "dial"
                },
                "rotation": 3.14,
                "velocity": 1.0
            }
            """

            let data = json.data(using: .utf8)!
            let action = try JSONDecoder().decode(UITestAction.self, from: data)

            if case .rotate(let target, let rotation, let velocity) = action {
                if case .identifier(let value) = target {
                    #expect(value == "dial")
                } else {
                    Issue.record("Expected identifier target")
                }
                #expect(rotation == 3.14)
                #expect(velocity == 1.0)
            } else {
                Issue.record("Expected rotate action")
            }
        }

        // MARK: - drag

        @Test("drag action encodes correctly")
        func dragEncodesCorrectly() throws {
            let action = UITestAction.drag(
                from: .coordinate(x: 100, y: 100),
                to: .coordinate(x: 200, y: 200),
                duration: 0.5
            )

            let encoder = JSONEncoder()
            let data = try encoder.encode(action)
            let json = String(data: data, encoding: .utf8)!

            #expect(json.contains("\"type\":\"drag\""))
            #expect(json.contains("\"from\""))
            #expect(json.contains("\"to\""))
            #expect(json.contains("\"duration\""))
        }

        @Test("drag action decodes correctly")
        func dragDecodesCorrectly() throws {
            let json = """
            {
                "type": "drag",
                "from": {
                    "type": "identifier",
                    "value": "draggableItem"
                },
                "to": {
                    "type": "identifier",
                    "value": "dropZone"
                },
                "duration": 1.0
            }
            """

            let data = json.data(using: .utf8)!
            let action = try JSONDecoder().decode(UITestAction.self, from: data)

            if case .drag(let from, let to, let duration) = action {
                if case .identifier(let fromValue) = from {
                    #expect(fromValue == "draggableItem")
                } else {
                    Issue.record("Expected identifier for 'from' target")
                }
                if case .identifier(let toValue) = to {
                    #expect(toValue == "dropZone")
                } else {
                    Issue.record("Expected identifier for 'to' target")
                }
                #expect(duration == 1.0)
            } else {
                Issue.record("Expected drag action")
            }
        }

        // MARK: - scrollToElement

        @Test("scrollToElement action encodes correctly")
        func scrollToElementEncodesCorrectly() throws {
            let action = UITestAction.scrollToElement(
                target: .identifier("targetElement"),
                within: .identifier("scrollView"),
                direction: .down,
                maxScrolls: 10
            )

            let encoder = JSONEncoder()
            let data = try encoder.encode(action)
            let json = String(data: data, encoding: .utf8)!

            #expect(json.contains("\"type\":\"scrollToElement\""))
            #expect(json.contains("\"target\""))
            #expect(json.contains("\"within\""))
            #expect(json.contains("\"direction\""))
        }

        @Test("scrollToElement action decodes correctly")
        func scrollToElementDecodesCorrectly() throws {
            let json = """
            {
                "type": "scrollToElement",
                "target": {
                    "type": "identifier",
                    "value": "lastItem"
                },
                "within": {
                    "type": "identifier",
                    "value": "tableView"
                },
                "direction": "down",
                "maxScrolls": 5
            }
            """

            let data = json.data(using: .utf8)!
            let action = try JSONDecoder().decode(UITestAction.self, from: data)

            if case .scrollToElement(let target, let within, let direction, let maxScrolls) = action {
                if case .identifier(let targetValue) = target {
                    #expect(targetValue == "lastItem")
                } else {
                    Issue.record("Expected identifier for target")
                }
                if case .identifier(let withinValue) = within {
                    #expect(withinValue == "tableView")
                } else {
                    Issue.record("Expected identifier for within")
                }
                #expect(direction == .down)
                #expect(maxScrolls == 5)
            } else {
                Issue.record("Expected scrollToElement action")
            }
        }

        // MARK: - clearText

        @Test("clearText action encodes correctly")
        func clearTextEncodesCorrectly() throws {
            let action = UITestAction.clearText(target: .identifier("textField"))

            let encoder = JSONEncoder()
            let data = try encoder.encode(action)
            let json = String(data: data, encoding: .utf8)!

            #expect(json.contains("\"type\":\"clearText\""))
            #expect(json.contains("\"target\""))
        }

        @Test("clearText action decodes correctly")
        func clearTextDecodesCorrectly() throws {
            let json = """
            {
                "type": "clearText",
                "target": {
                    "type": "identifier",
                    "value": "emailField"
                }
            }
            """

            let data = json.data(using: .utf8)!
            let action = try JSONDecoder().decode(UITestAction.self, from: data)

            if case .clearText(let target) = action {
                if case .identifier(let value) = target {
                    #expect(value == "emailField")
                } else {
                    Issue.record("Expected identifier target")
                }
            } else {
                Issue.record("Expected clearText action")
            }
        }

        // MARK: - shake

        @Test("shake action encodes correctly")
        func shakeEncodesCorrectly() throws {
            let action = UITestAction.shake

            let encoder = JSONEncoder()
            let data = try encoder.encode(action)
            let json = String(data: data, encoding: .utf8)!

            #expect(json.contains("\"type\":\"shake\""))
        }

        @Test("shake action decodes correctly")
        func shakeDecodesCorrectly() throws {
            let json = """
            {
                "type": "shake"
            }
            """

            let data = json.data(using: .utf8)!
            let action = try JSONDecoder().decode(UITestAction.self, from: data)

            if case .shake = action {
                // Success
            } else {
                Issue.record("Expected shake action")
            }
        }

        // MARK: - getElementValue

        @Test("getElementValue action encodes correctly")
        func getElementValueEncodesCorrectly() throws {
            let action = UITestAction.getElementValue(target: .identifier("textField"))

            let encoder = JSONEncoder()
            let data = try encoder.encode(action)
            let json = String(data: data, encoding: .utf8)!

            #expect(json.contains("\"type\":\"getElementValue\""))
            #expect(json.contains("\"target\""))
        }

        @Test("getElementValue action decodes correctly")
        func getElementValueDecodesCorrectly() throws {
            let json = """
            {
                "type": "getElementValue",
                "target": {
                    "type": "identifier",
                    "value": "usernameField"
                }
            }
            """

            let data = json.data(using: .utf8)!
            let action = try JSONDecoder().decode(UITestAction.self, from: data)

            if case .getElementValue(let target) = action {
                if case .identifier(let value) = target {
                    #expect(value == "usernameField")
                } else {
                    Issue.record("Expected identifier target")
                }
            } else {
                Issue.record("Expected getElementValue action")
            }
        }

        // MARK: - getElementProperties

        @Test("getElementProperties action encodes correctly")
        func getElementPropertiesEncodesCorrectly() throws {
            let action = UITestAction.getElementProperties(target: .identifier("button"))

            let encoder = JSONEncoder()
            let data = try encoder.encode(action)
            let json = String(data: data, encoding: .utf8)!

            #expect(json.contains("\"type\":\"getElementProperties\""))
            #expect(json.contains("\"target\""))
        }

        @Test("getElementProperties action decodes correctly")
        func getElementPropertiesDecodesCorrectly() throws {
            let json = """
            {
                "type": "getElementProperties",
                "target": {
                    "type": "label",
                    "value": "Submit"
                }
            }
            """

            let data = json.data(using: .utf8)!
            let action = try JSONDecoder().decode(UITestAction.self, from: data)

            if case .getElementProperties(let target) = action {
                if case .label(let value) = target {
                    #expect(value == "Submit")
                } else {
                    Issue.record("Expected label target")
                }
            } else {
                Issue.record("Expected getElementProperties action")
            }
        }

        // MARK: - getElementFrame

        @Test("getElementFrame action encodes correctly")
        func getElementFrameEncodesCorrectly() throws {
            let action = UITestAction.getElementFrame(target: .identifier("imageView"))

            let encoder = JSONEncoder()
            let data = try encoder.encode(action)
            let json = String(data: data, encoding: .utf8)!

            #expect(json.contains("\"type\":\"getElementFrame\""))
            #expect(json.contains("\"target\""))
        }

        @Test("getElementFrame action decodes correctly")
        func getElementFrameDecodesCorrectly() throws {
            let json = """
            {
                "type": "getElementFrame",
                "target": {
                    "type": "identifier",
                    "value": "profileImage"
                }
            }
            """

            let data = json.data(using: .utf8)!
            let action = try JSONDecoder().decode(UITestAction.self, from: data)

            if case .getElementFrame(let target) = action {
                if case .identifier(let value) = target {
                    #expect(value == "profileImage")
                } else {
                    Issue.record("Expected identifier target")
                }
            } else {
                Issue.record("Expected getElementFrame action")
            }
        }
    }
}
