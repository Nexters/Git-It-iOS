# 계약: 패키지 의존성 규칙과 자동 검사

**요구사항**: FR-018·FR-019·FR-024, SC-007·SC-008 | **결정**: [research.md](../research.md) R11

## 1. 허용 의존성

`tools/package-dependencies/config/allowed-dependencies`와 `docs/architecture.md` 3.1 표는 같은 내용을 가져야
한다(검사기 `table-mismatch`).

| 패키지 | 변경 전 | 변경 후 |
|--------|---------|---------|
| App | Feature Composition Domain | 변경 없음 |
| Composition | Domain Data Infrastructure | **Domain Data** |
| Feature | Domain UI | 변경 없음 |
| Domain | — | 변경 없음 |
| Data | Infrastructure | 변경 없음 |
| Infrastructure | — | 변경 없음 |
| UI | — | 변경 없음 |

## 2. 판정 기대값

| 입력 | 기대 결과 |
|------|-----------|
| 현재 저장소(변경 완료 후) | `tools/package-dependencies/bin/run.sh` 종료 코드 0 |
| Composition Swift 파일에 `import InfrastructureStorage` 추가 | `import-package` 위반, 종료 코드 0이 아님 |
| `CompositionModuleName.swift`에 `.fromInfrastructure(...)` 추가 | `manifest-package` 위반 |
| 설정만 바꾸고 아키텍처 3.1 표를 그대로 둠 | `table-mismatch` 위반 |
| Data target의 `import InfrastructureNetworkClient` | 통과 |
| Infrastructure 테스트 target의 Infrastructure import | 통과(같은 패키지) |

회귀 사례는 `tools/package-dependencies/tests/test-package-dependencies.sh` fixture에 둔다.

## 3. 함께 바꾸는 문서

| 파일 | 위치 | 변경 |
|------|------|------|
| `docs/architecture.md` | L11, L22, L35 | Composition이 Infrastructure 객체를 조립한다는 설명을 Data 생성 진입점 사용으로 교정 |
| `docs/architecture.md` | L66 3.1 표 | `Composition | Domain, Data` |
| `docs/architecture.md` | 3.3 L149-172 | "생성 인자는 Composition 조립에서 주입" 예시를 Data 역할 Protocol 주입으로 교정 |
| `docs/architecture.md` | 6장 L265 | Composition의 외부 기술 사용 설명 교정 |
| `docs/architecture.md` | 7.1 L278-299 | `Composition → Infrastructure`, `App → Infrastructure` 금지 추가 |
| `docs/architecture.md` | 9장 D-ARCH-004 L364-369 | DS-06 후속 작업 설명을 이 기능 결과로 갱신하고 결정 기록 추가 여부 판단 |
| `docs/assets/package-dependency-graph.dot` 및 생성 SVG | L46 | `Composition -> Infrastructure` 간선 제거 |
| `docs/package-rules/composition.md` | L9, L19, L21, L31, L57, L63, L66-69, L79-80 | Infrastructure 조립·진입점 호출 설명 교정 |
| `docs/package-rules/data.md` | L11, L19, L21 | Data 기술 능력 계약 소유와 생성 진입점 규칙 추가 |
| `docs/package-rules/infrastructure.md` | L11, L20 | 소비자가 Data뿐임을 명시 |
| `docs/package-rules/app.md` | L22 | Infrastructure 직접 의존 금지 확인 |
| `docs/conventions/abstraction/protocol-criteria.md` | 근거 A·B 절 | Data 기술 능력 계약 근거 추가 |
| `docs/conventions/abstraction/test-double-injection.md` | L5-6, L18-23, L31-40 | 주입 대상 표를 Data 계약으로 교정 |
| `docs/conventions/abstraction/structure-baseline.md` | 지표 표, 3.1 L45-59 | 추가·제거된 계약 수와 목록 갱신 |
| `docs/conventions/file-vocabulary/shape-vocabulary.md` | Data 행 L17-29 | `Factories/` 추가, `Migrations/` 제거 |
| `docs/review/domain-data-infra-design-review.md` | DS-02·DS-03·DS-05·DS-06·DS-11 | 처리 결과 갱신 |

그래프 SVG 생성 방법은 구현 시 `docs/assets/` 주변 스크립트나 README를 확인해 따른다. 생성 도구가 없으면
`.dot`만 갱신하고 SVG 미갱신을 PR에 기록한다.
