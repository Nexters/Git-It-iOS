import ComposableArchitecture
import DomainAuthentication
import DomainLearningProject
import DomainMember
import Foundation

public enum MainShellTab: String, CaseIterable, Hashable, Identifiable, Sendable {
    case projects
    case saved
    case settings

    public var id: String {
        rawValue
    }
}
