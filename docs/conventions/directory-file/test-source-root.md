# test 소스 루트

[Git It iOS 디렉터리·파일 컨벤션](../directory-file.md)의 규칙 문서입니다.

```text
sources/Projects/<패키지>/Tests/<역할>/
```

test 소스 루트 아래 구조는 production과 동일한 규칙을 따릅니다. 같은 production 모듈에
test target이 둘 이상이면 [테스트 컨벤션 — 파일과 Target 구성](../test.md#7-파일과-target-구성)에 따라
`Tests/<역할>/<구분>/`을 소스 루트로 사용합니다 — 이때 소스 루트는 두 세그먼트이며
뎁스는 그 아래부터 셉니다.
