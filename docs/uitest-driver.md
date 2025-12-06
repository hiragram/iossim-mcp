汎用UITestドライバーを Swift Package に含めるための作業指示
ゴール

「simdriver（仮）」Swift Package の中に、

✅ 汎用UITestドライバー（XCUITestバンドル）

✅ それを呼び出す CLI ツール
を 同梱した状態にしたい。

ユーザーは 自分のアプリ側で UI テストターゲットを用意せず、
このパッケージだけでシミュレータ操作ができるようにしたい。

1. 汎用UITestドライバー用の Xcode プロジェクトを作成する

新規 Xcode プロジェクトを作成

テンプレート: iOS App（中身は最小限でOK。実際のアプリに依存しない「ホストダミー」でも可）

プロジェクト名: SimDriverHost（仮）

このプロジェクトに UI テストターゲットを追加

Target → Add → UI Testing Bundle

ターゲット名: SimDriverUITests（仮）

SimDriverUITests 内に、汎用ドライバーとなるテストクラスを1つ作成

例: DriverTests.swift

2. 汎用UITestドライバー（DriverTests）の実装方針

testScript() のようなメソッドを1本だけ用意し、

環境変数（例: UI_TEST_SCRIPT_PATH）で渡された JSON パスを読み込む

JSON の内容（actions）に従って XCUIApplication を操作する

ざっくりイメージ：

import XCTest

final class DriverTests: XCTestCase {

    func testScript() throws {
        let app = XCUIApplication()
        app.launch()

        guard let path = ProcessInfo.processInfo.environment["UI_TEST_SCRIPT_PATH"] else {
            XCTFail("UI_TEST_SCRIPT_PATH is not set")
            return
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let script = try JSONDecoder().decode(Script.self, from: data)

        try script.execute(on: app)
    }
}


Script/Action のスキーマは別途定義（tap/typeText/swipe など）

将来の拡張を見越し、enum + associated values で拡張可能な形にしておくと良いです

3. 汎用ドライバーのビルドと .xctest バンドルの取得

SimDriverUITests のスキームで Build for Testing を実行

xcodebuild なら例：

xcodebuild \
  -project SimDriverHost.xcodeproj \
  -scheme SimDriverUITests \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build-for-testing


ビルド後、DerivedData 配下に SimDriverUITests.xctest バンドルが生成されるので、それをコピーする

例:
~/Library/Developer/Xcode/DerivedData/.../Build/Products/Debug-iphonesimulator/SimDriverUITests-Runner.app/PlugIns/SimDriverUITests.xctest

ランナーapp配下に入っている場合は、運用しやすいように .xctest を丸ごと取り出しておく

必要に応じて .xctestrun を一緒にエクスポートしておいても良い（test-without-building 用）

4. Swift Package に汎用ドライバーを含める

Swift Package のリポジトリ構成イメージ：

SimDriverPackage/
 ├ Package.swift
 ├ Sources/
 │   └ SimDriverCLI/      ← CLI本体
 └ Resources/
     ├ SimDriverUITests.xctest
     └ (必要なら) SimDriver.xctestrun

4.1 Package.swift の修正

CLI ターゲットに .copy リソースとして .xctest を含める。

// Package.swift の一例
.targets: [
    .executableTarget(
        name: "simdriver",
        dependencies: [],
        resources: [
            .copy("Resources/SimDriverUITests.xctest"),
            // .copy("Resources/SimDriver.xctestrun") // 必要なら
        ]
    )
]

5. CLI 側からドライバーを呼び出す実装

CLI 実行時に、MCPから受け取った JSON を一時ファイルに書き出す

/tmp/simdriver-XXXXXX.json 等

Swift Package のリソースとして含めた .xctest のパスを取得する

import Foundation

let resourceURL = Bundle.module.url(
    forResource: "SimDriverUITests",
    withExtension: "xctest"
)!


必要に応じて、/tmp 配下などにコピーしてから xcodebuild で実行

// 擬似コード
let testBundlePath = resourceURL.path
let scriptPath = "/tmp/simdriver-actions.json" // JSON書いたところ

let process = Process()
process.launchPath = "/usr/bin/xcrun"
process.arguments = [
    "xcodebuild",
    "test-without-building",
    "-destination", "platform=iOS Simulator,name=iPhone 16",
    // ここで test bundle / xctestrun を指定する形にする
    // 環境変数で JSON パスを渡す
]
process.environment = [
    "UI_TEST_SCRIPT_PATH": scriptPath,
    // 他必要な環境変数
]
try process.run()
process.waitUntilExit()


test-without-building に渡すオプション（-xctestrun など）は、
Xcodeのビルド成果物構成に合わせて適宜最適な形を選んでほしいです
（ここは実際のプロジェクト構成を見て詰める部分）

6. ユーザー視点での最終動作イメージ

Swift Package を導入すれば、ユーザーは：

アプリプロジェクトに UI テストターゲットを追加せずに

CLI simdriver を叩くだけで

iOS シミュレータ内のアプリを操作できる

例：

simdriver --script /tmp/actions.json --destination 'platform=iOS Simulator,name=iPhone 16'


内部では、

actions.json → /tmp に保存

パッケージ内の SimDriverUITests.xctest を使って xcodebuild test-without-building 実行

UIテスト側で UI_TEST_SCRIPT_PATH を読み取り、順に操作を実行

結果を CLI が標準出力(JSON)で返す

7. 開発者への補足メモ（自由に削ってOK）

初期段階では「特定のデバイス・OSバージョン（例: iPhone 16 / iOS 18）」に固定して良いので、まずは動く経路を作り、柔軟な -destination 指定は後から対応でOKです

.xctest をどう参照するか（xctestrun の有無やパス等）は、Xcode のバージョンやビルド構成に依存する部分があるため、実際に xcodebuild build-for-testing → test-without-building の動作確認をした上で、安定する形で決めてください