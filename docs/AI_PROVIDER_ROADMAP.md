# AI Provider 확장 로드맵

## 현행 코드 조사 결과

기준 브랜치 `main`의 다음 코드를 확인했다.

- `lib/services/llm/providers/i_llm_provider.dart`: Provider 공통 계약
- `lib/services/llm/llm_provider_factory.dart`: Provider 인스턴스 등록 및 조회
- `lib/services/llm/i_llm_service.dart`: 번역 서비스 계약
- `lib/services/llm/models/llm_provider_config.dart`: 정적 URL, 토큰/요청 제한, 재시도 설정
- `lib/services/llm/providers/openai_provider.dart`: OpenAI Chat Completions 구현
- `lib/services/llm/providers/deepseek_provider.dart`: OpenAI 호환 형식을 사용하는 별도 구현
- `lib/services/llm/providers/gemini_provider.dart`: Gemini 전용 API 구현
- `lib/services/llm/providers/anthropic_provider.dart`: Anthropic 전용 API 구현

Factory에는 Anthropic, OpenAI, DeepL, DeepSeek, Gemini가 이미 등록되어 있다. 따라서 이 포크의 첫 작업은 기존 Provider를 다시 만드는 것이 아니라, 현재 기능과 설정 흐름을 보존하며 확장하는 것이다.

## 중요한 구조적 제약

현재 `ILlmProvider`의 요청 메서드는 `String apiKey`를 받으며 OpenAI Provider는 고정된 base URL과 Bearer 인증을 사용한다. Ollama를 단순히 OpenAI Provider의 URL만 바꿔 연결한다고 끝나지 않는다.

구현 전에 확인할 항목:
- 로컬 인증키가 비어 있을 때 기존 서비스 계층이 이를 허용하는지
- 인증 헤더를 생략할 수 있는지
- base URL과 모델을 사용자 설정에서 안전하게 전달할 수 있는지
- 모델별 JSON 출력 지원, max token 파라미터 차이를 처리할 수 있는지
- 스트리밍 SSE 파서가 Ollama 호환 응답과 맞는지
- Provider 설정 및 모델 목록이 DB에 어떻게 저장되는지

## 단계별 범위

### 0 — 개발 기반 (현재)
- 포크 운영 규칙과 개발 환경 문서
- Provider 구조 조사
- 구현 전 확인 항목과 테스트 기준 정의

### 1 — Ollama 최소 연동
- 별도 `ollama` Provider 코드로 등록
- 기본 로컬 주소는 `http://127.0.0.1:11434`
- 모델 선택은 우선 사용자가 입력하거나 기존 모델 설정을 활용
- API 키 없이 번역 요청 가능
- 최소 번역 요청, 오류 처리, 연결 상태 테스트
- 첫 단계에서는 모델 자동 다운로드, 자동 라우팅, 다중 서버를 구현하지 않음

### 2 — 설정 화면 연결
- Ollama 주소 및 모델 입력
- 연결 확인과 오류 메시지
- 기존 API 키 보관 방식과 설정 UI를 최대한 재사용
- 설정 마이그레이션 필요 여부 검토

### 3 — 범용 OpenAI 호환 서버
- 사용자 지정 Base URL, 모델, 선택적 API 키
- 요청 파라미터 및 JSON 모드 호환성
- 로컬 서버와 외부 호환 API를 구분하는 보안/개인정보 안내

### 4 — 무료·유료 온라인 Provider 사용성 개선
- Gemini 기존 구현의 모델/쿼터/오류 처리 확인
- Claude 및 OpenAI 공식 API 연동은 기존 기능 유지
- 무료 웹 구독 계정을 제3자 앱의 API 키처럼 사용하는 방식은 구현하지 않음
- 무료 티어의 한도·가격·데이터 처리 정책은 실제 적용 시점의 공식 문서로 확인

## 첫 구현에서 하지 않을 것

- 자동으로 여러 모델을 순차 호출하는 번역 파이프라인
- AI 번역 품질 점수화 및 자동 재번역
- 프롬프트 편집기 전면 개편
- 번역 UI 전면 재설계
- 데이터베이스 구조의 선제적 대규모 변경
- 원본 팩 처리 파이프라인 수정

## 첫 기능 완료 기준

1. Ollama 미실행/실행 상태를 구분해 사용자에게 설명한다.
2. API 키 없이 로컬 모델 번역이 성공한다.
3. 번역 결과 구조와 기존 JSON/태그 보존 규칙이 유지된다.
4. 취소 및 네트워크 오류가 기존 오류 처리 계약을 따른다.
5. 스트리밍을 지원한다고 표시하기 전 실제 테스트로 확인한다.
6. 기존 원격 Provider 테스트와 번역 기능에 회귀가 없다.
