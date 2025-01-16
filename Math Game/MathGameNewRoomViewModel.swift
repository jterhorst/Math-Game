//
//  MathGameNewRoomViewModel.swift
//  Math Game Client
//
//  Created by Jason Terhorst on 1/7/25.
//

import Foundation

protocol MathGameNewRoomProvider {
    func loadRoomCode(_ completion: @escaping ((String?) -> Void))
}

class MockRoomLoader: MathGameNewRoomProvider {
    func loadRoomCode(_ completion: @escaping ((String?) -> Void)) {
        _ = Task {
            sleep(1)
            await MainActor.run {
                completion("YEST")
            }
        }
    }
}

class MockFailingRoomLoader: MathGameNewRoomProvider {
    func loadRoomCode(_ completion: @escaping ((String?) -> Void)) {
        _ = Task {
            sleep(1)
            print("Failure")
            await MainActor.run {
                completion(nil)
            }
        }
    }
}

class MathGameNewRoomLoader: MathGameNewRoomProvider {
    private var task: URLSessionTask?
    
    func loadRoomCode(_ completion: @escaping ((String?) -> Void)) {
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
                    completion(dataObject["code"])
                }
            }
        }
        task?.resume()
    }
}

class MathGameNewRoomViewModel: ObservableObject {
    
    private var roomLoader: MathGameNewRoomProvider
    @Published var roomCode: String? = nil
    
    init(roomLoader: MathGameNewRoomProvider = MathGameNewRoomLoader()) {
        self.roomLoader = roomLoader
        loadRoomCode()
    }
    
    func loadRoomCode() {
        roomLoader.loadRoomCode({ code in
            print("updated room code to \(String(describing: self.roomCode))")
            self.roomCode = code
        })
    }
}
