# CreateLearningProject

## 목적
확인된 외부 Repository를 기반으로 새로운 학습 프로젝트 생성을 요청한다.

## 역할
Repository와 문제 난이도 조건을 서버에 전달하여 학습 프로젝트 생성 및 문제 생성 작업을 시작한다.

## 책임
- canonical Repository URL을 프로젝트 생성 요청에 사용한다.
- 사용자가 선택한 `quizLevel`을 생성 조건으로 전달한다.
- 서버에 학습 프로젝트 생성을 요청한다.
- 생성된 프로젝트 식별자와 현재 생성 상태를 반환한다.

## 입력
- canonical Repository URL
- Quiz Level (`L1`, `L2`, `L3`)

## 출력
- Project ID
- Project Status

## 제외 책임
- 생성 완료 대기
- FCM 이벤트 수신
- Polling / Timer 관리
- Timeout 감시
- Retry 자체
- 생성 요청 정보의 로컬 영속화

---

> 기준 문서: `git-it-handoff-2026-08-17.md`
