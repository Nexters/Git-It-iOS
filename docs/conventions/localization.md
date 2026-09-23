# Git It iOS 현지화 컨벤션

**상태**: 초안

**작성일**: 2026-09-24

**최종 수정일**: 2026-09-24 (최초 작성)

## 목적

이 문서는 사용자에게 보이는 고정 문구를 소스 리터럴이 아니라 모듈이 소유하는 String Catalog에서
조회하도록 하고, 카탈로그 배치·키·주석·조회 진입점·제외 대상과 검증 방식을 통일합니다.

패키지 책임은 `docs/package-rules/`의 패키지 규칙이, `Resources/`·`Localization/` 폴더 목록은
[형태 어휘 표](./file-vocabulary/shape-vocabulary.md)가, View `Constant`는
[View 내부 선언 컨벤션](./view-declarations.md)이 소유합니다. 문서 우선순위, 문서 구조와 문서 간
참조 규칙은 [컨벤션 공통 원칙](./common/README.md)이 소유합니다.

## 1. 적용 범위

- `sources/Projects/UI/Component/**`, `sources/Projects/Feature/**`, `sources/Projects/App/GitIt/**`의
  production 소스와 `Resources/*.xcstrings`
- 위 target의 표시 문구를 검증하는 테스트

Domain·Data·Infrastructure·Composition은 사용자 노출 문구를 소유하지 않으므로 대상이 아닙니다.
사용자에게 보여야 하는 값이 이 패키지에서 나오면 표시 책임을 가진 Feature·App이 현지화합니다.

포맷 도구 설정과 Tuist helper 구현 자체는 대상이 아닙니다. 이 문서는 그 helper가 지켜야 할 설정
값만 정합니다.

## 2. 현지화 대상

사용자에게 보이거나 보조 기술이 읽어 주는 고정 문구는 모두 현지화 대상입니다. 시스템 밖에서 온
값과 개발자만 보는 문자열은 대상이 아닙니다.

### 2.1 현지화 대상

→ [현지화 대상](./localization/target-text.md)

### 2.2 제외 대상

→ [제외 대상](./localization/exclusion.md)

## 3. 문구 리소스

문구의 정본은 코드가 아니라 모듈이 소유한 카탈로그의 수동 항목입니다. 키는 의미를, 값은 표시를,
주석은 번역 맥락을 소유합니다.

### 3.1 String Catalog

→ [String Catalog](./localization/string-catalog.md)

### 3.2 키

→ [키](./localization/key.md)

### 3.3 값과 주석

→ [값과 주석](./localization/entry-value.md)

## 4. 조회 진입점

모듈마다 문구 전용 타입 하나가 카탈로그 항목을 `String`으로 제공하며, 호출부는 그 타입만
거칩니다.

### 4.1 `LocalizedText`

→ [`LocalizedText`](./localization/localized-text.md)

### 4.2 호출부

→ [호출부](./localization/call-site.md)

## 5. 개발 언어와 빌드 설정

개발 언어는 한국어이며, 어떤 기기 언어에서도 키나 빈 문자열이 보이지 않아야 합니다.

### 5.1 개발 언어와 빌드 설정

→ [개발 언어와 빌드 설정](./localization/development-language.md)

## 6. 언어 추가

언어 추가는 카탈로그와 지원 언어 목록 변경만으로 끝나야 하며, 조회 진입점과 호출부를 바꾸지
않습니다.

### 6.1 언어 추가 절차

→ [언어 추가](./localization/adding-language.md)

## 7. 검증

누락·미사용 항목을 자동으로 검출하는 도구가 없으므로 테스트와 리뷰 검사로 규칙을 지킵니다.

### 7.1 검증

→ [검증](./localization/verification.md)

## 8. 검토 체크리스트

- [ ] 새로 추가한 사용자 노출 문구가 모두 소유 모듈의 카탈로그 항목인가?
- [ ] 제외 대상(서버 값, 사용자 입력, 로그, 진단, 프리뷰, 테스트 픽스처)을 카탈로그에 넣지 않았는가?
- [ ] 키가 lowerCamelCase 식별자이며 테이블 문맥을 반복하지 않는가?
- [ ] 같은 한국어 값이라도 용도가 다르면 다른 키인가?
- [ ] 모든 항목에 주석이 있고, 보간 항목의 주석이 인자마다 의미를 설명하는가?
- [ ] 호출부가 `LocalizedText`만 거치며 한국어 리터럴·생성 심볼·`String(localized:)`를 직접 쓰지 않는가?
- [ ] View `Constant`와 표시 모델에 현지화 문구가 없는가?
- [ ] 컴포넌트 공개 입력이 `String`으로 유지되는가?
- [ ] 한국어 표시 문구 테스트가 키가 아니라 한국어 최종 문구를 기대하는가?
- [ ] 한국어 리터럴 잔여 검사(§7.1) 결과가 제외 대상뿐인가?

## 관련 문서

- [아키텍처](../architecture.md)
- [UI 패키지 규칙](../package-rules/ui.md)
- [Feature 패키지 규칙](../package-rules/feature.md)
- [App 패키지 규칙](../package-rules/app.md)
- [디렉터리·파일 컨벤션](./directory-file.md)
- [파일·형태 어휘 컨벤션](./file-vocabulary.md)
- [View 내부 선언 컨벤션](./view-declarations.md)
- [UIComponent 컨벤션](./ui-component.md)
- [네이밍 컨벤션](./naming.md)
- [테스트 컨벤션](./test.md)

## 문서 변경 기준

현지화 대상·제외 기준, 카탈로그 배치·형식, 키·주석 규칙, 조회 진입점 형태, 개발 언어·지원 언어,
빌드 설정 또는 검증 방식이 바뀌면 수정합니다. `Localization/`·`Resources/` 폴더 자리가 바뀌면 이
문서보다 [형태 어휘 표](./file-vocabulary/shape-vocabulary.md)를 먼저 갱신합니다. `Constant`의 일반
규칙이 바뀌면 [View 내부 선언 컨벤션](./view-declarations.md)을 갱신합니다.
