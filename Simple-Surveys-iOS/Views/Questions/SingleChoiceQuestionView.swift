import SwiftUI

public struct SingleChoiceQuestionView: View {
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
                Button(action: { answer = .string(option) }) {
                    HStack {
                        Image(systemName: selectedOption == option ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(selectedOption == option ? AppTheme.lightBlue : .secondary)
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

    private var selectedOption: String? {
        if case .string(let s) = answer { return s }
        return nil
    }
}
