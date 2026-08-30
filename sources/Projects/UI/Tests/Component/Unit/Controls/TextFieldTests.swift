import DesignSystem
import SwiftUI
import Testing

@testable import UIComponent

@Suite("TextField 계약")
struct TextFieldTests {
    @Test
    func `표시 값을 직접 받아 생성한다`() {
        _ = TextField(placeholder: "닉네임", text: .constant(""))
        _ = TextField(placeholder: "닉네임", text: .constant(""), errorMessage: "이미 사용 중입니다")
        _ = TextField(placeholder: "비밀번호", text: .constant(""), isSecure: true)
    }
}
