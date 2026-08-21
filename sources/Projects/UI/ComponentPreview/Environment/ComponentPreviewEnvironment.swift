import SwiftUI

struct ComponentPreviewEnvironment: Sendable, Equatable {
    static var process: Self {
        let arguments = ProcessInfo.processInfo.arguments
        return Self(
            isDark: arguments.contains("--preview-dark"),
            usesMaximumDynamicType: arguments.contains("--maximum-dynamic-type"),
            reducesMotion: arguments.contains("--reduce-motion"),
            usesResourceFallback: arguments.contains("--resource-fallback"),
        )
    }

    let isDark: Bool
    let usesMaximumDynamicType: Bool
    let reducesMotion: Bool
    let usesResourceFallback: Bool
}
