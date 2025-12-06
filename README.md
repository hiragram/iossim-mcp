# iossim-mcp

An MCP (Model Context Protocol) server for controlling iOS Simulator apps via XCUITest.

## Features

- **Simulator Control**: Boot, shutdown, and manage iOS Simulators
- **App Management**: Launch and terminate apps on simulators
- **UI Automation**: Tap, swipe, type text using XCUITest under the hood
- **Screenshots**: Capture simulator screenshots
- **No App Modification Required**: Uses a generic XCUITest driver that can control any app

## Requirements

- macOS 14.0+
- Xcode 26.0+ (with iOS Simulator)
- Swift 6.2+

## Installation

### Using swx (recommended)

Add to your MCP configuration:

```json
{
  "mcpServers": {
    "iossim": {
      "command": "swx",
      "args": ["hiragram/iossim-mcp"]
    }
  }
}
```

## Available Tools

### Simulator Control

| Tool | Description |
|------|-------------|
| `list_simulators` | List all available iOS simulators |
| `boot_simulator` | Boot an iOS simulator by UDID |
| `shutdown_simulator` | Shutdown an iOS simulator by UDID |

### App Management

| Tool | Description |
|------|-------------|
| `launch_app` | Launch an app on a simulator |
| `terminate_app` | Terminate an app on a simulator |

### UI Automation

| Tool | Description |
|------|-------------|
| `tap` | Tap on an element by accessibility identifier or label |
| `type_text` | Type text into an element or focused field |
| `swipe` | Swipe in a direction (up/down/left/right) |
| `run_ui_script` | Run a sequence of UI actions |

### Screenshots

| Tool | Description |
|------|-------------|
| `take_screenshot` | Take a screenshot of the simulator |

## Usage Examples

### List available simulators

```json
{
  "tool": "list_simulators"
}
```

### Boot a simulator and launch an app

```json
{
  "tool": "boot_simulator",
  "arguments": {
    "udid": "DF27CC78-36A5-44D0-AF24-60555158BDB8"
  }
}
```

```json
{
  "tool": "launch_app",
  "arguments": {
    "bundleId": "com.example.myapp"
  }
}
```

### Tap on a button

```json
{
  "tool": "tap",
  "arguments": {
    "bundleId": "com.example.myapp",
    "identifier": "login_button"
  }
}
```

### Type text into a field

```json
{
  "tool": "type_text",
  "arguments": {
    "bundleId": "com.example.myapp",
    "text": "hello@example.com",
    "identifier": "email_field"
  }
}
```

### Run a sequence of actions

```json
{
  "tool": "run_ui_script",
  "arguments": {
    "bundleId": "com.example.myapp",
    "actions": [
      { "type": "tap", "target": { "type": "identifier", "value": "email_field" } },
      { "type": "typeText", "text": "user@example.com" },
      { "type": "tap", "target": { "type": "identifier", "value": "password_field" } },
      { "type": "typeText", "text": "secretpassword" },
      { "type": "tap", "target": { "type": "identifier", "value": "login_button" } },
      { "type": "waitForElement", "target": { "type": "identifier", "value": "home_screen" }, "timeout": 10 }
    ]
  }
}
```

## Action Types for `run_ui_script`

| Action | Properties |
|--------|------------|
| `tap` | `target` (required) |
| `typeText` | `text` (required), `target` (optional) |
| `swipe` | `direction` (required: up/down/left/right), `target` (optional) |
| `longPress` | `target` (required), `duration` (optional, seconds) |
| `waitForElement` | `target` (required), `timeout` (optional, seconds) |
| `assertExists` | `target` (required) |
| `screenshot` | `outputPath` (optional) |

### Target Specification

```json
// By accessibility identifier
{ "type": "identifier", "value": "my_button" }

// By label text
{ "type": "label", "value": "Submit" }

// By screen coordinates
{ "type": "coordinate", "x": 100, "y": 200 }
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      MCP Client (Claude, etc.)              │
└─────────────────────────────────────────────────────────────┘
                              │ stdio
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     iossim-mcp (executable)                  │
│  - MCP Server (modelcontextprotocol/swift-sdk)              │
│  - Tool handlers                                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Core (library)                           │
│  - SimulatorController: simctl wrapper                       │
│  - UITestDriver: xcodebuild test-without-building            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              SimDriverUITests (bundled XCUITest)             │
│  - Generic test driver                                       │
│  - Reads JSON script, executes XCUITest actions              │
│  - Writes results to JSON                                    │
└─────────────────────────────────────────────────────────────┘
```

## Development

### Running tests

```bash
swift test
```

### Rebuilding the UITest driver

If you modify `SimDriverHost/SimDriverUITests/DriverTests.swift`:

```bash
cd SimDriverHost
xcodebuild -project SimDriverHost.xcodeproj \
  -scheme SimDriverUITests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build-for-testing

# Copy the built artifacts
cp -R ~/Library/Developer/Xcode/DerivedData/SimDriverHost-*/Build/Products/Debug-iphonesimulator/SimDriverUITests-Runner.app \
  ../Sources/iossim-mcp/Resources/

cp ~/Library/Developer/Xcode/DerivedData/SimDriverHost-*/Build/Products/*.xctestrun \
  ../Sources/iossim-mcp/Resources/
```

## License

MIT

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.
