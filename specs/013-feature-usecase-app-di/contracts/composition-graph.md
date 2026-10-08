# 계약: Composition 실행 그래프

**소유 패키지**: Composition | **관련 요구사항**: FR-021 ~ FR-031

## 공개 API 규칙

1. 외부에 노출하는 모든 property·반환 타입은 Domain UseCase Protocol 타입이다.
2. Adapter 타입, Data 구현 타입, Infrastructure 타입은 공개 API에 나타나지 않는다.
3. 조립 진입점은 기능 단위로 분리하며, 모든 UseCase를 담는 단일 컨테이너를 만들지 않는다.
4. 실행 환경 설정(baseURL, 타임아웃, Keychain 네임스페이스)은 진입점의 입력값으로 받는다.
5. Feature, Store, SwiftUI View, navigation 상태를 생성하지 않는다.

## 조립 대상과 충족 계약

| 조립 대상 | 충족하는 Domain 계약 | 노출하는 UseCase Protocol |
|---|---|---|
| LearningProject | `LearningProjectRepository` | `FetchLearningProjectsUseCase`, `FetchLearningProjectDetailUseCase`, `CreateLearningProjectUseCase`, `DeleteLearningProjectUseCase` |
| ExternalRepository | `ExternalRepositoryLookup` | `FetchExternalRepositoryUseCase` |
| Authentication | `AuthenticationRepository`, `LoginSessionRepository` | `SignInUseCase`, `SignOutUseCase`, `RestoreSessionUseCase`, `ObserveAuthenticationOutcomesUseCase` |

`DataMember`와 대응 Domain 계약이 없는 기능은 조립 대상이 아니다(FR-030).

## 객체 수명 규칙

- `HTTPClient`는 조립 진입점당 1회 생성하고 모든 Data 구현이 공유한다.
- Keychain 저장소와 세션 Repository는 앱 단위로 1개만 존재한다.
- 같은 Repository를 여러 UseCase가 사용할 때 Repository 인스턴스를 재사용한다.

## Adapter 변환 책임

- Domain↔Data Adapter는 Data DTO를 Domain 모델로, Data 오류를 Domain 오류로 변환한다.
- Adapter는 비즈니스 규칙을 구현하지 않는다. 정책은 Domain UseCase가 소유한다.
- 캐시·저장·동기화 정책을 Adapter에 구현하지 않는다.

## 검증

- live 그래프 생성이 세 기능 모두에 대해 성공한다.
- 공개 선언 목록에 Domain Protocol 이외의 타입이 없다.
- Adapter의 DTO→Domain 모델, Data 오류→Domain 오류 변환을 테스트로 검증한다.
- 공유 대상 객체가 1회만 생성되는지 검증한다.
