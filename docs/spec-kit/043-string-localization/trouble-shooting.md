# 043-string-localization 문제 해결 기록

**대상 기능**: `043-string-localization`

**기록 원칙**: 실제 발생한 문제와 검증 근거를 append-only로 보존한다.

## TS-20260925-001: 구현 완료 뒤 세션 지시로 바뀐 설계가 명세·설계 산출물과 어긋남

**기록일**: 2026-09-25
**상태**: 미해결
**발생 단계**: `$speckit-implement` 완료 뒤, Spec Kit 워크플로 밖의 직접 수정 세션
**관련 항목**: FR-001, 시나리오 1 수용 조건 4, `plan.md`, `research.md` 결정(카탈로그 위치·키 형식),
`data-model.md`, `contracts/localization-convention.md`, `contracts/localized-text.md`, 커밋 `2b4a7de`, `aabc3fa`, `0192d4c`

### 증상

`tasks.md`의 작업 161개가 모두 완료(`[X]`)된 뒤, 같은 브랜치에서 Spec Kit 스킬을 거치지 않은 사용자 직접
지시로 구현과 공용 컨벤션이 바뀌었다. 그 결과 `specs/043-string-localization/`의 명세·설계 산출물이 현재
코드와 `docs/conventions/localization/`을 설명하지 못한다. 어긋난 지점은 다음 네 가지다.

| 항목 | 명세·설계 산출물 | 현재 구현·컨벤션 |
| --- | --- | --- |
| 접근성 레이블 | FR-001과 시나리오 1 수용 조건 4가 접근성 레이블·힌트를 현지화 리소스에서 조회하도록 요구. `contracts/localized-text.md`의 `.accessibilityLabel(LocalizedText.ScreenControlBar.backAccessibilityLabel)` 예시 | 접근성 레이블 항목·`accessibility*` modifier·아이콘 버튼 `label:` 파라미터 전부 제거(`2b4a7de`) |
| 키 형식 | lowerCamelCase 식별자, 점·밑줄 금지, `<화면·컴포넌트><용도>` (`data-model.md`, `contracts/localization-convention.md` §키, `research.md` 결정) | `LocalizedText` 경로와 같은 점 구분 키 `MainShell.SingleQuestion.FailureConfirm.buttonTitle` (`docs/conventions/localization/key.md`) |
| 카탈로그 위치 | Feature는 흐름마다 `Feature/<흐름>/Resources/<흐름>.xcstrings` 11개, UIComponent·GitIt은 `Resources/Localizable.xcstrings` (`plan.md` 구조, `research.md`) | target마다 카탈로그 하나를 `LocalizedText`와 같은 `Localization/` 폴더에 둠 (`Feature/Shared/Localization/Localizable.xcstrings` 등) |
| `LocalizedText` 멤버 이름 | 키에서 첫 단어(중첩 enum)를 뗀 나머지를 멤버 이름으로 사용 (`contracts/localized-text.md` 3항) | `<흐름>.<화면>.<주제>.<요소>.<용도>` 중첩 enum과 용도 멤버 (`docs/conventions/localization/localized-text.md`) |

### 영향

- 이 명세를 근거로 `$speckit-analyze`, `$speckit-converge` 또는 검증을 실행하면 현재 구현을 요구사항
  위반으로 판정하거나, 제거된 접근성 레이블과 흐름별 카탈로그를 다시 만드는 작업을 생성할 수 있다.
- FR-001의 접근성 레이블 요구와 시나리오 1 수용 조건 4는 현재 코드로 충족되지 않는다. VoiceOver가 읽는
  값은 현지화 리소스가 아니라 SwiftUI 기본 추론 값이다. 이는 의도된 제거이지만 명세에는 반영돼 있지 않다.
- 현지화 규칙의 현재 정본은 `docs/conventions/localization/`이며, 명세 산출물과 둘 중 무엇을 따를지
  문서만으로는 판별할 수 없다.

### 근거

- `specs/043-string-localization/tasks.md`: `- [X]` 161개, `- [ ]` 0개. 구현 워크플로는 완료된 상태였다.
- `git log develop..HEAD`: 흐름별 이전 커밋(`8b5ebff`…`54ed823`) 뒤에 `2b4a7de`
  `[Refactor] LocalizedText를 경로형 키 중첩 구조로 전환하고 접근성 modifier 제거`(147 files),
  `aabc3fa` `[Docs] 현지화 컨벤션을 경로형 키와 LocalizedText 중첩 구조로 갱신`(11 files)이 이어진다.
  두 커밋 모두 `specs/`를 수정하지 않았다.
- `specs/043-string-localization/spec.md:115-117`: FR-001이 “접근성 레이블·힌트”를 현지화 대상에 포함한다.
- `specs/043-string-localization/spec.md:69-70`: VoiceOver 초점 시 접근성 레이블이 현지화 리소스 값으로
  읽혀야 한다.
- `specs/043-string-localization/contracts/localization-convention.md:155`: “키는 소문자로 시작하는
  lowerCamelCase Swift 식별자다. 점·밑줄·공백·한국어를 쓰지 않는다.”
- `specs/043-string-localization/plan.md:178`: `<흐름>/Resources/<흐름>.xcstrings  # 신규 11개`.
- `docs/conventions/localization/key.md`: 키는 `LocalizedText` 경로와 같은 점 구분 이름이며 생성 심볼은
  점을 없앤 lowerCamelCase다.
- `0192d4c`: `spec.md`·`plan.md`·`research.md`·`data-model.md`·`quickstart.md`·`contracts/`·`checklists/`는
  구현과 설계 변경이 끝난 뒤에야 처음 커밋됐다. 그 전까지는 `tasks.md`만 추적되고 나머지는 untracked였다.

### 원인

확정 원인:

1. **설계 변경 경로가 Spec Kit 워크플로를 거치지 않았다.** 구현 완료 뒤 사용자가 대화로 접근성 레이블 제거,
   카탈로그 통합, 경로형 키, 멤버 이름 분할을 순서대로 지시했다. 이 지시는 `$speckit-specify`·`$speckit-plan`
   개정 없이 소스와 `docs/conventions/`에 바로 적용됐다.
2. **Spec Kit 범위 규칙 때문에 해당 세션이 명세를 고칠 수 없었다.** Constitution 원칙 5에 따라 `specs/`는 각
   `speckit-*` 스킬만 수정할 수 있다. 직접 수정 세션은 공용 컨벤션(`aabc3fa`)만 갱신했고 명세는 그대로 남았다.
3. **사용자가 명세를 수정하지 않기로 결정했다(2026-09-25).** 명세 정합성을 맞추는 대신 이 원인 리포트로
   마무리하도록 지시했다. 따라서 어긋남은 의도적으로 남아 있다.

기여 요인(관찰된 사실에 기반한 해석):

- 명세·설계 산출물이 untracked 상태로 구현 기간 내내 남아 있어서, 설계 변경 커밋의 diff 검토에 명세가
  함께 드러나지 않았다. 변경이 명세와 충돌한다는 신호가 커밋 단위로는 보이지 않았다.
- 설계 변경은 여러 단계로 오갔다. case 기반 토큰 설계를 적용했다가 static `String` API로 되돌리는 등
  중간 형태가 있었다. 명세를 단계마다 개정하는 비용이 커서 최종 형태가 확정된 뒤로 미뤄졌다.

### 조치

- 현재 규칙을 `docs/conventions/localization/`(`key.md`, `localized-text.md`, `string-catalog.md`,
  `call-site.md`, `entry-value.md`, `development-language.md`)와 관련 디렉터리·UIComponent 컨벤션에
  반영했다(`aabc3fa`).
- 명세·설계 산출물은 사용자 결정에 따라 수정하지 않고 작성 당시 상태 그대로 커밋했다(`0192d4c`).
- 명세 개정: 미실행(사용자 결정).

### 검증

- `.tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER` `compile`·`build`·`test`:
  2026-09-25 설계 변경 이후 구현에서 모두 성공(시도 7·9·7, 실패 0).
- 명세와 구현의 정합성 검증: 미실행. 어긋남이 남아 있으므로 `$speckit-analyze` 결과는 불일치를 보고할 것으로
  예상되며 실제 실행은 하지 않았다.

### 재발 방지

- `043-string-localization` 산출물을 근거로 판단하기 전에 이 항목을 먼저 확인한다. 위 표의 네 항목에서는
  `docs/conventions/localization/`과 현재 코드가 우선한다.
- 이 명세로 `$speckit-converge`·`$speckit-analyze`를 실행할 때, 표의 항목을 미구현·위반으로 처리해
  작업을 생성하지 않는다. 필요하면 먼저 명세 개정 여부를 사용자에게 확인한다.
- `tasks.md` 완료 뒤 설계를 바꾸는 지시를 받으면, 변경이 FR·계약과 충돌하는지 먼저 대조한다. 충돌하면
  명세 개정 스킬을 거칠지 이 파일에 기록할지 사용자에게 확인한다.
- 명세·설계 산출물은 생성한 단계에서 커밋해, 이후 설계 변경 diff와 함께 검토되게 한다.

### 연결

없음
