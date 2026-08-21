import Foundation

struct ComponentPreviewEntry: Identifiable, Sendable, Equatable {
    enum Category: String, Sendable {
        case leaf
        case composite
    }

    let componentID: String
    let displayName: String
    let category: Category
    let variants: [String]
    let sizes: [String]
    let states: [String]
    let factoryIDs: [String]

    var id: String {
        componentID
    }
}
