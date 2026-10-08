# 계약: 패키지 의존성 규칙 (개정 후)

**관련 요구사항**: FR-009, FR-013, FR-016, FR-019, FR-025, FR-029, FR-059, FR-061

## 개정 후 허용 의존성

| 패키지 | 허용 내부 의존성 |
|---|---|
| App | Feature, Composition, 주입에 필요한 Domain |
| Feature | Domain, UI |
| Composition | Domain, Data, Infrastructure |
| Data | Infrastructure |
| Domain | — |
| Infrastructure | — |
| UI | — |

## 개정 내용

**추가**: `Data → Infrastructure`

**제거**: 금지 목록의 `Data → Infrastructure` 항목

**책임 이동**: Data 계약과 Infrastructure API 사이의 변환은 Composition의
`Data↔Infrastructure Adapter`가 아니라 **Data의 concrete 구현**이 소유한다.

## 개정이 필요한 문서 *(정확한 파일 경로)*

| 파일 | 개정 대상 |
|---|---|
| `docs/architecture.md` | 3.1 의존성 표, 3.3 Adapter 경계, 4장 제어 흐름, 7.1 금지 목록 |
| `docs/package-rules/data.md` | "프로젝트 내부의 다른 패키지에 의존해서는 안 됩니다", "Infrastructure 타입 또는 외부 라이브러리의 구체 API를 직접 참조해서는 안 됩니다", "Data↔Infrastructure Adapter를 Data 내부에 구현해서는 안 됩니다" |
| `docs/package-rules/composition.md` | Data 기술 계약 충족 정책, Data↔Infrastructure Adapter 소유 서술 |

## 유지되는 금지 의존성

```text
Domain → Data, Infrastructure, Feature, UI
Data → Domain, Feature, UI
Infrastructure → Domain, Data, Feature
Feature → Data, Infrastructure, Composition, App
Composition → Feature, App, UI
UI → Domain, Data, Feature
```

## 검증

- `tuist generate`가 성공하고 의존성 순환이 0건이다.
- 각 target의 Tuist 선언이 위 표를 벗어나지 않는다.
- 문서 세 파일과 실제 선언 사이에 모순이 없다.
