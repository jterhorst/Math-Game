//
//  NameEntryView.swift
//  Math Game Client
//
//  Created by Jason Terhorst on 1/10/25.
//

import SwiftUI

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
