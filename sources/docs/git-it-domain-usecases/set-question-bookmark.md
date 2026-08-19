# SetQuestionBookmark

## 목적
특정 문제의 북마크 상태를 사용자가 원하는 최종 상태로 변경한다.

## 역할
문제의 현재 UI 상태를 단순 toggle하는 것이 아니라 명시적인 북마크 상태를 서버에 반영한다.

## 책임
- Project ID와 Question ID를 기준으로 대상 문제를 식별한다.
- 원하는 최종 북마크 상태를 서버에 전달한다.
- 서버의 북마크 변경 결과를 처리한다.

## 입력
- Project ID
- Question ID
- Bookmarked (`true` / `false`)

## 출력
- 북마크 상태 변경 결과

## 제외 책임
- Toggle 상태 추론
- 북마크 목록 조회
- 북마크 상태의 로컬 영속화
- 버튼 애니메이션 및 UI 상태 관리

---

> 기준 문서: `git-it-handoff-2026-08-17.md`
