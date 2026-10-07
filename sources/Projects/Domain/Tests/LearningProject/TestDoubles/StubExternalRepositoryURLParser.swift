import Synchronization

@testable import DomainLearningProject

// MARK: - StubExternalRepositoryURLParser

final class StubExternalRepositoryURLParser: ExternalRepositoryURLParser {

    // MARK: Lifecycle

    init(location: ExternalRepositoryLocation?) {
        self.location = location
    }

    // MARK: Internal

    func location(from url: String) -> ExternalRepositoryLocation? {
        received.withLock { $0.append(url) }
        return location
    }

    func receivedURLs() -> [String] {
        received.withLock(\.self)
    }

    // MARK: Private

    private let location: ExternalRepositoryLocation?
    private let received = Mutex([String]())

}
