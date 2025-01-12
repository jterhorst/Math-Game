//
//  HostTVLaunchView.swift
//  Math Game Client
//
//  Created by Jason Terhorst on 1/10/25.
//

import SwiftUI

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
