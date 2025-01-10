//
//  Config.swift
//  Math Game Client
//
//  Created by Jason Terhorst on 1/7/25.
//

struct Config {
    private static let devMode = true
    
    static var host: String {
        devMode ? "ws://127.0.0.1:8080" : "wss://mathgame-server-llg5a.ondigitalocean.app"
    }
}
