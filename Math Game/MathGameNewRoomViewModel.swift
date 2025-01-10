//
//  MathGameNewRoomViewModel.swift
//  Math Game Client
//
//  Created by Jason Terhorst on 1/7/25.
//

import Foundation

class MathGameNewRoomViewModel: ObservableObject {
    
    @Published var roomCode: String? = nil
    private var task: URLSessionTask?
    
    init() {
        loadRoomCode()
    }
    
    func loadRoomCode() {
        guard let url = URL(string: "\(Config.host)/new_game") else { return }
        let request = URLRequest(url: url)
        task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                return
            }
            guard let data else {
                return
            }
            if let dataObject = try? JSONDecoder().decode([String: String].self, from: data) {
                DispatchQueue.main.async {
                    self.roomCode = dataObject["code"]
                }
                print("updated room code to \(String(describing: self.roomCode))")
            }
        }
        task?.resume()
    }
}
