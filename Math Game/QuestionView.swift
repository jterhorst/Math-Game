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
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.trailing)
    }
}

struct CardSuccessCheckmarkView: View {
    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .resizable()
            .scaledToFill()
            .frame(width: 100, height: 100)
            .foregroundStyle(.green)
            .shadow(radius: 4.0)
    }
}

#Preview("checkmark") {
    CardSuccessCheckmarkView()
}

struct CardFailureView: View {
    var body: some View {
        Image(systemName: "x.circle.fill")
            .resizable()
            .scaledToFill()
            .frame(width: 100, height: 100)
            .foregroundStyle(.red)
            .shadow(radius: 4.0)
    }
}

#Preview("failure") {
    CardFailureView()
}

private struct CardView<ChildView: View, AnswerView: View, AnnotationView: View>: View {
    @ViewBuilder var content: ChildView
    @ViewBuilder var answer: AnswerView
    @ViewBuilder var annotation: AnnotationView
    
    var body: some View {
        ZStack {
            VStack {
                content
                    .frame(maxWidth: 180)
                Rectangle()
                    .fill(.primary)
                    .frame(width: 180, height: 5)
                answer
                    .frame(maxWidth: 180, minHeight: 80)
            }
            .padding(30)
            .background {
                RoundedRectangle(cornerSize: CGSize(width: 10, height: 10))
                    .fill(.background)
                    .shadow(color: .primary, radius: 5.0)
            }
            
            annotation
        }
        
    }
}

struct QuestionView<AnswerView: View, OptionalOldAnswerView: View, OptionalOldAnswerAnnotationView: View>: View {
    var question: Question
    var answerView: AnswerView
    var oldQuestion: Question?
    var oldAnswerView: OptionalOldAnswerView?
    var oldAnswerAnnotationView: OptionalOldAnswerAnnotationView?
    @State var rotation = 0.0
    @State var dropPosition = 0.0
    @State var opacity = 1.0
    
    init(question: Question, answerView: () -> AnswerView, oldQuestion: Question? = nil, oldAnswerView: (() -> OptionalOldAnswerView)? = nil, oldAnswerAnnotationView: (() -> OptionalOldAnswerAnnotationView)? = nil, rotation: Double = 0.0, dropPosition: Double = 0.0, opacity: Double = 1.0) {
        self.question = question
        self.answerView = answerView()
        self.oldQuestion = oldQuestion
        self.oldAnswerView = oldAnswerView?()
        self.oldAnswerAnnotationView = oldAnswerAnnotationView?()
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
            }, answer: { answerView }, annotation: {
                EmptyView()
            })
            if let q = oldQuestion {
                CardView(content: {
                    VStack {
                        CardTextLine("\(q.lhs)")
                        CardTextLine("x \(q.rhs)")
                    }
                }, answer: { oldAnswerView }, annotation: {
                    oldAnswerAnnotationView
                })
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
                .onChange(of: question) { _ in
                    rotation = 0
                    dropPosition = 0
                    opacity = 1.0
                    withAnimation(.linear(duration: 0.4).delay(1), {
                        rotation = 20.0
                        dropPosition = UIScreen.main.bounds.size.height / 2
                        opacity = 0.0
                    })
                }
            }
        }
    }
}

extension QuestionView where OptionalOldAnswerView == EmptyView, OptionalOldAnswerAnnotationView == EmptyView {
    init(question: Question, answerView: () -> AnswerView, rotation: Double = 0.0, dropPosition: Double = 0.0, opacity: Double = 1.0) {
        self.question = question
        self.answerView = answerView()
        self.oldQuestion = nil
        self.oldAnswerView = nil
        self.oldAnswerAnnotationView = nil
        self.rotation = rotation
        self.dropPosition = dropPosition
        self.opacity = opacity
    }
}

#Preview("With old question") {
    @Previewable @State var answer: String = ""
    @FocusState var textFieldFocused: Bool
    QuestionView(question: Question(), answerView: {
        TextField("?", text: $answer)
            .focused($textFieldFocused)
            .multilineTextAlignment(.center)
            .foregroundStyle(.primary)
            .font(Font.system(size: 84))
            .keyboardType(.numberPad)
    }, oldQuestion: Question(), oldAnswerView: {
        CardAnswerText("??")
    }, oldAnswerAnnotationView: {
        CardSuccessCheckmarkView()
    })
}

#Preview("Without old question") {
    @Previewable @State var answer: String = ""
    @FocusState var textFieldFocused: Bool
    QuestionView(question: Question(), answerView: {
        TextField("?", text: $answer)
            .focused($textFieldFocused)
            .multilineTextAlignment(.center)
            .foregroundStyle(.primary)
            .font(Font.system(size: 84))
            .keyboardType(.numberPad)
    })
}
