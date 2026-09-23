# 키

[Git It iOS 현지화 컨벤션](../localization.md)의 규칙 문서입니다.

**키는 소문자로 시작하는 lowerCamelCase Swift 식별자입니다.** 점·밑줄·공백·한국어를 쓰지 않습니다.
키는 생성 심볼 이름이 되므로 Swift 식별자로 쓸 수 있어야 합니다.

**이름은 `<화면·컴포넌트><용도>` 순서입니다.** 예: `profileNicknameTitle`,
`webSheetCloseAccessibilityLabel`, `savedEmptyMessage`. `Localizable` 테이블을 여러 컴포넌트·기능이
함께 쓰는 `UIComponent`·`GitIt`은 첫 단어가 반드시 컴포넌트·기능 이름이어야 키가 테이블 안에서
유일합니다.

**테이블 이름이 주는 문맥(흐름 이름)은 키에 따로 붙이지 않습니다.** 키의 첫 단어는 화면·컴포넌트
이름입니다. `Settings` 흐름의 `Profile` 화면 제목은 `profileTitle`이고, 흐름과 이름이 같은
`Settings` 화면의 제목은 `settingsTitle`입니다(`settingsSettingsTitle`이 아닙니다). 흐름의
`Router`·`Shared`가 쓰는 문구는 첫 단어를 `router`·`shared`가 아니라 그 문구가 보이는
화면·컴포넌트 이름으로 씁니다.

- 용도 어휘는 `Title`, `Message`, `Description`, `ButtonTitle`, `Placeholder`, `ErrorMessage`,
  `AccessibilityLabel`, `AccessibilityHint`, `AccessibilityValue`처럼 표시 위치를 드러내는 명사로
  끝냅니다.
- 같은 한국어 값이라도 용도나 화면이 다르면 다른 키를 둡니다. 값이 같다는 이유로 키를 공유하지
  않습니다. 예: `ChoiceAnswerOption`과 `ChoiceResultRow`의 “정답”은
  `choiceAnswerOptionCorrectLabel`과 `choiceResultRowCorrectLabel`로 나뉩니다.
- 한국어 값을 고쳐도 키는 바꾸지 않습니다. 용도가 바뀌면 기존 항목을 지우고 새 키를 만듭니다.

이름 판단의 일반 기준은 [네이밍 컨벤션](../naming.md)이 소유합니다.
