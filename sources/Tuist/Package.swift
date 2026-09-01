// swift-tools-version: 6.0

import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    productTypes: [
        "CasePaths": .framework,
        "CasePathsCore": .framework,
        "CasePathsMacrosSupport": .staticFramework,
        "Clocks": .framework,
        "CombineSchedulers": .framework,
        "ComposableArchitecture": .framework,
        "ConcurrencyExtras": .framework,
        "CustomDump": .framework,
        "Dependencies": .framework,
        "IdentifiedCollections": .framework,
        "InternalCollectionsUtilities": .framework,
        "IssueReporting": .framework,
        "OrderedCollections": .framework,
        "Perception": .framework,
        "PerceptionCore": .framework,
        "Sharing": .framework,
        "Sharing1": .framework,
        "Sharing2": .framework,
        "SwiftNavigation": .framework,
        "SwiftUINavigation": .framework,
        "UIKitNavigation": .framework,
        "UIKitNavigationShim": .staticFramework,
        "XCTestDynamicOverlay": .framework,
        "FBLPromises": .framework,
        "Firebase": .framework,
        "FirebaseAuthInterop": .framework,
        "FirebaseCore": .framework,
        "FirebaseCoreInternal": .framework,
        "FirebaseInstallations": .framework,
        "GoogleDataTransport": .framework,
        "GoogleUtilities-AppDelegateSwizzler": .framework,
        "GoogleUtilities-Environment": .framework,
        "GoogleUtilities-Logger": .framework,
        "GoogleUtilities-NSData": .framework,
        "GoogleUtilities-Network": .framework,
        "GoogleUtilities-Reachability": .framework,
        "GoogleUtilities-UserDefaults": .framework,
        "nanopb": .framework,
        "third-party-IsAppEncrypted": .framework,
    ]
)
#endif

let package = Package(
    name: "GitItDependencies",
    platforms: [
        .iOS("26.0")
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture.git",
            from: "1.26.0",
        ),
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            from: "12.16.0",
        ),
        .package(
            url: "https://github.com/airbnb/lottie-ios.git",
            from: "4.6.1",
        ),
    ],
)
