# 참조 화면 Use Case 계약

**소유 target**: `DomainLearningProject` · **테스트 대역 위치**:
`FeatureTests/LearningProjectList/Mocks/`

## `FetchLearningProjects`

**책임**: 사용자가 학습할 수 있는 프로젝트 목록을 페이지 단위로 조회한다.

```swift
public protocol FetchLearningProjects: Sendable {
    func callAsFunction(page: Int, size: Int) async throws -> LearningProjectPage
}
```

| 항목 | 계약 |
| --- | --- |
| `page` | 0 이상 |
| `size` | 1 이상 |
| 성공 | `LearningProjectPage` 반환 |
| 일시 실패 | `LearningProjectError.temporarilyUnavailable` |
| 제외 책임 | 화면 로딩 상태, 무한 스크롤 감지, 캐시, 정렬 |

## `DeleteLearningProject`

**책임**: 식별한 학습 프로젝트를 사용자의 학습 대상에서 제거한다.

```swift
public protocol DeleteLearningProject: Sendable {
    func callAsFunction(_ id: LearningProjectID) async throws
}
```

| 항목 | 계약 |
| --- | --- |
| `id` | 비어 있지 않은 `LearningProjectID` |
| 성공 | 반환 없이 완료 |
| 대상 없음 | `LearningProjectError.projectUnavailable` |
| 일시 실패 | `LearningProjectError.temporarilyUnavailable` |
| 제외 책임 | 삭제 확인 UI, 화면 이동, 구체 저장 방식 |

## Mock 계약

`FeatureTests`는 `LearningProjectListFeature` 검증에 필요한 각 Protocol의 최소 로컬 Mock을
하나씩 제공한다.

| Mock 기능 | 검증 목적 |
| --- | --- |
| 사전 설정 결과 반환 | loaded·empty·failed 상태 전이 |
| 전달받은 입력 기록 | page·size·프로젝트 식별자 검증 |
| 호출 횟수 기록 | 중복 Effect 검출 |
| 제어 가능한 비동기 완료 | loading 및 취소 경로 검증 |

Mock 정의와 참조는 `FeatureTests/**` 안에만 둔다. `GitIt`, `Composition`, `Feature`
production target의 소스와 의존성에 포함하지 않는다. 후속 기능이 새 Use Case Protocol을
추가하면 그 Feature의 테스트 target에 필요한 Mock을 정의하고, 공유 Mock target이나 다른
Feature의 테스트 target에 의존하지 않는다.

## 앱 실행용 임시 구현

Composition은 두 Protocol을 만족하는 표본 구현과 `AppComposition` 조립 타입을 제공한다.

- 기본 조회는 고정 `LearningProjectPage`를 반환한다.
- 삭제는 표본 목록에서 식별자를 제거한 결과만 유지한다.
- harness용 `AppComposition.sample(fetch:)`는 조회 동작을 `projects`, `failure`, `pending`
  중 하나로 구성한다. `projects`는 loaded·empty, `failure`는 failed, `pending`은 loading
  launch scenario를 재현하며, 이 구성 타입은 Mock으로 이름 붙이거나 FeatureTests 자산을
  참조하지 않는다.
- 정렬, 권한, 네트워크 재시도 같은 비즈니스·데이터 정책을 구현하지 않는다.
- 구현 선택은
  `sources/Projects/Composition/Composition/AppComposition.swift`의
  `AppComposition.live()` 한 곳이 소유한다. 실제 구현으로 교체할 때 이 파일만 바뀌며
  App·Feature·화면 코드는 바뀌지 않는다.

## Feature 주입 계약

`LearningProjectListFeature` initializer가 두 Protocol을 명시적으로 받는다. Feature는
`@Dependency`, Service Locator, 전역 mutable container를 사용하지 않고 구현체를 직접
생성하지 않는다.
