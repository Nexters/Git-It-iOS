import Foundation

// MARK: - SharedURLExtractor

enum SharedURLExtractor {

    // MARK: Internal

    static func firstURLString(inText text: String) -> String? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let match = detector?.firstMatch(in: text, options: [], range: range)
        guard let url = match?.url, Constant.acceptedSchemes.contains(url.scheme?.lowercased() ?? "") else {
            return nil
        }
        return url.absoluteString
    }

    // MARK: Private

    private enum Constant {
        static let acceptedSchemes: Set = ["http", "https"]
    }

}
