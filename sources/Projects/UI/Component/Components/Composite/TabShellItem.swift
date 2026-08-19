/// 프로토콜은 타입에 중첩할 수 없으므로 `TabShell`이 소유하는 항목 계약을 파일 최상위에 둡니다.
public protocol TabShellItem: CaseIterable, Hashable, Identifiable, Sendable {
    var tabTitle: String { get }
    var tabSystemImage: String { get }
}
