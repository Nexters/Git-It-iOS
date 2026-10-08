import ComposableArchitecture
import DomainAppSetting

@Reducer
public struct NotificationPermissionFeature: Sendable {

    // MARK: Lifecycle

    public init(
        notificationAuthorization: @escaping @Sendable () async -> NotificationAuthorizationStatus,
        requestNotificationAuthorization: @escaping @Sendable () async -> NotificationAuthorizationStatus,
        openNotificationSettings: @escaping @MainActor @Sendable () async -> Void,
    ) {
        self.notificationAuthorization = notificationAuthorization
        self.requestNotificationAuthorization = requestNotificationAuthorization
        self.openNotificationSettings = openNotificationSettings
    }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init(notificationStatus: NotificationStatus = .idle) {
            self.notificationStatus = notificationStatus
        }

        // MARK: Public

        public enum NotificationStatus: Equatable, Sendable {
            case idle
            case allowed
            case denied
        }

        public var notificationStatus: NotificationStatus

    }

    public enum Action: Equatable, Sendable {
        case input(Input)
        case effect(EffectEvent)

        // MARK: Public

        @CasePathable
        public enum Input: Equatable, Sendable {
            case refresh
            case rowTapped
        }

        @CasePathable
        public enum EffectEvent: Equatable, Sendable {
            case authorizationChecked(NotificationAuthorizationStatus)
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .input(.refresh):
                return .run { [notificationAuthorization] send in
                    await send(.effect(.authorizationChecked(notificationAuthorization())))
                }

            case .input(.rowTapped):
                return .run { [notificationAuthorization, requestNotificationAuthorization, openNotificationSettings] send in
                    switch await notificationAuthorization() {
                    case .notDetermined:
                        let status = await requestNotificationAuthorization()
                        await send(.effect(.authorizationChecked(status)))

                    case .authorized,
                         .denied:
                        await openNotificationSettings()
                    }
                }

            case .effect(.authorizationChecked(let status)):
                state.notificationStatus = status == .authorized ? .allowed : .denied
                return .none
            }
        }
    }

    // MARK: Private

    private let notificationAuthorization: @Sendable () async -> NotificationAuthorizationStatus
    private let requestNotificationAuthorization: @Sendable () async -> NotificationAuthorizationStatus
    private let openNotificationSettings: @MainActor @Sendable () async -> Void

}
