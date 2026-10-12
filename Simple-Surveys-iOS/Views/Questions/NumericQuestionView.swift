import SwiftUI

public struct NumericQuestionView: View {
    public let question: Question
    @Binding public var answer: AnyCodableValue?

    @State private var textValue: String = ""

    public init(question: Question, answer: Binding<AnyCodableValue?>) {
        self.question = question
        self._answer = answer
        if case .double(let d) = answer.wrappedValue {
            _textValue = State(initialValue: String(d))
        } else if case .int(let i) = answer.wrappedValue {
            _textValue = State(initialValue: String(i))
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question.prompt)
                .font(.headline)
                .foregroundColor(AppTheme.navy)

            TextField("0", text: $textValue)
                .keyboardType(question.validationRules?.allowDecimals == true ? .decimalPad : .numberPad)
                .textFieldStyle(.roundedBorder)
                .onChange(of: textValue) { _, newValue in
                    if let d = Double(newValue) {
                        answer = .double(d)
                    } else {
                        answer = nil
                    }
                }
        }
        .padding()
        .background(AppTheme.pureWhite)
        .cornerRadius(12)
    }
}
