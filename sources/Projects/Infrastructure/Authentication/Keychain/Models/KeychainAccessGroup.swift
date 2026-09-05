/// 여러 프로세스가 같은 Keychain 항목을 읽도록 허용하는 접근 그룹이다.
/// 값은 entitlements에 선언한 그룹 식별자와 정확히 같아야 한다.
public struct KeychainAccessGroup: Hashable, Sendable {

    // MARK: Lifecycle

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    // MARK: Public

    public let rawValue: String

}
