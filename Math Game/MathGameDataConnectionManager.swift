//
//  MathGameDataConnectionManager.swift
//  Math Game Client
//
//  Created by Jason Terhorst on 1/10/25.
//

import Foundation

protocol MathGameDataProvidableDelegate {
    func receivedEvent(_ event: Event)
    func receivedError(_ error: Error)
    func closedConnection()
}

protocol MathGameDataProvidable {
    var delegate: (MathGameDataProvidableDelegate)? { get set }
    func connect()
    func sendMessage(_ message: String, incorrectAnswer: () -> Void)
    func resetGame()
}

class MockDataConnectionManager: MathGameDataProvidable {
    let userName: String
    let roomCode: String
    var delegate: (any MathGameDataProvidableDelegate)?
    var question = Question()
    
    init(userName: String, roomCode: String, delegate: (any MathGameDataProvidableDelegate)? = nil) {
        self.userName = userName
        self.roomCode = roomCode
        self.delegate = delegate
    }
    
    private var players: [Player] {
        [Player(name: userName, score: 5), Player(name: "Jeff", score: 2)]
    }
    
    func connect() {
        delegate?.receivedEvent(Event(type: .join, data: userName, playerName: userName, players: players, question: question))
        self.delegate?.receivedEvent(Event(type: .question, data: "\(self.question.lhs) * \(question.rhs)", playerName: self.userName, players: players, question: self.question))
        simulateOtherPlayerAnswer()
    }
    
    private func simulateOtherPlayerAnswer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            guard let self = self else {
                return
            }
            delegate?.receivedEvent(Event(type: .answer, data: "\(self.question.correctAnswer)", playerName: "Jeff", players: players, question: question))
            self.question = Question()
            self.delegate?.receivedEvent(Event(type: .question, data: "\(self.question.lhs) * \(question.rhs)", playerName: self.userName, players: players, question: self.question))
        }
    }
    
    func sendMessage(_ message: String, incorrectAnswer: () -> Void) {
        delegate?.receivedEvent(Event(type: .answer, data: message, playerName: userName, players: players, question: question))
        question = Question()
        delegate?.receivedEvent(Event(type: .question, data: "\(question.lhs) * \(question.rhs)", playerName: userName, players: players, question: question))
    }
    
    func resetGame() {
        question = Question()
        delegate?.receivedEvent(Event(type: .question, data: "\(question.lhs) * \(question.rhs)", playerName: userName, players: players, question: question))
    }
}

class MathGameDataConnectionManager: MathGameDataProvidable {
    let userName: String
    let roomCode: String
    
    private var webSocketTask: URLSessionWebSocketTask? = nil
    var delegate: (any MathGameDataProvidableDelegate)?
    
    init(userName: String, roomCode: String, delegate: (any MathGameDataProvidableDelegate)? = nil) {
        self.userName = userName
        self.roomCode = roomCode
        self.delegate = delegate
    }
    
    func connect() {
        let params = "code=\(roomCode)&username=\(userName)"
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
                    self.delegate?.receivedError(error)
                    
                    if self.webSocketTask?.closeCode != nil {
                        self.delegate?.closedConnection()
                    }
                case .success(let message):
                    switch message {
                    case .string(let text):
                        print("message: \(text)")
                        if let data = text.data(using: .utf8) {
                            guard let event = try? JSONDecoder().decode(Event.self, from: data) else {
                                return
                            }
                            self.delegate?.receivedEvent(event)
                        }
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
                self.delegate?.closedConnection()
            }
        }
    }
    
    func sendMessage(_ message: String, incorrectAnswer: () -> Void) {
        
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
