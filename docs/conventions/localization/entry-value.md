# 값과 주석

[Git It iOS 현지화 컨벤션](../localization.md)의 규칙 문서입니다.

**값은 화면에 보이는 최종 한국어 문구입니다.** 줄바꿈은 값 안의 `\n`으로 유지합니다.

**모든 항목은 주석을 가집니다.** 주석은 “어느 화면·컴포넌트의 어디에 보이는 무엇인지”를 한 문장으로
씁니다.

**동적 값이 들어가는 문구는 이름 있는 위치 지정자를 씁니다.** 수량은 `%1$(count)lld`, 문자열은
`%1$(name)@` 형식이며, 주석에 `인자이름: 의미`를 인자마다 적습니다. 지정자의 이름은 생성
심볼의 인자 레이블이 되고, 인자 순서는 지정자의 위치 번호를 따릅니다.

- 문장을 여러 항목으로 쪼개 코드에서 이어 붙이지 않습니다. 한 문장은 한 항목입니다.
- 한국어는 복수 변형을 만들지 않습니다. 수량 문구는 정수 지정자로 두어 다른 언어가 복수 변형을
  추가할 수 있게 합니다.

고정 문구 항목은 다음 형태입니다.

```json
"Example.title" : {
  "comment" : "예시 화면 상단 제목",
  "extractionState" : "manual",
  "localizations" : {
    "ko" : {
      "stringUnit" : { "state" : "translated", "value" : "예시" }
    }
  }
}
```

보간 항목은 다음 형태입니다.

```json
"Example.Detail.Summary.Done.title" : {
  "comment" : "예시 상세 화면 요약 영역의 완료 제목. count: 완료한 항목 수",
  "extractionState" : "manual",
  "localizations" : {
    "ko" : {
      "stringUnit" : { "state" : "translated", "value" : "%1$(count)lld개 항목을 완료했어요" }
    }
  }
}
```

- `localizations`에는 지원 언어(`ko`)만 둡니다.
- `version` 값과 JSON 들여쓰기는 Xcode가 저장한 형태를 따릅니다.
