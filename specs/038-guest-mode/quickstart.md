# 빠른 시작: 비로그인(게스트) 모드 검증

**기능**: [spec.md](spec.md) | **계약**: [contracts/feature-actions.md](contracts/feature-actions.md)

## 사전 조건

- 브랜치 `feature/guest-mode`, workspace 생성 완료(`make tuist`)
- 시뮬레이터 `iPhone 17 Pro`(iOS 26)

## 자동 검증

```sh
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" build
"$project_build_runner" compile
"$project_build_runner" test
```

기대 결과: 7개 scheme 모두 통과. 이 기능에서 추가하거나 수정하는 테스트 묶음은 다음과 같다.

| 대상 | 테스트 파일 | 확인하는 명세 |
| --- | --- | --- |
| UI | `UI/Tests/Component/Unit/Scaffolds/TabShellContractTests.swift` | FR-009 표시 계약 |
| Feature | `Feature/Tests/Onboarding/Tutorial/TutorialFeatureTests.swift` | FR-001, 로그인 중 중복 입력 |
| Feature | `Feature/Tests/Onboarding/Router/OnboardingRouterFeatureTests.swift` | FR-002, FR-012 중단 |
| Feature | `Feature/Tests/Home/Home/HomeFeatureGuestAccessTests.swift` | FR-004(Home 요청), FR-005, FR-006, FR-008, SC-002 |
| Feature | `Feature/Tests/Home/Home/ViewModels/HomeProjectSectionStateTests.swift` | FR-007 |
| Feature | `Feature/Tests/MainShell/Router/GuestSignInFeatureTests.swift` | FR-011, FR-012 약관 단계, FR-013 |
| Feature | `Feature/Tests/MainShell/Router/MainShellRouterFeatureGuestAccessTests.swift` | FR-004(Router 재조회), FR-009, FR-011, 탭 유지 |
| App | `App/Tests/GitIt/Reducers/AppRootFeatureGuestAccessTests.swift` | FR-002, FR-004(기기 등록), FR-012, FR-014, FR-015 |

FR-003(비로그인 선택 비저장)은 저장 코드를 추가하지 않는 것으로 충족하며 아래 수동 검증 7로, FR-010(마이 탭 로그인
화면)은 View 분기이므로 수동 검증 4·8로 확인한다.

## 수동 검증(시뮬레이터)

1. 앱 삭제 후 설치·실행 → 튜토리얼 마지막 면까지 넘김 → Apple 로그인 버튼 아래 `로그인 없이 둘러보기` 표시 확인.
   1·2면에는 표시되지 않는다.
2. `로그인 없이 둘러보기` → 약관·직군 화면 없이 홈 탭 표시(SC-001: 선택 2회 이하 — 페이지 넘김 제외).
3. 홈: 로그인 섹션, 프로젝트 영역 안내 문구, 비활성 전체보기 확인. 등록 패널의 `지금 불러오기` → `로그인이 필요해요` 알럿,
   `닫기`로 닫힘.
4. 탭 막대: 프로젝트·저장 탭이 흐리게 표시되고 눌러도 전환되지 않음. 마이 탭 → 로그인 화면.
5. Xcode 네트워크 로그(또는 Proxy)로 1~4 동안 계정 API 요청과 기기 등록 요청이 0건인지 확인(SC-002).
6. 앱을 백그라운드 → 포그라운드 → 비로그인 메인 화면 유지(FR-014).
7. 앱 종료 후 재실행 → 튜토리얼 첫 면(FR-003).
8. 비로그인 → 마이 탭 로그인 화면에서 Apple 로그인 취소 → 화면 유지(FR-013). 다시 로그인 성공 → 마이 탭이
   프로필로 바뀌고 모든 탭 활성(명확화 Q3).
9. 신규 계정으로 홈 로그인 섹션에서 로그인 → 직군 선택 화면에서 나가기 → 로그아웃 후 비로그인 메인 화면(명확화 Q1).
10. 로그인 상태에서 마이 → 로그아웃 → 튜토리얼 첫 면(명확화 Q2, FR-015).
