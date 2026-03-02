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

## License

MIT
