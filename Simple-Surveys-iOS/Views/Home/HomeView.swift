import SwiftUI

public struct HomeView: View {
    @Bindable public var viewModel: HomeViewModel
    public let repository: SurveyRepositoryProtocol
    public let locationService: LocationServiceProtocol

    @State private var showingSurveySheet = false

    public init(
        viewModel: HomeViewModel,
        repository: SurveyRepositoryProtocol,
        locationService: LocationServiceProtocol
    ) {
        self.viewModel = viewModel
        self.repository = repository
        self.locationService = locationService
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.canvasBackground.ignoresSafeArea()

                if !viewModel.arePermissionsValid {
                    PermissionRevokedView {
                        Task { await viewModel.checkPermissions() }
                    }
                } else {
                    mainContent
                }
            }
            .navigationTitle("Simple Surveys")
            .task {
                await viewModel.checkPermissions()
            }
            .fullScreenCover(isPresented: $showingSurveySheet) {
                if let survey = viewModel.activeSurvey {
                    SurveyContainerView(
                        viewModel: SurveyViewModel(
                            survey: survey,
                            notificationSentAt: viewModel.notificationSentAt,
                            timeToCompleteMinutes: AppConfiguration.defaultTimeToCompleteMinutes,
                            repository: repository,
                            locationService: locationService
                        )
                    )
                }
            }
        }
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header status card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Circle()
                            .fill(viewModel.activeSurvey != nil ? AppTheme.lightBlue : Color.green)
                            .frame(width: 12, height: 12)
                        Text(viewModel.activeSurvey != nil ? "Active Survey Pending" : "Sampling Schedule Active")
                            .font(.headline)
                            .foregroundColor(AppTheme.navy)
                    }

                    Text("You will receive notifications throughout the day when scheduled survey windows open. Please keep notifications and location enabled.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineSpacing(2)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.pureWhite)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.navy.opacity(0.1), lineWidth: 1))
                .shadow(color: AppTheme.navy.opacity(0.04), radius: 6, x: 0, y: 2)

                // Active survey prompt banner if available
                if let survey = viewModel.activeSurvey {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "bell.badge.fill")
                                .foregroundColor(AppTheme.lightBlue)
                            Text("Scheduled Prompt Ready")
                                .font(.headline)
                                .foregroundColor(AppTheme.navy)
                        }

                        Text(survey.title)
                            .font(.title3.bold())
                            .foregroundColor(.primary)

                        if let desc = survey.description {
                            Text(desc)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Button(action: {
                            showingSurveySheet = true
                        }) {
                            HStack {
                                Text("Start Survey")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.pureWhite)
                                Image(systemName: "arrow.right")
                                    .foregroundColor(AppTheme.lightBlue)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(AppTheme.navy)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(AppTheme.pureWhite)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.lightBlue, lineWidth: 1.5))
                    .shadow(color: AppTheme.lightBlue.opacity(0.15), radius: 8, x: 0, y: 3)
                }

                if viewModel.isLoading {
                    ProgressView("Loading prompt...")
                        .padding()
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding()
                }

                Spacer()
            }
            .padding()
        }
    }
}
