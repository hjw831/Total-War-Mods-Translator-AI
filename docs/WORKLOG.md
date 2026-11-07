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
