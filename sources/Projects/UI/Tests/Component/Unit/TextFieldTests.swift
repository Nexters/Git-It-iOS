import DesignSystem
import SwiftUI
import Testing

@testable import UIComponent

@Suite("TextField 계약")
struct TextFieldTests {
    @Test
    func `errorMessage가 있으면 error 상태로 판정한다`() {
        let viewModel = TextField.ViewModel(placeholder: "닉네임", errorMessage: "이미 사용 중입니다")

        #expect(viewModel.errorMessage == "이미 사용 중입니다")
    }

    @Test
    func `불변 ViewModel로 생성한다`() {
        let viewModel = TextField.ViewModel(placeholder: "닉네임")

        _ = TextField(viewModel: viewModel, text: .constant(""))
        #expect(viewModel.placeholder == "닉네임")
        #expect(viewModel.isSecure == false)
    }

    @Test
    func `isSecure를 지정하면 보존한다`() {
        let viewModel = TextField.ViewModel(placeholder: "비밀번호", isSecure: true)

        #expect(viewModel.isSecure == true)
    }
}
