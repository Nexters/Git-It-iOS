import ProjectDescription

enum AppModuleName: String, CaseIterable {
    case GitIt
}

extension AppModuleName {
    var target: Target {
        .target(
            name: rawValue,
            destinations: .iOS,
            product: .app,
            bundleId: "com.nexters.hytime.gitit",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UIApplicationSceneManifest": [
                        "UIApplicationSupportsMultipleScenes": false,
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
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            entitlements: .file(path: "GitIt.entitlements"),
            dependencies: [
                .fromCore(.Auth),
                .fromCore(.Cache),
                .fromCore(.HTTPClient),
                .fromDomain(.Domain),
                .fromData(.Data),
                .fromUI(.DesignSystem),
                .fromUI(.UIComponent),
                .fromUI(.Resource),
                .fromFeature(.Feature),
                .fromUtility(.Utility),
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
                    "MARKETING_VERSION": "1.0",
                    "STRING_CATALOG_GENERATE_SYMBOLS": "YES",
                    "SUPPORTS_MACCATALYST": "NO",
                    "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "NO",
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
                        xcconfig: "Config/debug.xcconfig"
                    ),
                    .release(
                        name: "Release",
                        xcconfig: "Config/release.xcconfig"
                    ),
                ]
            )
        )
    }
}
