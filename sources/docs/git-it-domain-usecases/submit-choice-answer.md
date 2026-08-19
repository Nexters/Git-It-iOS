# SubmitChoiceAnswer

## 목적
객관식 문제에 대한 사용자의 답변을 제출한다.

## 역할
선택한 답안을 서버에 전달하고 채점 결과와 해설을 반환한다.

## 책임
- Project ID와 Question ID를 기준으로 대상 문제를 식별한다.
- 사용자가 선택한 선택지 index를 제출한다.
- 정답 여부를 반환한다.
- 정답 index와 해설을 반환한다.
- 재풀이 시 서버의 최신 답변 상태가 사용되도록 한다.

## 입력
- Project ID
- Question ID
- Selected Index

## 출력
- 정답 여부
- 정답 Index
- Explanation

## 제외 책임
- 선택지 UI 상태 관리
- 정답 표시 UI
- 재시도 UI
- 답변의 로컬 영속화

---

> 기준 문서: `git-it-handoff-2026-08-17.md`
