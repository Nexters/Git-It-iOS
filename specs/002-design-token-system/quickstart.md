# 빠른 시작: 디자인 토큰 시스템 검증

**입력**: [data-model.md](./data-model.md), [contracts/design-token-api.md](./contracts/design-token-api.md)

이 문서는 세 사용자 스토리를 실제로 실행해 확인하는 절차입니다. 코드 전체 구현은
`tasks.md`/구현 단계에서 다루며, 여기서는 실행 가능한 검증 시나리오만 기술합니다.

## 사전 준비

```bash
make init
```

`sources/Projects/UI` 아래 `DesignSystem`(값 모델 + 적용 수단)과 `DesignSystemTests`(신규
unitTests 타겟, research.md §1)가 Tuist 프로젝트에 포함되어 있어야 합니다.

## 시나리오 1 — 화면 없는 토큰 정의 검증 (사용자 스토리 3, SC-001·SC-004·SC-007)

```bash
xcodebuild test \
  -workspace GitIt.xcworkspace \
  -scheme DesignSystemTests \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

**기대 결과**: 시뮬레이터 부팅은 되지만 화면 렌더링·앱 실행 없이 아래가 모두 통과합니다.

- `ColorToken.Name.allCases.count == 24`이고 그룹별 개수(Blue 5·Purple 5·Grey 7·Opacity
  4·State 3)와 각 hex 값이 명세 표와 일치.
- `GradientToken.Name.allCases.count == 3`이고 각 정지점 2개, 위치 0/1, 기본 좌표
  `(0.5, 0)`→`(0.5, 1)` 일치.
- `TextStyleToken.Name.allCases.count == 10`이고 굵기·크기·행간이 명세 표와 일치.
- `LayoutToken.margin.value == 20`, `LayoutToken.gutter.value == 12`.
- 존재하지 않는 토큰 이름을 참조하는 코드는 이 단계 이전(빌드)에서 이미 실패해야 함
  (별도 실행 테스트 불필요 — 컴파일 실패 자체가 증거, FR-004).

## 시나리오 2 — 토큰만으로 화면 구성 (사용자 스토리 1, SC-002·SC-003·SC-005·SC-006)

디자인 참고 문서(`docs/design-system-ref/Design system.png`)의 화면 예시 하나를 토큰
API로만 구성한 SwiftUI 미리보기를 작성합니다.

```swift
#Preview("디자인 토큰 적용 예시") {
    VStack(spacing: DesignSystem.tokenGutter) {
        Text("한글 Title 혼용 Text")
            .tokenTextStyle(.subtitle2)
            .tokenForeground(.grey100)
    }
    .tokenScreenMargin()
    .tokenGradientBackground(.gradient2)
}
```

**기대 결과**: Xcode Preview 캔버스에서 색상·글꼴·행간·여백이 참고 디자인과 일치.
소스 파일 어디에도 hex 값·pt 숫자·글꼴 이름 리터럴이 등장하지 않아야 합니다(SC-003, 코드
리뷰로 확인). 한/영 혼용 문자열에서 한글·숫자·공백·기호는 Noto Sans, 영문 알파벳은
Plus Jakarta Sans로 렌더링되는지 육안 확인합니다(FR-010).

## 시나리오 3 — 값 변경이 사용처에 영향 없이 반영 (사용자 스토리 2, SC-002)

1. `ColorToken.Name.blue300`의 `RGBAComponents` 값을 임시로 다른 색으로 바꿉니다.
2. 시나리오 2의 `#Preview`를 다시 렌더링합니다(코드 수정 없이).
3. 미리보기 색상이 즉시 바뀌는지 확인한 뒤 값을 원복합니다.

**기대 결과**: 1단계(정의 파일) 외에 수정한 파일이 0개입니다.

## 완료 기준

세 시나리오가 모두 통과하면 `/speckit-tasks`로 넘어가 이 계획을 작업 단위로 분해할 수
있습니다.
