import SwiftUI

public struct TextQuestionView: View {
    public let question: Question
    @Binding public var answer: AnyCodableValue?

    public init(question: Question, answer: Binding<AnyCodableValue?>) {
        self.question = question
        self._answer = answer
    }

    private var placeholder: String { question.validationRules?.placeholder ?? "Enter text here..." }
    private var maxLength: Int { question.validationRules?.maxLength ?? 500 }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question.prompt)
                .font(.headline)
                .foregroundColor(AppTheme.navy)

            TextEditor(text: textBinding)
                .frame(minHeight: 100)
                .padding(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.separator), lineWidth: 1))

            HStack {
                Spacer()
                Text("\(currentText.count)/\(maxLength)")
                    .font(.caption)
                    .foregroundColor(currentText.count > maxLength ? .red : .secondary)
            }
        }
        .padding()
        .background(AppTheme.pureWhite)
        .cornerRadius(12)
    }

    private var currentText: String {
        if case .string(let s) = answer { return s }
        return ""
    }

    private var textBinding: Binding<String> {
        Binding(
            get: { self.currentText },
            set: { val in
                if val.count <= maxLength {
                    self.answer = .string(val)
                }
            }
        )
    }
}
