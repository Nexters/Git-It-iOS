import DesignSystem
import Lottie
import SwiftUI

// MARK: - ResourceAnimation

public struct ResourceAnimation: View {

    // MARK: Lifecycle

    public init(
        asset: Asset,
        onCompletion: ((Bool) -> Void)? = nil,
    ) {
        self.asset = asset
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
            .playing(loopMode: isLooping ? .loop : .playOnce)
            .animationSpeed(speed)
            .animationDidFinish { onCompletion?($0) }
            .resizable()
            .aspectRatio(contentMode: contentMode)
    }

    // MARK: Private

    private let asset: Asset
    private var isLooping = true
    private var speed: Double = 1
    private var contentMode = ContentMode.fit
    private let onCompletion: ((Bool) -> Void)?

}

// MARK: ResourceAnimation 상태 선언

extension ResourceAnimation {
    public func looping(_ isLooping: Bool) -> Self {
        var copy = self
        copy.isLooping = isLooping
        return copy
    }

    public func speed(_ speed: Double) -> Self {
        var copy = self
        copy.speed = speed
        return copy
    }

    public func contentMode(_ contentMode: ContentMode) -> Self {
        var copy = self
        copy.contentMode = contentMode
        return copy
    }
}

#Preview("Resource Animation") {
    VStack(spacing: LayoutToken.gutter) {
        ResourceAnimation(asset: .generalLoading)
            .frame(width: 128, height: 128)

        ResourceAnimation(asset: .notification)
            .looping(false)
            .frame(width: 128, height: 128)

        ResourceAnimation(asset: .storageEmpty)
            .looping(false)
            .frame(width: 128, height: 128)
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}

#Preview("Resource Animation 2") {
    VStack(spacing: LayoutToken.gutter) {
        ResourceAnimation(asset: .setCreationLoading)
            .speed(1.5)
            .frame(width: 250, height: 250)

        ResourceAnimation(asset: .complete)
            .looping(false)
            .frame(width: 200, height: 200)
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}
