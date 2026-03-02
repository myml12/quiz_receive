//
//  QuizViewModel.swift
//  quiz_receive
//
//  3台のボタン接続状態と「先に押された順」を保持。リセット対応。
//

import Foundation
import Combine
import AVFoundation

@MainActor
final class QuizViewModel: ObservableObject, QuizBLEManagerDelegate {
    @Published var statusText: String = "BLE を初期化しています..."
    @Published var connectionState: [String: Bool] = [:] // deviceName -> isConnected
    /// 受信した順（先頭が一番乗り）
    @Published var pressOrder: [String] = []
    @Published var isScanning: Bool = false

    private let ble = QuizBLEManager()
    private var melodyPlayer: AVAudioPlayer?

    init() {
        ble.delegate = self
    }

    func startScan() {
        isScanning = true
        ble.startScan()
    }

    func stopScan() {
        isScanning = false
        ble.stopScan()
    }

    func reset() {
        pressOrder.removeAll()
        statusText = "リセットしました。次の問題をどうぞ。"
    }

    // MARK: - QuizBLEManagerDelegate
    func didReceiveButtonPress(deviceName: String) {
        guard !pressOrder.contains(deviceName) else { return } // 同一問題で二重カウントしない
        playMelody()
        pressOrder.append(deviceName)
        if pressOrder.count == 1 {
            statusText = "1番乗り: \(displayName(deviceName))"
        }
    }

    private func playMelody() {
        melodyPlayer?.stop()
        guard let url = Bundle.main.url(forResource: "melody", withExtension: "mp3") else { return }
        do {
            melodyPlayer = try AVAudioPlayer(contentsOf: url)
            melodyPlayer?.play()
        } catch {
            // 再生失敗時は無視
        }
    }

    func didUpdateConnection(deviceName: String, isConnected: Bool) {
        connectionState[deviceName] = isConnected
        let count = connectionState.values.filter { $0 }.count
        if count > 0 {
            statusText = "\(count)台接続済み（1〜3台で利用可能）"
        }
    }

    func didUpdateStatus(_ text: String) {
        statusText = text
    }

    func isConnected(_ deviceName: String) -> Bool {
        connectionState[deviceName] ?? false
    }

    /// 表示用ラベル（button1 → 左 など）
    func displayName(_ deviceName: String) -> String {
        switch deviceName {
        case "button1": return "左"
        case "button2": return "中央"
        case "button3": return "右"
        default: return deviceName
        }
    }

    /// 1番乗りかどうか
    func isFirstPressed(_ deviceName: String) -> Bool {
        pressOrder.first == deviceName
    }

    /// 押した順位（1-based、未押下は nil）
    func order(of deviceName: String) -> Int? {
        guard let idx = pressOrder.firstIndex(of: deviceName) else { return nil }
        return idx + 1
    }
}
