import SwiftUI

public struct RatingScaleQuestionView: View {
    public let question: Question
    @Binding public var answer: AnyCodableValue?

    public init(question: Question, answer: Binding<AnyCodableValue?>) {
        self.question = question
        self._answer = answer
    }

    private var minValue: Int { Int(question.validationRules?.minValue ?? 1) }
    private var maxValue: Int { Int(question.validationRules?.maxValue ?? 10) }
    private var step: Int { Int(question.validationRules?.step ?? 1) }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(question.prompt)
                .font(.headline)
                .foregroundColor(AppTheme.navy)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(stride(from: minValue, through: maxValue, by: step)), id: \.self) { value in
                        Button(action: { answer = .int(value) }) {
                            Text("\(value)")
                                .font(.body.bold())
                                .frame(width: 44, height: 44)
                                .background(selectedInt == value ? AppTheme.navy : Color(.secondarySystemBackground))
                                .foregroundColor(selectedInt == value ? AppTheme.pureWhite : AppTheme.navy)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(selectedInt == value ? AppTheme.lightBlue : Color.clear, lineWidth: 2)
                                )
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            if let minLabel = question.validationRules?.minLabel,
               let maxLabel = question.validationRules?.maxLabel {
                HStack {
                    Text(minLabel).font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Text(maxLabel).font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(AppTheme.pureWhite)
        .cornerRadius(12)
        .shadow(color: AppTheme.navy.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private var selectedInt: Int? {
        if case .int(let v) = answer { return v }
        return nil
    }
}
