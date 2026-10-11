import Foundation
import Testing

@testable import DataAuthentication
@testable import DataShared

// MARK: - AppleIdentityStoreTests

@Suite("AppleIdentityStore")
struct AppleIdentityStoreTests {

    @Test
    func `저장한 사용자 식별자를 다시 읽는다`() throws {
        let store = AppleIdentityStore(storage: InMemorySecureValueStorage())

        try store.save("user-1")

        #expect(try store.load() == "user-1")
    }

    @Test
    func `사용자 식별자를 appleUserID key에 UTF-8 바이트로 저장한다`() throws {
        let storage = InMemorySecureValueStorage()

        try AppleIdentityStore(storage: storage).save("user-1")

        #expect(storage.storedData(forKey: "appleUserID") == Data("user-1".utf8))
    }

    @Test
    func `삭제하면 사용자 식별자를 읽을 수 없다`() throws {
        let store = AppleIdentityStore(storage: InMemorySecureValueStorage())
        try store.save("user-1")

        try store.delete()

        #expect(try store.load() == nil)
    }

    @Test
    func `저장소 오류를 호출자에게 전달한다`() {
        let store = AppleIdentityStore(storage: InMemorySecureValueStorage(failure: .unavailable))

        #expect(throws: SecureValueStorageError.unavailable) {
            try store.load()
        }
        #expect(throws: SecureValueStorageError.unavailable) {
            try store.save("user-1")
        }
    }

}
