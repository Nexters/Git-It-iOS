# 빠른 시작: 검증 절차

**날짜**: 2026-08-21 | **명세**: [spec.md](./spec.md) | **계획**: [plan.md](./plan.md)

이 문서는 각 패키지 단계의 승인 게이트에서 실행할 검증 절차를 정의한다. 구현 코드는 포함하지
않는다.

## 사전 준비

```sh
make init
```

workspace가 이미 있으면 다음으로 충분하다.

```sh
cd sources && tuist generate
```

빌드 실행기 경로는 다음으로 얻는다.

```sh
./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER
```

## 공통 검증 명령

```sh
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" build
"$project_build_runner" compile
"$project_build_runner" test
```

세 명령은 `sources/DerivedData/PreCommit`을 공유하므로 **순차 실행**해야 한다.

## 단계 0: 문서 개정 (Domain 단계 선행)

**성공 판정**

- `docs/architecture.md` 3.1 표에서 Data의 허용 의존성에 Infrastructure가 있다.
- `docs/architecture.md` 7.1 금지 목록에 `Data → Infrastructure`가 없다.
- `docs/package-rules/data.md`의 Infrastructure 금지 제약 3건이 개정됐다.
- `docs/package-rules/composition.md`의 Data↔Infrastructure Adapter 소유 서술이 개정됐다.
- `docs/architecture.md`에 `D-ARCH-003` 결정 기록이 있다.
- 세 문서와 [contracts/package-dependency-rules.md](./contracts/package-dependency-rules.md)
  사이에 모순 서술이 0건이다.

**대응 요구사항**: FR-055 ~ FR-061 / SC-015 ~ SC-017

## 단계 1: Domain

**성공 판정**

- `SignInUseCase`, `SignOutUseCase`, `RestoreSessionUseCase`,
  `ObserveAuthenticationOutcomesUseCase`가 선언되고 기존 4개 구현이 conform한다.
- Protocol 시그니처에 DTO·HTTP·Infrastructure·외부 SDK 타입이 0건이다.
- Domain이 다른 내부 패키지를 import하지 않는다.
- **rename 검증**: `DomainLearningProject`에 `projectId`, `githubRepoUrl`, `nextSetId`,
  `nextQuestionId`, `setId` 표기가 0건 남는다.
- **rename 검증**: `ObserveAuthorizationChanges` 표기가 0건 남고 구현 본문은 변하지 않았다.
- **rename 검증**: rename 전후로 동일한 Domain 테스트 집합이 통과한다.

```sh
"$project_build_runner" compile
"$project_build_runner" test
```

**대응 요구사항**: FR-001 ~ FR-009, FR-062, FR-063, FR-065, FR-067 / SC-001, SC-002, SC-018, SC-020

## 단계 2: Infrastructure

**성공 판정**

- Data 구현이 요구하는 기술 API 목록과 Infrastructure 공개 API 대조 결과를 보고했다.
- 보완한 API마다 대응 테스트가 있고 통과한다.
- 소비처 없이 추가된 API가 0건이다.
- Infrastructure가 다른 내부 패키지를 import하지 않는다.

**대응 요구사항**: FR-010 ~ FR-014 / SC-006

**비고**: 대조 결과 보완이 필요 없으면 변경 없이 근거를 보고하고 다음 단계로 넘어간다.

## 단계 3: Data

**성공 판정**

- `ProjectRemote`, `AuthenticationRemote`, `ExternalRepositoryRemote`를 포함해 조립에 필요한
  Data Protocol에 실행 구현이 존재한다.
- Data target이 사용하는 Infrastructure target을 Tuist에 명시적으로 선언한다.
- 요청 구성, 응답 변환, 오류 변환 테스트가 통과한다.
- Data가 Domain·Composition·Feature·App·UI를 import하지 않는다.
- `DataMember`는 변경되지 않았다.

**대응 요구사항**: FR-015 ~ FR-020 / SC-003 ~ SC-005

## 단계 4: Composition

**성공 판정**

- `Authentication`, `LearningProject`, `ExternalRepository`의 live 그래프 생성이 성공한다.
- 공개 선언에 Domain UseCase Protocol 이외의 타입이 0건이다.
- Feature·Store·View 생성 코드가 0건이고, Feature·App·UI 의존성 선언이 0건이다.
- `HTTPClient`와 Keychain 저장소가 진입점당 1회만 생성된다.
- Adapter의 DTO→Domain 모델, Data 오류→Domain 오류 변환 테스트가 통과한다.
- **rename 검증**: `Adepter` 표기가 manifest·폴더·target 이름·의존성 선언에 0건 남는다
  (`docs/spec-kit/**`의 append-only 기록은 제외).
- **rename 검증**: App의 변경이 target 이름 참조 1건뿐이고 App 소스 파일 변경은 0건이다.
- **rename 검증**: Adapter에 식별자·URL 표기를 뒤집는 변환이 0건이다.

**대응 요구사항**: FR-021 ~ FR-031, FR-064, FR-064a / SC-007 ~ SC-011, SC-021, SC-022

## 최종 검증 (마지막 패키지 완료 후)

```sh
cd sources && tuist generate && cd ..
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" build
"$project_build_runner" compile
"$project_build_runner" test
```

**성공 판정**

- 의존성 순환 0건, `tuist generate`와 전체 공유 scheme Debug 빌드 성공 (SC-012)
- Domain·Data·Infrastructure·Composition 테스트 전부 통과 (SC-013)
- `Feature`와 `App`의 소스가 변경되지 않았다. App은 target 이름 참조 1건만 갱신됐다 (SC-014, SC-021)
- 저장소 Swift 선언에 `Url`·`Id`·`Http` 절충 표기가 0건이다. Data `CodingKeys`의 서버 원문 키
  문자열과 테스트 JSON fixture는 집계에서 제외한다 (SC-019)
- `Feature` target 의존성이 Domain·UI 범위를 유지한다 (SC-010 계열 규칙 유지)

**비고**: 셸 스크립트를 변경하지 않았다면 `tools/script-tests`와 `tools/script-verification`
실행은 필요하지 않다. pre-commit 훅이 커밋 시점에 동일 검증을 수행한다.
