import SwiftUI

public struct MultipleChoiceQuestionView: View {
    public let question: Question
    @Binding public var answer: AnyCodableValue?

    public init(question: Question, answer: Binding<AnyCodableValue?>) {
        self.question = question
        self._answer = answer
    }

    private var options: [String] { question.validationRules?.options ?? [] }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.prompt)
                .font(.headline)
                .foregroundColor(AppTheme.navy)

            ForEach(options, id: \.self) { option in
                Button(action: { toggle(option) }) {
                    HStack {
                        Image(systemName: selectedOptions.contains(option) ? "checkmark.square.fill" : "square")
                            .foregroundColor(selectedOptions.contains(option) ? AppTheme.lightBlue : .secondary)
                        Text(option)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(AppTheme.pureWhite)
        .cornerRadius(12)
    }

    private var selectedOptions: [String] {
        if case .stringArray(let arr) = answer { return arr }
        return []
    }

    private func toggle(_ option: String) {
        var current = selectedOptions
        if current.contains(option) {
            current.removeAll { $0 == option }
        } else {
            current.append(option)
        }
        answer = .stringArray(current)
    }
}
