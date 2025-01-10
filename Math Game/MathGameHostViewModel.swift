//
//  MathGameHostViewModel.swift
//  Math Game Client
//
//  Created by Jason Terhorst on 1/7/25.
//

import Foundation
import SwiftUI

class MathGameHostViewModel: ObservableObject {
    let deviceName: String = UUID().uuidString
    let roomCode: String
    @Published var isActive = false
    @Published var currentQuestion: Question?
    @Published var oldQuestion: Question?
    @Published var players: [Player] = []
    @FocusState var focused: Bool
    var answer: String = ""
    
    private let didDisconnect: (() -> Void)
    private let didUpdateQuestion: (() -> Void)
    
    private var webSocketTask: URLSessionWebSocketTask?
    
    init(roomCode: String, didDisconnect: @escaping (() -> Void), didUpdateQuestion: @escaping (() -> Void)) {
        self.roomCode = roomCode
        self.didDisconnect = didDisconnect
        self.didUpdateQuestion = didUpdateQuestion
        self.connect()
    }
    
    private func connect() {
        var params = "code=\(roomCode)&device=\(deviceName)"
        guard let url = URL(string: "\(Config.host)/game?\(params)") else { return }
        let request = URLRequest(url: url)
        webSocketTask = URLSession.shared.webSocketTask(with: request)
        webSocketTask?.resume()
        receiveMessage()
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { result in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    print(error.localizedDescription)
                    if self.webSocketTask?.closeCode != nil {
                        self.players = []
                        self.currentQuestion = nil
                        self.connect()
                    }
                case .success(let message):
                    switch message {
                    case .string(let text):
                        print("message: \(text)")
                        if let data = text.data(using: .utf8) {
                            guard let event = try? JSONDecoder().decode(Event.self, from: data) else {
                                return
                            }
                            self.players = event.players ?? []
                            switch event.type {
                            case .question:
                                if self.currentQuestion != event.question {
                                    self.oldQuestion = self.currentQuestion
                                    self.currentQuestion = event.question
                                }
                                self.focused = true
                            default: break
                            }
                        }
                        self.isActive = true
                        self.receiveMessage()
                    case .data(_):
                        // Handle binary data
                        break
                    @unknown default:
                        break
                    }
                }
            }
            if self.webSocketTask?.progress.isCancelled == false {
                
            } else {
                self.isActive = false
                self.players = []
                self.didDisconnect()
            }
        }
    }
    
    func sendMessage(_ message: String, incorrectAnswer: () -> Void) {
        guard let result = Int(message) else { return }
        guard result == self.currentQuestion?.correctAnswer else {
            incorrectAnswer()
            return
        }
        guard let package = try? JSONEncoder().encode(["type": EventTypes.answer.rawValue, "data": message]) else { return }
        guard let stringResult = String(data: package, encoding: .utf8) else { return }
        webSocketTask?.send(.string(stringResult)) { error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    func resetGame() {
        guard let package = try? JSONEncoder().encode(["type": EventTypes.reset.rawValue, "data": ""]) else { return }
        guard let stringResult = String(data: package, encoding: .utf8) else { return }
        webSocketTask?.send(.string(stringResult)) { error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
}
