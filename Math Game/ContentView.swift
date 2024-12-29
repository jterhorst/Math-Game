//
//  ContentView.swift
//  Math Game
//
//  Created by Jason Terhorst on 12/9/24.
//

import SwiftUI
import SwiftData

struct QuestionView: View {
    var question: Question
    var body: some View {
        VStack {
            Text("\(question.lhs)")
                .font(Font.system(size: 84))
                .foregroundStyle(.primary)
            Text("x \(question.rhs)")
                .font(Font.system(size: 84))
                .foregroundStyle(.primary)
        }
    }
}

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

struct PlayerView: View {
    @State private var answer: String = ""
    @FocusState private var textFieldFocused: Bool
    @ObservedObject private var vm: MathGameClientViewModel
    
    init(username: String, didDisconnect: @escaping (() -> Void)) {
        self.vm = MathGameClientViewModel(userName: username, didDisconnect: didDisconnect)
        self.textFieldFocused = true
        
    }
    
    var body: some View {
        VStack {
            Text("Score: \(vm.currentPlayer?.score ?? 0)")
            Spacer()
            VStack {
                if let question = vm.currentQuestion {
                    QuestionView(question: question)
                }
                TextField("?", text: $answer)
                    .focused($textFieldFocused)
                    .multilineTextAlignment(.center)
                    .foregroundStyle($vm.textEntryColor.wrappedValue)
                    .font(Font.system(size: 84))
                    .keyboardType(.numberPad)
                    .onSubmit {
                        submit(answer)
                    }
                    .onChange(of: answer) {
                        vm.answer = answer
                    }
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
        vm.sendMessage(result)
        if Int(result) == vm.currentQuestion?.correctAnswer {
            answer = ""
            textFieldFocused = true
        }
    }
}

struct HostTVView: View {
    @ObservedObject private var vm = MathGameClientViewModel(didDisconnect: {})
    var body: some View {
        VStack {
            Spacer()
            if let question = vm.currentQuestion {
                QuestionView(question: question)
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

#Preview {
    QuestionView(question: Question())
}
