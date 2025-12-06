# SimDriverHost

SimDriverHost is a companion iOS app and UI test bundle used by iossim-mcp to execute UI automation commands on iOS Simulator apps.

## Architecture

```
SimDriverHost/
├── SimDriverHost/           # Minimal iOS app (required as UITest host)
│   ├── SimDriverHostApp.swift
│   └── ContentView.swift
├── SimDriverHost.xcodeproj
└── SimDriverUITests/        # UITest target that executes commands
    └── DriverTests.swift    # Main test driver
```

### Components

1. **SimDriverHost.app** - A minimal iOS application that serves as the UITest host. This app is automatically installed on the simulator but is not the app being tested.

2. **SimDriverUITests-Runner.app** - The test runner app that contains the test logic. It includes:
   - `PlugIns/SimDriverUITests.xctest` - The actual test bundle

3. **DriverTests.swift** - Contains `testScript()` which:
   - Reads a JSON script from `UI_TEST_SCRIPT_PATH` environment variable
   - Launches/activates the target app using `XCUIApplication(bundleIdentifier:)`
   - Executes UI actions (tap, swipe, type, etc.)
   - Writes results to `UI_TEST_RESULT_PATH`

## How It Works

1. MCP tool receives a UI command (e.g., `tap`)
2. `UITestDriver` creates a JSON script with the action
3. `UITestDriver` copies SimDriverUITests-Runner.app and SimDriverHost.app to a temp directory
4. `UITestDriver` modifies the `.xctestrun` file to inject paths and environment variables
5. `xcodebuild test-without-building` executes `DriverTests/testScript`
6. The test reads the script, activates the target app, and performs the action
7. Results are written to a JSON file and returned to the MCP client

## Updating SimDriverUITests

When you modify `SimDriverUITests/DriverTests.swift`, you must rebuild and update the bundled resources.

### Steps to Update

1. **Make your changes** to files in `SimDriverHost/SimDriverUITests/`

2. **Build for testing**:
   ```bash
   cd /Users/hiragram/Development/iossim-mcp/SimDriverHost
   xcodebuild -project SimDriverHost.xcodeproj \
     -scheme SimDriverUITests \
     -sdk iphonesimulator \
     -configuration Debug \
     -derivedDataPath /tmp/SimDriverUITestsBuild \
     build-for-testing
   ```

3. **Update the Runner.app resource**:
   ```bash
   cd /Users/hiragram/Development/iossim-mcp
   rm -rf Sources/iossim-mcp/Resources/SimDriverUITests-Runner.app
   cp -R /tmp/SimDriverUITestsBuild/Build/Products/Debug-iphonesimulator/SimDriverUITests-Runner.app \
     Sources/iossim-mcp/Resources/
   ```

4. **Rebuild the package**:
   ```bash
   swift build
   ```

5. **Test your changes** and commit both the source and the updated `.app` bundle.

### If You Also Modified SimDriverHost.app

If you changed the host app itself (not just the tests):

```bash
cd /Users/hiragram/Development/iossim-mcp/SimDriverHost
xcodebuild -project SimDriverHost.xcodeproj \
  -scheme SimDriverHost \
  -sdk iphonesimulator \
  -configuration Debug \
  -derivedDataPath /tmp/SimDriverHostBuild \
  build

cd /Users/hiragram/Development/iossim-mcp
rm -rf Sources/iossim-mcp/Resources/SimDriverHost.app
cp -R /tmp/SimDriverHostBuild/Build/Products/Debug-iphonesimulator/SimDriverHost.app \
  Sources/iossim-mcp/Resources/
```

## Script Format

The JSON script passed to DriverTests has this structure:

```json
{
  "bundleId": "com.example.app",
  "actions": [
    {
      "type": "tap",
      "target": {
        "type": "label",
        "value": "Button Text"
      }
    }
  ]
}
```

### Supported Actions

| Action | Fields |
|--------|--------|
| `tap` | `target` |
| `typeText` | `text`, `target` (optional) |
| `swipe` | `direction` (up/down/left/right), `target` (optional) |
| `longPress` | `target`, `duration` (optional, default 1.0) |
| `waitForElement` | `target`, `timeout` (optional, default 10.0) |
| `assertExists` | `target` |
| `screenshot` | `outputPath` (optional) |

### Target Types

| Type | Fields | Description |
|------|--------|-------------|
| `identifier` | `value` | Accessibility identifier |
| `label` | `value` | Element label text |
| `coordinate` | `x`, `y` | Screen coordinates |

## Result Format

```json
{
  "success": true,
  "results": [
    {
      "actionIndex": 0,
      "success": true,
      "error": null,
      "screenshotPath": null
    }
  ],
  "error": null
}
```

## Updating the .xctestrun File

The `.xctestrun` file (`SimDriverUITests_SimDriverUITests_iphonesimulator26.0-arm64.xctestrun`) contains test configuration. If you need to update it:

1. Build for testing (as shown above)
2. Find the new `.xctestrun` file in the build output:
   ```bash
   find /tmp/SimDriverUITestsBuild -name "*.xctestrun"
   ```
3. Copy it to Resources (rename if needed)
4. The file uses `__TESTROOT__` placeholder which is replaced at runtime

### Important xctestrun Settings

- `ParallelizationEnabled`: Must be `false` to avoid spawning additional simulators
- `TestingEnvironmentVariables`: Where `UI_TEST_SCRIPT_PATH` and `UI_TEST_RESULT_PATH` are injected
- `UITargetAppPath`: Points to SimDriverHost.app (the host, not the tested app)
- `DependentProductPaths`: Must include both SimDriverHost.app and SimDriverUITests-Runner.app

## Troubleshooting

### "TEST EXECUTE FAILED" with no details

- Check that environment variables are being injected into the `.xctestrun` file
- Verify the script JSON is valid
- Check simulator logs: `xcrun simctl spawn booted log stream`

### App restarts on each action

- Ensure DriverTests uses `activate()` for running apps, not `launch()`

### Host app not found

- Run `boot_simulator` or `launch_app` first - they auto-install SimDriverHost.app
- Or manually: `xcrun simctl install booted /path/to/SimDriverHost.app`

### Wrong simulator starts

- Ensure `ParallelizationEnabled` is `false` in the `.xctestrun` file
