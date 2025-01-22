//
//  PlayerView.swift
//  Math Game Client
//
//  Created by Jason Terhorst on 1/10/25.
//

import SwiftUI

private struct Shake: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

struct PlayerView: View {
    @State private var answer: String = ""
    @State private var attempts: Int = 0
    @FocusState private var textFieldFocused: Bool
    @ObservedObject private var vm: MathGameClientViewModel
    
    init(username: String, roomCode: String, didDisconnect: @escaping (() -> Void), connection: MathGameDataProvidable? = nil) {
        self.vm = MathGameClientViewModel(userName: username, roomCode: roomCode, didDisconnect: didDisconnect, didUpdateQuestion: {}, connection: connection)
        self.textFieldFocused = true
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
            Text("Score: \(vm.currentPlayer?.score ?? 0)")
            Spacer()
            if let battle = vm.activeBattle, let player = vm.currentPlayer, let question = battle.questions[player.name] {
                QuestionView(question: question, answerView: {
                    TextField("?", text: $answer)
                        .focused($textFieldFocused)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                        .font(Font.system(size: 84))
                        .keyboardType(.numberPad)
                        .onSubmit {
                            submit(answer)
                        }
                        .onChange(of: answer) {
                            vm.answer = answer
                        }
                }, oldQuestion: vm.oldBattle?.questions[player.name], oldAnswerView: {
                    CardAnswerText("\(vm.oldBattle?.questions[player.name]?.correctAnswer ?? 0)")
                }, oldAnswerAnnotationView: {
                    EmptyView()
                })
                .modifier(Shake(animatableData: CGFloat(attempts)))
            }
            Spacer()
            Button(action: {
                submit(answer)
            }, label: {
                Text("Send")
            })
            .disabled(answer.isEmpty)
            .font(Font.system(.largeTitle))
        }
    }
    
    func submit(_ result: String) {
        vm.sendMessage(result, incorrectAnswer: {
            withAnimation(.default) {
                self.attempts += 1
            } completion: {
                answer = ""
                textFieldFocused = true
            }
        })
        guard let player = vm.currentPlayer else { return }
        if Int(result) == vm.activeBattle?.questions[player.name]?.correctAnswer {
            answer = ""
            textFieldFocused = true
        }
    }
}

#Preview("Player") {
    PlayerView(username: "Bob", roomCode: "YEST", didDisconnect: {
        
    }, connection: MockDataConnectionManager(userName: "Bob", roomCode: "YEST"))
}
