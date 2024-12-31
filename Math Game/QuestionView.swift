//
//  QuestionView.swift
//  Math Game Client
//
//  Created by Jason Terhorst on 12/30/24.
//

import SwiftUI

private struct CardTextLine: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .font(Font.system(size: 84))
            .foregroundStyle(.primary)
            .multilineTextAlignment(.trailing)
    }
}

struct CardAnswerText: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .font(Font.system(size: 84))
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.trailing)
    }
}

private struct CardView<ChildView: View, AnswerView: View>: View {
    @ViewBuilder var content: ChildView
    @ViewBuilder var answer: AnswerView
    
    var body: some View {
        VStack {
            content
            Rectangle()
                .fill(.black)
                .frame(width: 180, height: 5)
            answer
        }
        .padding(30)
        .background {
            RoundedRectangle(cornerSize: CGSize(width: 10, height: 10))
                .fill(.white)
                .shadow(radius: 5.0)
        }
    }
}

struct QuestionView<AnswerView: View>: View {
    var question: Question
    var answerView: () -> AnswerView
    var incomingQuestion: Question?
    var incomingAnswerView: (() -> AnswerView)?
    @State var rotation = 0.0
    @State var dropPosition = 0.0
    @State var opacity = 1.0
    
    @ViewBuilder
    var placeholderAnswer: AnswerView {
        Text("??") as! AnswerView
    }
    
    var body: some View {
        ZStack {
            CardView(content: {
                VStack {
                    CardTextLine("\(question.lhs)")
                    CardTextLine("x \(question.rhs)")
                }
            }, answer: { answerView() })
            if let incomingQuestion {
                CardView(content: {
                    VStack {
                        CardTextLine("\(incomingQuestion.lhs)")
                        CardTextLine("x \(incomingQuestion.rhs)")
                    }
                }, answer: incomingAnswerView ?? { placeholderAnswer })
                .opacity(opacity)
                .rotationEffect(Angle(degrees: rotation))
                .offset(CGSize(width: 0, height: dropPosition))
                .onAppear {
                    withAnimation(.linear(duration: 0.4), {
                        rotation = 20.0
                        dropPosition = UIScreen.main.bounds.size.height / 2
                        opacity = 0.0
                    })
                }
            }
        }
    }
}

#Preview {
    QuestionView(question: Question(), answerView: {
        CardAnswerText("??")
    }, incomingQuestion: Question(), incomingAnswerView: {
        CardAnswerText("??")
    })
}
