# Target과 소스 폴더

[Git It iOS 네이밍 컨벤션](../naming.md)의 규칙 문서입니다.

Tuist target 이름은 빌드 그래프에서 소속 패키지를 식별해야 하므로 필요한 패키지 문맥을
포함할 수 있습니다. 반면 `sources/Projects/<패키지>/` 아래의 source·test 폴더는 이미
패키지 문맥 안에 있으므로 target 이름의 패키지 접두어를 반복하지 않고 역할만 사용합니다.
예를 들어 `InfrastructureExample`과 `InfrastructureExampleTests` target의
source·test 폴더는 각각 `Example/`, `Tests/Example/`으로 둡니다.

이 이름 관계를 실제 폴더 경로와 Tuist 매니페스트에 적용하는 절차는
[디렉터리·파일 컨벤션 — 소스 루트](../directory-file.md#3-소스-루트)과
[디렉터리·파일 컨벤션 — Tuist 매니페스트와의 일치](../directory-file/tuist-manifest.md)이 소유합니다.
