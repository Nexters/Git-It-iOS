# Data 패키지 리뷰 가이드: Apple 소셜 로그인

## 목적

이 문서는 `001-apple-social-login`의 Data 작업 패키지 T048~T076을 리뷰할 때 확인할
경계, 동작과 검증 근거를 정리한다. 구현의 기준은 다음 문서다.

- [기능 명세](../spec.md)
- [구현 계획](../plan.md)
- [데이터 및 상태 모델](../data-model.md)
- [인증 경계 계약](../contracts/authentication-boundary.md)
- [작업 목록](../tasks.md)
- [Data 패키지 규칙](../../../sources/docs/package-rules/data.md)

## 리뷰 범위

이번 리뷰의 변경 범위는 다음 두 target과 `tasks.md`의 T048~T076 완료 표시다.

```text
sources/Projects/Data/DataAuthentication/
sources/Projects/Data/DataAuthenticationTests/
specs/001-apple-social-login/tasks.md
```

`Domain`, `Core`, `Composition`, `UI`, `Feature`, `App` 구현은 이번 리뷰 범위가 아니다.
Data는 외부 기술을 직접 실행하지 않고, 이후 Composition Adapter가 구현할 계약과
공급자 중립 데이터만 정의해야 한다.

## 권장 리뷰 순서

1. 계약이 외부 인증과 Git It 서버 세션 책임을 분리하는지 확인한다.
2. DTO와 저장 모델에 공급자별 필드 또는 다른 패키지 타입이 유입되지 않았는지 확인한다.
3. 인증 참조와 서버 세션 저장 경계가 분리되어 있는지 확인한다.
4. 오류가 공급자 중립 의미로 분류되는지 확인한다.
5. payload와 token이 문자열 표현에 노출되지 않는지 확인한다.
6. 테스트가 위 공개 계약과 보안 경계를 실제로 고정하는지 확인한다.

## 핵심 계약 검토

### 외부 인증

- [ ] `ExternalAuthenticationProvider`가 `methodIdentifier` 기반 인증, authorization 상태
  조회와 변경 stream만 제공한다.
- [ ] 공개 API에 `AuthenticationServices`, `ASAuthorization`, Apple credential state 또는
  Domain/Core 타입이 없다.
- [ ] `ExternalAuthorizationState`는 `active`, `inactive`, `temporarilyUnavailable`만
  제공한다.
- [ ] `ExternalAuthenticationEvidence`는 `methodIdentifier`, 불투명 subject reference와
  `opaquePayload`만 보유한다.

### 서버 세션

- [ ] `SessionRemote`가 세션 시작, refresh, refresh token 폐기만 담당한다.
- [ ] `SessionStartRequestDTO`에는 공급자 중립 method identifier와 단발성 payload만 있다.
- [ ] `SessionResponseDTO`에는 Git It 사용자와 access/refresh token, access 만료 시각만 있다.
- [ ] refresh DTO에 Apple 또는 다른 공급자별 필드가 없다.
- [ ] 실제 HTTP endpoint, method, header와 JSON schema를 추측해 고정하지 않는다.

### 저장 경계

- [ ] `SessionStorage`는 `StoredSession`의 원자적 저장·읽기·삭제만 정의한다.
- [ ] `AuthenticationAuthorizationStorage`는 `StoredAuthorizationReference`의
  저장·읽기·삭제만 정의한다.
- [ ] `StoredSession`에 `appleUserID`, method identifier 또는 provider subject reference가
  없다.
- [ ] `StoredAuthorizationReference`에 access/refresh token 또는 Git It 사용자 정보가 없다.
- [ ] Keychain과 namespace의 실제 구현은 Data가 아니라 이후 Composition/Core 경계에 남아 있다.

## 데이터 안전성 검토

- [ ] `ExternalAuthenticationEvidence.OpaquePayload`가 `Equatable`을 채택하지 않는다.
- [ ] payload, access token과 refresh token의 `description` 및 `debugDescription`이 실제 값을
  출력하지 않는다.
- [ ] `DataAuthenticationError`가 민감 값이나 외부 오류 객체를 associated value로 보유하지 않는다.
- [ ] 오류 의미가 취소, 일시 실패, 저장 실패, 세션 시작 거부, refresh 거부·만료,
  폐기 실패로 구분된다.
- [ ] production 코드에 로그 출력이나 분석 이벤트 전송이 추가되지 않았다.

## 의존성과 아키텍처 검토

- [ ] `DataAuthentication` target에 다른 프로젝트 내부 target 의존성이 없다.
- [ ] production 코드가 Domain Repository를 구현하거나 Domain 모델로 변환하지 않는다.
- [ ] Core 타입, Apple API, URLSession, Keychain의 구체 API를 직접 참조하지 않는다.
- [ ] 모든 공개 계약과 값이 `Sendable`이거나 동시성 경계를 안전하게 표현한다.
- [ ] Feature 상태, 화면, Navigation 또는 Domain 비즈니스 규칙이 포함되지 않는다.

## 테스트 검토

| 영역 | 주요 테스트 | 확인 사항 |
| --- | --- | --- |
| 외부 인증 계약 | `ExternalAuthenticationProviderContractTests` | 인증·상태 조회·변경 stream |
| 세션 계약 | `SessionRemoteContractTests` | 시작·refresh·폐기 책임 |
| 저장 계약 | `SessionStorageContractTests`, `AuthenticationAuthorizationStorageContractTests` | 분리된 원자적 CRUD 경계 |
| DTO와 모델 | `DTOs/`, `Models/`의 테스트 | 필드 구성과 공급자 중립성 |
| 오류 | `DataAuthenticationErrorTests` | 실패 의미의 완전한 구분 |
| 보안 | `SensitiveValueExposureTests` | payload·token 문자열 비노출 |

리뷰 시 테스트가 구현 세부사항보다 공개 필드, 호출 계약과 보안 불변 조건을 검증하는지
확인한다. 테스트를 통과시키기 위해 계약 범위를 불필요하게 확장하거나 민감 값을 비교 가능한
모델로 바꾸는 수정은 허용하지 않는다.

## 검증 명령과 현재 증거

```sh
derived_data_root=$(./tools/repository-paths/bin/repository-paths.sh --absolute GIT_IT_DERIVED_DATA_PATH)
xcodebuild \
  -workspace sources/GitIt.xcworkspace \
  -scheme DataAuthentication \
  -derivedDataPath "$derived_data_root/TestSchemes/DataAuthentication" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

2026-08-12 구현 시점의 결과는 Swift Testing 13개 테스트 통과다. Xcode target dependency
graph에는 `DataAuthenticationTests → DataAuthentication`만 있으며 `DataAuthentication`의
프로젝트 내부 의존성은 없다. 리뷰 후 코드가 바뀌면 위 명령을 다시 실행하고 최신 결과를
기준으로 판단한다.

## 승인 판단

다음 조건을 모두 만족하면 Data 패키지를 승인할 수 있다.

- [ ] T048~T076의 파일과 완료 표시가 실제 변경 내용과 일치한다.
- [ ] 계약·DTO·저장 모델이 공급자 중립이며 패키지 경계를 위반하지 않는다.
- [ ] 민감 값 비노출 테스트를 포함한 Data 테스트가 모두 통과한다.
- [ ] placeholder가 제거되고 실제 production/test 파일이 target에 포함된다.
- [ ] 미해결 리뷰 의견과 검증 실패가 없다.

Data 승인은 다음 `Core` 작업 패키지의 구현을 자동 승인하지 않는다. `Core`는 별도의 사용자
승인 후 T077부터 시작한다.
