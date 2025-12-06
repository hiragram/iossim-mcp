import Testing
import Foundation
@testable import Core

@Suite("UICommand Tests")
struct UICommandTests {

    @Suite("TapCommand")
    struct TapCommandTests {

        @Test("TapCommand with identifier encodes to JSON correctly")
        func tapCommandWithIdentifierEncodesToJSON() throws {
            let command = TapCommand(target: .identifier("login_button"))

            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let data = try encoder.encode(command)
            let json = String(data: data, encoding: .utf8)!

            #expect(json.contains("\"command\":\"tap\""))
            #expect(json.contains("\"target\""))
            #expect(json.contains("\"type\":\"identifier\""))
            #expect(json.contains("\"value\":\"login_button\""))
        }

        @Test("TapCommand with coordinate encodes to JSON correctly")
        func tapCommandWithCoordinateEncodesToJSON() throws {
            let command = TapCommand(target: .coordinate(x: 100, y: 200))

            let encoder = JSONEncoder()
            let data = try encoder.encode(command)
            let json = String(data: data, encoding: .utf8)!

            #expect(json.contains("\"command\":\"tap\""))
            #expect(json.contains("\"type\":\"coordinate\""))
            #expect(json.contains("\"x\":100"))
            #expect(json.contains("\"y\":200"))
        }

        @Test("TapCommand with label encodes to JSON correctly")
        func tapCommandWithLabelEncodesToJSON() throws {
            let command = TapCommand(target: .label("Login"))

            let encoder = JSONEncoder()
            let data = try encoder.encode(command)
            let json = String(data: data, encoding: .utf8)!

            #expect(json.contains("\"command\":\"tap\""))
            #expect(json.contains("\"type\":\"label\""))
            #expect(json.contains("\"value\":\"Login\""))
        }

        @Test("TapCommand decodes from JSON correctly")
        func tapCommandDecodesFromJSON() throws {
            let json = """
            {
                "command": "tap",
                "target": {
                    "type": "identifier",
                    "value": "submit_button"
                }
            }
            """

            let data = json.data(using: .utf8)!
            let command = try JSONDecoder().decode(TapCommand.self, from: data)

            #expect(command.command == "tap")
            if case .identifier(let id) = command.target {
                #expect(id == "submit_button")
            } else {
                Issue.record("Expected identifier target")
            }
        }
    }

    @Suite("SwipeCommand")
    struct SwipeCommandTests {

        @Test("SwipeCommand encodes to JSON correctly")
        func swipeCommandEncodesToJSON() throws {
            let command = SwipeCommand(direction: .up, target: .identifier("scroll_view"))

            let encoder = JSONEncoder()
            let data = try encoder.encode(command)
            let json = String(data: data, encoding: .utf8)!

            #expect(json.contains("\"command\":\"swipe\""))
            #expect(json.contains("\"direction\":\"up\""))
            #expect(json.contains("\"type\":\"identifier\""))
        }

        @Test("SwipeCommand without target encodes correctly")
        func swipeCommandWithoutTargetEncodesToJSON() throws {
            let command = SwipeCommand(direction: .left, target: nil)

            let encoder = JSONEncoder()
            let data = try encoder.encode(command)
            let json = String(data: data, encoding: .utf8)!

            #expect(json.contains("\"command\":\"swipe\""))
            #expect(json.contains("\"direction\":\"left\""))
        }
    }

    @Suite("TypeTextCommand")
    struct TypeTextCommandTests {

        @Test("TypeTextCommand encodes to JSON correctly")
        func typeTextCommandEncodesToJSON() throws {
            let command = TypeTextCommand(text: "hello@example.com", target: .identifier("email_field"))

            let encoder = JSONEncoder()
            let data = try encoder.encode(command)
            let json = String(data: data, encoding: .utf8)!

            #expect(json.contains("\"command\":\"typeText\""))
            #expect(json.contains("\"text\":\"hello@example.com\""))
            #expect(json.contains("\"type\":\"identifier\""))
        }
    }
}
