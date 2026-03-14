# quiz_receive

> BLE-based buzzer system for 3-player quiz games — XIAO ESP32S3 + iOS

3台の BLE ボタン（XIAO ESP32S3）と iOS アプリで構成される早押しクイズシステム。  
ボタン押下を BLE Notify で iOS デバイスに送信し、受信順で順位を判定する。

## Architecture

```
┌────────────┐        BLE Notify        ┌──────────────┐
│  button 1  │ ──────────────────────▶  │              │
│  (ESP32S3) │                          │    iOS App   │
├────────────┤                          │   (SwiftUI)  │
│  button 2  │ ──────────────────────▶  │              │
│  (ESP32S3) │                          │  受信順で判定  │
├────────────┤                          │  順位を表示    │
│  button 3  │ ──────────────────────▶  │              │
│  (ESP32S3) │                          └──────────────┘
└────────────┘
```

## Project Structure

```
quiz_button1.ino        # Firmware for button 1
quiz_button2.ino        # Firmware for button 2
quiz_button3.ino        # Firmware for button 3
quiz_receive/           # iOS app (Xcode project)
└── quiz_receive/
    ├── ContentView.swift
    ├── QuizViewModel.swift
    ├── BLEManager.swift
    └── quiz_receiveApp.swift
```

## Tech Stack

| Layer | Stack |
|-------|-------|
| Hardware | XIAO ESP32S3 × 3 + tactile switch (D4) |
| Firmware | Arduino (ESP32 BLE) |
| App | Swift / SwiftUI / CoreBluetooth / AVFoundation |
| Protocol | BLE GATT Notify (`0x01` on press) |

## Getting Started

### Firmware

```bash
# Arduino IDE で XIAO ESP32S3 ボードを選択し、各 .ino を書き込む
# D4 – GND 間にタクトスイッチを接続
```

### iOS App

```bash
open quiz_receive/quiz_receive.xcodeproj
# Xcode で Development Team を設定 → 実機に Run (⌘R)
```

## Usage

1. ESP32 3台の電源を入れる
2. アプリで **スキャン開始** → 3台接続
3. ボタン押下順に順位が表示される
4. 画面タップでリセット → 次の問題へ

## ボタンを追加する場合

4台目以降のボタンを使うには、次の4箇所を変更する。

### 1. ファームウェア（Arduino）

既存の `quiz_button1.ino` をコピーし、**デバイス名だけ**変えた `.ino` を用意する。

```cpp
// 例: quiz_button4.ino
static const char* BLE_DEVICE_NAME = "button4";  // ここだけ変更
// UUID_SERVICE / UUID_CHAR_NOTIFY はそのまま
```

その `.ino` を書き込んだ ESP32 を1台用意し、D4–GND にタクトスイッチを接続する。

### 2. BLEManager.swift

`QuizButtonName` に新しい case を追加する。

```swift
enum QuizButtonName: String, CaseIterable {
    case button1 = "button1"
    case button2 = "button2"
    case button3 = "button3"
    case button4 = "button4"   // 追加
}
```

アプリはこの enum に含まれる名前のペリフェラルだけを接続対象にする。

### 3. QuizViewModel.swift

`displayName(_:)` の switch に、追加したボタンの表示名を追加する。

```swift
case "button4": return "4番"   // 任意のラベル
default: return deviceName
```

### 4. ContentView.swift

- `buttonPanel(deviceName:color:label:isLandscape:)` を呼ぶ行を1つ増やす（例: `button4` 用に色とラベルを指定）。
- 4台以上にする場合は、レイアウトを `HStack` 1行のままにするか、`VStack` で行を分けて 2 列にするかは好みで調整する。

| ファイル | 変更内容 |
|----------|----------|
| 新規 `.ino` | `BLE_DEVICE_NAME` を `"buttonN"` に設定 |
| `BLEManager.swift` | `QuizButtonName` に `case buttonN = "buttonN"` を追加 |
| `QuizViewModel.swift` | `displayName` に `"buttonN"` のラベルを追加 |
| `ContentView.swift` | 対応する `buttonPanel` を1つ追加（色・ラベルを指定） |

## License

MIT
