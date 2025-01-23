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
    let battleMode: BattleMode
    var delegate: (any MathGameDataProvidableDelegate)?
    lazy var battle = Battle(questions: ["Jeff": Question(), userName: Question()], mode: battleMode)
    
    init(userName: String, roomCode: String, mode: BattleMode = .shared, delegate: (any MathGameDataProvidableDelegate)? = nil) {
        self.userName = userName
        self.roomCode = roomCode
        self.battleMode = mode
        self.delegate = delegate
    }
    
    private var players: [Player] {
        [Player(name: userName, score: 5), Player(name: "Jeff", score: 2)]
    }
    
    func connect() {
        delegate?.receivedEvent(Event(type: .join, data: userName, playerName: userName, players: players, activeBattle: battle))
        self.delegate?.receivedEvent(Event(type: .battle, data: Battle.dataString(self.battle), playerName: self.userName, players: players, activeBattle: battle))
        simulateOtherPlayerAnswer()
        _ = Task { [weak self] in
            while self?.battle.remainingTime ?? 0 > 0 {
                try? await Task.sleep(nanoseconds: 1000000000)
                guard let weakBattle = self?.battle else {
                    return
                }
                self?.battle.remainingTime = (self?.battle.remainingTime ?? 0) - 1
                self?.delegate?.receivedEvent(Event(type: .timerTick, data: Battle.dataString(weakBattle), playerName: nil, players: self?.players, activeBattle: weakBattle))
            }
        }
    }
    
    private func updateQuestions() {
        battle = Battle(questions: ["Jeff": Question(), userName: Question()], mode: battleMode)
    }
    
    private func simulateOtherPlayerAnswer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            guard let self = self else {
                return
            }
            guard let player = players.first(where: {$0.name == self.userName}) else { return }
            delegate?.receivedEvent(Event(type: .answer, data: Battle.dataString(self.battle), playerName: "Jeff", players: players, activeBattle: battle))
            updateQuestions()
            self.delegate?.receivedEvent(Event(type: .battle, data: Battle.dataString(self.battle), playerName: self.userName, players: players, activeBattle: battle))
        }
    }
    
    func sendMessage(_ message: String, incorrectAnswer: () -> Void) {
        delegate?.receivedEvent(Event(type: .answer, data: message, playerName: userName, players: players, activeBattle: battle))
        updateQuestions()
        delegate?.receivedEvent(Event(type: .battle, data: Battle.dataString(self.battle), playerName: userName, players: players, activeBattle: battle))
    }
    
    func resetGame() {
        updateQuestions()
        delegate?.receivedEvent(Event(type: .battle, data: Battle.dataString(self.battle), playerName: userName, players: players, activeBattle: battle))
    }
}

class MathGameDataConnectionManager: MathGameDataProvidable {
    let deviceName: String?
    let userName: String?
    let roomCode: String
    
    private var webSocketTask: URLSessionWebSocketTask? = nil
    var delegate: (any MathGameDataProvidableDelegate)?
    
    init(deviceName: String? = nil, userName: String? = nil, roomCode: String, delegate: (any MathGameDataProvidableDelegate)? = nil) {
        self.deviceName = deviceName
        self.userName = userName
        self.roomCode = roomCode
        self.delegate = delegate
    }
    
    func connect() {
        let clientParam = (deviceName != nil) ? "device=\(deviceName ?? "")" : "user=\(userName ?? "")"
        let params = "code=\(roomCode)&\(clientParam)"
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
