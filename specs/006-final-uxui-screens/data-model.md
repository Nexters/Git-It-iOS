# 데이터 모델: 최종 UXUI 화면 구현 기반

**대상 기능**: `006-final-uxui-screens` · **작성일**: 2026-08-19

이 문서는 명세의 핵심 엔터티를 두 층으로 나눠 정의한다. 1층은 계약 문서가 표현하는
**기록 엔터티**이고, 2층은 참조 화면 구현이 소유하는 **런타임 타입**이다. 두 층을 섞지
않는다. 기록 엔터티는 `contracts/**`의 표 구조를 규정하고, 런타임 타입은 Domain·Feature가
소유하는 선언을 규정한다.

## 1. 기록 엔터티

### 1.1 화면(Screen)

| 필드 | 값 | 규칙 |
| --- | --- | --- |
| `id` | `screen.<그룹>.<이름>` | 계약 전체에서 고유 |
| `frameName` | Figma 프레임 이름 | 원문 유지 |
| `nodeIds` | 노드 식별자 목록 | 상태 변형 프레임을 모두 포함 |
| `group` | `G1`~`G5` 또는 `제외` | 정확히 하나 |
| `classificationStatus` | `대조 완료` · `내용 미대조` · `제외` | 참조 화면 외에는 `내용 미대조` 허용 |
| `states` | 상태 변형 목록 | 참조 화면은 전량 확정, 나머지는 확인한 범위 또는 `내용 미대조` |
| `implementation` | 구현 위치 또는 `미구현` | 참조 화면에 필수, 나머지는 후속 기능에서 추가 |
| `status` | `구현` · `미구현` · `제외` | 참조 화면에 필수 |

**규칙**: 이름이 같은 프레임은 내용을 대조하기 전에는 별개 화면으로 집계하지 않고
`내용 미대조`로 표시한다. 자식 구성이 같고 특정 구성 요소의 변형만 다르면 한 화면의 상태
변형이다(R-08). 이 기능은 참조 화면만 상태·구현 필드를 모두 확정하며 나머지 화면의 상세
대조는 담당 후속 기능이 수행한다.

### 1.2 상태 변형(Screen state)

| 필드 | 값 | 규칙 |
| --- | --- | --- |
| `id` | `<screen.id>.<상태>` | 화면 안에서 고유 |
| `nodeId` | 대응 프레임 노드 | 없으면 `없음`과 사유 |
| `condition` | 표시 조건 | 사용자 관점으로 서술 |
| `evidence` | `A` · `B` · `C` · `보류` · `운영` | Figma 미대응 운영 상태는 `운영` |
| `covered` | `대응` · `미대응` | 미대응이면 사유 필수 |

**전이**: 상태 변형 사이의 전이는 화면 안 상호작용으로만 표현하고, 다른 화면으로 넘어가는
이동은 화면 전환(1.5)으로 기록한다.

### 1.3 레이아웃 상수(Layout constant)

| 필드 | 값 | 규칙 |
| --- | --- | --- |
| `id` | `<대상>.<항목>` | 계약 전체에서 고유 |
| `target` | 화면 또는 컴포넌트 | |
| `value` | 수치와 단위 | `pt` 고정 |
| `evidence` | `A` · `B` · `C` · `보류` | `보류`는 목표값을 비운다 |
| `sourceNode` | Figma 노드 식별자 | `A`이면 필수 |
| `tolerance` | 기본 `±0.5pt` | 다르면 사유 기록 |
| `testId` | 자동 검증 식별자 | 없으면 `없음`과 사유 |

**규칙**: 현재 구현값을 근거 없이 목표값으로 승격하지 않는다. `C`는 값 보존 검증에만
사용하고 Figma 일치 판정에 쓰지 않는다.

### 1.4 색 적용(Color application)

| 필드 | 값 | 규칙 |
| --- | --- | --- |
| `element` | 적용 대상 요소 | |
| `tokenName` | 저장소 토큰 이름 | 리터럴 금지 |
| `hex` | `#RRGGBB` | 대문자 |
| `opacity` | 0~1 | 생략 시 1 |
| `evidence` | `A` · `B` · `C` · `보류` | |

**규칙**: 색과 불투명도는 한 항목으로 함께 기록한다. 불투명도만 다른 값을 같은 항목으로
합치지 않는다.

### 1.5 화면 전환(Screen transition)

| 필드 | 값 | 규칙 |
| --- | --- | --- |
| `from` / `to` | 화면 식별자 | |
| `trigger` | 전환을 일으키는 조작 | |
| `evidence` | `프로토타입 확인` · `추정` | 둘을 섞어 기록하지 않는다 |
| `owner` | 확정 책임 기능 | 추정 항목은 담당 그룹 기능 |

**규칙**: 추정 전환을 확정 전환으로 기록하지 않는다(FR-028).

### 1.6 후속 기능 그룹(Screen group)

| 필드 | 값 | 규칙 |
| --- | --- | --- |
| `id` | `G1`~`G5` | |
| `screens` | 포함 화면 목록 | 다른 그룹과 겹치지 않는다 |
| `entryScreen` | 시작 화면 | 정확히 1개 |
| `links` | 다른 그룹과의 연결 지점 | 근거 수준 포함 |
| `prerequisites` | 선행 조건 | |
| `baseline` | 의존하는 기반 항목 | 006 산출물 참조 |
| `ownedComponents` | 그룹이 소유하는 공용 컴포넌트 | 중복 소유 금지 |

### 1.7 Use Case 계약(Use case contract)

| 필드 | 값 | 규칙 |
| --- | --- | --- |
| `name` | Protocol 이름 | Domain 어휘만 사용 |
| `input` / `output` | 시그니처 | 기술 용어 노출 금지 |
| `failure` | 실패 조건 | |
| `mock` | Mock 존재 여부와 Feature별 테스트 target 안의 로컬 위치 | production·공유 Mock target 금지 |
| `sampleImplementation` | 임시 구현 존재 여부와 위치 | |

## 2. 런타임 타입

### 2.1 Domain — `DomainLearningProject`

```text
LearningProjectID          값 객체. 문자열 원시값을 감싸고 비교 가능
LearningProjectSummary     목록 표시용 투영
  ├ id: LearningProjectID
  ├ name: String                 프로젝트 이름
  ├ technologies: String         부제로 표시하는 기술 목록
  ├ progress: LearningProgress   전체 진행 정보
  └ nextSet: LearningSetMark     다음 학습 세트 표시 정보
LearningProgress
  └ completedRatio: Double       0...1 범위. 범위 밖 값은 생성 시 걸러진다
LearningSetMark
  ├ order: Int                   세트 번호
  └ title: String                세트 제목
LearningProjectPage
  ├ projects: [LearningProjectSummary]
  └ hasNextPage: Bool
LearningProjectError           Use Case 실패 표현
  ├ temporarilyUnavailable
  └ projectUnavailable
```

**검증 규칙**

- `LearningProgress.completedRatio`는 `0...1`을 벗어나면 경계값으로 고정한다.
- `LearningSetMark.order`는 1 이상이다.
- 모든 타입은 `Sendable`이며 저장·네트워크 용어를 이름과 타입에 노출하지 않는다.

**Use Case 계약**

```text
FetchLearningProjects  (page: Int, size: Int) async throws -> LearningProjectPage
DeleteLearningProject  (LearningProjectID) async throws -> Void
```

세부 시그니처와 실패 의미는 `contracts/use-case-contracts.md`가 소유한다.

### 2.2 Feature — 프로젝트 목록 화면

```text
LearningProjectListFeature.State
  ├ projects: IdentifiedArrayOf<LearningProjectSummary>
  ├ loadState: LoadState            .idle | .loading | .loaded | .failed
  ├ isMenuPresented: Bool           상단 메뉴 펼침 여부
  ├ isDeleteMode: Bool              삭제 모드 여부
  ├ pendingDeletion: LearningProjectID?   삭제 확인 모달 대상
  └ isEmpty: Bool                   파생값. loaded이면서 projects가 비었을 때 참

LearningProjectListFeature.Action
  ├ onAppear
  ├ projectsResponse(Result<LearningProjectPage, Error>)
  ├ retryButtonTapped
  ├ menuButtonTapped
  ├ menuDismissed
  ├ deleteModeEntered
  ├ deleteModeExited
  ├ deleteButtonTapped(LearningProjectID)
  ├ deletionConfirmed
  ├ deletionCancelled
  ├ deletionResponse(Result<LearningProjectID, Error>)
  └ delegate(Delegate)              화면 밖 이동 의도
```

**상태 전이**

| 현재 | Action | 다음 |
| --- | --- | --- |
| `idle` | `onAppear` | `loading`, `FetchLearningProjects` 호출 |
| `loading` | `projectsResponse(.success)` | `loaded`. 비어 있으면 `isEmpty` 참 |
| `loading` | `projectsResponse(.failure)` | `failed` |
| `failed` | `retryButtonTapped` | `loading`, `FetchLearningProjects` 재호출 |
| `loaded` | `menuButtonTapped` | `isMenuPresented` 참 |
| `isMenuPresented` | `deleteModeEntered` | `isMenuPresented` 거짓, `isDeleteMode` 참 |
| `isDeleteMode` | `deleteButtonTapped(id)` | `pendingDeletion = id` |
| `pendingDeletion != nil` | `deletionConfirmed` | `DeleteLearningProject` 호출 |
| — | `deletionResponse(.success(id))` | 목록에서 제거, `pendingDeletion = nil` |
| — | `deletionResponse(.failure)` | `pendingDeletion = nil`, 목록 유지 |
| `pendingDeletion != nil` | `deletionCancelled` | `pendingDeletion = nil` |

**주입 규칙**: `FetchLearningProjects`와 `DeleteLearningProject`는 initializer 인자로만
전달한다. Feature 안에서 구현을 생성하지 않고 `@Dependency`를 사용하지 않는다.

### 2.3 UI — 참조 화면이 사용하는 표현 계약

화면은 Feature State를 다음 컴포넌트의 불변 `ViewModel`로 변환한다. 컴포넌트는 Feature
타입을 알지 못한다.

| 컴포넌트 | 역할 | 상태 |
| --- | --- | --- |
| `ScreenContainer` | 배경과 색 구성표 | 기존 |
| `ScreenHeader` | 상단 툴바(Inline Title · Large Title) | 기존, 근거 승격 |
| `ProjectRow` | 목록 행 | 기존, 교정 |
| `EmptyState` | 빈 상태 | 기존 |
| `SheetSurface` | 삭제 확인 시트 표면 | 기존, 교정 |
| `BottomActionBar` | 시트 하단 액션 영역 | 기존, 근거 승격 |
| `ActionButton` | 삭제·취소 버튼 | 기존, 크기 계단 교정 |
| `IconGlassButton` | 행의 삭제 아이콘 | 기존, 근거 승격 |
| `IconPlainButton` | 행의 학습 시작 아이콘 | 기존 |
| `TagBadge` | 세트 번호 태그 | 기존, 반경 교정 |
| `TabShell` | 하단 탭 | 기존, 목표 형태 보류 |
| `ActionMenu` | 상단 메뉴(Figma `Dropdown menu`) | 신설 |
| `ScreenEdgeScrim` | 상·하단 dim 그라데이션 | 신설, 상단 아래→위·하단 위→아래 |

`ActionMenu`와 `ScreenEdgeScrim`의 최종 이름·계약은
`contracts/reference-screen-layout.md`에서 확정한다.
