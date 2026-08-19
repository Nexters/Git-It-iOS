# 계약: FetchExternalRepository

**날짜**: 2026-08-19 | **명세**: [spec.md](../spec.md) FR-001~004 |
**데이터 모델**: [data-model.md](../data-model.md) `ExternalRepository` |
**도메인 문서**: [fetch-external-repository.md](../../../sources/docs/git-it-domain-usecases/fetch-external-repository.md)

사용자가 입력한 GitHub Repository URL이 등록 가능한 Public Repository인지 확인한다.

## 엔드포인트

**Git-It 서버 API가 아니다.** GitHub 공개 API(`https://api.github.com`)를 직접
호출한다(FR-002) — Git-It 서버에는 저장소 검증 전용 엔드포인트가 없다.

## 요청

| 항목 | 타입 | 설명 |
|---|---|---|
| GitHub Repository URL | string | 사용자 입력. 소유자·저장소 이름을 식별하는 데 사용(FR-001) |

## 성공 응답

`ExternalRepository`(canonical Repository URL + 메타데이터)를 반환한다. 정확한 필드
구성은 GitHub API 응답을 따르며, 최소한 등록(`CreateLearningProject`) 화면에 필요한
이름·이미지·star 수·기술 스택에 준하는 정보를 포함해야 한다(FR-003).

## 오류

| 조건 | 처리 |
|---|---|
| 존재하지 않는 저장소 | 등록 가능한 `ExternalRepository`를 반환하지 않는다(FR-004) |
| Private Repository | 등록 가능한 `ExternalRepository`를 반환하지 않는다(FR-004) |
| GitHub API rate limit | 이 문서의 범위 밖(spec.md에 명시적 요구사항 없음) — 후속 구현 스펙에서 재시도·인증 전략을 결정한다 |

## 제외 책임

학습 프로젝트 생성, Repository 정보의 로컬 영속화, Private Repository 인증, URL 자동
정규화, 화면 입력 상태 관리(도메인 문서 `제외 책임`).
