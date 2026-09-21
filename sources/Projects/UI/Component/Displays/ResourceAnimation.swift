import DesignSystem
import Lottie
import SwiftUI

// MARK: - ResourceAnimation

public struct ResourceAnimation: View {

    // MARK: Lifecycle

    public init(
        asset: Asset,
        stateModel: StateModel = .init(),
        onCompletion: ((Bool) -> Void)? = nil,
    ) {
        self.asset = asset
        self.stateModel = stateModel
        self.onCompletion = onCompletion
    }

    // MARK: Public

    public enum Asset: String, Sendable, Equatable, CaseIterable {
        case complete
        case generalLoading = "general-loading"
        case notification
        case projectEmpty = "project-empty"
        case setCreationLoading = "set-creation-loading"
        case storageEmpty = "storage-empty"

        var animation: LottieAnimation? {
            .named(rawValue, bundle: .module)
        }
    }

    public var body: some View {
        LottieView(animation: asset.animation)
            .playing(loopMode: stateModel.isLooping ? .loop : .playOnce)
            .animationSpeed(stateModel.speed)
            .animationDidFinish { onCompletion?($0) }
            .resizable()
            .aspectRatio(contentMode: stateModel.contentMode)
    }

    // MARK: Private

    private let asset: Asset
    private let stateModel: StateModel
    private let onCompletion: ((Bool) -> Void)?

}

// MARK: ResourceAnimation.StateModel

extension ResourceAnimation {
    public struct StateModel: Sendable, Equatable {
        public init(
            isLooping: Bool = true,
            speed: Double = 1,
            contentMode: ContentMode = .fit,
        ) {
            self.isLooping = isLooping
            self.speed = speed
            self.contentMode = contentMode
        }

        public let isLooping: Bool
        public let speed: Double
        public let contentMode: ContentMode
    }
}

#Preview("Resource Animation") {
    VStack(spacing: LayoutToken.gutter) {
        ResourceAnimation(asset: .generalLoading)
            .frame(width: 128, height: 128)

        ResourceAnimation(asset: .notification, stateModel: .init(isLooping: false))
            .frame(width: 128, height: 128)

        ResourceAnimation(asset: .storageEmpty, stateModel: .init(isLooping: false))
            .frame(width: 128, height: 128)
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}

#Preview("Resource Animation 2") {
    VStack(spacing: LayoutToken.gutter) {
        ResourceAnimation(asset: .setCreationLoading, stateModel: .init(speed: 1.5))
            .frame(width: 250, height: 250)

        ResourceAnimation(asset: .complete, stateModel: .init(isLooping: false))
            .frame(width: 200, height: 200)
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}
