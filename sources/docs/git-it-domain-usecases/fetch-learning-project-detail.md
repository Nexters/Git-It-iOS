# FetchLearningProjectDetail

## 목적
특정 학습 프로젝트의 상세 학습 정보를 조회한다.

## 역할
Repository 정보, 전체 진행도, 학습 세트 등 프로젝트 상세 화면에 필요한 서버 데이터를 반환한다.

## 책임
- Project ID를 기준으로 프로젝트 상세를 조회한다.
- Repository 기본 정보를 반환한다.
- 프로젝트 전체 진행 정보를 반환한다.
- 학습 세트 목록과 각 세트의 진행 정보를 반환한다.
- 다음 학습 문제 정보가 제공되는 경우 함께 반환한다.

## 입력
- Project ID

## 출력
- Learning Project Detail

## 제외 책임
- 프로젝트 생성 완료 감지
- 세트 문제 상세 조회
- 상세 데이터 로컬 캐싱
- 화면 조합 및 Navigation

---

> 기준 문서: `git-it-handoff-2026-08-17.md`
