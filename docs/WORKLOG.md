# 작업 기록

## 2026-11-07 — 포크 개발 준비 및 Ollama 연동 조사

### 수행
- 포크 저장소 `hjw831/Total-War-Mods-Translator-AI` 확인
- 개발 기반 문서 PR #1 병합 확인 (merge commit: `e3cd57458d2a07d51f2f536e3f65b2b9e09138db`)
- 기본 브랜치 `main`에서 Provider/서비스/설정/DB 모델 구조 재조사
- 작업 브랜치 `feature/ollama-provider` 생성

### 확인된 핵심 통합 지점
- Provider 계약: `lib/services/llm/providers/i_llm_provider.dart`
- Provider 등록: `lib/services/llm/llm_provider_factory.dart`
- 번역 호출 및 API 키 게이트: `lib/services/llm/llm_service_impl.dart`
- 모델 DB/관리: `llm_provider_models`, `LlmModelManagementService`
- 설정 UI와 연결 테스트: `llm_providers_tab.dart`, `settings_providers.dart`
- DB 마이그레이션 등록: `migration_registry.dart`
- 모델 ID 교차 검증: `LlmModelValidator`

### 중요한 발견
Provider만 추가하면 실제 앱에서는 사용할 수 없다. 서비스 계층이 빈 API 키를 먼저 차단하며, 설정 연결 테스트도 기존 5개 Provider와 API 키가 존재한다는 가정을 갖고 있다. 모델 선택 UI는 DB에 저장된 모델 목록을 사용하므로 Ollama 모델의 DB 공급도 필요하다.

### 구현 결정
- 첫 구현은 Ollama native `/api/chat` 비스트리밍 요청으로 제한한다.
- 기본 서버 주소는 `http://127.0.0.1:11434`.
- API 키 없이 호출할 수 있도록 Ollama만 서비스 인증 게이트를 통과시킨다.
- 초기에는 모델 자동 다운로드, 자동 라우팅, 스트리밍, 범용 OpenAI 호환 서버를 구현하지 않는다.
- DB 마이그레이션과 설정 UI를 포함해 실제 사용 가능한 단위로 통합한다.

### 검증 상태
- GitHub 원격 코드/구조 검토만 수행.
- 로컬 Windows Flutter SDK, Ollama 프로세스 및 모델을 이 실행 환경에서 직접 확인하지 못함.
- Flutter analyze/test/build는 아직 실행하지 않음.
- 앱 소스 변경은 아직 없음. 현재 브랜치에는 계획 문서 업데이트만 반영 예정.

### 다음 작업
1. OllamaProvider 비스트리밍 구현 및 단위 테스트
2. Factory/서비스 계층의 키 없는 Provider 처리
3. DB 마이그레이션과 모델 기본값 추가
4. 설정 UI에 Ollama 전용 서버/모델 설정 연결
5. 기존 Provider 인증/번역 회귀 테스트

## 2026-11-07 — Ollama 첫 통합 구현

### 구현
- `OllamaProvider`: Ollama native `/api/chat` 비스트리밍 호출, JSON 응답 파싱, 태그/플레이스홀더 보존 지침, 토큰 사용량/처리 시간 매핑, 취소/네트워크/서버 오류 처리
- Factory 기본 등록 및 reset 경로 등록
- 번역 서비스의 API 키 필수 게이트에서 Ollama만 예외 처리
- 연결 테스트에서 Ollama API 키 없이 `/api/tags`와 모델 설치 여부 확인
- DB migration priority 270: Ollama Provider 및 `qwen3.5:9b` 모델 row 등록
- Provider 설정 화면에 API 키 없는 Ollama 전용 섹션, 연결 테스트, DB 모델 목록 추가
- Ollama provider/factory 단위 테스트 작성

### 의도적으로 제한한 범위
- 기본 주소는 `http://127.0.0.1:11434` 고정
- 모델 자동 검색/추가 및 자동 다운로드 미구현
- NDJSON 스트리밍 미구현
- 원격 OpenAI 호환 엔드포인트 미구현

### 검증
- 원격 저장소 코드와 diff 검토만 수행.
- 이 실행 환경에는 Flutter/Dart 실행 환경과 사용자의 로컬 Ollama 프로세스가 없어 `flutter analyze`, `flutter test`, 실제 번역 호출은 미실행.
- 따라서 현재 상태는 구현 초안이며, PR 검토 및 CI 결과 확인이 필요함.

## 2026-11-07 — Flutter 자동 검증 기반 추가

### 수행
- Flutter/Dart 분석과 Ollama Provider 테스트를 자동 실행하는 GitHub Actions workflow 추가
- PR #3 `ci: add Flutter validation workflow` 병합
- Workflow: `.github/workflows/flutter-validation.yml`

### 검증 순서
1. Flutter stable 설치 및 의존성 설치
2. Slang / Riverpod 코드 생성
3. `flutter analyze`
4. Ollama Provider 단위 테스트
5. Provider Factory 단위 테스트

### 현재 상태
- PR #2의 새 커밋으로 자동 검증을 실행하고 결과를 확인할 예정.
- 실제 Windows Ollama 서버 연결 및 번역은 사용자 PC 환경에서 별도 확인이 필요함.

### 추가 코드 검토 — 번역 응답 완전성
- Ollama 응답에 일부 키만 포함되어도 성공으로 처리될 수 있는 경로 확인.
- 누락된 번역 키가 있으면 응답 파싱 오류로 반환하도록 수정.
- `{"translations": {...}}` 형태의 래핑된 JSON 응답도 지원.
- 부분 응답 거부 및 래핑된 응답 처리 테스트 추가.
- PR #2를 Ready for review로 전환해 자동 검증 대상에 포함.

## 2026-11-07 — Ollama 설치 모델 동기화

### 구현
- Ollama native `/api/tags`를 통해 설치된 모델 태그를 조회하는 기능 추가
- 응답 모델명을 중복 제거하고 정렬해 반환
- 기존 DB 모델은 그대로 두고, 새 모델만 중복 없이 등록하는 관리 서비스 메서드 추가
- 새로 발견한 모델은 기본 비활성으로 등록해 사용자가 선택하도록 함
- 기존 모델의 활성화/기본값/보관 상태는 덮어쓰지 않음
- 설정 화면에 `Sync installed models` 버튼 추가
- Ollama 연결 테스트는 특정 모델 활성화 여부와 분리해 서버 연결만 검사하도록 조정

### 테스트
- Ollama 설치 모델 목록 파싱/중복 제거/오류 응답 테스트 추가
- 새 모델 등록 및 기존 모델 설정 보존 테스트 추가
- Flutter validation workflow에 모델 관리 테스트 추가

### 범위
- Ollama 모델 다운로드/삭제는 수행하지 않음
- 서버 주소는 여전히 기본 loopback 주소로 고정
- 실제 Ollama 서버 및 Flutter 테스트 결과는 자동 실행 기록을 확인한 뒤 업데이트

## 2026-11-07 — Ollama 모델 ID 검증 예외

### 발견
- 공통 모델 검증기는 `gpt`, `claude`, `deepl` 접두어를 각 Provider 전용으로 간주한다.
- Ollama는 모델 실행 런타임이므로 `gpt-oss:20b`처럼 다른 공급자 계열의 모델 이름도 정상적으로 사용할 수 있다.
- 기존 규칙을 그대로 적용하면 Ollama에 설치된 일부 모델이 앱 DB에 등록되지 않을 수 있다.

### 조치
- Ollama Provider에 한해 공급자 계열 접두어 검사를 건너뛰도록 수정.
- 공통 모델 검증의 빈 Provider/빈 모델 ID 검사는 계속 유지.
- Repository 통합 테스트에 `gpt-oss:20b` 등록 케이스 추가.
- Flutter validation workflow에 Repository 테스트 실행 단계 추가.

## 2026-11-07 — Ollama 모델 동기화 및 검증 보완 병합

### 병합
- PR #2 — Ollama 비스트리밍 Provider: `90a10409e93796fab55fc060058b112149b93188`
- PR #3 — Flutter validation workflow: `c2327702845c7cbd96bc540478e68e089c5dfc4e`
- PR #4 — 설치 모델 동기화: `7c524c6869d082a35deeb2bd6f5fed5254914b66`
- PR #5 — Ollama 제3자 모델 ID 허용: `6441d68709dd36f055757fd6ab5d1abc369c8a9b`

### 검증 상태
- Ollama Provider, 설치 모델 조회, 모델 DB 등록, 공급자별 모델명 검증에 대한 단위/통합 테스트를 추가했다.
- GitHub connector에서 해당 PR head의 workflow 실행 결과를 확인하지 못했다. 테스트 통과로 간주하지 않는다.
- 이 실행 환경에는 Flutter/Dart SDK가 없어 직접 분석/테스트하지 못했다.
- Windows Ollama 연결 및 실제 번역은 별도 실행 검증이 남아 있다.

### 현재 다음 단계
- 실제 앱에서 Ollama 서버 연결, 설치 모델 동기화, 모델 활성화, 짧은 번역을 순서대로 검증한다.
- 사용자 지정 Base URL은 실제 사용 필요성이 확인되면 별도 작은 기능으로 진행한다.


## 2026-11-09 — Windows 격리 테스트판 준비

### 수행
- 최신 `main`의 Ollama 구현/문서 상태 확인. PR #1~#5는 모두 병합 완료로 개발 인덱스에 기록되어 있다.
- `feature/windows-isolated-test-build` 브랜치를 `main`에서 생성.
- `docs/WINDOWS_ISOLATED_TEST_BUILD.md` 작성.
- Windows 플랫폼 폴더가 저장소에 없고, 현재 디버그 데이터 경로가 원본 설치판과 공유되며, Inno Setup ID가 원본 값과 같다는 위험을 확인했다.

### 안전성 결정
- 기존 설치판과 원본 사용자 데이터는 그대로 둔다.
- 테스트판 전용 AppData 경로를 강제하고, DB/config/log/cache 및 secure storage를 분리한다.
- 테스트판은 우선 별도 ZIP으로 배포한다. 원본과 동일한 설치 프로그램 ID를 재사용하지 않는다.
- 격리 플래그가 없는 기존 빌드의 데이터 경로는 변경하지 않는다.

### 아직 하지 않은 작업
- Windows runner 생성 및 앱 식별자 분리
- secure storage 네임스페이스 조사/분리
- 데이터 경로 격리 코드와 테스트
- 수동 Windows 빌드 workflow 및 ZIP artifact
- 실제 Windows 실행/Ollama 번역 검증

### 다음 순서
1. secure storage 초기화 지점과 Windows credential key namespace 확인
2. compile-time 격리 플래그 및 AppData 경로 구현/테스트
3. Windows runner/제품 식별자 추가
4. 수동 Windows 빌드 및 ZIP artifact workflow 구현
5. 빌드 산출물 검사 후 PR 준비


## 2026-11-09 — Windows 테스트판 데이터 경로 격리 1차 구현

### 저장소 식별
- 대상 저장소: `hjw831/Total-War-Mods-Translator-AI`
- 작업 브랜치: `feature/windows-isolated-test-build`
- 기준 브랜치: `main`
- 이 작업은 TWMT 번역기 포크에만 해당하며 Total War 모드 프로젝트나 RunningShoeMileage와 혼합하지 않는다.

### 조사
- `DatabaseConfig`는 기존 Windows 디버그 실행에서 원본 설치판과 같은 `%APPDATA%\\com.github.slavyk82\\twmt` 경로를 사용할 수 있었다.
- `LoggingService`는 `getApplicationCacheDirectory()`를 직접 조회해 중앙 경로 정책을 우회하고 있었다.
- `LlmServiceLocator`는 `FlutterSecureStorage(WindowsOptions(useBackwardCompatibility: false))`를 사용한다.
- 현재 lockfile의 `flutter_secure_storage_windows`는 3.1.2다. Windows 구현은 application support directory에 암호화된 파일을 저장하므로 DB 경로만 바꾸면 secure storage는 분리되지 않는다.
- `shared_preferences`도 Windows runner의 앱 식별자/경로와 함께 검증해야 한다.
- 구형 secure-storage 호환 경로 자동 이전은 `useBackwardCompatibility: false`로 비활성화된 상태이며, 이 정책을 유지한다.

### 구현
- `DatabaseConfig.isIsolatedTestBuild` compile-time define 추가: `TWMT_ISOLATED_TEST_BUILD`.
- 격리 빌드는 Windows에서 `%APPDATA%\\TWMT_AI_Test`를 전용 루트로 사용.
- APPDATA 누락 또는 비-Windows 환경에서는 원본 경로로 fallback하지 않고 오류 발생.
- DB/config/log/cache 경로를 격리 루트 아래로 모음.
- `LoggingService`가 `DatabaseConfig.getLogsDirectory()`를 사용하도록 변경.
- `test/config/isolated_database_config_test.dart`에 경로 계산/빈 경로 거부 테스트 추가.
- `.github/workflows/flutter-validation.yml`에 신규 테스트 실행 단계 추가.
- 개발 인덱스와 격리 빌드 계획 문서 갱신.

### 검증 상태
- GitHub 파일 업데이트 성공 확인.
- 아직 Flutter SDK에서 `flutter analyze` 또는 테스트를 실제 실행하지 않았다.
- CI는 PR 생성 후 실행되도록 연결했으며 현재 통과 여부는 미확인.
- Secure storage/shared_preferences는 W2에서 Windows runner의 CompanyName/ProductName을 원본과 분리한 뒤 실제 파일 경로를 확인해야 한다.
- Windows runner가 저장소에 아직 없으므로 현재 Windows 실행 파일은 만들지 않았다.

### 다음 업무
1. Flutter Windows runner를 생성하고 원본과 다른 CompanyName/ProductName 및 실행 파일 식별자를 설정한다.
2. Secure storage와 shared_preferences가 별도 application support 경로를 사용하는지 확인한다.
3. 테스트판 전용 ZIP 산출 workflow를 추가한다.
4. Windows 환경에서 테스트판/기존 앱을 함께 실행해 DB, 설정, API 키가 서로 보이지 않는지 확인한다.

- 추가 조치: 격리 define이 켜진 실행 파일은 창 제목과 앱 제목을 `TWMT AI Test`로 표시한다.
- 테스트 명령은 격리 define 없이 실행해야 한다. define은 Windows 테스트 앱 빌드에만 전달하며, 비-Windows 환경에서는 안전하게 거부한다.

- W2 준비: Windows runner의 VERSIONINFO `CompanyName=TWMT_AI`, `ProductName=TWMT AI Test`, EXE `TWMT_AI_Test.exe`를 수동 빌드 workflow에서 설정한다.
- 조사 결과 `path_provider_windows`는 VERSIONINFO의 `CompanyName\\ProductName`으로 Application Support 경로를 만들며, `flutter_secure_storage_windows`와 `shared_preferences_windows`는 이 경로를 사용한다. 따라서 이 runner 식별자 분리는 두 저장소 모두를 원본과 분리하는 데 필요하다.
- `.github/workflows/windows-isolated-test-build.yml` 추가. `workflow_dispatch` 전용이며, CI 임시 공간에서 Windows runner를 생성하고 격리 식별자를 적용한 뒤 Release ZIP artifact를 만드는 구조다.
- 이 workflow는 아직 실행하지 않았다. 빌드 산출물/경로/실행은 검증 전이다. 기존 Inno Setup 설정과 설치판은 변경하지 않는다.

- 프로젝트 혼동 방지: `docs/DEVELOPMENT_INDEX.md`에 새 채팅 재개 체크리스트를 추가했다. 작업 전 저장소명/브랜치/업무일지를 확인하고, 다른 GPT 프로젝트의 코드나 업무기록을 섞지 않도록 명시했다.
