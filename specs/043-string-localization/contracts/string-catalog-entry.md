# 계약: String Catalog 항목

**기능**: [spec.md](../spec.md) | **데이터 모델**: [data-model.md §2](../data-model.md#2-현지화-항목)

`.xcstrings` 파일(JSON)의 항목 형태다. 파일은 Xcode String Catalog 편집기로 편집하는 것을 기본으로 하고,
직접 편집할 때도 아래 형태를 지킨다.

## 고정 문구

```json
{
  "sourceLanguage" : "ko",
  "strings" : {
    "settingsTitle" : {
      "comment" : "설정 화면 상단 제목",
      "extractionState" : "manual",
      "localizations" : {
        "ko" : {
          "stringUnit" : { "state" : "translated", "value" : "설정" }
        }
      }
    }
  },
  "version" : "1.0"
}
```

## 보간 문구

```json
"filterCount" : {
  "comment" : "저장한 문제 필터 칩의 문제 수. count: 해당 필터에 속한 저장 문제 수",
  "extractionState" : "manual",
  "localizations" : {
    "ko" : {
      "stringUnit" : { "state" : "translated", "value" : "%1$(count)lld개" }
    }
  }
}
```

## 규칙

- `sourceLanguage`는 `ko`이고 `localizations`에는 `ko`만 둔다.
- 모든 항목은 `comment`와 `"extractionState" : "manual"`을 가진다.
- 수량 인자는 `lld`, 문자열 인자는 `@` 지정자를 이름과 위치를 붙여 쓴다.
- 줄바꿈은 값 안의 `\n`으로 유지한다.
- `version` 값과 JSON 들여쓰기는 Xcode가 저장한 형태를 따른다.
