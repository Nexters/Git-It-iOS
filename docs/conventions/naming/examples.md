# 허용·비허용 이름 예

[Git It iOS 네이밍 컨벤션](../naming.md)의 규칙 문서입니다.

아래 이름은 판단 기준을 보여 주는 예시이며 프로젝트 전체에 그대로 사용해야 하는 식별자 목록이 아닙니다.

| 상황 | 허용 예 | 비허용 예 | 이유 |
| --- | --- | --- | --- |
| 서로 다른 종류의 세션이 공존 | `LoginSessionRepository` | `SessionRepository` | `Login`이 실제 책임을 구분하는 최소 문맥입니다. |
| 로컬 인증 정보의 저장·조회·삭제 | 책임을 그대로 표현하는 `AuthenticationStorage` | 실제로 다루지 않는 상태를 붙인 `AuthenticationAuthorizationStorage` | 저장 값의 내부 용어를 계약 책임으로 오인시키지 않습니다. |
| 실제 authorization 상태 조회 | `authorizationStatus()` | `status()` | 상태 종류를 구분해야 하는 공개 계약에서는 목적어가 필요합니다. |
| 타입이 대상을 이미 제공하는 지역 인자 | `SessionStorage.save(_ session:)` | `SessionStorage.save(_ storedLoginSession:)` | 타입과 연산이 제공하는 문맥을 지역 이름에 반복하지 않습니다. |
| 저장 후 독립적으로 해석되는 식별자 | 발급 주체가 실제로 구분되는 `issuerIdentifier` | 여러 발급 주체가 공존하는 모델의 `id` | 저장 문맥이 사라져도 값의 목적을 식별할 수 있어야 합니다. |
| Data의 wire 응답 모델 | `ProfileResponseDTO` | Domain의 `ProfileDTO` | `DTO`는 실제 전송 경계에서만 역할을 설명합니다. |
| 공급자 중립 Domain 상태 | 프로젝트 소유 `AuthorizationStatus` | 플랫폼 고유 credential 상태 타입 | 외부 공급자 타입을 Domain 계약에 노출하지 않습니다. |
| Data가 요구하는 보안 저장 능력 | 책임 중심의 `CredentialStorage` | 구현 기술 중심의 `KeychainCredentialStorage` 프로토콜 | 구현 기술은 중립 계약이 아니라 Infrastructure 구현 경계에서 선택합니다. |
| 플랫폼 API를 직접 감싸는 Infrastructure 타입 | 플랫폼 고유 명칭을 보존한 Adapter 이름 | 고유 명칭을 임의의 프로젝트 용어로 치환 | 외부 계약과의 대응을 숨기지 않습니다. |
| 한 기능의 공개 타입 묶음 | 각 책임을 완전한 용어로 표현 | 모든 타입에 `Auth...` 같은 축약 접두어 적용 | 소속 표시만을 위한 일괄 축약은 책임을 설명하지 않습니다. |
