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
    
    @State var loadingNewRoom = false
    @State var roomLoaded = false
    @State var roomLoadComplete: ((String) -> Void)? = nil
    
    @State var nameEntryComplete: ((String, String) -> Void)
    
    private var roomLoader: MathGameNewRoomProvider
    
    init(roomLoader: MathGameNewRoomProvider = MathGameNewRoomLoader(), roomLoaded: Bool = false, roomCode: String = "", roomLoadComplete: ((String) -> Void)? = nil, nameEntryComplete: @escaping ((String, String) -> Void)) {
        self.roomLoader = roomLoader
        self.roomLoaded = roomLoaded
        self.roomCode = roomCode
        self.roomLoadComplete = roomLoadComplete
        self.nameEntryComplete = nameEntryComplete
        nameFieldFocused = true
    }
    
    var body: some View {
        VStack {
            
            Spacer()
            Text("Join existing game:")
            
            if roomLoaded {
                Text("Room code: \(roomCode)")
                .font(Font.system(.title))
            }
            
            TextField("Enter your name", text: $userName)
                .multilineTextAlignment(.center)
                .font(Font.system(.title))
                .focused($nameFieldFocused)
                .onSubmit {
                    submit(userName, code: roomCode)
                }
            if roomLoaded == false {
                TextField("Room code", text: $roomCode)
                    .multilineTextAlignment(.center)
                    .font(Font.system(.title))
                    .focused($roomCodeFieldFocused)
                    .onSubmit {
                        submit(userName, code: roomCode)
                    }
            }
            Button(action: {
                submit(userName, code: roomCode)
            }, label: {
                Text("Send")
            })
            .disabled(userName.isEmpty || roomCode.isEmpty)
            .font(Font.system(.largeTitle))
            Spacer()
            
            if loadingNewRoom {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(2, anchor: .center)
            } else if roomLoaded == false {
                Button(action: {
                    createRoom()
                }, label: {
                    Text("Create new game")
                })
                .font(Font.system(.largeTitle))
            }
            
            Spacer()
        }
    }
    
    func createRoom() {
        self.loadingNewRoom = true
        roomLoader.loadRoomCode({ code in
            loadingNewRoom = false
            if let code {
                roomLoaded = true
                roomCode = code
                roomLoadComplete?(code)
            }
        })
    }
    
    func submit(_ name: String, code: String) {
        nameEntryComplete(name, code)
    }
}

#Preview("Name entry") {
    NameEntryView(roomLoader: MockRoomLoader(), roomLoadComplete: { code in
        
    }, nameEntryComplete: { name, code in
        
    })
}
