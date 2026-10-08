import Foundation
@testable import InfrastructureNetworkClient

struct TestPayload: Codable, Equatable, Sendable {
    let id: Int
    let name: String
}
