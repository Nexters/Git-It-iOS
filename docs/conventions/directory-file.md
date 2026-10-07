# Git It iOS 디렉터리·파일 컨벤션

**상태**: 초안

**작성일**: 2026-08-27

**최종 수정일**: 2026-09-03 (Feature 패키지 흐름 배치 규칙 추가와 체크리스트 정리)

## 목적

이 문서는 `sources/Projects/` 아래 모든 패키지가 **공통으로** 지키는 폴더 구조와 파일
분할 기준을 정의합니다.

공개 이름의 어휘 선택은 [네이밍 컨벤션](./naming.md), 테스트 target·scheme 연결은
[테스트 컨벤션](./test.md), View 내부 선언을 중첩할지 여부는
[View 컨벤션](./view.md)이 소유합니다. 파일당 타입 개수, 파일 이름 규칙과 형태 폴더
어휘의 정본은 [파일·형태 어휘 컨벤션](./file-vocabulary.md)이 소유합니다. 이 문서는
**그 선언이 어느 폴더에 놓이는지**만 정합니다. 문서 우선순위, 문서 구조와 문서 간 참조 규칙은
[컨벤션 공통 원칙](common/README.md)이 소유합니다.

## 1. 적용 범위

적용합니다.

- `sources/Projects/<패키지>/` 아래 production·test Swift 소스 파일과 그 폴더
- 각 target이 소유하는 `Resources/` 자산 폴더의 최상위 구성
- `sources/Tuist/ProjectDescriptionHelpers/Projects/*ModuleName.swift`가 계산하는
  `sourceDirectory` 경로

적용하지 않습니다.

- Tuist·Xcode 생성물: `Derived/`, `build/`, `*.xcodeproj`, `*.xcworkspace`
- 패키지 루트의 `Project.swift`와 `Config/`
- `*.xcassets` 내부 구조와 서드파티가 배포한 폰트·리소스 폴더 구조 — 도구와 배포본이
  소유합니다(§6)
- `docs/`, `tools/`, `.agents/`, `specs/`

## 2. 경로 구조

모든 소스 파일 경로는 패키지, 소스 루트, 형태, 타입 패밀리, 파일의 자리로 구성합니다.

→ [경로 구조](./directory-file/path-structure.md)

## 3. 소스 루트

소스 루트는 Tuist target의 `sourceDirectory`가 가리키는 폴더이며 **하나의 관심사
경계**를 담습니다. 폴더 이름은 [네이밍 컨벤션 — 패키지 문맥과 Target 이름](./naming.md#4-패키지-문맥)에 따라
target 이름에서 패키지 접두어를 제거한 역할 이름을 사용합니다.

### 3.1 production 소스 루트

→ [production 소스 루트](./directory-file/production-source-root.md)

### 3.2 관심사 세그먼트

→ [관심사 세그먼트](./directory-file/concern-segment.md)

### 3.3 test 소스 루트

→ [test 소스 루트](./directory-file/test-source-root.md)

### 3.4 진입점 파일

→ [진입점 파일](./directory-file/entry-point-file.md)

## 4. 1뎁스 — 형태 폴더와 Feature 흐름 단위

소스 루트 바로 아래 1뎁스는 그 선언이 코드에서 맡는 종류를 나타냅니다. Feature 패키지만 예외로, target 하나가 모든 흐름을 담으므로 1뎁스를
형태가 아니라 흐름을 이루는 단위로 씁니다.

### 4.1 판단 기준

→ [판단 기준](./directory-file/shape-criteria.md)

### 4.2 규칙

→ [규칙](./directory-file/shape-rules.md)

### 4.3 Feature 패키지의 흐름 배치

Feature 패키지는 흐름을 §3.2의 관심사 세그먼트로 두고, 그 아래 1뎁스는 형태가 아니라 흐름을 이루는 *단위*입니다.

→ [Feature 패키지의 흐름 배치](./directory-file/feature-layout.md)

## 5. 2뎁스 — 타입 패밀리 폴더

2뎁스는 한 메인 타입에 딸린 파일들을 모으는 자리입니다. 폴더는 묶을 파일이 둘 이상일 때만 만들고, 형태 폴더의 대체물로 쓰지 않습니다.

### 5.1 규칙

→ [규칙](./directory-file/type-family-rules.md)

### 5.2 책임 이름 폴더

→ [책임 이름 폴더](./directory-file/responsibility-folder.md)

## 6. 자산과 생성물

자산은 소스 루트 아래 `Resources/`가 소유하고 Swift 소스와 같은 형태 폴더에 섞지 않습니다.

→ [자산과 생성물](./directory-file/resources.md)

## 7. Tuist 매니페스트와의 일치

실제 폴더 경로와 매니페스트의 `sourceDirectory` 계산 결과는 항상 같아야 합니다.

→ [Tuist 매니페스트와의 일치](./directory-file/tuist-manifest.md)

## 8. 검토 체크리스트

### 경로

- [ ] 소스 루트 아래 폴더 뎁스가 2 이하인가?
- [ ] 1뎁스 폴더가 형태이고 2뎁스 폴더가 관심사인가? 두 축이 뒤바뀌지 않았는가?
      (Feature 패키지는 이 축 대신 §4.3의 흐름 단위를 씁니다 — 아래 항목을 봅니다.)
- [ ] 형태 폴더 이름이 [파일·형태 어휘 컨벤션 — 패키지별 형태 어휘](./file-vocabulary/shape-vocabulary.md)의
      표에 있는가? 표에 없으면 같은 PR에서 표를 갱신했는가?
- [ ] 형태 폴더 자리에 `Common`, `Shared`, `Utils`, `Etc` 같은 잔여 이름을 쓰지
      않았는가? (§4.1의 두 예외 자리는 제외)
- [ ] 관심사 세그먼트를 추가했다면 target 분리를 먼저 검토했는가?
- [ ] 타입 패밀리 폴더가 파일 둘 이상일 때만 존재하는가?
- [ ] 타입 패밀리 폴더 이름이 메인 타입 이름과 같은가?

### Feature 패키지 (§4.3)

- [ ] 1뎁스가 `Router/`, 화면 폴더, `Previews/`, `Shared/`, `Resources/` 중 하나인가?
- [ ] 화면 폴더에 Screen 하나와 그 화면이 조합하는 Feature가 함께 있는가?
- [ ] 화면 폴더 이름이 `Screen`·`Feature` 접미어를 뗀 이름인가?
- [ ] 흐름에 화면이 둘 이상인데 `Router/`가 없지는 않은가?
- [ ] 화면 폴더와 `Router/`의 루트에 View·Feature와 그들이 직접 소유하는 값 타입만 있는가?
- [ ] 서브뷰가 `SubViews/`, 표시 모델이 `ViewModels/`, 프리뷰가 `Previews/`에 있는가?
- [ ] 흐름 1뎁스 `Previews/`에 한 화면만 쓰는 프리뷰를 두지 않았는가?
- [ ] `Shared/`에 한 화면만 쓰는 선언을 두지 않았는가?
- [ ] test 소스 루트가 `Tests/<흐름>/<화면>/`으로 같은 축을 미러링하는가? 역할 폴더도 함께 미러링했는가?

### 매니페스트

- [ ] 실제 폴더와 `sourceDirectory` 계산 결과가 일치하는가?
- [ ] 폴더 이동을 매니페스트 갱신과 같은 커밋에 담았는가?
- [ ] source glob이 소스 루트 아래 `/**` 하나로 유지되는가?

## 관련 문서

- [아키텍처](../architecture.md)
- [네이밍 컨벤션](./naming.md)
- [파일·형태 어휘 컨벤션](./file-vocabulary.md)
- [테스트 컨벤션](./test.md)
- [View 컨벤션](./view.md)
- [UIComponent 컨벤션](./ui-component.md)

## 문서 변경 기준

소스 루트 계산 방식, 폴더 뎁스 규칙 또는 관심사 세그먼트 기준이 바뀔 때 수정합니다.
파일 분할 기준이나 패키지별 형태 어휘가 바뀌면 이 문서가 아니라
[파일·형태 어휘 컨벤션](./file-vocabulary.md)을 갱신합니다. target 이름과 폴더
이름의 관계가 바뀌면 이 문서보다 [네이밍 컨벤션](./naming.md)을 먼저 갱신합니다.
컴포넌트 역할 폴더의 목록과 판정 기준은 이 문서가 아니라
[UIComponent 컨벤션](./ui-component.md)이 소유합니다.
