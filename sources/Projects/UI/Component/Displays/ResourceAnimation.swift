import DesignSystem
import Lottie
import SwiftUI

public struct ResourceAnimation: View {

    // MARK: Lifecycle

    public init(
        asset: Asset,
        isLooping: Bool = true,
        speed: Double = 1,
        contentMode: ContentMode = .fit,
        onCompletion: ((Bool) -> Void)? = nil,
    ) {
        self.asset = asset
        self.isLooping = isLooping
        self.speed = speed
        self.contentMode = contentMode
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
    private let isLooping: Bool
    private let speed: Double
    private let contentMode: ContentMode
    private let onCompletion: ((Bool) -> Void)?

}

#Preview("Resource Animation") {
    VStack(spacing: LayoutToken.gutter.cgFloatValue) {
        ResourceAnimation(asset: .generalLoading)
            .frame(width: 128, height: 128)

        ResourceAnimation(asset: .notification, isLooping: false)
            .frame(width: 128, height: 128)

        ResourceAnimation(asset: .projectEmpty, isLooping: false)
            .frame(width: 128, height: 128)

        ResourceAnimation(asset: .storageEmpty, isLooping: false)
            .frame(width: 128, height: 128)
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}

#Preview("Resource Animation 2") {
    VStack(spacing: LayoutToken.gutter.cgFloatValue) {
        ResourceAnimation(asset: .setCreationLoading, speed: 1.5)
            .frame(width: 250, height: 250)

        ResourceAnimation(asset: .complete, isLooping: false)
            .frame(width: 200, height: 200)
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
