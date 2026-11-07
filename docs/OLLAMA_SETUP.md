# Ollama 로컬 번역 사용법

## 기본 조건

- Windows에서 Ollama가 실행 중이어야 한다.
- 기본 API 주소는 `http://127.0.0.1:11434`다.
- Ollama는 로컬 호출이므로 API 키가 필요하지 않다.
- 현재 Provider는 비스트리밍 JSON 번역만 지원한다.

## 모델 확인

PowerShell에서 다음 명령으로 설치된 모델을 확인한다.

```powershell
ollama list
```

시작 모델이 없다면 설치한다.

```powershell
ollama pull qwen3.5:9b
```

Ollama가 실행 중인지 확인하려면 다음을 호출한다.

```powershell
Invoke-RestMethod http://127.0.0.1:11434/api/tags
```

응답의 `models` 목록에 실제 모델 태그가 표시되어야 한다.

## 앱에서 설정

1. TWMT의 Settings → LLM Providers 탭을 연다.
2. Ollama (Local) 섹션을 펼친다.
3. Test local connection을 눌러 Ollama 서버가 응답하는지 확인한다.
4. Sync installed models를 눌러 현재 설치된 Ollama 모델을 앱의 모델 목록에 등록한다.
5. 새로 등록된 모델은 기본적으로 비활성 상태이므로, 사용할 모델을 활성화한다.
6. 원하는 모델 행의 기본 모델 표시(별표)를 선택해 Ollama를 활성 Provider로 지정한다.
7. 번역 화면에서 해당 모델을 선택해 테스트한다.

## 오류 확인

- 연결 실패: Ollama 데스크톱 앱이 실행 중인지 확인한다.
- 모델 없음: `ollama list`의 실제 태그와 앱에 등록된 모델 ID가 일치하는지 확인한다.
- 모델이 목록에 없음: Sync installed models를 다시 눌러 Ollama에 설치된 모델을 가져온다.
- 모델 목록에 있는데 번역이 실패함: 해당 모델이 실제로 설치되어 있는지 `ollama list`로 확인한다. 동기화는 새 모델을 추가하지만 기존 모델을 자동 삭제하거나 비활성화하지 않는다.
- 번역 실패: 앱 로그에서 Ollama HTTP 상태와 JSON 파싱 오류를 확인한다.

## 현재 제한

- 서버 주소는 기본 loopback 주소로 고정되어 있다.
- 설치된 모델 검색 및 앱 목록 등록은 지원한다.
- 모델 자동 다운로드는 지원하지 않는다.
- 동기화로 새로 등록된 모델은 기본 비활성 상태이며, 사용자가 직접 활성화해야 한다.
- 스트리밍은 지원하지 않는다.
- 원격 Ollama 서버나 OpenAI 호환 서버 주소 변경은 후속 작업이다.
