# Git It iOS View 내부 선언 컨벤션

**상태**: 초안

**작성일**: 2026-08-31

**최종 수정일**: 2026-09-24 (사용자 노출 문구를 `Constant`에서 제외하고 현지화 컨벤션으로 연결)

## 목적

이 문서는 UIComponent 컴포넌트와 Feature 화면이 소유하는 비상태 보조 선언
(`Constant`, `Style`, `DisplayModel`, 그 밖의 보조 타입)을 View 파일에 중첩하는 방식과, Swift 제약으로
중첩할 수 없는 경우의 예외를 정의합니다. 공개 생성 경로, 화면 조립과 프리뷰는
[View 컨벤션](./view.md), 디자인 토큰 사용 규칙은
[View 토큰 컨벤션](./view-tokens.md)이 소유합니다.

문서 우선순위, 문서 구조와 문서 간 참조 규칙은
[컨벤션 공통 원칙](./common/README.md)이 소유합니다.

## 1. 적용 범위

- `sources/Projects/UI/Component/**` 컴포넌트가 소유하는 `Constant`, `Style`,
  `DisplayModel`과 그 밖의 비상태 보조 타입
- `sources/Projects/Feature/**` 화면이 소유하는 `Constant`와 화면 전용 렌더링 보조 선언

Feature의 `State`, `Action`, Reducer와 cancellation ID는 View가 아니라 Feature 타입이
소유하므로 이 문서의 적용 대상이 아닙니다([TCA 컨벤션](./tca/README.md)).

## 2. View 내부 선언

View가 소유하는 선언은 언제나 그 View의 이름 아래에, 소유 View와 같은 파일에 둡니다.
표시 값이 2개 이상인 컴포넌트는 표시 값을 `public` 중첩 타입 `DisplayModel` 하나로 묶어
받습니다.

→ [View 내부 선언](./view-declarations/internal-declarations.md)

### 2.1 `Constant`

상태와 무관한 수치, 사용자에게 보이지 않는 정적 문자열, 플레이스홀더는 case 없는 `Constant`의 `static`
멤버로 정의합니다. 사용자 노출 문구는 [현지화 컨벤션](./localization.md)의 `LocalizedText`가 소유합니다.

→ [`Constant`](./view-declarations/constant.md)

### 2.2 `private`을 붙일 수 없으면 소유가 잘못된 것입니다

View가 소유하는 선언은 `private`입니다. 컴포넌트 초기화 계약의 일부인 `DisplayModel`은 내부 선언이
아니라 공개 계약이므로 이 규칙의 대상이 아닙니다.

→ [선언 소유 판단](./view-declarations/ownership.md)

### 2.3 `Style`

고정된 토큰 조합을 갖는 시각 변형이 둘 이상일 때만 `Style`을 정의합니다. 변형은 초기화
인자가 아니라 `StyleConfigurable`의 `style(_:)` 메서드로 선택합니다.

→ [`Style`](./view-declarations/style.md)

### 2.4 외부 상태와 `Binding`

UI 컴포넌트는 표시 상태의 원본을 소유하지 않습니다.

→ [외부 상태와 `Binding`](./view-declarations/binding.md)

### 2.5 중첩할 수 없는 경우

Swift 제약으로 중첩이 불가능하거나 중첩이 호출부를 해치는 경우가 있습니다.

→ [중첩할 수 없는 경우](./view-declarations/non-nestable.md)

## 3. 검토 체크리스트

- [ ] UI 컴포넌트의 `Constant`, `Style`, `DisplayModel`과 비상태 보조 타입이 컴포넌트
      타입에 중첩되어 파일에 함께 있는가?
- [ ] 표시 값이 2개 이상인 컴포넌트가 표시 값을 `public` `DisplayModel`(`Sendable`,
      `Equatable`) 하나로 묶어 `init(displayModel:...)`으로 받고, 상태·`Binding`·콜백은
      모델 밖에 두었는가?
- [ ] Feature 화면에는 `Constant`와 화면 전용 렌더링 보조 선언만 있고, `State`,
      `Action`, Reducer를 중복한 ViewModel·Style이 없는가?
- [ ] 최상위로 꺼낸 선언이 §2.5의 중첩 불가 사유에 해당하는가?
- [ ] View가 소유하는 선언이 공개 계약인 `DisplayModel`을 제외하고 `private`인가? 접근
      수준을 넓히는 대신 §2.2의 표대로 소유를 다시 정했는가?
- [ ] 최상위 View의 `Constant`가 파일 하단 `private extension` 블록에 있는가?
- [ ] 중첩 서브뷰의 `Constant`가 부모가 아니라 서브뷰 자신에게 있는가?
- [ ] 화면과 서브뷰가 주고받는 표시 모델을 View에 중첩하지 않고 최상위 타입으로
      분리했는가?
- [ ] `{View}+Constant.swift`처럼 선언을 별도 파일로 나누지 않았는가?
- [ ] 중첩 타입 이름이 소유 View 이름을 반복하지 않는가?
- [ ] 이름 없이 의미가 드러나지 않는 수치가 `Constant`에 있는가?
- [ ] `Constant`에 case와 인스턴스 멤버가 없고 멤버가 리터럴만 반환하는가?
- [ ] 제네릭 View의 `Constant`가 파일 최상위가 아니라 View 안에 `static var`로 있는가?
- [ ] 변형별 표현 값을 View가 아니라 `Style`이 소유하는가?
- [ ] `Style`을 초기화 인자로 받지 않고, 기본값이 있는 `private var`로 저장한 뒤
      `StyleConfigurable`의 `style(_:)` 메서드로 선택하게 했는가?

## 관련 문서

- [아키텍처](../architecture.md)
- [View 컨벤션](./view.md)
- [View 토큰 컨벤션](./view-tokens.md)
- [TCA 컨벤션](./tca/README.md)

## 문서 변경 기준

View 내부 선언의 중첩 규칙, `Constant`·`Style`·`DisplayModel`의 책임 또는 중첩할 수 없는 경우의
예외가 바뀔 때 수정합니다. 공개 생성 경로, 화면 조립이나 프리뷰가 바뀌면 이 문서가
아니라 [View 컨벤션](./view.md)을, 디자인 토큰 사용 규칙이 바뀌면
[View 토큰 컨벤션](./view-tokens.md)을 갱신합니다.
