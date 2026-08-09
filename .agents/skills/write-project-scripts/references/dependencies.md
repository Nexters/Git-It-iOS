# 스크립트 검증 도구 의존성

ShellCheck와 shfmt는 애플리케이션 런타임이 아니라 저장소 셸 자동화를 검증하는 개발 도구다. 정확한 version, 지원 macOS artifact URL과 SHA-256은 `tools/script-verification/dependencies/tools.lock`만 정의하고, 검사 옵션과 대상은 `tools/script-verification/config/verification.conf`만 정의한다.

## 준비와 검증 분리

도구 준비는 네트워크와 `.build/` 쓰기가 허용된 명시적 명령에서만 수행한다.

```sh
./tools/script-verification/bin/prepare-tools.sh
```

준비된 실행 파일, 다운로드 파일, 압축 해제 파일과 cache는 모두 `tools/script-verification/.build/` 안에 두며 Git에서 추적하지 않는다. 공용 검증은 이 경계를 읽기만 하고 도구를 자동으로 내려받거나 교체하지 않는다.

```sh
./tools/script-verification/bin/run.sh
```

도구가 없거나 version 또는 checksum이 lock과 다르면 검증은 실패하며 준비 명령을 복구 조치로 안내한다.

## Version 갱신

1. upstream의 안정 release와 macOS arm64/x86_64 artifact를 확인한다.
2. artifact URL과 upstream이 게시한 SHA-256을 lock에서 함께 갱신한다.
3. 기존 `.build/`를 지운 뒤 준비 명령을 다시 실행한다.
4. 두 실행 파일의 version과 checksum, 공용 검증 결과를 확인한다.
5. lock, 검증 설정과 이 문서를 하나의 논리적 변경으로 검토한다.

불완전 다운로드나 checksum 불일치가 발생하면 준비 명령은 사용 가능한 `bin/` 파일을 교체하지 않는다. 복구하려면 `.build/`만 제거하고 다시 준비한다.
