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
    
    private func questionView(player: String, question: Question) -> some View {
        QuestionView(question: question, answerView: {
            CardAnswerText("??")
        }, oldQuestion: vm.oldBattle?.questions[player], oldAnswerView: {
            CardAnswerText("\(vm.oldBattle?.questions[player]?.correctAnswer ?? 0)")
        }, oldAnswerAnnotationView: {
            EmptyView()
        })
        .focusable()
    }
    
    var body: some View {
        VStack {
            Text("Room code: \(vm.roomCode)")
                .font(.headline)
            Spacer()
            if let battle = vm.activeBattle {
                let players = battle.questions.keys.shuffled()
                ForEach(players, id: \.self) { player in
                    if let question = battle.questions[player] {
                        questionView(player: player, question: question)
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

#Preview("Host") {
    HostTVRoomView(roomCode: "YEST", connection: MockDataConnectionManager(userName: "Bob", roomCode: "YEST"))
}
