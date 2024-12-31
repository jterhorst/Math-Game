//
//  ContentView.swift
//  Math Game
//
//  Created by Jason Terhorst on 12/9/24.
//

import SwiftUI
import SwiftData

struct NameEntryView: View {
    @FocusState private var textFieldFocused: Bool
    @State var userName: String = ""
    @State var nameEntryComplete: ((String) -> Void)
    
    init(nameEntryComplete: @escaping ((String) -> Void)) {
        self.nameEntryComplete = nameEntryComplete
        textFieldFocused = true
    }
    
    var body: some View {
        VStack {
            Spacer()
            TextField("Enter your name", text: $userName)
                .multilineTextAlignment(.center)
                .font(Font.system(.title))
                .focused($textFieldFocused)
                .onSubmit {
                    submit(userName)
                }
            Spacer()
            Button(action: {
                submit(userName)
            }, label: {
                Text("Send")
            })
            .disabled(userName.isEmpty)
            .font(Font.system(.largeTitle))
        }
    }
    
    func submit(_ result: String) {
        nameEntryComplete(userName)
    }
}

#Preview("Name entry") {
    NameEntryView(nameEntryComplete: { name in
        
    })
}

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
    
    init(username: String, didDisconnect: @escaping (() -> Void)) {
        self.vm = MathGameClientViewModel(userName: username, didDisconnect: didDisconnect)
        self.textFieldFocused = true
        
    }
    
    var body: some View {
//        VStack {
//            Text("Score: \(vm.currentPlayer?.score ?? 0)")
//            Spacer()
            if let question = vm.currentQuestion {
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
                })
                .modifier(Shake(animatableData: CGFloat(attempts)))
            }
//            Spacer()
//            Button(action: {
//                submit(answer)
//            }, label: {
//                Text("Send")
//            })
//            .disabled(answer.isEmpty)
//            .font(Font.system(.largeTitle))
//        }
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
        if Int(result) == vm.currentQuestion?.correctAnswer {
            answer = ""
            textFieldFocused = true
        }
    }
}

#Preview("Player") {
    PlayerView(username: "Bob", didDisconnect: {
        
    })
}

struct HostTVView: View {
    @ObservedObject private var vm = MathGameClientViewModel(didDisconnect: {})
    var body: some View {
        VStack {
            Spacer()
            if let question = vm.currentQuestion {
                QuestionView(question: question, answerView: {
                    CardAnswerText("??")
                })
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
}

#Preview("Host") {
    HostTVView()
}

struct ContentView: View {
    @State private var userName: String?
    var body: some View {
        #if os(tvOS)
        HostTVView()
        #else
        if let userName {
            PlayerView(username: userName, didDisconnect: {
                self.userName = nil
            })
        } else {
            NameEntryView(nameEntryComplete: { name in
                userName = name
            })
        }
        #endif
    }
}
