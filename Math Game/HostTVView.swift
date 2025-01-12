//
//  HostTVView.swift
//  Math Game Client
//
//  Created by Jason Terhorst on 1/10/25.
//

import SwiftUI

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
