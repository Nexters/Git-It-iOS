# 계약: `AuthenticationRemote`

**Target**: `DataAuthentication` | **참조 문서 영역**: AUTH-01, AUTH-02

## 연산

| 연산 | 참조 Operation ID | 인증 | Request | Response |
|---|---|---|---|---|
| `appleLogin(idToken:)` | AUTH-01 | 없음 | `AppleLoginRequestDTO` | `LoginResponseDTO` |
| `verifyAccessToken()` | AUTH-02 | Bearer 필수 | 없음 | Unit |

## 금지 사항

다음은 이 계약에 포함하지 않는다(spec.md FR-002, FR-012, research.md 결정 1).

- `googleLogin(...)`
- `refreshSession(...)` / `revokeRefreshToken(...)` 등 refresh/revoke/logout 계열 연산

## 오류 매핑

`DataAuthenticationError`: `invalidRequest`, `unauthorized`, `temporarilyUnavailable`,
`transport`, `decoding`, `unexpectedStatus`.

## 보안 요구사항

`AppleLoginRequestDTO.idToken`, `LoginResponseDTO.accessToken`,
`LoginResponseDTO.refreshToken`은 `description`/`debugDescription`에서 `<redacted>`로
치환한다(FR-014, research.md 결정 6).

## AUTH-02 응답 해석 제약

200 응답에서 `needsCuration == false`나 온보딩 완료 여부를 추론하지 않는다 — 이 연산은
access token 유효성만 확인한다(spec.md 시나리오 2).
