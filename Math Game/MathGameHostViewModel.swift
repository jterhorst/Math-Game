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
    
    private var connection: MathGameDataProvidable?
    
    init(roomCode: String, didDisconnect: @escaping (() -> Void), didUpdateQuestion: @escaping (() -> Void), connection: MathGameDataProvidable? = nil) {
        self.roomCode = roomCode
        self.didDisconnect = didDisconnect
        self.didUpdateQuestion = didUpdateQuestion
        self.connection = connection != nil ? connection : MathGameDataConnectionManager(userName: deviceName, roomCode: roomCode, delegate: self)
        self.connection?.delegate = self
        self.connect()
    }
    
    private func connect() {
        self.connection?.connect()
    }
    
    func sendMessage(_ message: String, incorrectAnswer: () -> Void) {
        guard let result = Int(message) else { return }
        guard result == self.currentQuestion?.correctAnswer else {
            incorrectAnswer()
            return
        }
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
    
    func receivedError(_ error: any Error) {
        print(error.localizedDescription)
    }
    
    func closedConnection() {
        self.isActive = false
        self.didDisconnect()
        self.players = []
        self.currentQuestion = nil
        self.connect()
    }
}
