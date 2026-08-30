import Foundation

enum AppBundleMetadata: String {

    case shortVersion = "CFBundleShortVersionString"

    var value: String {
        (Bundle.main.object(forInfoDictionaryKey: rawValue) as? String) ?? "0.0.0"
    }

}
