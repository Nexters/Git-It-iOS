# 프리뷰 전용 타입

[Git It iOS 파일·형태 어휘 컨벤션](../file-vocabulary.md)의 규칙 문서입니다.

프리뷰 전용 타입은 계약이 아니므로 중첩하지 않고 이름을 `{소유타입}Preview{역할}`로
짓습니다. UI 패키지에서는 소유 컴포넌트 파일의 최상위에 두고
([UIComponent 컨벤션 — 폴더와 파일](../ui-component/folder-file.md)), Feature 패키지에서는
`{소유타입}Preview{역할}.swift`로 분리해 그 화면의 `Previews/` 폴더에, 여러 화면이 공유하면
흐름 1뎁스의 `Previews/` 폴더에 둡니다
([View 컨벤션 — 프리뷰](../view/preview.md)).
