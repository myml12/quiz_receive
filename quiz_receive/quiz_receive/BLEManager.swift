//
//  BLEManager.swift
//  quiz_receive
//
//  早押しクイズ用: button1 / button2 / button3 に接続し、Notify 受信順を通知
//

import Foundation
import CoreBluetooth

/// デバイス名（左=1, 中央=2, 右=3）
enum QuizButtonName: String, CaseIterable {
    case button1 = "button1"
    case button2 = "button2"
    case button3 = "button3"
}

protocol QuizBLEManagerDelegate: AnyObject {
    /// いずれかのボタンが押された（受信順で呼ばれる）
    func didReceiveButtonPress(deviceName: String)
    /// 接続状態が変化した
    func didUpdateConnection(deviceName: String, isConnected: Bool)
    /// ステータス文言（スキャン中等）
    func didUpdateStatus(_ text: String)
}

final class QuizBLEManager: NSObject {
    weak var delegate: QuizBLEManagerDelegate?

    private var central: CBCentralManager!
    private let deviceNames = Set(QuizButtonName.allCases.map(\.rawValue))

    // 早押しクイズ用 UUID（新規）
    private let serviceUUID = CBUUID(string: "e3b01001-8a0f-4a3b-9c8a-1b2c3d4e5f01")
    private let notifyCharUUID = CBUUID(string: "e3b01002-8a0f-4a3b-9c8a-1b2c3d4e5f01")

    /// 発見したペリフェラル（名前 → ペリフェラル）
    private var foundPeripherals: [String: CBPeripheral] = [:]
    /// ペリフェラル識別子 → デバイス名（接続後コールバックで名前を引くため）
    private var identifierToName: [UUID: String] = [:]
    /// デバイス名 → Notify 用キャラクタリスティック
    private var notifyCharacteristics: [String: CBCharacteristic] = [:]

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    func startScan() {
        guard central.state == .poweredOn else {
            delegate?.didUpdateStatus("Bluetooth をオンにしてください")
            return
        }
        foundPeripherals.removeAll()
        identifierToName.removeAll()
        notifyCharacteristics.removeAll()
        delegate?.didUpdateStatus("スキャン中... (1〜3台対応。接続できたらスキャン停止を押してください)")
        central.scanForPeripherals(withServices: [serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    func stopScan() {
        central.stopScan()
    }

    private func deviceName(for peripheral: CBPeripheral) -> String? {
        if let name = peripheral.name, deviceNames.contains(name) { return name }
        return identifierToName[peripheral.identifier]
    }
}

// MARK: - CBCentralManagerDelegate
extension QuizBLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else {
            delegate?.didUpdateStatus("Bluetooth: \(central.state.rawValue)")
            return
        }
        startScan()
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        let name = peripheral.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? ""
        guard deviceNames.contains(name), foundPeripherals[name] == nil else { return }

        delegate?.didUpdateStatus("発見: \(name) → 接続中")
        foundPeripherals[name] = peripheral
        identifierToName[peripheral.identifier] = name
        peripheral.delegate = self
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard let name = deviceName(for: peripheral) else { return }
        delegate?.didUpdateConnection(deviceName: name, isConnected: true)
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard let name = deviceName(for: peripheral) else { return }
        delegate?.didUpdateStatus("切断: \(name)")
        delegate?.didUpdateConnection(deviceName: name, isConnected: false)
        notifyCharacteristics[name] = nil
        // 再接続はユーザーが「スキャン」し直す想定とする（必要ならここで connect 再試行も可）
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        guard let name = deviceName(for: peripheral) else { return }
        delegate?.didUpdateStatus("接続失敗: \(name)")
        delegate?.didUpdateConnection(deviceName: name, isConnected: false)
        foundPeripherals[name] = nil
        identifierToName[peripheral.identifier] = nil
    }
}

// MARK: - CBPeripheralDelegate
extension QuizBLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            delegate?.didUpdateStatus("サービス取得エラー: \(error.localizedDescription)")
            return
        }
        guard let _ = deviceName(for: peripheral),
              let services = peripheral.services else { return }
        for s in services where s.uuid == serviceUUID {
            peripheral.discoverCharacteristics([notifyCharUUID], for: s)
            break
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            delegate?.didUpdateStatus("キャラクタリスティック取得エラー: \(error.localizedDescription)")
            return
        }
        guard let name = deviceName(for: peripheral), let chars = service.characteristics else { return }
        for c in chars where c.uuid == notifyCharUUID {
            notifyCharacteristics[name] = c
            peripheral.setNotifyValue(true, for: c)
            break
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil { return }
        guard characteristic.uuid == notifyCharUUID,
              let data = characteristic.value, data.count >= 1,
              data[0] == 0x01 else { return }
        guard let name = deviceName(for: peripheral) else { return }
        delegate?.didReceiveButtonPress(deviceName: name)
    }
}
