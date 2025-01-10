//
//  ContentView.swift
//  Math Game
//
//  Created by Jason Terhorst on 12/9/24.
//

import SwiftUI
import SwiftData

struct NameEntryView: View {
    @FocusState private var nameFieldFocused: Bool
    @FocusState private var roomCodeFieldFocused: Bool
    @State var userName: String = ""
    @State var roomCode: String = ""
    @State var nameEntryComplete: ((String, String) -> Void)
    
    init(nameEntryComplete: @escaping ((String, String) -> Void)) {
        self.nameEntryComplete = nameEntryComplete
        nameFieldFocused = true
    }
    
    var body: some View {
        VStack {
            TextField("Enter your name", text: $userName)
                .multilineTextAlignment(.center)
                .font(Font.system(.title))
                .focused($nameFieldFocused)
                .onSubmit {
                    submit(userName, code: roomCode)
                }
            TextField("Room code", text: $roomCode)
                .multilineTextAlignment(.center)
                .font(Font.system(.title))
                .focused($roomCodeFieldFocused)
                .onSubmit {
                    submit(userName, code: roomCode)
                }
            Button(action: {
                submit(userName, code: roomCode)
            }, label: {
                Text("Send")
            })
            .disabled(userName.isEmpty || roomCode.isEmpty)
            .font(Font.system(.largeTitle))
        }
    }
    
    func submit(_ name: String, code: String) {
        nameEntryComplete(name, code)
    }
}

#Preview("Name entry") {
    NameEntryView(nameEntryComplete: { name, code in
        
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
    
    init(username: String, roomCode: String, didDisconnect: @escaping (() -> Void)) {
        self.vm = MathGameClientViewModel(userName: username, roomCode: roomCode, didDisconnect: didDisconnect, didUpdateQuestion: {})
        self.textFieldFocused = true
    }
    
    var body: some View {
        VStack {
            Text("Score: \(vm.currentPlayer?.score ?? 0)")
            Spacer()
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
                }, oldQuestion: vm.oldQuestion, oldAnswerView: {
                    CardAnswerText("\(vm.oldQuestion?.correctAnswer ?? 0)")
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
        if Int(result) == vm.currentQuestion?.correctAnswer {
            answer = ""
            textFieldFocused = true
        }
    }
}

#Preview("Player") {
    PlayerView(username: "Bob", roomCode: "YEST", didDisconnect: {
        
    })
}

struct HostTVRoomView: View {
    @ObservedObject private var vm: MathGameHostViewModel
    @State private var showingAlert = false
    
    init(roomCode: String) {
        vm = MathGameHostViewModel(roomCode: roomCode, didDisconnect: {}, didUpdateQuestion: {})
    }
    
    var body: some View {
        VStack {
            Text("Room code: \(vm.roomCode)")
                .font(.headline)
            Spacer()
            if let question = vm.currentQuestion {
                QuestionView(question: question, answerView: {
                    CardAnswerText("??")
                }, oldQuestion: vm.oldQuestion, oldAnswerView: {
                    CardAnswerText("\(vm.oldQuestion?.correctAnswer ?? 0)")
                }, oldAnswerAnnotationView: {
                    EmptyView()
                })
                .focusable()
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
    HostTVRoomView(roomCode: "YEST")
}

struct HostTVLaunchView: View {
    
    var body: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .scaleEffect(2, anchor: .center)
    }
}

#Preview("Host loading") {
    HostTVLaunchView()
}

struct HostTVView: View {
    @ObservedObject var model = MathGameNewRoomViewModel()
    
    var body: some View {
        if let roomCode = model.roomCode {
            HostTVRoomView(roomCode: roomCode)
        } else {
            HostTVLaunchView()
        }
    }
}

struct ContentView: View {
    @State private var userName: String?
    @State private var roomCode: String?
    var body: some View {
        #if os(tvOS)
        HostTVView()
        #else
        if let userName, let roomCode {
            PlayerView(username: userName, roomCode: roomCode, didDisconnect: {
                self.userName = nil
            })
        } else {
            NameEntryView(nameEntryComplete: { name, code  in
                userName = name
                roomCode = code
            })
        }
        #endif
    }
}
