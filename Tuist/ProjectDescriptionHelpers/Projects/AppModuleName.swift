import ProjectDescription

// MARK: - AppModuleName

enum AppModuleName: String, CaseIterable {
    case GitIt
    case GitItTests
}

extension AppModuleName {
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
                    ],
                ),
                sources: ["Sources/**"],
                resources: ["Resources/**"],
                entitlements: .file(path: "GitIt.entitlements"),
                dependencies: [
                    .fromDI(.DILive),
                    .fromFeature(.Feature),
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
                    ],
                    configurations: [
                        .debug(
                            name: "Debug",
                            xcconfig: "Config/debug.xcconfig",
                        ),
                        .release(
                            name: "Release",
                            xcconfig: "Config/release.xcconfig",
                        ),
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
                sources: ["Tests/**"],
                dependencies: [
                    .target(name: AppModuleName.GitIt.rawValue)
                ],
                settings: .settings(
                    base: [
                        "CODE_SIGN_STYLE": "Automatic",
                        "DEVELOPMENT_TEAM": "6924CABL23",
                        "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                        "SWIFT_VERSION": "5.0",
                    ]
                ),
            )
        }
    }

    static let schemes: [Scheme] = [
        .scheme(
            name: AppModuleName.GitIt.rawValue,
            shared: true,
            buildAction: .buildAction(
                targets: [
                    .target(AppModuleName.GitIt.rawValue)
                ]
            ),
            testAction: .targets([
                .testableTarget(
                    target: .target(AppModuleName.GitItTests.rawValue)
                )
            ]),
            runAction: .runAction(
                executable: .executable(.target(AppModuleName.GitIt.rawValue))
            ),
            archiveAction: .archiveAction(configuration: .release),
            profileAction: .profileAction(
                executable: .executable(.target(AppModuleName.GitIt.rawValue))
            ),
            analyzeAction: .analyzeAction(configuration: .debug),
        )
    ]
}
