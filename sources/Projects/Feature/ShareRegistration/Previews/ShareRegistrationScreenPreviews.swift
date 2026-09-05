#if DEBUG
import ComposableArchitecture
import DomainLearningProject
import SwiftUI

#Preview("저장소 확인") {
    ShareRegistrationScreen(store: ShareRegistrationPreviewSupport.store(status: .repositoryConfirmation))
}

#Preview("난이도 선택") {
    ShareRegistrationScreen(store: ShareRegistrationPreviewSupport.store(status: .quizLevelSelection))
}

#Preview("생성 확인") {
    ShareRegistrationScreen(
        store: ShareRegistrationPreviewSupport.store(status: .quizGenerationConfirmation)
    )
}

#Preview("로그인 필요") {
    ShareRegistrationScreen(store: ShareRegistrationPreviewSupport.store(status: .signInRequired))
}

#Preview("앱 실행 필요") {
    ShareRegistrationScreen(store: ShareRegistrationPreviewSupport.store(status: .appLaunchRequired))
}

#Preview("실패") {
    ShareRegistrationScreen(
        store: ShareRegistrationPreviewSupport.store(
            status: .failed(reason: "네트워크에 연결할 수 없어요.", retry: .registration)
        )
    )
}
#endif
