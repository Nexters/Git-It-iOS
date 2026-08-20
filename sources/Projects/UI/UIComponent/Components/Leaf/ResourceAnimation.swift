import DesignSystem
import Lottie
import SwiftUI

public struct ResourceAnimation: View {

    // MARK: Lifecycle

    public init(
        viewModel: ViewModel,
        onCompletion: ((Bool) -> Void)? = nil,
    ) {
        self.viewModel = viewModel
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

    public struct ViewModel: Sendable, Equatable {
        public init(
            asset: Asset,
            isLooping: Bool = true,
            speed: Double = 1,
            contentMode: ContentMode = .fit,
        ) {
            self.asset = asset
            self.isLooping = isLooping
            self.speed = speed
            self.contentMode = contentMode
        }

        public let asset: Asset
        public let isLooping: Bool
        public let speed: Double
        public let contentMode: ContentMode
    }

    public var body: some View {
        LottieView(animation: viewModel.asset.animation)
            .playing(loopMode: viewModel.isLooping ? .loop : .playOnce)
            .animationSpeed(viewModel.speed)
            .animationDidFinish { onCompletion?($0) }
            .resizable()
            .aspectRatio(contentMode: viewModel.contentMode)
    }

    // MARK: Private

    private let viewModel: ViewModel
    private let onCompletion: ((Bool) -> Void)?

}

#Preview("Resource Animation") {
    VStack(spacing: LayoutToken.gutter.cgFloatValue) {
        ResourceAnimation(viewModel: .init(asset: .generalLoading))
            .frame(width: 128, height: 128)
        ResourceAnimation(viewModel: .init(asset: .notification, isLooping: false))
            .frame(width: 128, height: 128)
        ResourceAnimation(viewModel: .init(asset: .projectEmpty, isLooping: false))
            .frame(width: 128, height: 128)
        
        ResourceAnimation(viewModel: .init(asset: .storageEmpty, isLooping: false))
            .frame(width: 128, height: 128)

    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}


#Preview("Resource Animation 2") {
    VStack(spacing: LayoutToken.gutter.cgFloatValue) {
        ResourceAnimation(viewModel: .init(asset: .setCreationLoading,speed: 1.5))
            .frame(width: 250, height: 250)
        
        
        ResourceAnimation(viewModel: .init(asset: .complete, isLooping: false))
            .frame(width: 200, height: 200)
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
