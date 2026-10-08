# Reducer 책임

[Git It iOS TCA 컨벤션 — Reducer와 Effect](../effect.md)의 규칙 문서입니다.

- Reducer는 현재 State와 Action을 해석해 State를 동기적으로 전이하고 실행할 Effect를
  반환합니다.
- 화면 상태를 바꾸는 판단, 사용자 의도 해석과 유효하지 않은 입력 차단은 Reducer가
  소유합니다.
- Reducer나 View 안에서 `Task`를 만들거나 Use Case, `URLSession`,
  `NotificationCenter` 같은 외부 작업을 직접 실행하지 않습니다.
- 오류를 무시하거나 View가 Domain 오류를 직접 해석하게 하지 않습니다.

## Action 분기

**`body`의 `Reduce`는 `Action`의 최상위 case만 분기합니다.** 각 case는 연관값을 한 단계만
벗겨 그 연관값 전용 `private func reduce(into:<case>:)`로 넘깁니다. `.view(.task)`,
`.home(.delegate(.signInRequired))`처럼 여러 단계를 한 패턴에 중첩하지 않습니다.

```swift
Reduce { state, action in
    switch action {
    case .view(let action):
        reduce(
            into: &state,
            view: action,
        )

    case .effect(let event):
        reduce(
            into: &state,
            effect: event,
        )

    case .home(let action):
        reduce(
            into: &state,
            home: action,
        )

    case .delegate:
        .none
    }
}
```

- 분기 함수는 `private func reduce(into state: inout State, <case> action: <연관값 타입>) ->
  Effect<Action>`입니다. 인자 레이블은 Action case 이름과 같고, `effect` case는 매개변수 이름을
  `event`로 씁니다. 함수 안의 `switch`도 한 단계만 분기합니다.
- 처리할 내용이 없는 case(보통 `delegate`)는 최상위 `switch`에서 `.none`을 반환하며 빈 분기 함수를
  만들지 않습니다.
- 하위 Feature Action은 부모가 `delegate`만 해석하므로 분기 함수 첫 줄에서
  `guard case .delegate(let action) = action else { return .none }`로 한 단계를 벗긴 뒤 `Delegate`를
  `switch`합니다. `PresentationAction`은 `.presented`와 `.delegate`를 `guard`의 조건 두 개로 한
  단계씩 벗깁니다.
- 부모가 하위 Action의 `delegate` 외 case도 해석하면 하위 Action을 한 단계 `switch`하고, 각 case를
  `<하위 case><하위 Action case>` 레이블의 분기 함수로 넘깁니다 → `reduce(into:legalAgreementEffect:)`,
  `reduce(into:legalAgreementDelegate:)`.
- 자기 `delegate` case에서 할 일이 있으면(예: `dismiss()`) 다른 case와 같이 `reduce(into:delegate:)`로
  넘깁니다.
- 연관값 `switch`는 `default` 없이 모든 case를 나열합니다. 무시하는 case도 `.none`을 반환하는
  분기로 적어 새 case가 추가되면 컴파일러가 알리게 합니다.
- 분기 함수는 `// MARK: Private` 아래, 최상위 case 순서대로 두고 Effect 생성 보조 함수보다 앞에
  둡니다.
