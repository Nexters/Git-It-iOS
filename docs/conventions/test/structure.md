# 테스트 구성

[Git It iOS 테스트 컨벤션](../test.md)의 규칙 문서입니다.

테스트 본문은 준비, 실행, 검증 순서를 유지합니다. 단계 주석은 의미를 더할 때만 쓰고,
일반적으로 빈 줄로 구분합니다.

```swift
@Test
func `삭제 확인 성공은 선택한 식별자를 한 번 전달한다`() async throws {
    let project = try makeProject(id: "project-1")
    let deleteProject = DeleteLearningProjectMock(
        behavior: .result(.success(()))
    )
    let store = makeStore(
        project: project,
        isDeleteMode: true,
        deleteLearningProject: deleteProject,
    )

    await store.send(.deleteButtonTapped(project.id)) {
        $0.pendingDeletion = project.id
    }
    await store.send(.deletionConfirmed)
    await store.receive(\.deletionResponse) {
        $0.projects.remove(id: project.id)
        $0.pendingDeletion = nil
        $0.isDeleteMode = false
    }

    #expect(await deleteProject.snapshot() == [project.id])
}
```

- 테스트 입력과 기대값은 테스트 본문에서 확인할 수 있는 결정적인 값으로 구성합니다.
- force unwrap과 강제 타입 변환으로 테스트 전제 조건을 숨기지 않습니다.
- 의미 있는 생성 규칙이 반복될 때만 private helper로 추출합니다.
- 실제 시간, 실행 순서, 네트워크 상태와 공유 전역 mutable state에 결과를 의존시키지
  않습니다.
