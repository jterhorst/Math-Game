//
//  ContentView.swift
//  Math Game
//
//  Created by Jason Terhorst on 12/9/24.
//

import SwiftUI
import SwiftData

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
        } else if let roomCode {
            NameEntryView(roomLoaded: true, roomCode: roomCode, nameEntryComplete: { name, code in
                userName = name
            })
        } else {
            NameEntryView(roomLoadComplete: { code in
                roomCode = code
            }, nameEntryComplete: { name, code  in
                userName = name
                roomCode = code
            })
        }
        #endif
    }
}
