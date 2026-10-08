# 빠른 시작: 학습 프로젝트 생명주기 UseCase 검증

**명세**: [spec.md](./spec.md) | **계획**: [plan.md](./plan.md) | **데이터 모델**:
[data-model.md](./data-model.md) | **계약**: [contracts/](./contracts/)

이 문서는 구현이 끝난 뒤 5개 UseCase가 spec.md의 수용 시나리오대로 "실제로 동작함"을
검증하는 절차다. 이 계획 단계는 코드를 작성하지 않으므로 아래 명령은 `/speckit-implement`
이후 실행 대상이다. Composition 배선이 없으므로 모든 검증은 Domain/Data 패키지 단위
계약 테스트(Test Double 기반)로 수행하며, 실제 GitHub API·Git-It 서버로의 네트워크 호출은
포함하지 않는다(spec.md 범위 밖).

## 사전 조건

- `make init`으로 Tuist 프로젝트가 생성되어 있어야 한다(`GitIt.xcworkspace` 존재).
- `tasks.md`의 Domain 단계(`DomainLearningProject`)와 Data 단계(`DataLearningProject`)가
  각각 완료되어 있어야 한다(원칙 7 패키지 진행 게이트).
- Tuist 구성 변경 후에는 `tuist generate`(또는 `make init`)로 스킴을 다시 생성해야
  `xcodebuild test`가 새 스킴을 찾을 수 있다.

## 시나리오 1 — 등록이 실제로 동작한다 (P1, SC-001·SC-002·SC-003 일부)

1. `DomainLearningProjectTests`에서 `FetchExternalRepository` 계약 테스트를 실행해
   URL 형식 오류·오프라인·그 밖의 오류 3가지와 성공 1개를 확인한다
   (contracts/fetch-external-repository.md "FR-025 테스트 매트릭스").
2. 같은 target에서 `CreateLearningProject` 계약 테스트를 실행해 신규 등록·재등록 멱등성
   (FR-007)·삭제 후 복원(FR-008)·400 오류(FR-009) 경로를 확인한다
   (contracts/create-learning-project.md).
3. 실행:

   ```sh
   xcodebuild test \
     -workspace GitIt.xcworkspace \
     -scheme DomainLearningProject \
     -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
   ```

**기대 결과**: 실패 0건. `FetchExternalRepository`가 반환한 `ExternalRepository`를
`CreateLearningProject`에 그대로 전달하는 조합 테스트가 `projectId`와 `status`를
확인한다(SC-001 "전체 생명주기를 계약 테스트로 실행").

## 시나리오 2 — 목록·상세 조회가 실제로 동작한다 (P2, SC-002·SC-003 일부)

1. `FetchLearningProjects` 계약 테스트로 진행률·다음 학습 정보(`nextSetId`,
   `nextQuestionId`)·`hasNext`가 그대로 반환되는지, `COMPLETED`가 아닌 항목에 대한 추가
   필터링이 없는지 확인한다(contracts/fetch-learning-projects.md).
2. `FetchLearningProjectDetail` 계약 테스트로 `sets[]` 기반 `nextSet` 계산(FR-019)과
   404(`PROJECT-001`) 동일 처리(FR-018)를 확인한다(contracts/fetch-learning-project-detail.md).
3. 실행: 시나리오 1과 동일한 `xcodebuild test`(같은 `DomainLearningProject` 스킴).

**기대 결과**: 실패 0건. `sets`에 완료되지 않은 세트가 있을 때와 모두 완료했을 때 두
경우 모두 `nextSet` 계산 테스트가 통과한다.

## 시나리오 3 — 삭제가 실제로 동작한다 (P3, SC-002·SC-003 일부)

1. `DeleteLearningProject` 계약 테스트로 성공 경로와 404(`PROJECT-001`) 동일 처리
   (FR-022)를 확인한다(contracts/delete-learning-project.md).
2. 삭제 후 미노출 회귀(spec.md 시나리오 3 "독립 테스트")는 `DeleteLearningProject`와
   `FetchLearningProjectDetail`을 같은 Fake `LearningProjectRepository` 인스턴스에 대해
   순서대로 호출하는 조합 테스트로 검증한다 — Fake가 삭제 이후 같은 `projectId` 조회에
   `.notFound`를 던지도록 구성한다.
3. 실행: 시나리오 1과 동일한 `xcodebuild test`.

**기대 결과**: 실패 0건.

## Data 패키지 검증 (DTO·오류 타입)

```sh
xcodebuild test \
  -workspace GitIt.xcworkspace \
  -scheme DataLearningProject \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

- `RegisterProjectRequestDTO`/`RegisterProjectResponseDTO`/`ProjectListResponseDTO`/
  `ProjectDetailResponseDTO`/`GitHubRepositoryResponseDTO`가 `Git-It-server-scheme.json`
  예시 JSON(및 GitHub API 표준 응답 형태)을 실제로 디코딩하는지 확인한다
  (data-model.md §2).
- `DataLearningProjectError`/`DataExternalRepositoryError`가 `CaseIterable`이 요구하는
  전체 케이스를 가지는지 확인한다(`AuthenticationErrorTests` 관례와 동일한 형태).

**기대 결과**: 실패 0건.

## 전체 재확인

```sh
xcodebuild test \
  -workspace GitIt.xcworkspace \
  -scheme DomainLearningProject \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
xcodebuild test \
  -workspace GitIt.xcworkspace \
  -scheme DataLearningProject \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

두 스킴 모두 실패 0건이면 SC-001~004가 이 기능 범위(Domain·Data) 안에서 충족된 것으로
본다. Composition 배선과 실제 네트워크 왕복 검증은 후속 스펙의 몫이다(spec.md `범위 밖`).
