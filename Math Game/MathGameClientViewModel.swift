//
//  MathGameClientViewModel.swift
//  Math Game Client
//
//  Created by Jason Terhorst on 12/15/24.
//

import Foundation
import SwiftUI

class MathGameClientViewModel: ObservableObject {
    let userName: String?
    let roomCode: String?
    @Published var isActive = false
    @Published var activeBattle: Battle?
    @Published var oldBattle: Battle?
    @Published var players: [Player] = []
    @Published var currentPlayer: Player?
    @FocusState var focused: Bool
    var answer: String = ""
    
    private var connection: MathGameDataProvidable?
    
    private let didDisconnect: (() -> Void)
    private let didUpdateQuestion: (() -> Void)
    
    init(userName: String? = nil, roomCode: String? = nil, didDisconnect: @escaping (() -> Void), didUpdateQuestion: @escaping (() -> Void), connection: MathGameDataProvidable? = nil) {
        self.userName = userName
        self.roomCode = roomCode
        self.didDisconnect = didDisconnect
        self.didUpdateQuestion = didUpdateQuestion
        self.connection = connection != nil ? connection : MathGameDataConnectionManager(userName: userName ?? "", roomCode: roomCode ?? "", delegate: self)
        self.connection?.delegate = self
        self.connect()
    }
    
    private func connect() {
        self.connection?.connect()
    }
    
    func sendMessage(_ message: String, incorrectAnswer: () -> Void) {
        guard let result = Int(message) else { return }
        guard let currentPlayer else { return }
        guard let question = self.activeBattle?.questions[currentPlayer] else { return }
        guard result == question.correctAnswer else {
            incorrectAnswer()
            return
        }
        self.connection?.sendMessage(message, incorrectAnswer: incorrectAnswer)
    }
    
    func resetGame() {
        self.connection?.resetGame()
    }
}

extension MathGameClientViewModel: MathGameDataProvidableDelegate {
    func receivedEvent(_ event: Event) {
        self.isActive = true
        self.players = event.players ?? []
        self.currentPlayer = self.players.first(where: { $0.name == self.userName })
        switch event.type {
        case .battle:
            if self.activeBattle != event.activeBattle {
                self.oldBattle = self.activeBattle
                self.activeBattle = event.activeBattle
            }
            self.focused = true
        default: break
        }
    }
    
    func receivedError(_ error: any Error) {
        print(error.localizedDescription)
    }
    
    func closedConnection() {
        self.isActive = false
        self.didDisconnect()
        self.players = []
        self.currentPlayer = nil
        self.activeBattle = nil
        self.connect()
    }
}
