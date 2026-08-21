import ProjectDescription

// MARK: - AppModuleName

enum AppModuleName: String, CaseIterable {
    case GitIt
    case GitItTests
}

extension AppModuleName {
    var sourceDirectory: String {
        switch self {
        case .GitIt:
            "Sources"
        case .GitItTests:
            "Tests/GitIt"
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
                        "UIApplicationSceneManifest": [
                            "UIApplicationSupportsMultipleScenes": false
                        ],
                        "UIApplicationSupportsIndirectInputEvents": true,
                        "UILaunchScreen": [:],
                        "UISupportedInterfaceOrientations": [
                            "UIInterfaceOrientationPortrait",
                            "UIInterfaceOrientationLandscapeLeft",
                            "UIInterfaceOrientationLandscapeRight",
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
                resources: ["Resources/**"],
                entitlements: .file(path: "GitIt.entitlements"),
                dependencies: [
                    .fromComposition(.CompositionAdepter),
                    .fromFeature(.Feature),
                    .fromDomain(.DomainAuthentication),
                    .external(.FirebaseAnalytics),
                    .external(.FirebaseCrashlytics),
                ],
                settings: .settings(
                    base: [
                        "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                        "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
                        "CODE_SIGN_STYLE": "Automatic",
                        "CURRENT_PROJECT_VERSION": "1",
                        "DEVELOPMENT_TEAM": "6924CABL23",
                        "ENABLE_PREVIEWS": "YES",
                        "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                        "MARKETING_VERSION": "1.0",
                        "STRING_CATALOG_GENERATE_SYMBOLS": "YES",
                        "SUPPORTS_MACCATALYST": "NO",
                        "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "YES",
                        "SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD": "NO",
                        "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
                        "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor",
                        "SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY": "YES",
                        "SWIFT_VERSION": "5.0",
                        "TARGETED_DEVICE_FAMILY": "1,2",
                    ]
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
                sources: ["\(sourceDirectory)/**"],
                dependencies: [
                    .target(name: AppModuleName.GitIt.rawValue)
                ],
                settings: .settings(
                    base: [
                        "BUNDLE_LOADER": "$(TEST_HOST)",
                        "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/GitIt.app/GitIt",
                        "CODE_SIGN_STYLE": "Automatic",
                        "DEVELOPMENT_TEAM": "6924CABL23",
                        "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                        "SWIFT_VERSION": "5.0",
                    ]
                ),
            )
        }
    }
}
