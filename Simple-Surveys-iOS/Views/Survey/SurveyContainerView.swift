import SwiftUI

public struct SurveyContainerView: View {
    @Bindable public var viewModel: SurveyViewModel
    @State private var showingCamera = false

    public init(viewModel: SurveyViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isExpired {
                    ExpiredSurveyView()
                } else if viewModel.submissionCompleted {
                    SurveyCompletedView()
                } else {
                    surveyContent
                }
            }
            .navigationTitle(viewModel.survey.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    TimerBadgeView(remainingSeconds: viewModel.remainingSeconds)
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraCaptureView { captured in
                viewModel.capturedImage = captured
            }
        }
    }

    private var surveyContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Description header
                if let desc = viewModel.survey.description {
                    Text(desc)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }

                // Dynamic questions
                ForEach(viewModel.survey.questions) { question in
                    questionView(for: question)
                        .padding(.horizontal)
                }

                // Photo capture card
                PhotoPreviewCard(
                    image: viewModel.capturedImage?.previewImage,
                    onTapCapture: { showingCamera = true },
                    onTapRemove: { viewModel.capturedImage = nil }
                )
                .padding(.horizontal)

                // Error message
                if let err = viewModel.errorMessage {
                    Text(err)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                // Submit button
                Button(action: { Task { await viewModel.submitResponse() } }) {
                    if viewModel.isSubmitting {
                        ProgressView().tint(AppTheme.pureWhite)
                    } else {
                        Text("Submit Survey")
                            .font(.headline)
                            .foregroundColor(AppTheme.pureWhite)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 50)
                .background(AppTheme.navy)
                .cornerRadius(12)
                .padding()
                .disabled(viewModel.isSubmitting)
            }
            .padding(.vertical)
        }
    }

    @ViewBuilder
    private func questionView(for q: Question) -> some View {
        switch q.type {
        case .ratingScale:
            RatingScaleQuestionView(question: q, answer: binding(for: q.questionId))
        case .singleChoice:
            SingleChoiceQuestionView(question: q, answer: binding(for: q.questionId))
        case .multipleChoice:
            MultipleChoiceQuestionView(question: q, answer: binding(for: q.questionId))
        case .text:
            TextQuestionView(question: q, answer: binding(for: q.questionId))
        case .numeric:
            NumericQuestionView(question: q, answer: binding(for: q.questionId))
        }
    }

    private func binding(for id: String) -> Binding<AnyCodableValue?> {
        Binding(
            get: { viewModel.answers[id] },
            set: { val in
                if let val = val {
                    viewModel.answers[id] = val
                } else {
                    viewModel.answers.removeValue(forKey: id)
                }
            }
        )
    }
}
