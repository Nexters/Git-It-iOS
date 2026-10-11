# TCA 화면과 Store 연결

[Git It iOS TCA 컨벤션 — Navigation과 화면 연결](../navigation.md)의 규칙 문서입니다.

- 화면은 `@ViewAction`을 적용해 Store를 관찰하고, View가 `View` Action만 보낼 수 있는
  경계를 코드로 드러냅니다([Action 컨벤션 — Action 출처 분류](../action/source.md)).
- UIComponent 콜백은 View Action으로 해석합니다. UIComponent에 Feature·TCA 타입을
  전달하지 않고 화면 ViewModel을 두지 않는다는 제약은
  [Feature 패키지 규칙](../../../package-rules/feature.md#제약조건)이 소유합니다.

화면의 생성 경로(`init(store:)`), Store 상태를 컴포넌트 표시 값·`Binding`으로 연결하는
형태와 화면 조립은 [View 컨벤션 — 화면의 생성 경로](../../view/screen-init.md)·
[화면 조립](../../view.md#4-화면-조립)이, UIComponent 입력 경계는
[UIComponent 컨벤션 — 공개 계약](../../ui-component/public-contract.md)가 소유합니다.
