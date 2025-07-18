//
//  HostTVRoomView.swift
//  Math Game Client
//
//  Created by Jason Terhorst on 1/10/25.
//

import SwiftUI

struct HostTVRoomView: View {
    @ObservedObject private var vm: MathGameHostViewModel
    @State private var showingAlert = false
    
    init(roomCode: String, connection: MathGameDataProvidable? = nil) {
        vm = MathGameHostViewModel(roomCode: roomCode, didDisconnect: {}, didUpdateQuestion: {}, connection: connection)
    }
    
    private func questionView(player: String?, question: Question) -> some View {
        var oldQuestion: Question? = vm.oldBattle?.questions.values.first
        if let player {
            oldQuestion = vm.oldBattle?.questions[player]
        }
        return QuestionView(question: question, answerView: {
            CardAnswerText("??")
        }, oldQuestion: oldQuestion, oldAnswerView: {
            CardAnswerText("\(oldQuestion?.correctAnswer ?? 0)")
        }, oldAnswerAnnotationView: {
            EmptyView()
        })
        .focusable()
    }
    
    private var activeBody: some View {
        VStack {
            Text("Join at mathbattle.tv, enter room code \(vm.roomCode)")
                .font(.headline)
                .foregroundStyle(Color.accent)
            Text("Time: \(vm.timeRemaining)")
                .font(.largeTitle)
            Spacer()
            HStack {
                if let battle = vm.activeBattle {
                    if battle.mode == .shared {
                        if let question = battle.questions.values.first {
                            Spacer()
                            questionView(player: nil, question: question)
                            Spacer()
                        }
                    } else {
                        let players = battle.questions.keys.shuffled()
                        ForEach(players, id: \.self) { player in
                            if let question = battle.questions[player] {
                                Spacer()
                                questionView(player: player, question: question)
                                Spacer()
                            }
                        }
                    }
                }
            }
            Spacer()
            HStack {
                Spacer()
                ForEach(vm.players, id: \.name) { player in
                    VStack {
                        Text(player.name)
                        Text("\(player.score)")
                    }
                    Spacer()
                }
            }
        }
    }
    
    private var inactiveBody: some View {
        VStack {
            
            Text("Join at mathbattle.tv on your mobile device")
                .font(.largeTitle)
            Text("enter room code \(vm.roomCode)")
                .font(.largeTitle)
                .foregroundStyle(Color.accent)
        }
    }
    
    var body: some View {
        VStack {
            if vm.players.isEmpty {
                inactiveBody
            } else {
                activeBody
            }
        }
#if os(tvOS)
        .onExitCommand {
            showingAlert.toggle()
        }
#endif
        .alert("New Game?", isPresented: $showingAlert) {
            Button("Cancel", role: .cancel) { }
            Button("New Game", role: .destructive) {
                vm.resetGame()
            }
        }
    }
}

#Preview("Host - Individual questions") {
    HostTVRoomView(roomCode: "YEST", connection: MockDataConnectionManager(userName: "Bob", roomCode: "YEST", mode: .speedTrial))
}

#Preview("Host - Shared") {
    HostTVRoomView(roomCode: "YEST", connection: MockDataConnectionManager(userName: "Bob", roomCode: "YEST", mode: .shared))
}
