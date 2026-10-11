# 빠른 시작: 마이페이지 검증

**입력**: [spec.md](./spec.md)의 수용 시나리오, [contracts/](./contracts/)

## 사전 준비

```sh
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
```

`sources`에 workspace가 없으면 먼저 `tuist generate`를 실행한다.

## 자동화 검증

```sh
"$project_build_runner" build
"$project_build_runner" compile
"$project_build_runner" test
```

- Domain 테스트: `LearningStatistics`/`WeeklyLearningCount`의 교정된 필드로 기존 테스트가
  통과하는지 확인한다.
- Composition 테스트: `MemberRepositoryAdapterTests`가 `thisWeekSolvedCount`/
  `thisMonthSolvedCount`/`streakDays`/`weeklyChart`를 손실 없이 `LearningStatistics`로
  매핑하는지 검증한다(특히 요일 라벨 "월" 등이 더 이상 버려지지 않는지).
- `ProfileDisplayTests`(신규): `ProfileFeature.State`의 로딩/성공/실패 전이가 표시 값을
  올바르게 파생하는지 검증한다.
- 기존 `SettingsFeature`(변경 없음) 관련 테스트는 회귀 없이 그대로 통과해야 한다.

## Simulator 수동 검증 (시나리오별)

`mcp__Claude_Code_iOS_Simulator__control`로 앱을 빌드·실행한 뒤 확인한다.

1. **시나리오 1 (프로필 화면)**: 로그인 후 "마이" 탭 선택 → 이름·이메일·직군 배지·
   연차 배지와 이번 주/이번 달/연속 학습·주간 추이가 표시되는지 확인. 로딩·실패·재시도
   확인. 설정 아이콘 탭 → 설정 화면 이동 확인.
2. **시나리오 2 (직군·연차 변경)**: 설정 화면에서 "개발 분야" 행 탭 → 선택 화면에서
   옵션 선택 → 설정 화면으로 돌아와 즉시 반영 확인. "개발 수준"도 동일하게 확인. 앱
   재시작 후에도 유지되는지 확인. 서버 오류 강제 가능 환경이면 실패 시 이전 값 유지·
   오류 표시 확인.
3. **시나리오 3 (로그아웃·계정 삭제)**: 로그아웃 버튼 → 로그인 화면 이동 확인. "계정
   삭제" 행 → 확인 화면 이동 → 뒤로가기 시 변화 없음 확인 → (테스트 계정에서만) "회원
   탈퇴" 확정 → 계정 삭제와 로그인 화면 이동 확인.
4. **시나리오 4 (이용약관)**: 설정 화면에서 "서비스 약관 및 정책" 행 탭 → 내용 또는
   외부 링크 확인.

## Figma 대조

`implement-figma-ui` 스킬로 5개 노드(`1539:19209` 외 2개 프로필 변형, `1465:19689` 설정,
`1535:18281`/`1535:18378` 개발 분야/수준 선택, `1636:31714` 계정 삭제)를 조회해
레이아웃·색상·타이포그래피·문구가 일치하는지 확인한다(FR-012, SC-005). 차이가 있으면
수정하거나 사용자 승인을 받아 PR에 근거를 남긴다.

## 완료 기준

[spec.md 성공 기준](./spec.md#측정-가능한-결과) SC-001~SC-005가 모두 위 검증으로
확인되면 이 기능은 완료 상태다.
