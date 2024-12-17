//
//  MathGameClientViewModel.swift
//  Math Game Client
//
//  Created by Jason Terhorst on 12/15/24.
//

import Foundation
import SwiftUI

enum EventTypes: String, Codable {
    case join = "join"
    case leave = "leave"
    case question = "question"
    case answer = "answer"
    case heartbeat = "heartbeat"
}

struct Player: Codable {
    let name: String
    var score: Int
}

struct Event: Codable {
    let type: EventTypes
    let data: String
    let playerName: String?
    let players: [Player]?
    let question: Question?
}

final class Question: Codable {
    let lhs: Int
    let rhs: Int
    let correctAnswer: Int

    init() {
        let lhs = Int.random(in: 1...10)
        let rhs = Int.random(in: 1...10)
        let correctAnswer = lhs * rhs
        self.lhs = lhs
        self.rhs = rhs
        self.correctAnswer = correctAnswer
    }
}

class MathGameClientViewModel: ObservableObject {
    let userName: String?
    @Published var isActive = false
    @Published var currentQuestion: Question?
    @Published var players: [Player] = []
    @Published var currentPlayer: Player?
    @FocusState var focused: Bool
    
    private let devMode = false
    
    private var webSocketTask: URLSessionWebSocketTask?
    
    init(userName: String? = nil) {
        self.userName = userName
        self.connect()
    }
    
    private var host: String {
        devMode ? "ws://127.0.0.1:8080" : "wss://mathgame-server-llg5a.ondigitalocean.app"
    }
    
    private func connect() {
        var params = "device=\(UUID().uuidString)"
        if let userName {
            params = "username=\(userName)"
        }
        guard let url = URL(string: "\(host)/game?\(params)") else { return }
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
                    self.players = []
                    self.currentPlayer = nil
                    self.currentQuestion = nil
                    if self.webSocketTask?.closeCode != nil {
                        self.connect()
                    }
                case .success(let message):
                    switch message {
                    case .string(let text):
                        print("message: \(text)")
//                        self.messages.append(text)
                        if let data = text.data(using: .utf8) {
                            guard let event = try? JSONDecoder().decode(Event.self, from: data) else {
                                return
                            }
                            self.players = event.players ?? []
                            self.currentPlayer = self.players.first(where: { $0.name == self.userName })
                            switch event.type {
                            case .question:
                                self.currentQuestion = event.question
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
            }
        }
    }
    
    func sendMessage(_ message: String) {
        guard let result = Int(message) else { return }
        guard let package = try? JSONEncoder().encode(["type": EventTypes.answer.rawValue, "data": message]) else { return }
        guard let stringResult = String(data: package, encoding: .utf8) else { return }
        webSocketTask?.send(.string(stringResult)) { error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
}
