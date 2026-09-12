# Binding Action

[Git It iOS TCA 컨벤션 — Action](../action.md)의 규칙 문서입니다.

`BindableAction`은 아직 제출되지 않은 텍스트, selection과 local form toggle처럼 화면의
draft 입력을 변경하는 용도로 제한합니다. 삭제, 탈퇴, 북마크 또는 서버 정본을 즉시
바꾸는 작업은 binding setter에서 실행하지 않고 `submitTapped`, `deletionConfirmed`와
같은 명시적인 View Action을 거칩니다.
