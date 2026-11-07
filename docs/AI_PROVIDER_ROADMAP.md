# AI Provider 확장 로드맵

## 현행 구조 조사 결과

기준 브랜치 `main`에서 다음 구조를 확인했다.

- `lib/services/llm/providers/i_llm_provider.dart`: Provider 공통 계약
- `lib/services/llm/llm_provider_factory.dart`: Provider 등록 및 조회
- `lib/services/llm/llm_service_impl.dart`: API 키 확인, 번역 실행, 스트리밍 진입점
- `lib/services/llm/models/llm_provider_config.dart`: Provider 기본 URL과 제한 설정
- `lib/models/domain/llm_provider_model.dart`: DB에 저장되는 모델 레코드
- `lib/services/llm/llm_model_management_service.dart`: 모델 선택/활성화 관리
- `lib/providers/settings_providers.dart`: Provider별 API 키 로드, 연결 테스트, 설정 저장
- `lib/features/settings/widgets/llm_providers_tab.dart`: Provider 설정 UI
- `lib/services/database/migrations/migration_registry.dart`: DB 마이그레이션 등록

현재 기본 Provider는 Anthropic, OpenAI, DeepL, DeepSeek, Gemini다. 모델 목록은 UI에서 임의로 생성하지 않고 DB 마이그레이션으로 공급한다.

## Ollama 연동에서 확인된 필수 변경점

단순히 Provider 클래스를 Factory에 추가하는 것만으로는 작동하지 않는다.

1. `LlmServiceImpl.translateBatch`와 `translateStreaming`은 API 키가 비어 있으면 Provider 호출 전에 중단한다. Ollama만 키 없이 통과하도록 Provider capability 기반 예외 처리가 필요하다.
2. `LlmProviderSettings.testConnection`은 Provider를 명시적으로 5개만 허용하고, 키와 활성 모델을 필수로 확인한다. Ollama는 키 대신 로컬 서버 연결과 모델 존재 여부를 검사해야 한다.
3. `llm_provider_models`는 DB 모델 목록이다. Ollama를 UI에 노출하려면 Provider 레코드와 초기 모델 레코드를 마이그레이션으로 공급해야 한다.
4. `LlmModelValidator`는 현재 GPT/Claude/DeepL 접두어 위주로 교차 Provider를 검사한다. Ollama 모델 이름은 자유 형식이므로 기존 규칙을 깨지 않고 검증을 통과해야 한다.
5. 기존 설정 탭은 Provider별 API 키 입력을 전제로 한다. Ollama 전용 섹션은 API 키 필드를 재사용하지 않고 서버 주소, 모델 연결 테스트를 보여야 한다.
6. 스트리밍은 기존 Provider가 SSE 형식을 사용한다. Ollama native API의 NDJSON 응답은 별도 파서가 필요하다. 첫 구현에서는 스트리밍을 지원한다고 선언하지 않고 비스트리밍부터 안정화한다.

## 단계별 구현 범위

### 0 — 개발 기반 (완료)
- 포크 운영 규칙과 개발 환경 문서
- Provider 구조 조사
- 구현 전 확인 항목과 테스트 기준 정의

### 1 — Ollama 비스트리밍 Provider (기본 연결 구현 완료, 검증 대기)
- 별도 `OllamaProvider` 구현 및 Factory 등록 — 완료
- 기본 주소 `http://127.0.0.1:11434`
- Ollama native `/api/chat` 사용 — 완료
- `stream: false`, JSON 응답 형식 요청 — 완료
- API 키 없이 번역 요청 — 서비스 인증 게이트 예외 처리 완료
- 기존 태그/플레이스홀더 보존 프롬프트와 JSON 파싱 규칙 유지
- 모델명은 요청의 `modelName` 사용 — 완료
- 연결 상태 및 오류 매핑 테스트 — 단위 테스트 작성, 실행 대기
- 스트리밍은 비활성화 — 완료

### 2 — 설정 및 모델 관리 연결 (초기 연결 완료, 로컬 주소/모델 목록 개선은 후속)
- DB 마이그레이션으로 Ollama Provider 및 `qwen3.5:9b` 시작 모델 레코드 추가 — 완료
- Ollama 모델명 수동 입력/등록 흐름
- 로컬 서버 주소 저장 및 연결 확인
- 설정 UI에 API 키 없는 Ollama 섹션, 기본 서버 주소 안내, 모델 목록 및 연결 테스트 추가 — 완료
- 키 없는 Provider를 허용하는 서비스 계층 처리 — 완료
- 기존 원격 Provider 설정/인증 회귀 테스트

### 3 — 선택적 확장
- Ollama 모델 목록 자동 조회 및 새 모델 등록
- 필요할 경우 Ollama NDJSON 스트리밍
- 사용자 지정 Base URL 및 OpenAI 호환 서버
- 원격 OpenAI 호환 서버는 별도 보안/개인정보 안내와 함께 다룸

## 첫 구현에서 하지 않을 것

- 모델 자동 다운로드 또는 Ollama 설치 자동화
- 자동 다중 모델 라우팅/순차 호출
- AI 번역 품질 점수화 및 자동 재번역
- 프롬프트 편집기 전면 개편
- 번역 UI 전면 재설계
- 원본 팩 처리 파이프라인 수정

## 완료 기준

1. Ollama 미실행/실행 상태를 구분해 설명한다.
2. API 키 없이 로컬 모델 번역이 성공한다.
3. JSON 객체와 원본 키가 보존되고 번역 값만 결과로 반환된다.
4. 게임 태그와 템플릿 플레이스홀더 보존 지침을 유지한다.
5. 취소 및 네트워크 오류가 기존 오류 계약을 따른다.
6. 스트리밍 미지원 상태가 명시적이며 잘못된 성공 신호를 주지 않는다.
7. 기존 원격 Provider 테스트와 번역 기능에 회귀가 없다.
