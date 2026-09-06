import ProjectDescription

// MARK: - AppModuleName

enum AppModuleName: String, CaseIterable {
    case GitIt
    case GitItTests
    case ShareExtension
}

extension AppModuleName {
    var sourceDirectory: String {
        let directoryName = rawValue.droppingPrefix(ProjectName.App.rawValue)
        return switch self {
        case .GitIt:
            directoryName
        case .GitItTests:
            "Tests/\(directoryName.droppingSuffix("Tests"))"
        case .ShareExtension:
            directoryName
        }
    }

    var target: Target {
        switch self {
        case .GitIt:
            .target(
                name: rawValue,
                destinations: .iOS,
                product: .app,
                bundleId: "com.nexters.hytime.gitit",
                deploymentTargets: .iOS("26.0"),
                infoPlist: .extendingDefault(
                    with: [
                        "CFBundleShortVersionString": "$(MARKETING_VERSION)",
                        "UIApplicationSceneManifest": [
                            "UIApplicationSupportsMultipleScenes": false
                        ],
                        "UIApplicationSupportsIndirectInputEvents": true,
                        "UIBackgroundModes": [
                            "remote-notification"
                        ],
                        "FirebaseAppDelegateProxyEnabled": false,
                        "GIT_IT_API_HOST": "$(GIT_IT_API_HOST)",
                        "GIT_IT_EXTERNAL_REPOSITORY_HOST": "$(GIT_IT_EXTERNAL_REPOSITORY_HOST)",
                        "UILaunchScreen": [:],
                        "UISupportedInterfaceOrientations": [
                            "UIInterfaceOrientationPortrait",
                        ],
                        "UISupportedInterfaceOrientations~ipad": [
                            "UIInterfaceOrientationPortrait",
                            "UIInterfaceOrientationPortraitUpsideDown",
                            "UIInterfaceOrientationLandscapeLeft",
                            "UIInterfaceOrientationLandscapeRight",
                        ],
                    ]
                ),
                sources: ["\(sourceDirectory)/**"],
                resources: [
                    "\(sourceDirectory)/Resources/**",
                    "Config/GoogleService-Info.plist",
                ],
                entitlements: .file(path: "GitIt.entitlements"),
                dependencies: [
                    .target(name: AppModuleName.ShareExtension.rawValue),
                    .fromComposition(.CompositionApp),
                    .fromFeature(.Feature),
                    .fromDomain(.DomainAuthentication),
                ],
                settings: .settings(
                    base: [
                        "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                        "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
                        "CODE_SIGN_STYLE": "Automatic",
                        "DEVELOPMENT_TEAM": "6924CABL23",
                        "ENABLE_PREVIEWS": "YES",
                        "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                        "MARKETING_VERSION": "1.0.0",
                        "STRING_CATALOG_GENERATE_SYMBOLS": "YES",
                        "SUPPORTS_MACCATALYST": "NO",
                        "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "YES",
                        "SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD": "NO",
                        "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
                        "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor",
                        "SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY": "YES",
                        "SWIFT_VERSION": "5.0",
                        "TARGETED_DEVICE_FAMILY": "1,2",
                    ],
                    configurations: [
                        .debug(name: "Debug", xcconfig: "Config/debug.xcconfig"),
                        .release(name: "Release", xcconfig: "Config/release.xcconfig"),
                    ],
                ),
            )

        case .GitItTests:
            .target(
                name: rawValue,
                destinations: .iOS,
                product: .unitTests,
                bundleId: "com.nexters.hytime.gitit.tests",
                deploymentTargets: .iOS("26.0"),
                infoPlist: .default,
                sources: [
                    "\(sourceDirectory)/**",
                    "\(AppModuleName.ShareExtension.sourceDirectory)/SharedItemURLResolver.swift",
                ],
                dependencies: [
                    .target(name: AppModuleName.GitIt.rawValue),
                    .external(.ComposableArchitecture),
                    .fromFeature(.Feature),
                    .fromComposition(.CompositionApp),
                    .fromDomain(.DomainAuthentication),
                    .fromDomain(.DomainLearningProject),
                    .fromDomain(.DomainMember),
                ],
                settings: .settings(
                    base: [
                        "CODE_SIGN_STYLE": "Automatic",
                        "DEVELOPMENT_TEAM": "6924CABL23",
                        "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                        "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor",
                        "SWIFT_VERSION": "5.0",
                    ]
                ),
            )

        case .ShareExtension:
            .target(
                name: rawValue,
                destinations: .iOS,
                product: .appExtension,
                bundleId: "com.nexters.hytime.gitit.ShareExtension",
                deploymentTargets: .iOS("26.0"),
                infoPlist: .file(path: "\(sourceDirectory)/Info.plist"),
                sources: ["\(sourceDirectory)/**/*.swift"],
                entitlements: .file(path: "ShareExtension.entitlements"),
                dependencies: [
                    .fromComposition(.CompositionShareExtension),
                    .fromComposition(.CompositionAdapter),
                    .fromFeature(.Feature),
                    .fromDomain(.DomainLearningProject),
                    .external(.ComposableArchitecture),
                ],
                settings: .settings(
                    base: [
                        "CODE_SIGN_STYLE": "Automatic",
                        "CURRENT_PROJECT_VERSION": "1",
                        "DEVELOPMENT_TEAM": "6924CABL23",
                        "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                        "MARKETING_VERSION": "1.0.0",
                        "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
                        "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor",
                        "SWIFT_VERSION": "5.0",
                        "TARGETED_DEVICE_FAMILY": "1,2",
                    ],
                    configurations: [
                        .debug(name: "Debug", xcconfig: "Config/debug.xcconfig"),
                        .release(name: "Release", xcconfig: "Config/release.xcconfig"),
                    ],
                ),
            )
        }
    }
}
