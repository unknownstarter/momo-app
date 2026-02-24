# AI 비디오 생성 기술 현황 — 숏폼 드라마 제작 관점 (2026년 2월)

> 리서치 일자: 2026-02-20
> 목적: AI로 1-3분 에피소드 숏폼 드라마 제작이 **지금 당장** 가능한지 파악

---

## 1. AI 비디오 생성 도구 — 현재 상태

### 도구별 상세 분석

#### Sora 2 (OpenAI)
- **품질**: 가장 뛰어난 스토리텔링, 감정 표현, 대화 장면. 시네마틱 퀄리티
- **해상도**: 480p ~ 1080p (플랜별)
- **영상 길이**: 최대 20-35초/클립 (Pro 기준)
- **가격**:
  - API: $0.10/초 (720p) ~ $0.50/초 (1024p Pro)
  - **1분 영상 비용: $6~$30**
  - ChatGPT Plus ($20/월): 무제한 480p
  - ChatGPT Pro ($200/월): 크레딧제, 1080p 가능
- **강점**: 내러티브 코히어런스, 감정 깊이, 대화 장면
- **약점**: 짧은 클립 길이, 높은 가격

#### Veo 3 / 3.1 (Google DeepMind)
- **품질**: 물리적 리얼리즘 최상위. **네이티브 오디오 생성** (대화+효과음+환경음 동시 생성)
- **해상도**: 720p ~ 2K
- **영상 길이**: 최대 60초/클립
- **가격**:
  - API: Veo 3.1 Fast $0.15/초, Standard $0.40/초, Full $0.75/초
  - **1분 영상 비용: $9~$45 (오디오 포함)**
  - Google AI Pro ($19.99/월): Veo 3 Fast 하루 3회
  - Google AI Ultra ($249.99/월): 풀 액세스
- **강점**: **업계 유일 네이티브 립싱크 오디오 생성**, 자연스러운 바디랭귀지
- **약점**: 가장 비쌈, Ultra 플랜 필요

#### Kling 2.6 (Kuaishou / 쾌수)
- **품질**: 시네마틱 수준의 비주얼, 가격 대비 최고 품질
- **해상도**: 720p ~ 1080p
- **영상 길이**: 최대 3분/클립 (경쟁사 중 최장)
- **가격**:
  - API: $0.07~$0.14/초
  - **1분 영상 비용: ~$1.04~$1.27**
  - 서드파티 (Fal.ai): ~$0.90/10초 클립
  - 구독: $6.99~$180/월
- **강점**: **가성비 최강**, 긴 클립 길이 (3분), 안정적 품질
- **약점**: 다중 캐릭터 장면에서 일관성 약함

#### Runway Gen-4 / Gen-4.5
- **품질**: 스타일라이즈드 창작에 최강. **캐릭터 일관성 기능 내장**
- **해상도**: 720p ~ 4K (Pro 이상)
- **영상 길이**: 최대 40초/클립
- **가격**:
  - Gen-4 Turbo: 5크레딧/초, Gen-4.5: 25크레딧/초
  - Standard ($12/월): 625크레딧
  - Pro ($28/월): 2,250크레딧
  - Unlimited ($76/월): 무제한 (relaxed 모드)
  - **1분 Gen-4 Turbo: ~300크레딧 = Pro 1회 분량 정도**
- **강점**: **Reference 기능으로 캐릭터 고정 가능**, Act-Two 모캡, Aleph 인비디오 편집
- **약점**: 짧은 클립 길이 (40초)

#### Seedance 2.0 (ByteDance)
- **품질**: **2026년 2월 기준 가장 화제**. 할리우드급 리얼리즘으로 논란 중
- **해상도**: 720p ~ 2K
- **영상 길이**: 최대 15초/클립 (스티칭으로 연장 가능)
- **가격**:
  - 무료 체험: 가입 시 3회 무료 생성
  - Jimeng (Dreamina) 구독: ~$9.60/월 (69 RMB)
  - API: $0.10~$0.80/분 (해상도별)
  - 서드파티: $0.05/요청까지 가능
- **강점**: **90%+ 사용 가능 결과물 비율**, 멀티모달 입력, 매우 저렴
- **약점**: 저작권 논란 중, 15초 제한, 중국 플랫폼 종속

#### Pika 2.5
- **품질**: 빠른 렌더링, 74% 사용 가능 결과물
- **해상도**: 720p ~ 1080p
- **영상 길이**: 1~10초
- **가격**: 무료(80크레딧) ~ $95/월
- **강점**: Pikaformance (립싱크 아바타), Pikaframes (키프레임 제어)
- **약점**: 짧은 클립, 드라마 제작용으로는 부족

#### Hailuo / MiniMax 2.3
- **품질**: 캐릭터 미세 표정 우수, 아트스타일 다양 (수묵화, 게임CG 등)
- **해상도**: 720p ~ 1080p
- **가격**: Standard $9.99/월 (1000크레딧), Unlimited $94.99/월
- **강점**: 가성비 좋음, 애니메이션/일러스트 스타일에 강점
- **약점**: 리얼리즘에서 Sora/Veo에 뒤처짐

#### Luma Dream Machine (Ray3 / Ray3.14)
- **품질**: 시네마틱 모션, 네이티브 1080p
- **해상도**: 1080p 네이티브
- **가격**: Lite $9.99/월 ~ Unlimited $94.99/월
- **강점**: Ray3.14가 4배 빠르고 3배 저렴해짐
- **약점**: 드라마 특화 기능 부족

### 도구별 1분 영상 비용 비교표

| 도구 | 1분 비용 (API) | 최대 클립 길이 | 캐릭터 일관성 | 드라마 적합도 |
|------|--------------|-------------|------------|-----------|
| **Kling 2.6** | **~$1.04** | 3분 | 중 | ★★★★ |
| **Seedance 2.0** | **~$0.10~$0.80** | 15초 | 중 | ★★★☆ |
| **Hailuo 2.3** | ~$1~2 | 불명 | 중 | ★★★☆ |
| **Runway Gen-4** | ~$3~5 (크레딧) | 40초 | **상 (Reference)** | ★★★★☆ |
| **Sora 2** | ~$6~30 | 35초 | 중상 | ★★★★ |
| **Veo 3.1** | ~$9~45 | 60초 | 중상 | ★★★★★ |
| **Luma Ray3** | ~$3~5 | 불명 | 중 | ★★★ |
| **Pika 2.5** | ~$2~4 | 10초 | 중하 | ★★ |

---

## 2. 캐릭터 일관성 문제 — 핵심 과제

### 현재 상태: "해결 중이지만 완벽하지 않다"

캐릭터 일관성은 AI 드라마 제작의 **가장 큰 기술적 장벽**이다.

### 도구별 솔루션

#### Runway Gen-4 Reference (가장 진보됨)
- 레퍼런스 이미지를 업로드하면 동일 캐릭터를 다른 장면에 배치
- entity-level encoding으로 얼굴, 의상, 헤어스타일 등 보존
- reference strength 조절로 identity lock ↔ motion freedom 밸런스
- **현재 가장 실용적인 캐릭터 일관성 솔루션**

#### ByteDance StoryMem (연구 단계)
- 키프레임을 메모리 뱅크에 저장, 새 장면 생성 시 참조
- 여러 씬에 걸쳐 시각적 코히어런스 유지
- 아직 Seedance에 완전 통합되지 않음

#### SenseTime Seko 2.0 (가장 실전적)
- "캐릭터 디지털 ID 바인딩 + 다각도 프리셋 + 스타일 락킹"
- **100에피소드에 걸쳐 캐릭터/배경/소품 일관성 유지**
- 모션 코믹/애니메이션 스타일에 특화

#### LTX Studio (워크플로우 레벨)
- Persistent Character Profiles: 나이, 인종, 헤어, 의상, 얼굴 디테일 한번 정의
- 모든 샷에서 동일 외모 유지
- 스크립트→스토리보드→영상 전체 파이프라인 지원

### 실전 워크플로우 (Best Practice)

1. **캐릭터 디자인 먼저** — 비디오 모델에 캐릭터 발명과 애니메이션을 동시에 시키지 말 것
2. **레퍼런스 이미지 갤러리** — 캐릭터별 "정규" 프레임 세트 유지
3. **프레임 체이닝** — 이전 클립의 마지막 프레임을 다음 클립의 레퍼런스로 사용
4. **상세 프롬프트** — "캐주얼 복장" 대신 "파란 데님 재킷, 롤업 소매, 흰 티셔츠, 검정 진"
5. **Reference Strength 조절** — 첫 패스에서 높게(ID 고정), 이후 약간 낮춰(모션 자연스럽게)

### 현실적 평가
- **단일 장면 내**: 거의 완벽하게 유지 가능
- **같은 에피소드 내 여러 장면**: Runway Reference나 LTX Studio로 80~90% 일관성 가능
- **수십 에피소드에 걸쳐**: Seko 2.0 (모션 코믹 스타일) 외에는 아직 어려움
- **다중 캐릭터 상호작용**: 현재 기술의 가장 큰 약점. 2인 이상 장면은 품질 급격히 저하

---

## 3. AI 음성/더빙

### ElevenLabs (업계 리더)
- **한국어 지원**: 32개 언어 중 하나로 포함. eleven_v3 모델로 한국어 지원
- **품질**: 감정 표현과 리얼리즘에서 업계 최고. Audio Tags로 감정/톤 정밀 제어 가능
- **가격**:
  - Creator: ~$0.30/분
  - Pro: ~$0.24/분
  - Scale: ~$0.18/분
  - Business: ~$0.12/분
  - Flash 모델: ~$0.09~$0.15/분 (저렴한 대안)
- **1시간 분량 비용**: $7.20~$18.00
- **감정 표현**: Audio Tags로 기쁨/슬픔/분노 등 제어 가능
- **Voice Cloning**: 특정 성우 목소리 복제 가능

### PlayHT
- **한국어**: 네이티브 스피커 학습 데이터로 한국어 지원. 중국어/일본어/한국어에 강점
- **프리미엄 음성**: 영어 전용. 한국어는 레거시 인터페이스에서만 사용
- **900+ 음성, 142개 언어**

### LOVO AI
- **한국어**: 100+ 언어 지원 중 포함
- **약점**: 프리미엄 음성이 영어 전용. 한국어 음성은 다소 모노톤/로봇적

### Veo 3의 네이티브 오디오 (게임 체인저)
- **별도 TTS 불필요**: 영상 생성 시 대화/효과음/배경음이 동시 생성
- **립싱크**: 프레임 퍼펙트 수준의 립싱크
- **다국어 지원**: 여러 언어와 억양에서 리얼리스틱한 립싱크
- **제한**: 프롬프트 기반이므로 정확한 대사 제어가 어려울 수 있음

### 음성 비용 비교 (1분 대화 기준)

| 서비스 | 1분 비용 | 한국어 품질 | 감정 표현 |
|--------|---------|-----------|---------|
| ElevenLabs (Pro) | $0.24 | 상 | ★★★★★ |
| ElevenLabs (Flash) | $0.12 | 중상 | ★★★★ |
| PlayHT | ~$0.20 | 중상 | ★★★★ |
| LOVO AI | ~$0.15 | 중 | ★★★ |
| Veo 3 네이티브 | 영상 비용에 포함 | 불명 | ★★★★ |

---

## 4. AI 음악/사운드

### Suno
- Free: 50크레딧/일 (~10곡), 비상업적 용도
- Pro: $10/월 (2,500크레딧 ~500곡), 상업적 사용 가능
- Premier: $30/월 (10,000크레딧 ~2,000곡)
- **강점**: 보컬 포함 완전한 곡 생성

### Udio
- Free: 10곡/일
- Standard: $10/월 (1,200곡)
- Pro: $30/월 (무제한)
- **강점**: 프로페셔널 인스트루멘탈 품질

### 드라마 배경음악 비용
- 80에피소드 시리즈 전체: Suno/Udio Pro ($30/월) 하나면 충분
- **사실상 무시할 수 있는 비용**

---

## 5. 풀 파이프라인: Script -> Video

### 실제 파이프라인 (2026년 기준)

```
1. 스크립트 작성 (5분) — AI (Claude/GPT) + 인간 감수
   ↓
2. 스토리보드 생성 (10분) — LTX Studio / AI 이미지 생성
   ↓
3. 캐릭터 디자인 & 레퍼런스 이미지 생성 — Runway Gen-4 / Midjourney / FLUX
   ↓
4. 장면별 영상 생성 (15-30분) — Kling / Veo 3 / Runway / Seedance
   ↓
5. 음성 생성 & 립싱크 (10분) — ElevenLabs + 립싱크 도구
   ↓
6. 배경음악 생성 (5분) — Suno / Udio
   ↓
7. 편집 & 합성 (15-30분) — CapCut / Premiere / DaVinci
   ↓
8. 최종 검수 & 내보내기
```

**1에피소드 (1-2분) 제작 시간: 약 1~2시간** (MicroDrama AI 같은 올인원 도구 사용 시 30분)

### 올인원 플랫폼들

#### MicroDrama AI
- 아이디어 입력 → 30분 만에 완성된 숏폼 드라마 출력
- 전통 대비 **90% 비용 절감, 20배 출력량 증가**
- HD 영상 + 보이스오버 + BGM + 전환 효과 자동 생성

#### SenseTime Seko 2.0
- **100에피소드 시리즈 한 문장으로 생성 시작**
- 캐릭터/장면/소품 일관성 100에피소드에 걸쳐 유지
- 제작 시간 80-90% 단축
- "밀크티 한 잔 가격"으로 제작 가능
- **모션 코믹/애니메이션 스타일 특화** (실사가 아님)

#### LTX Studio
- 스크립트 → 스토리보드 → 캐릭터 프로필 → 영상 전체 파이프라인
- Persistent Character Profiles
- Veo 3 통합 지원
- 4K 렌더링, 동기화된 오디오+비디오

#### Genra AI
- 쓰기, 연출, 보이스, 편집 올인원
- Character Reference로 수백 개 샷에 걸쳐 얼굴 ID 유지
- 립싱크 매칭 자동 더빙
- 무료 티어 제공, 상업적 사용 허용

---

## 6. 실제 사례

### "The Sun That Fell" (2025, 중국)
- 중국 최초 AI 생성 SF 마이크로 드라마
- 30에피소드, 에피소드당 2-3분, 50+ 캐릭터, 200+ 장면
- **모든 과정 100% AI**: 장면 생성, 캐릭터 생성, 촬영, VFX
- 3개월 만에 완성
- **1,000만 뷰 달성**
- 약점: 다중 캐릭터 상호작용 장면이 가장 어려웠음

### Vigloo (한국, SpoonLabs)
- Krafton 투자 ($86M), PUBG 배틀그라운드 제작사
- **"Met a Savior in Hell", "Seoul: 2053"** — 한국 최초 풀 AI 마이크로 드라마
- 4인 팀으로 제작 (Google Imagen, ByteDance SeedDream, 자동 더빙/립싱크)
- 30분 오리지널
- 라이브액션이든 AI든 "스토리를 가장 빠르게 전달하는 것"에 집중
- 월 1편 출시 계획
- 300+ 프리미엄 드라마 보유 (2분 미만 에피소드)

### Seedance 2.0 바이럴 영상들 (2026년 2월)
- 브래드 피트 vs 톰 크루즈 격투 장면 — 2줄 프롬프트로 생성, 수백만 뷰
- 자장커 감독의 AI 단편 "Jia Zhangke's Dance"
- **할리우드 반발**: 디즈니, 파라마운트가 ByteDance에 중단 요청
- **AI 영상이 실사와 거의 구분 불가 수준에 도달했음을 증명**

### 중국 AI 드라마 산업
- AI 숏드라마 팀들이 월 20-30편 제작 (전통 대비 10배)
- 1인 제작 가능
- 비용: 10만~15만 위안/편 ($14,000~$21,000) — 전통 50만~80만 위안 대비 75% 절감

---

## 7. 하이브리드 접근법

### 접근법별 품질-비용 비율 비교

#### A. 풀 AI 실사 스타일
- **품질**: 6/10 (uncanny valley 존재, 다중 캐릭터 약함)
- **비용**: 최저 ($500~$5,000/80에피소드)
- **시간**: 최단 (1-2개월)
- **문제**: 캐릭터 일관성, uncanny valley, 복잡한 장면

#### B. AI 모션 코믹 / 만화 스타일 (추천)
- **품질**: 8/10 (uncanny valley 회피, 스타일 일관성 높음)
- **비용**: 저 ($1,000~$10,000/80에피소드)
- **시간**: 단축 (1-2개월)
- **강점**: Seko 2.0로 100에피소드 일관성 유지 가능, uncanny valley 없음
- **TikTok 트렌드**: 웹코믹/만화 변환 영상 1.55억+ 뷰

#### C. AI 배경 + 실제 배우
- **품질**: 8.5/10
- **비용**: 중 ($30,000~$80,000/80에피소드)
- **시간**: 중 (2-3개월)
- **접근**: Virtual Production 스타일. AI가 배경/VFX, 배우가 연기

#### D. AI 이미지/영상 + 인간 성우
- **품질**: 7.5/10
- **비용**: 중하 ($3,000~$15,000/80에피소드)
- **시간**: 단축 (1-2개월)
- **접근**: 영상은 AI, 음성만 전문 성우

#### E. 전통 제작 (ReelShort 스타일)
- **품질**: 9/10
- **비용**: 최고 ($150,000~$300,000/80에피소드)
- **시간**: 최장 (3-6개월)

### 아리의 추천: **B. AI 모션 코믹 / 만화 스타일**

이유:
1. **캐릭터 일관성 문제 회피** — 만화/웹툰 스타일은 일관성 유지가 훨씬 쉬움
2. **Uncanny Valley 회피** — 실사 AI는 아직 "이상한 골짜기"를 완전히 넘지 못함
3. **Seko 2.0 등 100에피소드 전용 도구 존재**
4. **비용 압도적 절감** — 전통 대비 95%+ 절감
5. **TikTok/Shorts 시장에서 이미 트렌드** — 1.55억+ 뷰의 검증된 포맷
6. **한국 웹툰 문화와 자연스러운 연결** — 한국 시장에서 만화 스타일이 거부감 없음

---

## 8. 비용 분석 — 80에피소드 시리즈 (에피소드당 1-2분)

### 전제 조건
- 총 영상 분량: 80에피소드 x 1.5분 = 120분 (2시간)
- 각 에피소드에 대화, BGM, 효과음 포함
- 여러 캐릭터 등장

### A. 풀 AI 생성 (비디오 + 음성 + 음악)

| 항목 | 도구 | 비용 |
|------|------|------|
| 스크립트 | Claude/GPT | ~$50 (API) |
| 비디오 생성 (120분) | Kling Pro | ~$125 (120분 x $1.04) |
| 비디오 생성 (120분) | Seedance API | ~$12~$96 |
| 비디오 생성 대안 | Seko 2.0 (만화스타일) | ~$50~$200 (추정) |
| 음성 (대화 60분 추정) | ElevenLabs Scale | ~$10.80 (60분 x $0.18) |
| 배경음악 | Suno Pro | $10/월 x 2개월 = $20 |
| 효과음 | Suno/무료 소스 | ~$0~$20 |
| 편집/후반작업 | CapCut Pro | $9.99/월 x 2개월 = $20 |
| **총 비용** | | **$200~$500** |

**에피소드당: $2.50~$6.25**

참고: 이것은 모든 것이 첫 시도에 성공한다고 가정한 낙관적 추정. 재생성, 수정, 시행착오 포함 시 x3~5배 예상.

**현실적 추정: $600~$2,500** (에피소드당 $7.50~$31.25)

### B. 하이브리드 (AI 이미지/비디오 + 인간 성우)

| 항목 | 비용 |
|------|------|
| 스크립트 | ~$50 (AI) + $500 (작가 감수) |
| 비디오 생성 | ~$500~$2,000 (재생성 포함) |
| 한국어 성우 (메인 3명) | ~$3,000~$6,000 |
| 보조 성우 | ~$1,000~$2,000 |
| 배경음악 | ~$50~$200 |
| 편집/후반작업 | ~$1,000~$3,000 (전문 편집자) |
| **총 비용** | **$6,000~$14,000** |

**에피소드당: $75~$175**

### C. 전통 제작 (ReelShort 스타일)

| 항목 | 비용 |
|------|------|
| 각본 | $5,000~$15,000 |
| 배우 출연료 | $20,000~$50,000 |
| 촬영 (7-10일) | $30,000~$60,000 |
| 장소 대여 | $10,000~$30,000 |
| 스태프 인건비 | $30,000~$60,000 |
| 후반작업 | $20,000~$40,000 |
| 기타 | $10,000~$30,000 |
| **총 비용** | **$150,000~$300,000** |

**에피소드당: $1,875~$3,750**

### 비용 비교 요약

| 방식 | 총 비용 | 에피소드당 | 전통 대비 절감 | 품질 | 제작 기간 |
|------|---------|----------|-------------|------|---------|
| **풀 AI** | $600~$2,500 | $7~$31 | **99%** | 6/10 | 1-2개월 |
| **하이브리드** | $6,000~$14,000 | $75~$175 | **95%** | 7.5/10 | 2-3개월 |
| **전통** | $150,000~$300,000 | $1,875~$3,750 | 기준 | 9/10 | 3-6개월 |

---

## 9. 아리의 종합 평가

### 지금 당장 가능한 것
1. **만화/모션코믹 스타일 AI 드라마**: Seko 2.0 + ElevenLabs로 100에피소드 시리즈 제작 가능
2. **5-15초 단위 AI 실사 클립**: 편집으로 연결하면 1-2분 에피소드 구성 가능
3. **AI 배경 + 실사 결합**: Virtual Production 스타일로 높은 품질 달성 가능
4. **AI 음성**: 한국어 포함, 감정 표현이 가능한 수준에 도달
5. **AI BGM**: 사실상 무료 수준으로 고품질 배경음악 생성 가능

### 아직 어려운 것
1. **실사 퀄리티 AI 드라마**: 캐릭터 일관성, uncanny valley, 다중 캐릭터 상호작용 문제
2. **완벽한 립싱크 한국어 대화**: Veo 3가 가장 근접하나 정확한 대사 제어 어려움
3. **복잡한 액션/감정 장면**: 아직 인간 연기자 수준에 미달
4. **80에피소드에 걸친 실사 캐릭터 일관성**: 만화 스타일 외에는 매우 어려움

### 전략적 시사점
1. **지금 시작해도 된다** — 만화/웹툰 스타일이라면 충분히 상업적 품질 달성 가능
2. **6개월 후면 실사도 가능해질 수 있다** — Seedance 2.0의 발전 속도 감안
3. **중국이 이 시장을 리드하고 있다** — Seko, Seedance, Kling 등 핵심 도구가 중국발
4. **한국은 Vigloo가 선두** — Krafton 투자, 월 1편 AI 드라마 출시
5. **비용 장벽은 사실상 사라졌다** — 풀 AI로 $2,500 이내, 하이브리드로 $14,000 이내

---

## Sources

### AI Video Generation Tools
- [Kling vs Sora vs Veo vs Runway Comparison](https://invideo.io/blog/kling-vs-sora-vs-veo-vs-runway/)
- [15 AI Video Models Tested (Feb 2026)](https://www.teamday.ai/blog/best-ai-video-models-2026)
- [Sora 2 API Pricing Guide](https://www.aifreeapi.com/en/posts/sora-2-api-pricing-quotas)
- [Sora 2 Complete Guide 2026](https://wavespeed.ai/blog/posts/openai-sora-2-complete-guide-2026/)
- [Kling AI Pricing 2026](https://aitoolanalysis.com/kling-ai-pricing/)
- [Runway AI Pricing](https://runwayml.com/pricing)
- [Runway API Pricing](https://docs.dev.runwayml.com/guides/pricing/)
- [Google Veo Pricing Calculator](https://costgoat.com/pricing/google-veo)
- [Veo 3 API Pricing Comparison](https://kie.ai/v3-api-pricing)
- [Seedance 2.0 Pricing & Plans](https://seedancevideo.com/pricing/)
- [Seedance 2.0 Developer Guide](https://www.aifreeapi.com/en/posts/seedance-2-api-integration-guide)
- [Pika AI Pricing](https://pika.art/pricing)
- [Hailuo AI Pricing](https://hailuoai.video/subscribe)
- [Luma Dream Machine Pricing](https://lumalabs.ai/pricing)
- [AI Video Cost Comparison](https://vidpros.com/breaking-down-the-costs-creating-1-minute-videos-with-ai-tools/)

### Character Consistency
- [Runway Gen-4 References Overview](https://www.imagine.art/blogs/runway-gen-4-references-overview)
- [Runway Gen-4 Solves Character Consistency](https://venturebeat.com/ai/runways-gen-4-ai-solves-the-character-consistency-challenge-making-ai-filmmaking-actually-useful)
- [ByteDance StoryMem](https://the-decoder.com/bytedances-storymem-gives-ai-video-models-a-memory-so-characters-stop-shapeshifting-between-scenes/)
- [Consistent Characters in AI Videos Guide](https://www.neolemon.com/blog/how-to-create-consistent-characters-in-ai-videos-complete-guide/)
- [LTX Studio Consistent Character](https://ltx.studio/blog/how-to-create-a-consistent-character)

### AI Voice/Audio
- [ElevenLabs Pricing](https://elevenlabs.io/pricing)
- [ElevenLabs API Pricing](https://elevenlabs.io/pricing/api)
- [ElevenLabs v3 Model](http://unifiedtts.com/en/news/2026-02-12-elevenlabs-v3-model)
- [Veo 3 Native Audio & Lip Sync](https://www.keyvalue.systems/blog/veo-models-at-a-glance/)
- [PlayHT vs LOVO Comparison](https://murf.ai/compare/play-ht-vs-lovo-ai)

### AI Music
- [Suno Pricing](https://suno.com/pricing)
- [Suno vs Udio vs Beatoven Comparison](https://genesysgrowth.com/blog/suno-vs-udio-vs-beatoven)

### Real Examples & Platforms
- [China's First AI Sci-Fi Series](http://www.china.org.cn/2025-05/14/content_117874624.shtml)
- [Vigloo AI Dramas](https://finance.yahoo.com/news/vigloo-unveils-first-full-length-120000513.html)
- [SenseTime Seko 2.0](https://www.prnewswire.com/apac/news-releases/sensetime-launches-seko-2-0-drama-series-generation-platform-302647940.html)
- [Seedance 2.0 (CNN)](https://edition.cnn.com/2026/02/20/china/china-ai-seedance-intl-hnk-dst)
- [Seedance Hollywood Backlash (TechCrunch)](https://techcrunch.com/2026/02/15/hollywood-isnt-happy-about-the-new-seedance-2-0-video-generator/)
- [MicroDrama AI Platform](https://microdrama.ai/)
- [Genra AI Drama Guide](https://genra.ai/blog/ai-short-drama-generation-guide)
- [LTX Studio](https://ltx.studio/)

### Market & Cost Data
- [Microdrama Financing Guide 2026](https://vitrina.ai/blog/short-form-storytelling-financing)
- [ReelShort Production Costs](https://theredchains.com/the-rise-of-micro-drama-production-in-the-usa-a-look-at-reelshort-and-beyond/)
- [Microdramas Going Global (Deadline)](https://deadline.com/2026/01/microdrama-vertical-video-apps-international-new-wave-holywater-1236684224/)
- [TechCrunch: Microdramas Making Billions](https://techcrunch.com/2026/01/23/tiktok-like-microdramas-are-going-to-make-billions-this-year-even-though-they-kind-of-suck/)
- [Best AI Video Styles 2026](https://virvid.ai/blog/best-visual-styles-for-ai-videos-2026)
