public protocol TabShellItem: CaseIterable, Hashable, Identifiable, Sendable {
    var tabTitle: String { get }
    var tabSystemImage: String { get }
}
