# L123 프로젝트 분석 정리 (한국어)

> 작성일: 2026-09-21
> 대상 커밋: `b06893d` / 버전 `v1.4.0`
> 성격: 저장소 전수조사 기반 분석 노트 (사양서 아님 — 정경 문서는
> `docs/SPEC.md`, `docs/PLAN.md`, `docs/MENU.md`)

## 저장소 주소

| 구분 | 주소 | 비고 |
|---|---|---|
| 원본(upstream) | https://github.com/duane1024/l123 | ⭐ 128 / 🍴 10 / 릴리스 v1.4.0 |
| 포크(this) | https://github.com/bmshin94/l123 | upstream의 fork, ⭐ 0 |
| 라이선스 | MIT (`LICENSE`) | 상업적 이용·수정·재배포 가능 |

---

## 1. 이게 뭐하는 프로젝트인가

**1993년 DOS용 스프레드시트 "Lotus 1-2-3 Release 3.4a"의 상호작용
모델을, 현대 Rust 스택으로 복각한 터미널(TUI) 스프레드시트.**

`docs/SPEC.md` §1의 두 가지 약속 — 하나라도 깨지면 프로젝트는 실패:

1. 로터스 R3.4a 숙련자가 아무 문서도 읽지 않고 바로 몰고 다닐 수 있다.
2. 파일이 `.xlsx`와 깨끗하게 왕복(round-trip)한다.

명시적 비목표: DOS 에뮬레이터가 아니고(UTF-8 end-to-end), CRT 감성
재현이 목적이 아니며(기능적 충실도), 계산 코어를 직접 구현하지 않는다
(IronCalc에 위임).

---

## 2. 폴더 전수조사

```
l123/
├── CLAUDE.md / AGENTS.md    AI 에이전트용 개발 규칙서 (내용 사실상 동일)
├── Cargo.toml               Rust 워크스페이스, 12 크레이트, v1.4.0
├── Makefile                 WK3(레거시 로터스 읽기) 빌드 모드 on/off 토글
├── README.md                마일스톤 M0~M13 진행표 + 키보드 치트시트
├── LICENSE                  MIT
├── rust-toolchain.toml      Rust 1.92 고정
├── .claude/settings.json    커밋/PR 자동 서명 비활성화 (3줄)
├── scripts/release.sh       릴리스 자동화
├── docs/
│   ├── SPEC.md      (38KB)  "L123은 무엇인가" — 절대 기준
│   ├── PLAN.md      (29KB)  마일스톤 + 리스크 레지스터 + 테스트 전략
│   ├── MENU.md      (18KB)  슬래시 메뉴 트리 전체 (l123-menu의 진실)
│   ├── AT_FUNCTIONS.md      @함수 목록
│   ├── CONFIG.md            ~/.l123/L123.CNF 레퍼런스
│   ├── GRAPH_PLAN.md / XLSX_IMPORT_PLAN.md
│   └── iterm-screenshot.png
├── crates/                  Rust 코드 63,273줄 / 79개 .rs 파일
└── tests/acceptance/        .tsv 키스트로크 트랜스크립트 311개
```

`.github/` 디렉터리 **없음** → 테스트 311개가 있는데도 CI 자동 실행
장치가 없다. 기여 포인트로 남아 있음.

## 3. 크레이트 구성

| 크레이트 | 줄 수 | 역할 |
|---|---|---|
| `l123-core` | 5,391 | 외부 의존성 0. 타입만 (`Address`, 포맷 등) |
| `l123-parse` | 2,265 | `@SUM(A1..A5)` → `SUM(A1:A5)` 문법 번역 |
| `l123-menu` | 7,752 | 슬래시 메뉴 트리 |
| `l123-engine` | 4,952 | IronCalc 래핑, `Engine` 트레이트 |
| `l123-io` | 2,622 | xlsx / csv / json / parquet / sqlite / postgres |
| `l123-graph` | 9,360 | 차트 7종 + WYSIWYG 아이콘 17개 |
| `l123-print` | 911 | ASCII / PDF / 라인프린터 |
| `l123-macro` | 786 | `{BRANCH}`, `{IF}` 등 매크로 인터프리터 |
| `l123-help` | 528 | F1 도움말 (R3.1 매뉴얼 824쪽 내장) |
| `l123-ui` | 27,829 | ratatui TUI — 화면·키입력 전부 |
| `l123-cmd` | 260 | 커맨드 저널 (Undo 기반) |
| `l123` | 617 | 바이너리 진입점 (CLI 파싱) |

계층 규칙: **위로 올라가는 의존성 금지.** `l123-ui`는 엔진을 직접
의존하지 않아 엔진 교체가 가능하고, IronCalc 타입은 `l123-engine`
밖으로 새지 않는다.

## 4. 개발 방법론 — 이 저장소의 진짜 자산

- **엄격한 TDD (Red → Green → Refactor).** Green 단계에서 "나중에
  쓸 헬퍼" 금지. 의도보다 먼저 초록이면 남는 코드를 지운다.
- **문서가 진실.** 코드와 문서가 어긋나면 문서를 먼저 고치고 코드를
  맞춘다.
- **Acceptance Transcript (`.tsv`) 311개.** 키 입력을 적으면 화면
  상태를 검증한다. 사람이 읽을 수 있는 형태의 eval 스위트.

```
RIGHT
ASSERT_POINTER   A:B1
DOWN
DOWN
ASSERT_POINTER   A:B3
PGDN
ASSERT_POINTER   A:A21
```

SPEC §20 "Authenticity Contract"의 모든 항목은 트랜스크립트가
최소 1개 붙어야 완료로 인정된다.

---

## 5. 설치 및 사용법

```bash
# Homebrew
brew install duane1024/l123/l123

# 소스 빌드 (Rust 1.92)
git clone https://github.com/bmshin94/l123.git && cd l123
cargo build --release && ./target/release/l123

# 실행
l123                  # 빈 워크북
l123 financials.xlsx  # 엑셀 열기
l123 config           # 설정 확인
l123 config --init    # ~/.l123/L123.CNF 생성
l123 --theme dos      # DOS 테마
l123 --replay f.l123log  # 조작 기록 재생
```

필수 키: `/` 슬래시 메뉴 · `:` WYSIWYG 메뉴 · 첫 글자로 메뉴 진입
(Enter 불필요) · `Esc` 한 단계 뒤로 · `Ctrl-Break` 강제 READY ·
`F1` 도움말 · `F2` 편집 · `F5` GOTO · `F9` 재계산 · `F10` 그래프 ·
`Alt-F4` Undo · `Alt-F5` 매크로 기록.

문법: `@SUM(A1..A5)` (엑셀 문법 `=SUM(A1:A5)`는 안 통함),
논리 연산 `#AND# #OR# #NOT#`, 첫 글자가 숫자나 `+ - . ( @ # $`면 값,
그 외는 라벨, `"` 우측정렬 · `^` 가운데 · `\-` 대시 채움.

개발 명령:

```bash
cargo test --workspace
cargo test -p l123-ui --test acceptance
cargo clippy --workspace --all-targets -- -D warnings
cargo fmt --all
make wk3-status
```

## 6. 플러그인인가, 스킬인가, MCP인가

**셋 다 아니다. 독립 실행형 터미널 앱(단일 바이너리).**

전수조사 근거: `*mcp*` / `*skill*` / `*plugin*` 파일 0개, `SKILL.md`
없음, `.mcp.json` 없음, `package.json`·`.py`·`.ts` 0개(순수 Rust),
`.claude/` 안에는 커밋 서명을 끄는 `settings.json` 3줄뿐.

혼동 원인은 `CLAUDE.md` / `AGENTS.md`의 존재다. 이건 "이 프로젝트를
AI가 개발할 때 읽는 규칙서"이지 제품 기능이 아니다. 즉 **AI가 만든
앱**이지 **AI용 앱**이 아니다. (다만 MCP 서버로 감싸는 것은 충분히
가능 — 아래 §8 참조.)

## 7. API 토큰 필요 여부

**불필요. 완전 오프라인 앱.** `api_key` / `API_KEY` / `ANTHROPIC` /
`OPENAI` / `reqwest` 검색 결과 0건. 네트워크 성격 의존성은 로컬
SQLite(`rusqlite`, bundled)와 `/Data External`용 `postgres` 드라이버
둘뿐이며, 후자는 사용자 소유 DB 접속정보만 쓴다.

환경변수는 전부 취향 설정: `L123_USER`, `L123_ORG`, `L123_THEME`,
`L123_BEEP`, `L123_LOG`, `RUST_LOG`.

## 8. 왜 GitHub에서 주목받는가 (팩트 체크 포함)

⭐ 128개는 "유명"보다 **니치 장인 프로젝트** 수준이다. 그래도 모인
이유는 뚜렷하다.

1. 레트로 복각 + 실제 기술 실력의 결합. "문서 안 읽고 바로 쓸 수
   있어야 한다"는 각오가 SPEC에 명문화돼 있음.
2. 1990년 실물 매뉴얼(Reference / Tutorial / Quick Reference) 고증,
   824쪽 매뉴얼을 F1 도움말로 내장.
3. 말이 아니라 테스트 311개로 증명.
4. 대규모 Rust + ratatui TUI 레퍼런스 수요 (6만 줄 + 엄격한 계층).
5. "AI로 진짜 소프트웨어 만들기" 방법론 사례로서의 가치.
6. README의 한 줄: *"Spreadsheets didn't get worse — they just got
   heavier."*

## 9. 로컬 에이전트 구축에 도움이 되는가

직접적으로는 아니다(LLM 호출·에이전트 루프·툴 정의 없음). 그러나
**방법론으로는 크게 도움이 된다.**

- `CLAUDE.md` 자체가 에이전트 시스템 프롬프트 설계 교본. "정경 문서
  우선", "최소 코드", "계층 금지"의 세 축.
- `.tsv` 트랜스크립트 = 사람이 읽을 수 있는 eval 스위트 패턴.
- 계층 강제 = 에이전트 툴 권한 경계 설계와 동형.
- `docs/MENU.md`의 계층형 명령 트리 = 에이전트 툴 트리 참고 자료.
- `Engine` 트레이트 추상화 + `--replay` 사이드카 덕에 **헤드리스로
  감싸 MCP 서버 툴(`read_range` / `write_range` / `recalc` /
  `to_xlsx`)로 노출하기 쉽다.**

## 10. React / PHP로 만들 수 있는가

**React: 가능.** ① 웹 스프레드시트 — React + TS, 가상 스크롤
(react-window), 계산 엔진은 HyperFormula 또는 IronCalc WASM, 엑셀
입출력은 SheetJS, `l123-parse`의 문법 번역만 이식. ② 터미널 룩 —
xterm.js + Rust→WASM (`l123-core`/`parse`/`menu`는 순수 로직이라
WASM 친화적, ratatui 렌더 백엔드만 교체). ③ Tauri — Rust 코드를
그대로 두고 React를 프론트로 (최소 노력).

**PHP: 절반만.** 요청-응답 모델이라 실시간 TUI에는 구조적으로 부적합.
대신 백엔드로는 잘 맞는다 — PhpSpreadsheet로 xlsx 처리, 저장·권한·
협업 담당. 계산은 프론트(HyperFormula), 영속화·인증은 PHP(Laravel)로
나누는 하이브리드가 현실적.

---

## 11. 수익화 아이디어

### Tier 1 — 즉시 착수 가능

| # | 아이디어 | 가격 모델 | 예상 | 현실성 |
|---|---|---|---|---|
| 1 | "Lotus Keys" 웹 스프레드시트 SaaS | Free / $8·월 / $15·월 팀 | 유료 300명 → 월 $2,400 | ⭐⭐⭐⭐ |
| 2 | VSCode / JetBrains 로터스 키맵 확장 | 무료 + $10 일회성 | 5만 DL × 2% → $10,000 | ⭐⭐⭐⭐ |
| 3 | 콘텐츠·교육 (전자책 $29, 강의 $49, 유튜브) | 일회성 | 책 500부 $14,500 / 강의 1,000명 $49,000 | ⭐⭐⭐⭐⭐ |
| 4 | GitHub Sponsors / Open Collective | 후원 | 월 $50~500 | ⭐⭐⭐ |

### Tier 2 — B2B 본게임

| # | 아이디어 | 내용 | 예상 | 현실성 |
|---|---|---|---|---|
| 5 | **레거시 마이그레이션 서비스** | `.WK3` → `.xlsx` 일괄 변환(파일당 $5), 매크로 변환($5,000~$50,000), 변환 감사 리포트($3,000~), 교육(일 $2,000) | 연 5건 × $20,000 = **연 $100,000** | ⭐⭐⭐⭐ |
| 6 | 터미널 데이터 워크벤치 스위트 | l123 + VisiData + DuckDB 결합 (SPEC §22 M13 계획과 일치) | 팀 30 × 5석 × $20 = 월 $3,000 | ⭐⭐⭐ |
| 7 | **헤드리스 스프레드시트 API / MCP 서버** | AI 에이전트용 정확한 계산 엔진. $0.001/호출 + $49·월 | API 500만 콜/월 → 월 $5,000 | ⭐⭐⭐⭐ |

5번의 기술적 근거: `ironcalc_lotus` 기반 `.WK3` 읽기가 `wk3` 카고
피처로 **이미 동작**한다 (`make wk3-on`).

### Tier 3 — 큰 베팅

| # | 아이디어 | 가격 | 현실성 |
|---|---|---|---|
| 8 | 임베디드 스프레드시트 컴포넌트 라이선스 | 스타트업 $499·년 / 엔터프라이즈 $9,999·년 | ⭐⭐ |
| 9 | 규제 산업용 감사 가능 스프레드시트 (`--replay` + `.l123log`가 모든 조작을 기록) | 좌석당 연 $500~2,000 | ⭐⭐⭐ |
| 10 | 레트로 컴퓨팅 브랜드 (웹 무료 공개 + 굿즈) | 굿즈 마진 | ⭐⭐⭐ (마케팅 가치 ⭐⭐⭐⭐⭐) |

### 실행 로드맵

| 단계 | 기간 | 할 일 | 목표 |
|---|---|---|---|
| 1 | 1~2개월 | 콘텐츠(③) + VSCode 확장(②) | $5,000 |
| 2 | 3~4개월 | React 웹 MVP 무료 티어 출시 | 사용자 1,000명 |
| 3 | 5~6개월 | Pro 유료화 + MCP/API 상품(⑦) | 월 $2,000 |
| 4 | 7~12개월 | 레거시 마이그레이션 B2B 영업(⑤) | 연 $100,000 |

- 노력 대비 최고: ③ 콘텐츠 (재료가 이미 저장소에 다 있음)
- 최대 수익: ⑤ 레거시 마이그레이션 (경쟁자 희소)
- 타이밍 최적: ⑦ AI 에이전트용 스프레드시트 API

### 법적 주의

l123은 MIT라 상업화 자유. 단 "Lotus", "1-2-3"은 IBM/HCL 상표일 수
있으므로 **제품명에 사용하지 말고** "Lotus 1-2-3 스타일/호환" 같은
서술적 표현만 사용. 브랜드는 새로 만든다.

---

## 12. 한눈에 정리

- **정체**: Rust로 만든 로터스 1-2-3 R3.4a 스타일 터미널 스프레드시트
- **규모**: 12 크레이트 / 63,273줄 / 트랜스크립트 311개 / v1.4.0
- **플러그인·스킬·MCP 아님**: 독립 바이너리
- **API 토큰 불필요**: 완전 오프라인
- **주목 이유**: 고증 집착 + 테스트로 증명 + AI 협업 방법론 사례
- **최대 가치**: 프로그램 자체보다 `CLAUDE.md` + `.tsv` 검증 패턴
- **수익 유망 3종**: 콘텐츠 · 레거시 마이그레이션 · 에이전트용 API
