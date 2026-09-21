import DesignSystem
import SwiftUI
import Testing

@testable import UIComponent

@Suite("TextField 계약")
struct TextFieldTests {
    @Test
    func `표시 값을 직접 받아 생성한다`() {
        _ = TextField(displayModel: .init(placeholder: "닉네임"), text: .constant(""))
        _ = TextField(displayModel: .init(placeholder: "닉네임", errorMessage: "이미 사용 중입니다"), text: .constant(""))
        _ = TextField(displayModel: .init(placeholder: "비밀번호"), text: .constant(""), isSecure: true)
    }

    @Test
    func `표면은 규격 높이 52와 반경 8과 내부 좌우 16을 쓴다`() {
        #expect(TextField.Constant.surfaceHeight == 52)
        #expect(TextField.Constant.horizontalPadding == 16)
        #expect(CornerRadiusToken.small.value == 8)
    }

    @Test
    func `상태별 테두리는 규격 토큰을 참조한다`() {
        #expect(TextField.State.default.borderColor == BorderToken.default.colorToken)
        #expect(TextField.State.active.borderColor == BorderToken.focus.colorToken)
        #expect(TextField.State.error.borderColor == BorderToken.error.colorToken)
    }

    @Test
    func `입력됨 상태는 grey400 1pt 테두리를 쓴다`() {
        #expect(TextField.State.filled.borderColor == ColorToken.grey400)
        #expect(TextField.State.filled.borderWidth == 1)
    }

    @Test
    func `오류 문구는 Caption 1 스타일 색을 쓴다`() {
        #expect(TextField.State.error.borderToken.width == 1)
    }
}
