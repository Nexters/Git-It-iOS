# 계약: `MemberRemote`

**Target**: `DataMember`(신규) | **참조 문서 영역**: MEMBER-01 ~ MEMBER-06

## 연산

| 연산 | 참조 Operation ID | Request | Response |
|---|---|---|---|
| `fetchProfile()` | MEMBER-01 | 없음 | `MemberProfileResponseDTO` |
| `registerDeviceInfo(...)` | MEMBER-02 | `DeviceInfoRequestDTO` | Unit |
| `curateMember(...)` | MEMBER-03 | `CurationRequestDTO` | Unit |
| `updatePosition(...)` | MEMBER-04 | `PositionRequestDTO` | Unit |
| `updateCareerLevel(...)` | MEMBER-05 | `CareerLevelRequestDTO` | Unit |
| `withdrawMember()` | MEMBER-06 | 없음 | Unit |

모든 연산은 Bearer 인증을 사용한다.

## 계약 불변식

- FR-009: `MemberProfileResponseDTO.weeklyChart` 순서를 Data가 재정렬하지 않는다.
- `DeviceInfoRequestDTO.deviceType`은 iOS에서 `"ios"`로 고정한다.
- MEMBER-06(회원 탈퇴)은 hard delete 의미를 보존하며 Unit 응답이다.

## 오류 매핑

`DataMemberError`: 공통(`invalidRequest`, `unauthorized`, `temporarilyUnavailable`,
`transport`, `decoding`, `unexpectedStatus`) + 도메인 전용(`memberUnavailable`).
