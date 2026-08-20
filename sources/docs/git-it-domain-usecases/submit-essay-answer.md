# SubmitEssayAnswer

## 목적
서술형 문제에 대한 사용자의 답변을 제출한다.

## 역할
작성한 서술형 답변을 서버에 전달하고 학습자가 자가채점할 수 있는 해설과 기준을 반환한다.

## 책임
- Project ID와 Question ID를 기준으로 대상 문제를 식별한다.
- 사용자가 작성한 답변을 제출한다.
- 서버가 제공하는 explanation을 반환한다.
- 자가채점에 필요한 rubric을 반환한다.
- 재풀이 시 서버의 최신 답변 상태가 사용되도록 한다.

## 입력
- Project ID
- Question ID
- Answer Text

## 출력
- Explanation
- Rubric

## 제외 책임
- 사용자 자가채점 판단
- 입력 UI 상태 관리
- 답변의 로컬 영속화
- 화면 내 글자 수 표시

---

> 기준 문서: `git-it-handoff-2026-08-17.md`
