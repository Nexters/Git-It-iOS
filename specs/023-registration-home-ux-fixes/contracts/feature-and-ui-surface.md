# 계약: Feature·UI 공개 표면 변화

**대상 요구사항**: FR-002~007, FR-013, FR-017~023, FR-025

## UI — LabeledTextField 포커스 노출

```swift
public struct LabeledTextField: View {
    public init(
        label: String,
        placeholder: String,
        text: Binding<String>,
        // 기존 인자 유지 …
        focus: FocusState<Bool>.Binding? = nil,
    )
}
```

- 기본값 `nil`이라 기존 호출부는 변경 없이 컴파일된다.
- 바인딩을 전달하면 화면이 값을 `false`로 바꿔 키보드를 내릴 수 있다(FR-002).
- 필드 자체의 표시·검증 동작은 변하지 않는다.

## Feature — HomeFeature

```swift
extension HomeFeature.Action {
    public enum Input {
        case learningProjectsReloadRequested            // 기존
        case generationProgressChanged(isInProgress: Bool)   // 추가
    }
}
```

- `Input`은 부모 Feature 또는 App이 보내는 외부 조정 신호라는 기존 정의를 그대로 따른다.
- 홈은 이 값만으로 불러오기 패널의 표시와 조작 가능 여부를 결정한다(FR-005~007).
- 진행 상태의 수명과 타이밍은 홈이 아니라 `AppRootFeature`가 소유한다(R-009).

| 조건 | 기대 |
| --- | --- |
| `generationProgressChanged(isInProgress: true)` 수신 | 불러오기 버튼이 "문제 생성 중" 비활성 표기로 바뀐다(FR-006) |
| 진행 중 상태에서 `projectRegistrationTapped` | `delegate(.projectRegistrationRequested)`를 보내지 않는다(FR-007) |
| `generationProgressChanged(isInProgress: false)` 수신 | 기본 활성 상태로 복귀한다(FR-008) |
| 진행 중 여부와 무관 | 프로필·카드·전체 보기 동작은 동일하다(FR-009) |

## Feature — ProjectRegistrationFeature

```swift
extension ProjectRegistrationFeature.State {
    public init(initialRepositoryURL: String = "")
}
```

- 공유 진입 시 링크 입력 초기값을 주입한다(FR-025).
- 값이 비어 있으면 기존과 동일한 빈 입력 화면이다.
- 초기값은 검증되지 않은 외부 입력이므로 기존 검증 경로를 그대로 통과해야 한다.
- 비어 있지 않은 초기값을 받으면 1회용 자동 실행 표식을 함께 세운다(FR-025a).

```swift
// Action.View
case task
```

| 관찰 | 기대 |
| --- | --- |
| 자동 실행 표식이 선 상태에서 `task` 수신 | 표식을 지우고 `validateTapped`와 동일한 검증을 시작한다(FR-025a) |
| 표식이 없는 상태에서 `task` 수신 | 아무 일도 일어나지 않는다 |
| 표식이 선 상태에서 `task`를 두 번 수신 | 검증은 1회만 시작된다 |
| 초기값이 빈 문자열 | 표식이 서지 않아 자동 실행하지 않는다 |

- 화면은 `task`만 보내고 자동 실행 여부를 판단하지 않는다. 판단은 Feature 상태가 소유한다.
- App이나 부모 Feature가 `view` Action을 직접 보내지 않는다
  ([TCA Action 컨벤션](../../../docs/conventions/tca/action.md)).

```swift
public init(
    // 기존 UseCase 인자 …
    waitPolicy: GenerationWaitPolicy = .standard,
    now: @escaping @Sendable () -> Date = { Date() },
)
```

- 최소 대기 게이트(FR-013)를 위한 시간 의존을 생성자로 주입한다(R-006).
- 테스트는 짧은 `waitPolicy`와 고정 `now`로 대기 동작을 검증한다.

| 조건 | 기대 |
| --- | --- |
| `readyDate` 전에 완료 결과 도착 | 진행 화면을 유지하고 `readyDate`에 완료로 전이한다(FR-013) |
| `readyDate` 전에 실패 결과 도착 | 진행 화면을 유지하고 `readyDate`에 실패 화면으로 전이한다 |
| `readyDate` 이후 결과 도착 | 추가 지연 없이 전이한다(FR-012) |
| 진행률 시뮬레이션이 먼저 끝남 | 마지막 단계를 진행 중으로 유지하고 완료 표시나 화면 전환을 하지 않는다(FR-013) |

## Feature — HomeCardScrollLayout 주입 기준값

```swift
struct HomeCardScrollLayout {
    init(p0CenterX: CGFloat, cardStride: CGFloat)
    func angle(cardCenterX: CGFloat) -> Double
}
```

- 타입의 공개 형태는 그대로 두고, `p0CenterX`에 **측정한 기준 위치**를 넘긴다(R-003).
- 화면은 카드 목록 콘텐츠의 선행 가장자리 앵커와 카드 중심을 같은 좌표 공간에서 읽는다.

| 조건 | 기대 |
| --- | --- |
| 정지 상태의 첫 카드 | `angle`이 정확히 0(FR-021) |
| 스크롤 위치 변화 | 각도 함수에 불연속 지점이 없다(FR-022) |
| 화면 폭·선행 여백 변경 | 첫 카드 각도가 여전히 0 |
| 단위 테스트 | 화면을 렌더링하지 않고 각도를 검증할 수 있다(FR-023) |

## Feature — 카드 영역 높이

- 로딩·빈 상태·실제 카드 목록의 컨테이너 높이를
  `cardHeight + verticalPadding * 2`로 통일한다(FR-019, SC-006).
- 로딩 표시는 기존 빈 데크 실루엣과 로딩 인디케이터를 유지한다(FR-017).
