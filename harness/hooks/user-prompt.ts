#!/usr/bin/env bun
// ============================================================================
// USER PROMPT HOOK - Inject relevant memories + rule reminder
// Hook: UserPromptSubmit
//
// 1. Memory server에서 관련 기억 검색 + 주입
// 2. 매 10턴마다 핵심 규칙 리마인더 주입
// ============================================================================

const MEMORY_API_URL = process.env.MEMORY_API_URL || "http://localhost:8765";
const TIMEOUT_MS = 5000;
const STATE_DIR = `${process.env.HOME || process.env.USERPROFILE}/.harness-state`;
const TURN_COUNTER_FILE = `${STATE_DIR}/turn_counter`;

// Short reminder (low token cost, injected every 10 turns)
const RULE_REMINDER = `[RULE REMINDER] 선언-미실행 금지. 불확실하면 ⚠️. 추측 금지.`;

// Full rule reminder (injected at context 20%/40%/60%/80%)
const FULL_RULE_REMINDER = `[⚠️ HARNESS RULE CHECK — 컨텍스트 마일스톤]
1. 즉시실행. 선언-미실행 금지. "할까요?" 금지.
2. "안 됩니다" 금지 — 웹 검색 + 3회 시도 + 대안 2개 후에만 불가 판정.
3. Evidence-First — 증거(도구 출력) 없이 상태 보고 금지.
4. Search-Before-Solve — 막히면 LESSONS_LEARNED, 옵시디언, 이전 세션에서 먼저 검색.
5. 완성형까지 반복 — Multi-Pass Review 최소 2라운드. 검수는 외부 모델(GPT-4.1 + Codex) 위임.
6. 검수 결과는 Playwright 스크린샷 + Read로 직접 확인. HTTP 200만으로 판단 금지.
[이 시점에서 하네스 규칙 위반 여부를 자체 점검하고, 위반이 있으면 즉시 수정하세요.]`;

// Context milestone check
const CONTEXT_MILESTONE_FILE = `${STATE_DIR}/context_milestone`;

function getProjectId(cwd: string): string {
  return cwd.split("/").pop() || "default";
}

async function httpPost(url: string, data: object): Promise<any> {
  try {
    const response = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data),
      signal: AbortSignal.timeout(TIMEOUT_MS),
    });
    return response.ok ? response.json() : {};
  } catch {
    return {};
  }
}

function getTurnCount(): number {
  try {
    const fs = require("fs");
    if (fs.existsSync(TURN_COUNTER_FILE)) {
      return parseInt(fs.readFileSync(TURN_COUNTER_FILE, "utf8").trim()) || 0;
    }
  } catch {}
  return 0;
}

function setTurnCount(n: number): void {
  try {
    const fs = require("fs");
    fs.mkdirSync(STATE_DIR, { recursive: true });
    fs.writeFileSync(TURN_COUNTER_FILE, String(n));
  } catch {}
}

async function main() {
  if (process.env.MEMORY_CURATOR_ACTIVE === "1") return;

  try {
    const inputText = await new Promise<string>((resolve) => {
      let data = "";
      process.stdin.on("data", (chunk: Buffer) => {
        data += chunk.toString();
      });
      process.stdin.on("end", () => resolve(data));
    });
    const input = JSON.parse(inputText);

    const sessionId = input.session_id || "unknown";
    const rawPrompt = input.prompt || "";
    // Extract telegram channel messages from <channel> tags in prompt
    const channelTexts = (
      rawPrompt.match(/<channel[^>]*>([\s\S]*?)<\/channel>/g) || []
    ).map((tag: string) => tag.replace(/<[^>]+>/g, "").trim());
    // Combine terminal prompt + telegram messages for feedback detection
    const prompt = [
      rawPrompt.replace(/<channel[\s\S]*?<\/channel>/g, ""),
      ...channelTexts,
    ]
      .join(" ")
      .trim();
    const cwd = process.env.CLAUDE_PROJECT_DIR || input.cwd || process.cwd();
    const projectId = getProjectId(cwd);

    // Increment turn counter
    const turnCount = getTurnCount() + 1;
    setTurnCount(turnCount);

    // === STUCK STATE DETECTION (gbrain Search-Before-Solve enforcement) ===
    // Reads ~/.harness-state/ files written by other hooks/agents
    let isStuck = false;
    let isNewToolDiscovered = false;
    try {
      const fs = require("fs");

      // Check recent error count file (written by stop-dispatcher.sh or similar)
      const errorCountFile = `${STATE_DIR}/error_count`;
      if (fs.existsSync(errorCountFile)) {
        const errorCount =
          parseInt(fs.readFileSync(errorCountFile, "utf8").trim()) || 0;
        if (errorCount >= 2) {
          isStuck = true;
        }
      }

      // Check retry log for repeated failure patterns (last 5 entries)
      const retryLog = `${STATE_DIR}/retry_log.jsonl`;
      if (fs.existsSync(retryLog)) {
        const lines = fs
          .readFileSync(retryLog, "utf8")
          .trim()
          .split("\n")
          .filter(Boolean)
          .slice(-5);
        const recentErrors = lines.filter((line: string) => {
          try {
            const entry = JSON.parse(line);
            const ageMs = Date.now() - new Date(entry.ts || 0).getTime();
            // Consider errors within last 10 minutes as "recent"
            return ageMs < 10 * 60 * 1000 && entry.status === "error";
          } catch {
            return false;
          }
        });
        if (recentErrors.length >= 2) {
          isStuck = true;
        }
      }

      // Check new_tool_discovered flag (written when npm install or new MCP add happens)
      const newToolFile = `${STATE_DIR}/new_tool_discovered.txt`;
      if (fs.existsSync(newToolFile)) {
        const toolInfo = fs.readFileSync(newToolFile, "utf8").trim();
        if (toolInfo) {
          isNewToolDiscovered = true;
          // Clear after reading so we don't repeat the reminder
          try {
            fs.unlinkSync(newToolFile);
          } catch {}
        }
      }
    } catch {}

    // Also detect stuck patterns from prompt text (error/failure keywords)
    const stuckTextPatterns = [
      /에러.*반복|같은.*에러|계속.*실패|또.*에러/, // "에러가 반복", "같은 에러"
      /timeout.*다시|다시.*timeout|연결.*실패|접근.*실패/, // "timeout 다시", "연결 실패"
      /not\s*found.*다시|찾을\s*수\s*없|모르겠|막혔/, // "not found 다시", "막혔어"
      /3번|세\s*번|여러\s*번.*실패|재시도.*실패/, // "3번 시도", "재시도 실패"
    ];
    if (!isStuck && stuckTextPatterns.some((p) => p.test(prompt))) {
      isStuck = true;
    }

    // Detect new npm package / API discovery in prompt
    const newToolTextPatterns = [
      /npm\s+install|npm\s+i\s+|npx\s+[-a-z]|yarn\s+add/, // npm/yarn install
      /새로운?\s*(도구|패키지|라이브러리|API|서비스)\s*(발견|찾|알게)/, // "새로운 도구 발견"
      /처음\s*(쓰는|사용|알게|발견)/, // "처음 쓰는", "처음 알게 된"
    ];
    if (
      !isNewToolDiscovered &&
      newToolTextPatterns.some((p) => p.test(prompt))
    ) {
      isNewToolDiscovered = true;
    }

    // === FEEDBACK DETECTION FIRST (before memory server, which may timeout) ===
    const feedbackPatterns = [
      /왜.*안\s*해|또.*그러|몇\s*번|지적.*했/, // "왜 안 해?", "또 그러네", "몇번이나"
      /검증.*안|확인.*안|팩트.*체크/, // "검증 안 하고", "팩트체크 안 하고"
      /말만.*하고|선언.*미실행|실행.*안/, // "말만 하고", "실행 안 하고"
      /검수.*안|검토.*안|건너뛰/, // "검수 안 해?", "건너뛰고"
      /못.*믿|신뢰.*없|거짓/, // "못 믿겠", "신뢰 없"
      /이것도\s*OK|통과.*시[켜킨]|제대로.*해/, // "이것도 OK야?", "통과시킨거야", "제대로 해"
      /깨져|잘못|엉뚱|안\s*보[여이]|누락/, // "깨져있는", "잘못된", "엉뚱한", "안 보여"
      /여전히|반복|또다시|계속/, // "여전히", "또다시", "계속"
      /잊[었은]|기록.*안|안.*했[어지잖]/, // "잊었어", "기록 안", "안 했잖아"
      /바보|엉망|실수/, // 강한 피드백
    ];

    const patternNames = [
      "skip_action",
      "skip_verify",
      "declare_no_execute",
      "skip_review",
      "distrust",
      "false_pass",
      "broken_output",
      "repeated_mistake",
      "forgot_record",
      "strong_feedback",
    ];
    const matchedPatterns = feedbackPatterns
      .map((p, i) => (p.test(prompt) ? patternNames[i] : null))
      .filter(Boolean);
    const isFeedback = matchedPatterns.length > 0;
    if (isFeedback) {
      const fs = require("fs");
      const feedbackLog = `${STATE_DIR}/feedback_log.jsonl`;
      const source = channelTexts.length > 0 ? "telegram" : "terminal";
      const entry = JSON.stringify({
        ts: new Date().toISOString(),
        prompt: prompt.substring(0, 200),
        turn: turnCount,
        patterns: matchedPatterns,
        source,
      });
      try {
        fs.appendFileSync(feedbackLog, entry + "\n");
      } catch {}
    }

    // Check context milestone (20% intervals)
    let contextMilestone = false;
    let contextPct = 0;
    try {
      const statusInput = input as any;
      const ctxSize =
        statusInput?.context_window?.context_window_size || 200000;
      const ctxUsage = statusInput?.context_window?.current_usage;
      if (ctxUsage) {
        const totalTokens =
          (ctxUsage.input_tokens || 0) + (ctxUsage.output_tokens || 0);
        contextPct = Math.round((totalTokens / ctxSize) * 100);
        // Save context info for other tools to read
        const fs = require("fs");
        try {
          fs.writeFileSync(`${STATE_DIR}/context_pct`, String(contextPct));
          fs.writeFileSync(
            `${STATE_DIR}/context_tokens`,
            `${totalTokens}/${ctxSize}`,
          );
        } catch {}
      }
      // Check if we crossed a 20% milestone
      const fs = require("fs");
      const lastMilestone =
        parseInt(fs.readFileSync(CONTEXT_MILESTONE_FILE, "utf8").trim()) || 0;
      const currentBucket = Math.floor(contextPct / 20) * 20;
      if (currentBucket > lastMilestone && currentBucket >= 20) {
        contextMilestone = true;
        fs.writeFileSync(CONTEXT_MILESTONE_FILE, String(currentBucket));
      }
    } catch {
      // First run or no context info
    }

    // === MEMORY SERVER (after feedback detection, may timeout) ===
    let memoryContext = "";
    try {
      const result = await httpPost(`${MEMORY_API_URL}/memory/context`, {
        session_id: sessionId,
        project_id: projectId,
        current_message: prompt,
        max_memories: 5,
      });
      memoryContext = result.context_text || "";
      await httpPost(`${MEMORY_API_URL}/memory/process`, {
        session_id: sessionId,
        project_id: projectId,
      });
    } catch {}

    // Build output
    const parts: string[] = [];

    if (memoryContext) parts.push(memoryContext);

    // === SESSION RENAME PENDING CHECK ===
    // post-edit-dispatcher.sh가 PRD.md/PLAN.md 작성 시 디렉토리 슬러그를 기록.
    // 이 hook에서 한 번만 클로드에게 안내 주입 후 파일 삭제.
    try {
      const fs = require("fs");
      const pendingFile = `${STATE_DIR}/session_rename_pending.txt`;
      if (fs.existsSync(pendingFile)) {
        const slug = fs.readFileSync(pendingFile, "utf8").trim();
        fs.unlinkSync(pendingFile);
        if (slug) {
          parts.push(
            `[🏷️ AUTO RENAME SUGGEST] 이전 작업에서 PRD/PLAN이 작성된 디렉토리를 감지했습니다: "${slug}". 세션 식별성 향상을 위해 이번 응답 끝에 사용자에게 다음 한 줄을 안내하세요 (사용자가 1초 입력으로 세션 이름 변경 가능):\n\n  /rename ${slug}\n\n현재 세션명이 이미 동일하면 안내를 생략하세요. 안내는 정보 전달이지 "할까요?" 질문이 아닙니다.`,
          );
        }
      }
    } catch {}

    // === SEARCH-BEFORE-SOLVE: gbrain enforcement ===
    if (isStuck) {
      parts.push(
        `[🔍 SEARCH-FIRST] 이전에 유사한 문제를 해결한 적이 있을 수 있습니다. 코드 수정 전에 반드시:\n1. gbrain query "관련 키워드" 로 먼저 검색 (과거 세션 지식, 디버깅 패턴, PITFALLS)\n2. gbrain query "pitfall 증상키워드" 로 PITFALLS 항목 검색 (P-001~P-030 gbrain에 저장됨)\n3. 옵시디언 세션 노트 검색\n같은 접근법 반복 변형 금지 — 새 정보 없으면 대표님께 보고.`,
      );
    }

    // === GBRAIN SAVE: new tool/technique discovered ===
    if (isNewToolDiscovered) {
      parts.push(
        `[💾 GBRAIN SAVE] 새로운 도구/기법을 발견했습니다. 작업 완료 후 즉시 저장하세요:\n  gbrain put <slug> <<EOF\n  # 도구명\n  설치: ...\n  용도: ...\n  주의: ...\n  EOF\n또는 MCP: mcp__gbrain__put_page`,
      );
    }

    // If feedback detected, inject stronger reminder + PITFALLS auto-record instruction
    if (isFeedback) {
      parts.push(`[⚠️ FEEDBACK DETECTED] 대표님이 문제를 지적했습니다. 추측하지 말고 검증하세요. 선언만 하지 말고 즉시 실행하세요. 안 된다고 단정하기 전에 웹 검색으로 확인하세요.
[📝 PITFALLS AUTO-RECORD] 이 지적이 타당하다고 동의하면:
1. \`gbrain query "증상키워드"\` 로 유사 항목 확인 (같은 증상/원인이면 gbrain 페이지에 "재발: {날짜}" 추가)
2. 신규면:
   a. \`D:/jamesclew/harness/pitfalls/pitfall-NNN-{slug}.md\` 파일 생성 (frontmatter + 본문)
   b. \`gbrain import D:/jamesclew/harness/pitfalls/\` 실행
   (주의: gbrain put --content 는 multi-line 깨짐 — 절대 사용 금지)
기록하지 않으면 forgot_record 패턴으로 재감지됩니다.`);
    }

    // Detect capability gap — trigger on-demand MCP search
    const capabilityGapPatterns = [
      /안\s*됩니다|불가능|지원.*안|할\s*수\s*없/, // "안 됩니다", "불가능합니다"
      /방법.*없|도구.*없|기능.*없/, // "방법이 없", "도구가 없"
      /MCP.*필요|서버.*필요|API.*필요/, // "MCP 필요", "API 필요"
    ];
    // Also detect domain keywords that might need specialized MCP
    const domainMcpPatterns = [
      {
        pattern: /법령|법률|법원|판례|관세/,
        mcp: "korean-law-mcp",
        desc: "국가법령정보센터",
      },
      { pattern: /특허|상표|지식재산/, mcp: "patent mcp", desc: "특허 검색" },
      {
        pattern: /주식|증권|코스피|코스닥/,
        mcp: "stock mcp korea",
        desc: "주식 정보",
      },
      { pattern: /날씨|기상|Weather/, mcp: "weather mcp", desc: "날씨 정보" },
      { pattern: /지도|좌표|geocod/, mcp: "maps mcp", desc: "지도/위치" },
    ];

    const isCapabilityGap = capabilityGapPatterns.some((p) => p.test(prompt));
    const matchedDomain = domainMcpPatterns.find((d) => d.pattern.test(prompt));

    if (isCapabilityGap || matchedDomain) {
      let mcpMsg = `[🔧 ON-DEMAND MCP] 필요한 기능이 없으면 "안 됩니다" 전에 반드시:\n1. npm search "{기능} mcp" 로 npm에서 MCP 서버 검색\n2. 존재하면 ~/.config/lazy-mcp/servers.json에 추가 (Edit)\n3. invoke_command로 즉시 사용\n4. npm에 없으면 GitHub에서 검색`;
      if (matchedDomain) {
        mcpMsg += `\n\n[HINT] "${matchedDomain.desc}" 관련 요청 감지. npm search "${matchedDomain.mcp}" 로 먼저 확인하세요.`;
      }
      parts.push(mcpMsg);
    }

    // === BUILD REQUEST DETECTION — enforce PRD + pipeline-install ===
    const buildPatterns =
      /만들어줘|만들려고|구현해|개발해|페이지로|앱으로|만들어\s*볼|만들자|빌드해/;
    const isBuildRequest = buildPatterns.test(prompt);
    if (isBuildRequest) {
      // Check if PRD and pipeline-install have been done in this session
      const fs = require("fs");
      const prdDone = fs.existsSync(`${STATE_DIR}/prd_done`);
      const pipelineDone = fs.existsSync(`${STATE_DIR}/pipeline_done`);

      // Mark build detected for enforce-build-transition.sh
      try {
        const fs2 = require("fs");
        fs2.writeFileSync(
          `${STATE_DIR}/build_detected`,
          new Date().toISOString(),
        );
      } catch {}

      if (!prdDone || !pipelineDone) {
        let buildMsg = `[🚨 BUILD REQUEST DETECTED] 빌드 요청 감지. Build Transition Rule 강제:`;
        if (!prdDone) {
          buildMsg += `\n1. /prd 먼저 실행하세요 (새 프로젝트). 완료 후: echo done > ${STATE_DIR}/prd_done`;
        }
        if (!pipelineDone) {
          buildMsg += `\n${!prdDone ? "2" : "1"}. /pipeline-install 실행하세요. 완료 후: echo done > ${STATE_DIR}/pipeline_done`;
        }
        buildMsg += `\n그 다음 /plan 진입 → 승인 → 코드 작성.`;
        buildMsg += `\n단순 일회성 유틸리티라면 판단 근거를 명시하고 바로 코드 작성 가능.`;
        parts.push(buildMsg);
      }
    }

    // Context milestone: inject full rules + trigger self-evolve
    if (contextMilestone) {
      let milestoneMsg = `[📊 Context ${contextPct}% — 20% 마일스톤 도달]\n${FULL_RULE_REMINDER}\n[ACTION REQUIRED] 지금 즉시:\n1. curl -s http://localhost:4141/v1/chat/completions 로 GPT-4.1이 이 세션 하네스 규칙 위반 검수\n2. codex "이 세션 규칙 위반 검수" 로 교차 검증\n3. bash ~/.claude/scripts/self-evolve.sh --apply 로 Self-Evolving Loop 이행`;

      // At 60%+, add compact preparation checklist
      if (contextPct >= 60) {
        const vaultPath = process.env.OBSIDIAN_VAULT || "$OBSIDIAN_VAULT";
        milestoneMsg += `\n\n[⚠️ COMPACT 준비] 65%에 수동 /compact 권장. compact 전 필수:\n1. 옵시디언 세션 요약 저장: ${vaultPath}/01-jamesclaw/harness/session-{날짜}-{주제}.md\n2. 하네스 변경 시 harness_design.md 변경 이력 업데이트\n3. git commit + push\n4. 미완료 작업 TodoWrite 기록`;
      }

      parts.push(milestoneMsg);
    }

    // Rule reminder: 토큰 절감을 위해 대폭 축소 (2026-04-08)
    // Full reminder는 컨텍스트 마일스톤(20%/40%/60%/80%)에서만, 턴 기반 제거
    // Short reminder는 30턴마다만 (이전 8턴에서 완화)
    if (turnCount % 30 === 0 && !contextMilestone && turnCount > 0) {
      parts.push(RULE_REMINDER);
    }

    // === SESSION TITLE AUTO-SET (first prompt only) ===
    let sessionTitle: string | undefined;
    try {
      const fs = require("fs");
      const titleDoneFile = `${STATE_DIR}/session_title_set`;
      if (!fs.existsSync(titleDoneFile)) {
        fs.writeFileSync(titleDoneFile, new Date().toISOString());

        // Step 1: Detect task category for prefix
        type CategoryRule = { pattern: RegExp; prefix: string };
        const categoryRules: CategoryRule[] = [
          {
            pattern: /블로그|포스트|글\s*작성|콘텐츠|키워드/,
            prefix: "블로그",
          },
          {
            pattern: /하네스|hook|설정|config|rules|settings/,
            prefix: "하네스",
          },
          {
            pattern: /버그|에러|오류|fix|수정.*안\s*되|고쳐|안\s*돼/,
            prefix: "버그 수정",
          },
          { pattern: /배포|deploy|firebase|빌드|build/, prefix: "배포" },
          { pattern: /진단|audit|감사|점검|체크/, prefix: "진단" },
          { pattern: /설계|PRD|계획|plan|아키텍처/, prefix: "설계" },
          { pattern: /리서치|조사|분석|검색|research/, prefix: "리서치" },
          { pattern: /이미지|사진|캡처|screenshot/, prefix: "이미지" },
          { pattern: /테스트|test|검증|verify/, prefix: "테스트" },
          { pattern: /스킬|커맨드|command|자동화/, prefix: "자동화" },
        ];

        let prefix = "";
        for (const rule of categoryRules) {
          if (rule.pattern.test(prompt)) {
            prefix = rule.prefix;
            break;
          }
        }

        // Step 2: Extract meaningful keywords (nouns/topics)
        const stopWords = new Set([
          "해줘",
          "진행해",
          "주세요",
          "부탁",
          "알려줘",
          "보여줘",
          "확인해",
          "실행해",
          "해주세요",
          "좀",
          "그냥",
          "이제",
          "일단",
          "먼저",
          "빨리",
          "바로",
          "해",
          "줘",
          "하고",
          "싶어",
          "싶다",
          "있어",
          "있다",
          "없어",
          "없다",
          "인데",
          "인지",
          "것을",
          "것이",
          "것은",
          "것도",
          "대해",
          "위해",
          "관련",
          "사용",
          "이용",
          "처리",
          "완료",
          "진행",
          "실행",
          "작업",
          "현재",
          "지금",
          "다시",
          "새로",
          "모든",
          "전체",
          "각각",
        ]);

        // Remove special chars, split on whitespace/punctuation
        const rawWords = prompt
          .replace(/[<>[\]{}()「」『』【】《》""''`]/g, " ")
          .replace(/[.!?。，、:;]/g, " ")
          .split(/\s+/)
          .map((w: string) =>
            w.replace(/^[^가-힣a-zA-Z0-9]+|[^가-힣a-zA-Z0-9]+$/g, ""),
          )
          .filter((w: string) => w.length >= 2 && !stopWords.has(w));

        // Prefer longer, more meaningful words (likely nouns)
        const keywords = rawWords
          .filter((w: string) => w.length >= 2)
          .slice(0, 6);

        // Step 3: Compose title
        let title = "";
        if (prefix && keywords.length > 0) {
          // "블로그 — 무선이어폰 추천"
          const topicStr = keywords.slice(0, 3).join(" ");
          title = `${prefix} — ${topicStr}`;
        } else if (prefix) {
          title = prefix;
        } else if (keywords.length > 0) {
          title = keywords.slice(0, 4).join(" ");
        }

        // Step 4: Enforce 30 char limit
        if (title.length > 30) {
          title = title.substring(0, 30);
        }

        sessionTitle = title || undefined;
      }
    } catch (e: any) {
      // Non-fatal — session continues without title, but always log
      console.error(`[session-title] ${e?.message || e}`);
      const fs2 = require("fs");
      try {
        fs2.appendFileSync(
          `${STATE_DIR}/user-prompt-errors.log`,
          `[${new Date().toISOString()}] [session-title] ${e?.message || e}\n`,
        );
      } catch (logErr: any) {
        console.error(
          `[session-title] log write failed: ${logErr?.message || logErr}`,
        );
      }
    }

    if (parts.length > 0 || sessionTitle) {
      // Output as UserPromptSubmit additionalContext
      const hookOutput: Record<string, any> = {
        hookEventName: "UserPromptSubmit",
        additionalContext: parts.join("\n"),
      };
      if (sessionTitle) {
        hookOutput.sessionTitle = sessionTitle;
      }
      const output = {
        hookSpecificOutput: hookOutput,
      };
      console.log(JSON.stringify(output));
    }
  } catch (e: any) {
    // Log errors for debugging but never crash
    try {
      const fs = require("fs");
      fs.appendFileSync(
        `${STATE_DIR}/user-prompt-errors.log`,
        `[${new Date().toISOString()}] ${e?.message || e}\n`,
      );
    } catch {}
  }
}

main();
