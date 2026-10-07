import Foundation
import Synchronization

final class ManualSleeper: Sendable {

    // MARK: Lifecycle

    init(now: Date) {
        state = Mutex(State(now: now))
    }

    // MARK: Internal

    var now: Date {
        state.withLock { $0.now }
    }

    var sleeperCount: Int {
        state.withLock { $0.sleepers.count }
    }

    func sleep(_: TimeInterval) async throws {
        await withCheckedContinuation { continuation in
            state.withLock { $0.sleepers.append(continuation) }
        }
    }

    func advance(by interval: TimeInterval) {
        let sleepers = state.withLock { state in
            state.now = state.now.addingTimeInterval(interval)
            defer { state.sleepers.removeAll() }
            return state.sleepers
        }
        for sleeper in sleepers {
            sleeper.resume()
        }
    }

    // MARK: Private

    private struct State {
        var now: Date
        var sleepers = [CheckedContinuation<Void, Never>]()
    }

    private let state: Mutex<State>

}
