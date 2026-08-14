// MARK: - HTTPHeaders

public struct HTTPHeaders: Equatable, Sendable, ExpressibleByDictionaryLiteral {

    // MARK: Lifecycle

    public init() {
        storage = [:]
    }

    public init(dictionaryLiteral elements: (String, String)...) {
        storage = [:]
        for (name, value) in elements {
            self[name] = value
        }
    }

    // MARK: Public

    public subscript(name: String) -> String? {
        get {
            storage[normalized(name)]
        }
        set {
            storage[normalized(name)] = newValue
        }
    }

    public func overridden(by other: HTTPHeaders) -> HTTPHeaders {
        var result = self
        for (name, value) in other.storage {
            result.storage[name] = value
        }
        return result
    }

    public var names: [String] {
        storage.keys.sorted()
    }

    public var all: [(name: String, value: String)] {
        names.compactMap { name in
            storage[name].map { (name: name, value: $0) }
        }
    }

    // MARK: Private

    private var storage: [String: String]

    private func normalized(_ name: String) -> String {
        name.lowercased()
    }
}
