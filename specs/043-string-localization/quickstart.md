# 빠른 검증 가이드: 사용자 노출 문자열 현지화 적용

**기능**: [spec.md](./spec.md) | **계획**: [plan.md](./plan.md)

구현이 명세를 충족하는지 확인하는 실행 절차다. 구현 코드는 [contracts/](./contracts/)와 `tasks.md`를
따른다.

## 사전 조건

- Xcode 26.6 이상, Tuist 4.202.2, iOS 26 시뮬레이터 `iPhone 17 Pro`
- 저장소 루트에서 `make tuist`로 workspace를 다시 생성한다(manifest 변경 반영).

## 1. 생성 결과 확인 (research R1·R2)

```sh
make tuist
ls sources/Projects/*/Derived/Sources | grep -i strings
```

- `TuistStrings+*.swift`가 없고, `TuistAssets+UIComponent.swift`·`TuistFonts+DesignSystem.swift`는 계속 있어야 한다
  ([research.md R2](./research.md#위험과-확인-절차)).
- Xcode에서 각 카탈로그의 항목을 선택해 Attributes inspector에 “Generate Swift Symbol”이 켜져 있고
  예시 사용법의 심볼 이름이 키와 같은지 확인한다.

## 2. 빌드·테스트 (SC-004, FR-014)

```sh
project_build_runner=$(./.tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" build
"$project_build_runner" compile
"$project_build_runner" test
```

- 세 명령이 모두 성공한다.
- 기존 한국어 기대값 테스트(`Feature/Tests`, `UI/Tests/Component`)가 수정 없이 통과한다.
- 모듈별 `LocalizedTextTests`가 영어 시뮬레이터에서 한국어 값을 반환한다(R3).

## 3. 한국어 리터럴 잔여 검사 (SC-001)

```sh
grep -rn '"[^"]*[가-힣]' --include='*.swift' \
  sources/Projects/UI/Component sources/Projects/Feature sources/Projects/App/GitIt \
  | grep -v '/Tests/' | grep -v '/Previews/' | grep -v '/Derived/'
```

남은 결과는 모두 다음 중 하나여야 한다. 그 외 결과가 하나라도 있으면 실패다.

- `Logger` 호출, `fatalError`·`precondition` 메시지
- `#Preview` 이름과 프리뷰 전용 선언(파일 안 `#Preview` 블록, `*PreviewItem` 등)

## 4. 카탈로그 품질 (SC-003, FR-003·FR-013)

```sh
find sources/Projects -name '*.xcstrings' -not -path '*/Derived/*'
```

각 파일에 대해 다음을 확인한다. 기준은 [contracts/string-catalog-entry.md](./contracts/string-catalog-entry.md)다.

- `sourceLanguage`가 `ko`이고 `ko` 외 언어가 없다.
- 모든 항목에 `comment`가 있고 `extractionState`가 `manual`이다.
- 키가 lowerCamelCase 식별자이며 한국어가 아니다.
- 보간 항목의 주석이 모든 인자의 의미를 설명한다.

## 5. 한국어 환경 화면 확인 (SC-002, 시나리오 1·2)

시뮬레이터 언어를 한국어로 두고 앱을 실행해 변경 전 빌드(`develop`)와 나란히 비교한다.

| 대상 | 확인 |
| --- | --- |
| 온보딩(약관·분야·수준·튜토리얼) | 제목·선택지·버튼 문구 동일 |
| 홈 | 프로젝트 카드, 빈 상태, 학습 시작 접근성 레이블 동일 |
| 프로젝트 등록 | 링크 입력 안내·오류, 확인, 난이도, 생성 진행 문구 동일 |
| 퀴즈 | 문제 풀이, 정답·오답, 학습 완료 문구 동일 |
| 저장 | 필터 개수(0·1·여러 개), 빈 상태·실패 문구 동일 |
| 설정 | 섹션 제목, 켜짐·꺼짐, 프로필 문구 동일 |
| 로컬 알림 | 세트 생성 완료·실패 알림 제목·본문 동일 |
| VoiceOver | 탭·닫기·뒤로 가기·진행률 레이블이 한국어로 읽힘 |

줄바꿈이 있는 문구는 같은 위치에서 줄이 바뀌어야 한다.

## 6. 비한국어 환경 대체 (SC-006, FR-008)

시뮬레이터 언어를 English로 바꾸고 §5의 대표 화면 6종을 다시 연다.

- 모든 문구가 한국어로 표시된다.
- 현지화 키(`profileTitle` 같은 lowerCamelCase 문자열)나 빈 문자열이 한 곳도 보이지 않는다.

## 7. 현지화 컨벤션 문서 (FR-010)

```sh
ls docs/conventions/localization.md docs/conventions/localization/
grep -n 'localization' docs/conventions/README.md docs/conventions/file-vocabulary/shape-vocabulary.md \
  docs/package-rules/ui.md docs/package-rules/feature.md docs/package-rules/app.md
```

- [contracts/localization-convention.md §A](./contracts/localization-convention.md#a-문서-목록)의 문서가 모두 있다.
- 인덱스가 목적 → 적용 범위 → `##`·`###` 규칙 → 검토 체크리스트 → 관련 문서 → 문서 변경 기준 순서이고,
  모든 `###`이 참고 단위 문서 링크 하나만 가진다.
- §D의 기존 문서가 규칙을 옮겨 적지 않고 한 줄 요약과 현지화 컨벤션 링크만 가진다.
- 구현된 `LocalizedText`, 카탈로그 경로, 키가 컨벤션 본문과 일치한다.

## 8. 카탈로그만 고쳐 문구 변경 (시나리오 1 수용 2, 로컬 확인 후 되돌림)

1. `Settings.xcstrings`에서 `settingsTitle` 한국어 값을 임시로 바꾼다.
2. Swift 파일을 수정하지 않고 빌드·실행해 설정 화면 제목이 바뀌었는지 확인한다.
3. 값을 원래대로 되돌리고 `git status`에 변경이 남지 않았는지 확인한다.
