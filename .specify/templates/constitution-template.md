# [PROJECT_NAME] 헌법
<!-- 예: Spec 헌법, TaskFlow 헌법 등 -->

## 핵심 원칙

### [PRINCIPLE_1_NAME]
<!-- 예: I. 라이브러리 우선 -->
[PRINCIPLE_1_DESCRIPTION]
<!-- 예: 모든 기능은 독립 라이브러리에서 시작한다. 라이브러리는 자체 완결되고 독립적으로 검증 가능하며 문서화해야 한다. 조직 편의만을 위한 라이브러리는 만들지 않는다. -->

### [PRINCIPLE_2_NAME]
<!-- 예: II. CLI 인터페이스 -->
[PRINCIPLE_2_DESCRIPTION]
<!-- 예: 모든 라이브러리는 CLI로 기능을 노출한다. 텍스트 입출력은 stdin/args → stdout, 오류는 stderr를 사용하고 JSON과 사람이 읽을 수 있는 형식을 지원한다. -->

### [PRINCIPLE_3_NAME]
<!-- 예: III. 테스트 우선(타협 불가) -->
[PRINCIPLE_3_DESCRIPTION]
<!-- 예: TDD를 의무화한다. 테스트 작성 → 사용자 승인 → 테스트 실패 → 구현 순서를 지키고 Red-Green-Refactor 주기를 엄격히 따른다. -->

### [PRINCIPLE_4_NAME]
<!-- 예: IV. 통합 테스트 -->
[PRINCIPLE_4_DESCRIPTION]
<!-- 예: 통합 테스트가 필요한 영역: 새 라이브러리 계약 테스트, 계약 변경, 서비스 간 통신, 공유 스키마 -->

### [PRINCIPLE_5_NAME]
<!-- 예: V. 관찰 가능성, VI. 버전·호환성 변경, VII. 단순성 -->
[PRINCIPLE_5_DESCRIPTION]
<!-- 예: 텍스트 입출력은 디버깅 가능성을 보장한다. 구조화된 로그가 필요하다. 또는 MAJOR.MINOR.BUILD 형식을 사용한다. 또는 단순하게 시작하고 YAGNI 원칙을 따른다. -->

## [SECTION_2_NAME]
<!-- 예: 추가 제약, 보안 요구사항, 성능 기준 등 -->

[SECTION_2_CONTENT]
<!-- 예: 기술 스택 요구사항, 준수 기준, 배포 정책 등 -->

## [SECTION_3_NAME]
<!-- 예: 개발 흐름, 검토 절차, 품질 게이트 등 -->

[SECTION_3_CONTENT]
<!-- 예: 코드 리뷰 요구사항, 테스트 게이트, 배포 승인 절차 등 -->

## 거버넌스
<!-- 예: 헌법은 다른 모든 관행보다 우선한다. 개정에는 문서화, 승인, 이관 계획이 필요하다. -->

[GOVERNANCE_RULES]
<!-- 예: 모든 PR과 리뷰는 준수를 확인한다. 복잡성은 정당화해야 한다. 런타임 개발 지침에는 [GUIDANCE_FILE]을 사용한다. -->

**버전**: [CONSTITUTION_VERSION] | **비준일**: [RATIFICATION_DATE] | **최종 수정일**: [LAST_AMENDED_DATE]
<!-- 예: 버전: 2.1.1 | 비준일: 2025-06-13 | 최종 수정일: 2025-07-16 -->
