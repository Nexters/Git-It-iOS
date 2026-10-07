# 구현 계획: 패키지 의존성 기계 검증과 CompositionAdapter 도메인 축 분할

**Git-flow 유형**: `feature`

**브랜치**: `feature/package-dependency-enforcement`

**날짜**: 2026-09-16 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/034-package-dependency-enforcement/spec.md`의 기능 명세

## 요약

[아키텍처 3.1](../../docs/architecture.md)의 패키지 의존성 표를 POSIX 셸 정적 검사 도구
`tools/package-dependencies/`로 기계 검증한다. 도구는 허용 표 설정과 아키텍처 문서 표의
1:1 대응, manifest `.from<패키지>` 선언의 패키지 조합, Swift `import`의 패키지 조합, target
manifest가 선언하지 않은 내부 모듈 import를 검사한다. 모듈과 소속 패키지는
`<패키지>ModuleName.swift`의 enum에서 읽고, Swift 파일은 설정의 source root 표로 target에
대응시킨다. 도구 도입 전에 현행 위반 6건을 해소해 위반 0에서 시작하고, 공개 경로 등록,
pre-commit 단계, CI job으로 연결한다.

그다음 `CompositionAdapter`(12개 모듈 의존)를 `CompositionAuthentication`(6),
`CompositionLearningProject`(6), `CompositionMember`(5)와 공용
`CompositionShared`(1)로 나누고, `CompositionApp`(9)과 `CompositionShareExtension`(8)이
Data·Storage 조립을 분할 target으로 넘겨 각각 6 이하가 되게 한다. 근거는
[research.md](./research.md), 배치 표는 [data-model.md](./data-model.md)에 있다.

## 기술 맥락

**언어/버전**: POSIX `sh`(도구), Swift 6과 Tuist manifest(분할)

**주요 의존성**: `awk`, `sed`, `grep`, `find`, `sort`. `rg`는 도구 본체에 쓰지 않는다. CI
job을 설치 단계 없이 `ubuntu-latest`에서 실행하기 위해서다. 회귀 테스트와 기존 검증은
기존 관행대로 `rg`를 쓸 수 있다.

**저장소**: 해당 없음

**테스트**: 도구는 `tools/package-dependencies/tests/test-package-dependencies.sh`(fixture
저장소 기반 셸 회귀), 분할은 Composition·App scheme의 기존 Swift Testing

**대상 플랫폼**: macOS 개발 환경, GitHub Actions `ubuntu-latest`, iOS Simulator(iPhone 17 Pro)

**프로젝트 유형**: Tuist 멀티 패키지 iOS 앱과 저장소 셸 도구

**성능 목표**: 전체 저장소 단독 실행 5초 이하(FR-013). 프로토타입 기준 Swift 파일 약
900개를 `find … -exec awk … {} +` 한 번으로 읽는다.

**제약 조건**: target 단위 예외 금지(FR-001), 예외 목록 없이 위반 0(FR-014), Feature 단일
target 유지, Domain↔Data 경계 불변, 사용자 관찰 동작 불변(SC-009), 사용자 소유 미커밋 변경
비stage

**규모/범위**: manifest 7개, target 41개(분할 후 45개), Composition Adapter 파일 26개와 테스트
14개 이동, 조립 루트 2개, 도구 등록 지점 9곳

## 기준선 실측

`a9021ec` 기준 프로토타입 측정값이다. 측정 방법은 [research.md](./research.md) 2·3절에 있다.

| 항목 | 값 |
| --- | --- |
| manifest 모듈 선언 / target 블록 | 41 / 41 |
| manifest 패키지 조합 위반 | 0 |
| import 패키지 조합 위반 | 0 |
| target 미선언 import(테스트 target이 production 선언 상속) | 6 |
| target 미선언 import(테스트 target 상속 없음) | 173 |
| `CompositionAdapter` / `CompositionApp` / `CompositionShareExtension` 다른 패키지 모듈 의존 | 12 / 9 / 8 |

미선언 import 6건의 내역은 `GitIt → DomainMember` 3건, `GitIt → DomainLearningProject` 2건,
`CompositionApp → DataMember` 1건이다.

## 명세와의 해석 차이

1. **"의존 모듈 수"의 정의**: 명세 기준선의 `CompositionApp` 9와 `CompositionShareExtension`
   8은 같은 패키지 `.target` 의존(`CompositionAdapter`)을 세지 않은 값이다. 이 계획은 같은
   정의를 따른다. 한 target의 manifest 블록에서 다른 프로젝트 패키지 모듈을 가리키는
   `.from<패키지>(…)` 선언 수이며 같은 패키지 `.target`, `.external`, `.sdk`는 세지 않는다.
   test target은 자기 블록의 추가 선언만 센다.
2. **FR-016의 적용 대상**: "Composition의 어느 target도"를 문자 그대로 적용한다. 분할한
   Adapter target뿐 아니라 `CompositionApp`과 `CompositionShareExtension`도 6 이하로 줄인다.
   SC-006의 최댓값 목표가 이를 요구한다.
3. **FR-005와 test target**: test target은 manifest의 `productionTarget`으로 production
   target을 선언하므로, 그 target과 그 target이 선언한 모듈을 test target의 선언 집합에
   포함한다. 이 상속은 target 단위 규칙에만 적용한다. 패키지 조합(FR-003·FR-004)은 완화하지
   않는다. 상속 없는 해석은 위반 173건을 만들고 해소하려면 test manifest에 production과 같은
   선언을 반복해야 한다([research.md](./research.md) 4절).
4. **UI 폰트 이름**: 명세 가정의 `notoSansKR`·`plusJakartaSans`는 `UIModuleName` enum의
   case가 아니라 폰트 enum case다. 모듈 목록에 넣지 않는다.
5. **현행 위반**: 명세는 "도입 시점 위반 0 확인"만 요구한다. 실측에서 6건이 나왔으므로 도구
   등록 전에 U2에서 해소한다. 예외 목록은 만들지 않는다.

## 헌법 점검

| 원칙 | 판정 | 근거 |
| --- | --- | --- |
| 1. 명시적인 경계 | 통과 | 표를 기계가 강제한다. 분할은 허용 방향(Composition → Domain·Data·Infrastructure)을 바꾸지 않는다 |
| 2. 상태와 데이터 안전성 | 통과 | 조립 코드 이동뿐이며 저장 형식·키·마이그레이션 호출 순서가 바뀌지 않는다 |
| 3. 검증 가능한 변경 | 통과 | SC-001~SC-009를 [quickstart.md](./quickstart.md)의 명령으로 확인한다. 해석 차이를 위에 기록했다 |
| 4. 스킬별 수정 경로 | 통과 | 이 명령은 `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/**`만 수정한다 |
| 5. Spec-Kit 범위 | 통과 | 내부 품질 명세이며 이해관계자는 저장소 기여자와 리뷰어다 |
| 6. 한국어 산출물 | 통과 | 식별자·명령·경로만 원문을 유지한다 |
| 7. 위험 기반 실행 단위 | **조건부 통과** | U3이 사용자 미커밋 변경이 있는 파일 5개를 수정해야 한다. 승인 지점을 아래에 둔다 |
| 8. Git-flow 네임스페이스 | 통과 | `feature/package-dependency-enforcement`를 생성해 사용 중이다 |
| 9. 세션 지식 기록 | 해당 없음 | 기록 문턱을 넘는 사건이 아직 없다 |
| 10. 책임 기반 네이밍 | 통과 | 분할 target 이름은 도메인 축을 드러낸다. `CompositionShared`는 여러 도메인 조립이 공유하는 요소라는 책임만 드러낸다([research.md](./research.md) 8절) |

**1단계 설계 후 재점검**: 통과. 새 패키지와 새 의존 방향이 없다. 분할 target 4개는 모두
Composition 패키지 안이며 다른 패키지 모듈 의존 수가 6 이하다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/034-package-dependency-enforcement/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/README.md
├── checklists/requirements.md
└── tasks.md            # /speckit-tasks 산출물
```

### 소스 코드(저장소 루트)

```text
tools/package-dependencies/                                    # 신설 (U1)
├── bin/run.sh
├── core/
│   ├── rules-policy.sh          # 순수 정책: 패키지 조합·선언 판정, 위반 설명
│   ├── architecture-table.sh    # adapter: 아키텍처 3.1 표 읽기
│   ├── manifest.sh              # adapter: ModuleName.swift 모듈·target·선언 읽기
│   ├── imports.sh               # adapter: Swift import 추출
│   └── run.sh                   # 유스케이스: 수집 → 판정 → 보고
├── config/
│   ├── allowed-dependencies     # 패키지 허용 표 (FR-001)
│   └── source-roots             # target ↔ source root 표
└── tests/test-package-dependencies.sh

sources/Tuist/ProjectDescriptionHelpers/
├── Projects/AppModuleName.swift                               # U2, U6
├── Projects/CompositionModuleName.swift                       # U5, U6
├── ProjectName.swift                                          # U5
└── AllTestsScheme.swift                                       # U5

sources/Projects/Composition/
├── Adapter/                     # U5에서 제거
├── Shared/Factories/            # 신설
├── Authentication/{Adapters,Assemblies,Codings}/              # 신설
├── LearningProject/{Adapters,Assemblies}/                     # 신설
├── Member/{Adapters,Assemblies}/                              # 신설
├── App/Assemblies/AppComposition.swift                        # U2, U6
├── ShareExtension/Assemblies/ShareExtensionComposition.swift  # U6
└── Tests/{Authentication,LearningProject,Member,App,ShareExtension}/

sources/Projects/App/ShareExtension/ShareViewController.swift  # U5

tools/repository-paths/{repository-paths.json,bin/repository-paths.sh,tests/test-no-hardcoded-paths.sh}  # U3
tools/script-tests/core/tests.sh                               # U3
tools/script-verification/config/verification.conf             # U3
tools/githooks/{pre-commit,pre-commit.d/package-dependencies.sh,pre-commit.d/enabled}  # U4
tools/githooks/hook-management/tests/test-pre-commit.sh        # U4
.github/workflows/ci.yml, tools/ci/tests/test-gate-evaluate.sh # U4
docs/package-rules/composition.md                              # U7
```

## 실행 단위

사용자 지시에 따라 검사 도구(FR-001~FR-014)를 분할(FR-015~FR-019)보다 먼저 둔다. 분할
단위는 도구가 위반 0을 유지하는지로 회귀를 확인한다.

| 단위 | 범위 | 목적 | 분리 가능성 |
| --- | --- | --- | --- |
| U1 | 도구 | 검사 도구 본체, 설정, 회귀 테스트 | 새 디렉터리만 만든다. 등록 전에도 직접 경로로 실행된다 |
| **I2** | App + Composition | 현행 미선언 import 6건 해소 | **불가분**이 아니라 FR-014 한 수용 기준의 최소 묶음. 아래 근거 |
| U3 | 도구 등록 | 공개 경로·셸 회귀·정적 검사 대상 등록 | **승인 필요**. 사용자 미커밋 변경과 같은 파일 |
| U4 | 훅·CI | pre-commit 단계와 CI job 연결 | U3의 공개 경로 키에 의존 |
| **I5** | Composition + App + Tuist + 도구 설정 | `CompositionAdapter`를 4개 target으로 분할 | **불가분**. 아래 근거 |
| U6 | Composition + App manifest | 조립 루트 2개의 의존을 6 이하로 축소 | I5 뒤. 단독 compile 가능 |
| U7 | 문서 | Composition target 구성과 6 이하 규칙 기록 | 모든 코드 단위 뒤 |

### U1을 먼저 두는 이유

분할(I5·U6)의 회귀 판정에 도구를 쓴다. 도구는 새 디렉터리만 만들고 저장소 연결점을 바꾸지
않으므로 다른 단위와 독립적으로 되돌릴 수 있다. 이 단위의 검증에서 저장소 전체 실행은 위반
6건을 보고해 실패하는 것이 기대값이다.

### I2를 App과 Composition 묶음으로 두는 근거

FR-014의 "위반 0"은 두 패키지의 변경이 모두 끝나야 성립한다. 변경은
`AppModuleName.swift`의 `GitIt` 블록에 `.fromDomain(.DomainLearningProject)`와
`.fromDomain(.DomainMember)`를 선언하는 것과 `AppComposition.swift`의 쓰이지 않는
`import DataMember`를 지우는 것뿐이다. 각각 따로 compile되지만 수용 기준 하나를 함께
충족하므로 하나의 커밋 단위로 둔다.

### U3의 승인 지점

등록에 필요한 파일 5개(`repository-paths.json`, `repository-paths.sh`,
`test-no-hardcoded-paths.sh`, `script-tests/core/tests.sh`, `verification.conf`)에 사용자가
만든 미커밋 변경(doc-registry 키 등록)이 이미 있다. 파일 단위 stage는 그 변경까지 커밋에
포함한다. 구현 시점에 다음 중 하나를 사용자에게 확인받는다.

1. 이 명세가 추가하는 hunk만 index에 적용한다(`git apply --cached`로 HEAD 기준 패치 적용).
   사용자 변경은 작업 트리에 그대로 남는다.
2. 사용자 변경을 포함해 파일 전체를 stage한다.
3. U3·U4를 보류하고 I5부터 진행한다. 이 경우 FR-008·FR-011·FR-012가 미완료로 남는다.

### I5를 다중 패키지 단위로 두는 근거

`CompositionAdapter` 모듈 이름이 사라지는 순간 그 모듈을 import하는 `CompositionApp`,
`CompositionShareExtension`, 테스트 target, App의 `ShareExtension` target과 manifest의
`ProjectName`·`AllTestsScheme`, 도구의 `source-roots` 설정이 함께 깨진다. target 선언,
파일 이동, import 갱신, scheme 목록을 나눌 수 없다.

이 단위는 공개 API를 옮기기만 한다. `makeHTTPClient`의 접근 수준을 `public`으로 올리고,
분할 target 사이 참조에 필요한 import를 바꾸는 것 외에 타입 서명과 동작을 바꾸지 않는다.

### U6을 I5 뒤 별도 단위로 두는 근거

조립 루트가 Data·Storage 타입을 직접 만드는 코드를 분할 target의 조립 API로 옮기는
변경이다. I5 결과 위에서 독립적으로 compile되고 되돌릴 수 있다. 이 단위에서
`CompositionApp` 9 → 6, `CompositionShareExtension` 8 → 6이 된다.

### 작업 트리 기준선 처리

현재 작업 트리에는 사용자 소유 변경 외에 이 세션의 빌드가 FormatSwift 플러그인으로 만든
포맷 변경이 여러 Swift 파일에 있다. 이 명세는 다음 규칙을 따른다.

- I5·U6이 이동하거나 수정하는 파일에 포맷 변경이 있으면 그 결과를 같은 단위에 포함한다.
  대상은 `Tests/Adapter/Assemblies/LearningProjectAssemblyTests.swift`,
  `Tests/App/Assemblies/AppCompositionTests.swift`,
  `Tests/App/Assemblies/AppCompositionSharedLifetimeTests.swift`,
  `Tests/ShareExtension/ShareExtensionCompositionTests.swift`다. 빌드가 같은 결과를 다시
  만들기 때문에 되돌리는 것은 의미가 없다.
- 그 밖의 파일의 포맷 변경과 사용자 소유 변경은 stage하지 않는다.

## 통합 검증

| 단위 | 검증 |
| --- | --- |
| U1 | 회귀 테스트 통과, fixture 3종(manifest·import·표 불일치) 실패 확인, 저장소 실행이 위반 6건을 정확히 보고 |
| I2 | 도구 위반 0, `tuist generate`, `GitIt`·`CompositionApp` scheme 빌드 |
| U3 | `script-tests/bin/run.sh`, `script-verification/bin/run.sh`, `repository-paths.sh GIT_IT_PACKAGE_DEPENDENCY_RUNNER` |
| U4 | `hook-management/tests/test-pre-commit.sh`, `ci/tests/test-gate-evaluate.sh`, `enabled`에 단계를 켠 임시 실행 |
| I5 | 도구 위반 0, `tuist generate`, Composition·App scheme 빌드, Composition scheme 테스트, `AllTests` target 목록 |
| U6 | 도구 위반 0, 의존 수 계산(모든 Composition target 6 이하), Composition·App scheme 빌드와 테스트 |
| U7 | 문서 링크와 target 표가 manifest와 일치 |

## 검증 계획

1. 각 단위마다 [quickstart.md](./quickstart.md)의 해당 시나리오를 실행한다.
2. 모든 단위 뒤 전체 읽기 전용 검증: 도구 실행 시간 5초 이하와 위반 0, 셸 회귀·정적 검사,
   `tuist generate`, 전체 공유 scheme Debug 빌드, Composition·App 테스트 scheme의 성공·실패
   목록이 시작 전과 같은지 확인한다.
3. 기준선 표를 다시 재고 [research.md](./research.md) 10절의 예상값과 대조한다.

## 복잡성 추적

위반 없음.
