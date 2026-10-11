import DomainUseCaseInterface
import Foundation

actor AppSettingUseCaseMock: AppSettingUseCase {

    // MARK: Lifecycle

    init(registrationResults: [Result<Void, any Error>] = [.success(())]) {
        self.registrationResults = registrationResults
    }

    // MARK: Internal

    private(set) var registerDeviceCallCount = 0
    private(set) var updatedDeviceTokens = [DeviceToken]()

    func notificationAuthorization() async -> NotificationAuthorizationStatus {
        .authorized
    }

    func requestNotificationAuthorization() async -> NotificationAuthorizationStatus {
        .authorized
    }

    func registerDevice() async throws {
        registerDeviceCallCount += 1
        guard suspends else {
            try nextResult().get()
            return
        }
        try await withCheckedThrowingContinuation { continuation in
            continuations.append((continuation, nextResult()))
        }
    }

    func updateDeviceToken(_ token: DeviceToken) async throws {
        updatedDeviceTokens.append(token)
    }

    func setSuspends(_ suspends: Bool) {
        self.suspends = suspends
    }

    func resumeOldest() {
        guard !continuations.isEmpty else { return }
        let (continuation, result) = continuations.removeFirst()
        continuation.resume(with: result)
    }

    // MARK: Private

    private var registrationResults: [Result<Void, any Error>]
    private var suspends = false
    private var continuations = [(CheckedContinuation<Void, any Error>, Result<Void, any Error>)]()

    private func nextResult() -> Result<Void, any Error> {
        guard !registrationResults.isEmpty else { return .success(()) }
        return registrationResults.count > 1 ? registrationResults.removeFirst() : registrationResults[0]
    }

}
