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
