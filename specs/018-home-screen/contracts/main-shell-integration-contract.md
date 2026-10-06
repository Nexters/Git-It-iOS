# MainShell·App 통합 계약

## 1. 탭 계약

| case | 표시 제목 | 화면 | 순서 |
|---|---|---|---:|
| `.home` | `홈` | scoped `HomeScreen` | 0 |
| `.projects` | `프로젝트` | 기존 제목 placeholder | 1 |
| `.saved` | `저장` | 기존 제목 placeholder | 2 |
| `.settings` | `마이` | 기존 제목 placeholder | 3 |

- `MainShellFeature.State().selectedTab == .home`다.
- 탭 선택은 child State를 재생성하지 않는다.
- Home의 `showAllProjectsTapped`은 `selectedTab = .projects`로 전이한다.
- Project·Saved·Settings reducer Scope는 유지하되 이 기능에서 실제 화면을 연결하지 않는다.

## 2. Child 소유

```text
MainShellFeature
├── Scope(HomeFeature)
├── Scope(ProjectListFeature)
├── Scope(SavedFeature)
└── Scope(SettingsFeature)
```

MainShell initializer가 받는 기존 `fetchLearningProjects`, `fetchMemberProfile`를 Home Scope에도
전달한다. 새 production dependency lookup을 추가하지 않는다.

## 3. Delegate 전달

| Home delegate | MainShell delegate | AppRoot 처리 |
|---|---|---|
| `projectRegistrationRequested` | 동일 의미의 등록 intent | `.none`, route 변경 없음 |
| `projectDetailRequested(projectID)` | payload 손실 없이 상세 intent | `.none`, destination 생성 없음 |
| `learningRequested(projectID,nextSetID,nextQuestionID)` | 세 ID 손실 없이 학습 intent | `.none`, destination 생성 없음 |

기존 `projectSelected`, `questionSelected`, `loggedOut` delegate는 유지한다. case 이름이 겹치면 의미를
통합할 수 있지만 Home의 payload를 손실하거나 실제 navigation을 시작해서는 안 된다.

## 4. 초기화

| 사건 | 결과 |
|---|---|
| MainShell 최초 생성 | Home 기본, 네 child 초기 State |
| Settings sign-out | 네 child와 선택 탭 초기화 후 `loggedOut` |
| Settings account deletion | 네 child와 선택 탭 초기화 후 `loggedOut` |
| App session invalidation/reset | `MainShellFeature.State()` 재생성; 다음 진입은 Home |

## 5. 통합 검증

1. `MainShellTab.allCases`는 Home→Project→Saved→Settings다.
2. 탭 전환 후 Home으로 복귀해도 Home State와 조회 호출 횟수가 유지된다.
3. `전체 보기`는 project 탭만 선택하고 App delegate를 발생시키지 않는다.
4. 등록·상세·학습 delegate는 Home→MainShell→App에서 payload를 유지한다.
5. 위 delegate 수신 후 AppRoot route·MainShell State·destination은 변경되지 않는다.
6. 로그아웃·계정 삭제·reset 후 재진입에서 Home이 기본이다.
