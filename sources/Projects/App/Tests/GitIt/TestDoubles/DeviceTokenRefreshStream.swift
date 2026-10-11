import Foundation
import Synchronization

nonisolated final class DeviceTokenRefreshStream: Sendable {

    // MARK: Internal

    func makeStream() -> AsyncStream<String> {
        let (stream, continuation) = AsyncStream<String>.makeStream()
        self.continuation.withLock { $0 = continuation }
        return stream
    }

    func emit(_ token: String = "device-token") {
        continuation.withLock { $0?.yield(token) }
    }

    func finish() {
        continuation.withLock { $0?.finish() }
    }

    // MARK: Private

    private let continuation = Mutex<AsyncStream<String>.Continuation?>(nil)

}
