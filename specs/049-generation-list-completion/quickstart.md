# 빠른 시작: 서버 프로젝트 목록에서 확인된 생성 중 프로젝트를 완료로 반영

**명세**: [spec.md](./spec.md) | **계약**: [contracts/list-confirmed-completion.md](./contracts/list-confirmed-completion.md)

## 1. 자동 검증

저장소 루트에서 실행한다. 세 명령은 `sources/DerivedData/PreCommit`을 공유하므로 순차 실행한다.

```sh
project_build_runner=$(./.tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" build
"$project_build_runner" compile
"$project_build_runner" test
```

기대 결과: 모두 성공. 특히 다음 테스트 파일이 이 기능의 규칙을 검증한다.

| 파일 | 검증 대상 |
|---|---|
| `Domain/Tests/ProjectGeneration/UseCases/ProjectGenerationTests.swift` | 판정표 1~7행, 도착 알림 미방출, 원격 알림과의 순서 조합(SC-001·SC-003·SC-004·SC-005) |
| `Domain/Tests/Project/UseCases/ProjectTests.swift` | 첫 페이지·다음 페이지 반영 시 알림, 대체 응답·실패 시 미알림 |
| 기존 생성 결과·중복·만료·로그아웃·삭제·목록 갱신 테스트 | 변경 전후 통과(SC-006) |

## 2. 문서 확인 (SC-007)

`specs/048-generation-outcome-payload/spec.md` 가정 섹션의 "생성 결과는 원격 알림으로만 들어오므로 …"
문장에 이 명세(049)로 갱신되었다는 표시가 있어야 한다.

## 3. 실기기 검증 (SC-001, SC-002)

**전제**:
- 개발 빌드를 설치한 iPhone(예: Mini Jerry, iPhone 12 mini)이 Mac과 연결되어 있다.
- 서버 알림 누락 상황을 만들 수 없으면 알림 권한을 **꺼서** 표시·탭 경로를 막고, 백그라운드 수신이
  일어나지 않는 조건(앱 종료 상태)에서 확인한다. 이 방법으로 재현되지 않으면 미검증으로 기록한다.
- Console.app에서 기기를 선택하고 "디버그 메시지 포함"을 켠다. 검색어는 `LocalPendingGenerationStore`다.

| # | 조작 | 기대 결과 |
|---|---|---|
| 1 | 정상 저장소를 등록하고 "홈에서 기다리기"를 누른 뒤 앱을 종료한다 | 홈 "지금 불러오기"가 잠긴 상태로 남는다 |
| 2 | 서버 목록에 프로젝트가 나타난 뒤(다른 기기·웹에서 확인) 알림을 누르지 않고 앱 아이콘으로 연다 | 포그라운드 진입 목록 갱신 직후 홈 잠금이 풀린다. Console에 `생성 기록 저장: completed=1` 계열 로그가 남는다 |
| 3 | 2 직후 공유 확장에서 다른 저장소를 공유한다 | 생성 중 안내 없이 등록이 진행된다 |
| 4 | 1을 반복하되 앱을 종료하지 않고 생성 진행 화면에서 기다린다. 목록이 갱신되는 계기(홈 당겨서 새로고침)를 만든다 | 진행 화면이 완료 흐름으로 넘어간다 |
| 5 | 2 뒤에 같은 프로젝트의 서버 알림이 늦게 도착한다(가능한 경우) | 홈 잠금·목록은 그대로. 기록 상태가 바뀌지 않는다 |
| 6 | 2 뒤 목록 갱신 횟수를 관찰한다 | 목록 확인 자체로 추가 목록 요청이 일어나지 않는다(포그라운드 진입 1회만) |

수행하지 못한 항목은 PR 미검증 범위에 적는다.
