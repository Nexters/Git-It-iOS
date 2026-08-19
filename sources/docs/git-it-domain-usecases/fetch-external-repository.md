# FetchExternalRepository

## 목적
사용자가 입력한 GitHub Repository URL을 기반으로 등록 가능한 외부 Repository 정보를 확인한다.

## 역할
조회 가능한 Public GitHub Repository인지 검증하고, 학습 프로젝트 등록에 사용할 `ExternalRepository`를 반환한다.

## 책임
- GitHub Repository URL에서 조회에 필요한 정보를 식별한다.
- GitHub API를 통해 Repository 존재 및 조회 가능 여부를 확인한다.
- Repository 메타데이터와 canonical Repository URL을 구성한다.
- 유효한 Repository 정보를 `ExternalRepository` 형태로 반환한다.

## 입력
- GitHub Repository URL

## 출력
- `ExternalRepository`

## 제외 책임
- 학습 프로젝트 생성
- Repository 정보의 로컬 영속화
- Private Repository 인증
- URL 자동 정규화
- 화면 입력 상태 관리

---

> 기준 문서: `git-it-handoff-2026-08-17.md`
