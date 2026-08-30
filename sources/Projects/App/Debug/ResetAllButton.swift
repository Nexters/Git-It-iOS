import SwiftUI

// MARK: - ResetAllButton

public struct ResetAllButton: View {

    // MARK: Lifecycle

    public init(action: @escaping @MainActor @Sendable () -> Void) {
        self.action = action
    }

    // MARK: Public

    public var body: some View {
        Button(
            "설정 초기화 (회원탈퇴·로그아웃·약관 동의 삭제)",
            action: action,
        )
        .buttonStyle(.borderedProminent)
        .tint(.red)
        .padding()
    }

    // MARK: Private

    private let action: @MainActor @Sendable () -> Void

}
