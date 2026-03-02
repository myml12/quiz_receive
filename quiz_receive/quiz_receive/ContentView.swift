//
//  ContentView.swift
//  quiz_receive
//
//  iPad 横向き想定。左=青(button1)、中央=黄(button2)、右=赤(button3)。先に押されたボタンを大きく表示。
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = QuizViewModel()

    private let leftColor = Color(red: 0.2, green: 0.4, blue: 0.9)   // 青
    private let centerColor = Color(red: 0.95, green: 0.85, blue: 0.2) // 黄
    private let rightColor = Color(red: 0.9, green: 0.25, blue: 0.2)   // 赤

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            VStack(spacing: 0) {
                // ステータス・操作バー（上部）
                statusBar(isLandscape: isLandscape)
                    .frame(height: isLandscape ? 56 : 72)
                    .background(Color(.systemGray6))

                // 3台のボタンエリア（左・中央・右）― タップでリセット
                HStack(spacing: 0) {
                    buttonPanel(deviceName: "button1", color: leftColor, label: "左", isLandscape: isLandscape)
                    buttonPanel(deviceName: "button2", color: centerColor, label: "中央", isLandscape: isLandscape)
                    buttonPanel(deviceName: "button3", color: rightColor, label: "右", isLandscape: isLandscape)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.reset()
                }
            }
            .ignoresSafeArea(.container)
        }
        .preferredColorScheme(.light)
    }

    private func statusBar(isLandscape: Bool) -> some View {
        HStack(spacing: 16) {
            Text(viewModel.statusText)
                .lineLimit(2)
                .font(.system(size: isLandscape ? 15 : 14, weight: .medium))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if viewModel.isScanning {
                Button("スキャン停止") {
                    viewModel.stopScan()
                }
                .buttonStyle(.bordered)
            } else {
                Button("スキャン開始") {
                    viewModel.startScan()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, 20)
    }

    private func buttonPanel(deviceName: String, color: Color, label: String, isLandscape: Bool) -> some View {
        let isFirst = viewModel.isFirstPressed(deviceName)
        let order = viewModel.order(of: deviceName)
        let connected = viewModel.isConnected(deviceName)

        return ZStack {
            color
                .opacity(connected ? 0.95 : 0.5)

            VStack(spacing: 8) {
                Text(label)
                    .font(.system(size: isLandscape ? 28 : 22, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)

                if let order = order {
                    Text(isFirst ? "1番乗り!" : "\(order)番目")
                        .font(.system(size: isFirst ? (isLandscape ? 48 : 36) : (isLandscape ? 24 : 20), weight: .heavy))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.4), radius: 2, x: 1, y: 1)
                } else {
                    Text(connected ? "待機中" : "未接続")
                        .font(.system(size: isLandscape ? 20 : 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .scaleEffect(isFirst ? 1.15 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isFirst)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(isFirst ? Color.white : Color.clear, lineWidth: 6)
        )
    }
}

#Preview {
    ContentView()
}
