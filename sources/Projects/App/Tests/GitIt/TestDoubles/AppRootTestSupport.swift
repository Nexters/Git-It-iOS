import ComposableArchitecture
import DomainAccount
import DomainIdentifier
import DomainProject
import DomainProjectGeneration
import DomainQuizDetail
import DomainUserInfo
import Foundation
@testable import GitIt

@MainActor
func makeAppRootStore(
    account: AccountUseCaseMock = AccountUseCaseMock(),
    userInfo: UserInfoUseCaseMock = UserInfoUseCaseMock(),
    appSetting: AppSettingUseCaseMock = AppSettingUseCaseMock(),
    project: ProjectUseCaseMock = ProjectUseCaseMock(),
    projectGeneration: ProjectGenerationUseCaseMock = ProjectGenerationUseCaseMock(),
    deviceTokenRefreshes: DeviceTokenRefreshStream = DeviceTokenRefreshStream(),
    openExternalURL: OpenExternalURLSpy = OpenExternalURLSpy(),
    state: AppRootFeature.State = AppRootFeature.State(bundleVersion: "1.0.0"),
) -> TestStoreOf<AppRootFeature> {
    TestStore(initialState: state) {
        AppRootFeature(
            account: account,
            userInfo: userInfo,
            appSetting: appSetting,
            externalRepository: NoopExternalRepositoryUseCase(),
            quizDetail: NoopQuizDetailUseCase(),
            project: project,
            projectGeneration: projectGeneration,
            openExternalURL: { await openExternalURL($0) },
            deviceTokenRefreshes: { deviceTokenRefreshes.makeStream() },
        )
    }
}
