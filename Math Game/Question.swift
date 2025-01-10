//
//  Question.swift
//  Math Game Client
//
//  Created by Jason Terhorst on 1/7/25.
//

import Foundation

final class Question: Codable, Equatable, ObservableObject {
    static func == (lhs: Question, rhs: Question) -> Bool {
        lhs.lhs == rhs.lhs && lhs.rhs == rhs.rhs
    }
    
    let lhs: Int
    let rhs: Int
    let correctAnswer: Int

    init() {
        let lhs = Int.random(in: 1...10)
        let rhs = Int.random(in: 1...10)
        let correctAnswer = lhs * rhs
        self.lhs = lhs
        self.rhs = rhs
        self.correctAnswer = correctAnswer
    }
}
