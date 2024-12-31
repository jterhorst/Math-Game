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
//        GeometryReader { reader in
            VStack {
                content
                Rectangle()
                    .fill(.black)
                    .frame(width: 180, height: 5)
                answer
            }
            .padding(30)
//            .frame(maxWidth: reader.size.width * 0.5)
            .background {
                RoundedRectangle(cornerSize: CGSize(width: 10, height: 10))
                    .fill(.white)
                    .shadow(radius: 5.0)
            }
//        }
    }
}

struct QuestionView<AnswerView: View, OptionalOldAnswerView: View>: View {
    var question: Question
    var answerView: AnswerView
    var oldQuestion: Question?
    var oldAnswerView: OptionalOldAnswerView?
    @State var rotation = 0.0
    @State var dropPosition = 0.0
    @State var opacity = 1.0
    
    init(question: Question, answerView: () -> AnswerView, oldQuestion: Question? = nil, oldAnswerView: (() -> OptionalOldAnswerView)? = nil, rotation: Double = 0.0, dropPosition: Double = 0.0, opacity: Double = 1.0) {
        self.question = question
        self.answerView = answerView()
        self.oldQuestion = oldQuestion
        self.oldAnswerView = oldAnswerView?()
        self.rotation = rotation
        self.dropPosition = dropPosition
        self.opacity = opacity
    }
    
    @ViewBuilder
    var placeholderAnswer: some View {
        Text("??")
    }
    
    var body: some View {
        ZStack {
            CardView(content: {
                VStack {
                    CardTextLine("\(question.lhs)")
                    CardTextLine("x \(question.rhs)")
                }
            }, answer: { answerView })
            if let q = oldQuestion, let a = oldAnswerView {
                CardView(content: {
                    VStack {
                        CardTextLine("\(q.lhs)")
                        CardTextLine("x \(q.rhs)")
                    }
                }, answer: { a })
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

extension QuestionView where OptionalOldAnswerView == EmptyView {
    init(question: Question, answerView: () -> AnswerView, rotation: Double = 0.0, dropPosition: Double = 0.0, opacity: Double = 1.0) {
        self.question = question
        self.answerView = answerView()
        self.oldQuestion = nil
        self.oldAnswerView = nil
        self.rotation = rotation
        self.dropPosition = dropPosition
        self.opacity = opacity
    }
}

#Preview {
    @Previewable @State var answer: String = ""
    @FocusState var textFieldFocused: Bool
    QuestionView(question: Question(), answerView: {
        CardAnswerText("??")
    }, oldQuestion: Question(), oldAnswerView: {
        TextField("?", text: $answer)
    })
}
