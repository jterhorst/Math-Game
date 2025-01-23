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
    @Published var activeBattle: Battle?
    @Published var timeRemaining: Int = Config.maxTime
    @Published var oldBattle: Battle?
    @Published var players: [Player] = []
    @FocusState var focused: Bool
    var answer: String = ""
    
    private let didDisconnect: (() -> Void)
    private let didUpdateQuestion: (() -> Void)
    
    private var connection: MathGameDataProvidable?
    
    init(roomCode: String, didDisconnect: @escaping (() -> Void), didUpdateQuestion: @escaping (() -> Void), connection: MathGameDataProvidable? = nil) {
        self.roomCode = roomCode
        self.didDisconnect = didDisconnect
        self.didUpdateQuestion = didUpdateQuestion
        self.connection = connection != nil ? connection : MathGameDataConnectionManager(deviceName: deviceName, roomCode: roomCode, delegate: self)
        self.connection?.delegate = self
        self.connect()
    }
    
    private func connect() {
        self.connection?.connect()
    }
    
    func sendMessage(_ message: String, incorrectAnswer: () -> Void) {
        self.connection?.sendMessage(message, incorrectAnswer: incorrectAnswer)
    }
    
    func resetGame() {
        self.connection?.resetGame()
    }
}

extension MathGameHostViewModel: MathGameDataProvidableDelegate {
    func receivedEvent(_ event: Event) {
        self.isActive = true
        self.players = event.players ?? []
        self.timeRemaining = event.activeBattle?.remainingTime ?? 0
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
        self.activeBattle = nil
        self.connect()
    }
}
