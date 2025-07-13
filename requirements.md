# Mac OCR App 要件定義書

## 1. プロジェクト概要

### プロジェクト名

ScreenTextExtractor

### 目的

Macユーザーが画面上の任意の領域を選択し、その領域内のテキストをOCR（光学文字認識）で抽出してクリップボードにコピーできるシンプルなアプリケーションを作成する。追加のOCRモデルをインストールせず、macOS標準のVisionフレームワークを使用することで、プライバシーと軽量性を確保する。ホットキー（Command + Shift + 2）でグローバルに起動可能とし、最小限の機能に絞ることで、誰でも簡単に実装・使用できるようにする。

### 対象ユーザー

- Macユーザー（macOS Ventura以降推奨、Visionフレームワーク搭載のため）。
- 画面上のテキストを頻繁にコピーしたい人（例: 開発者、研究者、学生）。

### 参照オープンソースプロジェクト

- macOCR (GitHub: schappim/macOCR): CLIベースで画面選択→Vision OCR→クリップボードコピーを実現。最小構成の参考にし、GUIを追加。
- Montelimar (GitHub: julien-blanchon/Montelimar): 高機能だが、ホットキー登録と画面キャプチャの構造を参考。Pythonサイドカーを避け、Swiftネイティブに簡略化。
- NormCap/Screenotate: Tesseract使用のためOCR部分は参考外だが、画面選択のUIを参考。

これらのプロジェクトから、画面キャプチャとOCRのコアロジックを抽出・簡略化。

### 範囲

- インスコープ: ホットキー起動、領域選択、OCR抽出、クリップボードコピー。
- アウトオブスコープ: 履歴管理、複数言語指定、画像保存、UIカスタマイズ（最小構成のため）。

## 2. 機能要件

機能は最小限に絞り、以下の流れで動作する：

1. ホットキー（Command + Shift + 2）を押す。
2. 画面選択モード（クロスヘアカーソル）に入り、ユーザーがドラッグで領域を選択。
3. 選択領域をキャプチャ。
4. macOS Visionフレームワークでテキスト抽出。
5. 抽出テキストをクリップボードにコピー。
6. 通知を表示（成功/失敗）。

### 詳細機能一覧

| 機能ID | 機能名                   | 詳細説明                                                                                                                        | 優先度 |
| ------ | ------------------------ | ------------------------------------------------------------------------------------------------------------------------------- | ------ |
| F-01   | グローバルホットキー登録 | Command + Shift + 2 でアプリを起動。システム全体で有効（MASShortcutやEventTap使用）。競合時はユーザーがシステム設定で調整。     | 高     |
| F-02   | 画面領域選択             | ホットキー後、スクリーンショットのような選択モード（ScreenCaptureKit等でキャプチャ）。ESCでキャンセル。                         | 高     |
| F-03   | OCRテキスト抽出          | キャプチャ画像をVNImageRequestHandlerで処理。VNRecognizeTextRequestを使用（言語: 自動検出、精度: fast）。エラー時は空テキスト。 | 高     |
| F-04   | クリップボードコピー     | 抽出テキストをNSPasteboardにコピー。                                                                                            | 高     |
| F-05   | 通知表示                 | NSUserNotificationで「テキストをコピーしました」またはエラーメッセージを表示。                                                  | 中     |

## 3. 非機能要件

### パフォーマンス

- 起動からコピーまで: 2秒以内（標準的なMacで）。
- OCR精度: macOS Visionのデフォルト（英語/日本語対応、フォントによる）。

### セキュリティ/プライバシー

- 追加インストール不要: Vision.frameworkのみ使用。
- 権限: 初回起動時に画面録画権限を要求（System Settings > Privacy & Security > Screen Recording）。
- データ保存: なし（一時キャプチャ画像のみ、即削除）。

### 互換性

- OS: macOS 15 (Sequoia) 以降（Visionテキスト認識機能必須）。ScreenCaptureKitを使用。
- アーキテクチャ: Apple Silicon 対応（Universal Binary）。

### ユーザビリティ

- グローバル動作: 任意のアプリ上で使用可能。
- エラーハンドリング: 選択なし時は何もしない。OCR失敗時は通知。
- アクセシビリティ: キーボード操作中心。

### メンテナンス性

- コード: Swiftで記述、モジュール化（例: HotkeyManager, CaptureManager, OCRManager）。
- ビルド: Xcodeでビルド可能。オープンソースとしてGitHub公開推奨。

## 4. システムアーキテクチャ

### 高レベル設計

- アプリタイプ: メニューバーアプリ（NSStatusBar）またはバックグラウンドアプリ。UIは最小（通知のみ）。
- コンポーネント:
  - Hotkey Module: MASShortcutライブラリ（オープンソース）でホットキー登録。
  - Capture Module: ScreenCaptureKitで領域キャプチャ（macOS 15+対応）。
  - OCR Module: Vision.framework (VNRecognizeTextRequest)。
  - Output Module: NSPasteboardとNSUserNotification。

### データフロー

1. ホットキーイベント → キャプチャモード開始。
2. ユーザー選択 → 画像取得。
3. 画像 → Visionリクエスト → テキスト抽出。
4. テキスト → クリップボード + 通知。

### 技術スタック

- 言語: Swift 5+（macOCR参考のネイティブ実装）。
- フレームワーク: AppKit, Vision, ScreenCaptureKit, CoreGraphics。
- 外部ライブラリ: MASShortcut (GitHub: shpakovski/MASShortcut) でホットキー（最小依存）。
- 開発ツール: Xcode 15+。
- ビルド: Swift Package ManagerまたはCocoaPodsで依存管理（最小）。

## 5. UI/UX設計

### UI要素

- なし（バックグラウンド動作）。メニューバーアイコンをオプションで追加（終了/設定用）。
- 選択モード: macOS標準のクロスヘアカーソル（NormCap参考）。

### UXフロー

- ホットキー押下 → 画面暗転/選択モード。
- ドラッグ選択 → 自動処理 → 通知ポップアップ（1-2秒表示）。
- キャンセル: ESCキー。

### ワイヤーフレーム

（テキストベース記述）

- 選択モード: 全画面オーバーレイなし、単にカーソル変更。
- 通知: 標準macOS通知（タイトル: "ScreenTextExtractor", メッセージ: "テキストをコピーしました"）。

## 6. 実装ガイドライン

誰でも作れるよう、ステップバイステップで記述。Xcodeで新規Mac Appプロジェクトを作成し、以下を実装。

### ステップ1: プロジェクトセットアップ

- Xcode > Create a new Xcode project > macOS > App。
- 言語: Swift, Interface: SwiftUI or Storyboard（シンプルならAppDelegateベース）。
- Info.plistにNSAppleEventsUsageDescription追加（ホットキー用）。

### ステップ2: ホットキー実装（macOCR/Montelimar参考）

- MASShortcutを追加（Swift Package: https://github.com/shpakovski/MASShortcut）。
- AppDelegateで:
  ```swift
  import MASShortcut
  let shortcut = MASShortcut(key: .two, modifiers: [.command, .shift])
  MASShortcutMonitor.shared().register(shortcut) { captureScreen() }
  ```

### ステップ3: 画面キャプチャ（macOCR参考）

- 選択モード関数:
  ```swift
  func captureScreen() {
      // 領域選択UI（カスタムビューまたはScreenCaptureKitで実装）
      let rect = // ユーザー選択矩形取得 (NSScreen, CGEvent)
      // macOS 15+: ScreenCaptureKitを使用
      SCScreenshotManager.captureImage(contentFilter: filter, configuration: config) { image, error in
          if let image = image { performOCR(on: image) }
      }
  }
  ```
- 詳細: カスタムNSWindowで透明オーバーレイを作成し、マウスイベントでrect計算。macOS 15未満はCGDisplayCreateImageForRectを条件分岐。

### ステップ4: OCR実装（Vision標準、macOCR参考）

- ```swift
  import Vision
  func performOCR(on image: CGImage) {
      let request = VNRecognizeTextRequest { (request, error) in
          guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
          let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
          copyToClipboard(text)
      }
      request.recognitionLevel = .fast
      let handler = VNImageRequestHandler(cgImage: image)
      try? handler.perform([request])
  }
  ```

### ステップ5: クリップボードと通知

- ```swift
  func copyToClipboard(_ text: String) {
      NSPasteboard.general.clearContents()
      NSPasteboard.general.setString(text, forType: .string)
      showNotification("テキストをコピーしました")
  }
  func showNotification(_ message: String) {
      let notification = NSUserNotification()
      notification.title = "ScreenTextExtractor"
      notification.informativeText = message
      NSUserNotificationCenter.default.deliver(notification)
  }
  ```

### ステップ6: テストとデプロイ

- ビルド&ラン: 権限許可後、ホットキーテスト。
- 配布: .appとしてZip、またはGitHubリリース。

## 7. リスクと前提

- リスク: ホットキー競合（システム設定で解決）。Vision精度の限界（手書き非対応）。macOSバージョンによるAPI変更（ScreenCaptureKit移行）。
- 前提: 開発者はXcode基本知識あり。追加質問でサポート。

この要件定義書に基づき、誰でもXcodeでプロトタイプを作成可能。実装で不明点があれば、参照GitHubのIssueをチェック。
