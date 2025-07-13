# ScreenTextExtractor

macOS用のOCRアプリケーション。画面の任意の領域を選択して、テキストを抽出してクリップボードにコピーします。

## 機能

- **ホットキー**: `Cmd+Shift+2`でOCR機能を起動
- **領域選択**: 標準のCmd+Shift+4と同様の選択UI
- **OCR処理**: Apple Vision frameworkを使用した高精度なテキスト認識
- **日本語対応**: 日本語テキストの認識に最適化
- **クリップボード**: 抽出したテキストを自動でクリップボードにコピー

## システム要件

- macOS 15.0 (Sequoia) 以降
- 画面録画権限の許可が必要

## インストール

1. [Releases](https://github.com/schroneko/ScreenTextExtractor/releases) から最新の `ScreenTextExtractor-1.0.dmg` をダウンロード
2. DMGファイルをダブルクリックして開く
3. `ScreenTextExtractor.app`を`Applications`フォルダにドラッグ&ドロップ
4. アプリケーションフォルダまたはSpotlightから起動

## 使用方法

1. アプリを起動（メニューバーにアイコンが表示される）
2. `Cmd+Shift+2`を押す
3. 画面が暗くなったら、マウスでドラッグして範囲を選択
4. 選択した範囲のテキストがクリップボードにコピーされる

## 技術仕様

- **言語**: Swift 6
- **フレームワーク**: Vision, ScreenCaptureKit, AppKit
- **依存関係**: MASShortcut (ホットキー機能)
- **アーキテクチャ**: Universal Binary (Apple Silicon対応)

## 開発履歴

- 基本的なOCR機能の実装
- 標準のCmd+Shift+4と同様の選択UI
- 日本語OCRの最適化
- 権限管理の改善
- メニューバーアプリ化

## TODO

- ESCキーでのキャンセル機能の修正
- User Notifications frameworkへの移行
- アプリアイコンの作成
- 縦書きテキスト対応の検討