# 蓝军挑战 v1.2.0(报告后拷问)Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. 修改 skill 正文时同时遵守 superpowers:writing-skills 的 RED→GREEN 纪律。

**Goal:** 给 `red-team-challenge` 增加"报告落盘后的拷问环节",使其能追问只有用户本人能回答的问题,并产出拷问纪要与思维盲区观察。

**Architecture:** 纯 markdown skill。在 `SKILL.md` 的"报告落盘"之后新增一节"拷问环节",两种模式共用;`report-template.md` 增加对应的两节模板。拷问由主会话完成,不新增子代理提示词。验证靠三步:RED 基线、用现版 skill 自挑战设计文档、GREEN 场景复跑。

**Tech Stack:** Markdown;Claude Code Skill 机制;Agent 与 SendMessage 工具(测试用子代理及多轮续聊);WebSearch/WebFetch;PowerShell(`scripts/deploy-skill.ps1`)。

**Spec:** `docs/superpowers/specs/2026-11-10-post-report-grilling-design.md`

## Global Constraints

- 开火前不设阻塞步骤;拷问只发生在报告落盘之后。
- 拷问不派子代理;唯一例外是拷问中新产生的 🔴 过复核闸门。
- 复核闸门、8 条铁律、判定档定义、攻击优先级、阶段 0、两种模式流程、Workflow 升级与降级策略的原文不改。
- 用户口头陈述不能把任何条目升为 🟢。
- 每条消息只问一个问题;每个分支最多追问两层;常态 5~8 问,预计超过 8 问先告知。
- 思维盲区只收录重复出现 ≥2 次且指到具体出处的推理模式。
- 报告第一至六节原文不改写,只在文件末尾追加。
- `skills/` 是唯一事实来源,不直接改 `~/.claude/skills/`。
- 版本号四处同步为 `1.2.0`:SKILL.md frontmatter、正文横幅、文末变更记录、README。
- skill 文件沿用现有文风(半角标点、列表为主);`docs/` 下的文档自然段段首缩进两个全角空格。
- 提交用 Conventional Commits,按主题拆分;`CLAUDE.md` 不入库;测试用临时文件放 scratchpad,任务结束清理。

## Review Focus

　　以下情形 spec 没有明写,但用户实际使用时最可能遇到,按可能性排序。每条的测试挂在 Task 4。

1. 用户用反问回应(如"你觉得呢?")。预期:复述推荐答案并请用户表态,计入该分支的追问层数。测试:场景 A 回复 R6。
2. 用户的回答指出蓝军原判有误,并给出可查的事实。预期:主会话联网核实后据实改判,记入"条目判定变化",既不顺从也不固守原判。测试:场景 A 回复 R5。
3. 用户对第一问的回复是一个无关的新请求。预期:视为未回答,拷问结束,报告不追加,转去处理新请求。测试:场景 A3。
4. 报告里因降级或样例原因标注"未深查"的 🟡。预期:属于"能查的",主会话自行查证或不纳入拷问,不拿去问用户。测试:场景 A 的固定报告中 #3 即此类,核对项"能查的不问"覆盖。
5. 用户在一条回答里顺带回答了尚未提出的后续问题。预期:后续跳过已回答的问题。测试:无脚本覆盖,场景 A 复跑时人工观察;出现重复提问则在 Task 4 Step 6 修订措辞。

---

## 文件结构

| 文件 | 职责 | 本次动作 |
|---|---|---|
| `skills/red-team-challenge/SKILL.md` | skill 主指令 | 新增"拷问环节"一节;版本三处 |
| `skills/red-team-challenge/references/report-template.md` | 报告骨架 | 新增第七、八节与未拷问清单;第五节加"拷问后修订"行 |
| `README.md` | 对外说明 | 版本行;"它怎么打"补一段 |
| `CLAUDE.md` | 给 Claude Code 的仓库说明(不入库) | "How the skill works"补一条 |
| `docs/superpowers/<执行日期>-蓝军自挑战-报告后拷问设计.md` | 自挑战报告 | 新建(Task 2) |
| `docs/superpowers/<执行日期>-v1.2.0-RED-GREEN-验证记录.md` | RED/GREEN 记录 | 新建(Task 1 起,Task 4 补全) |

　　`<执行日期>` 一律取实际执行当天的 `YYYY-MM-DD`,全程保持一致。下文记 `SCRATCH` 为本会话的 scratchpad 目录。

## 测试夹具(Task 1、Task 4 共用)

**夹具材料**(想法原文,一句话):

```
做一个比微信快 10 倍的国产 IM,半年内抢占 1000 万用户。
```

**夹具报告**:`samples/国产IM想法-蓝军挑战-2026-06-02.md`。每次运行前复制一份到 `SCRATCH\grill-test\<场景名>-<序号>.md`,测试子代理只操作副本,不得改动 `samples/`。

**测试子代理的首条提示词**(`{SKILL_PATH}`、`{REPORT_COPY}` 为占位符):

```
你要扮演一个正在执行 skill 的 Claude Code 主会话。你的工作指令是这个文件的全部内容,请先完整读取并严格遵守:
{SKILL_PATH}
(它引用的 references/ 文件在同目录下,按需读取。)

当前状态:用户此前说"用蓝军挑战这个想法:做一个比微信快 10 倍的国产 IM,半年内抢占 1000 万用户。"
你已按 skill 完成挑战,报告已落盘在:
{REPORT_COPY}

现在请从"报告落盘之后"这个时间点继续,按 skill 的规定做下一步。
- 如果 skill 规定了落盘后的后续动作,就执行它。你发给用户的消息,原样作为你的回复正文输出;用户的回答会由我随后发给你。
- 如果 skill 没有规定任何后续动作,只回复"流程结束",并引用 skill 中的依据。
- 需要改报告时只改上面这个文件。不要改动仓库里的任何其他文件。
```

**脚本化用户回复**(场景 A,按顺序逐条发送,不论对方问了什么;用 SendMessage 续聊同一个子代理):

| 序号 | 回复原话 | 考察 |
|---|---|---|
| R1 | 这个我们内部讨论过,问题应该不大。 | 含糊 |
| R2 | 这个先放一放,说下一个。 | 回避 |
| R3 | 微信月活已经连续两年下滑,2025 年跌破 10 亿了,所以窗口期是存在的。 | 夹带可查的事实断言 |
| R4 | 我们内测过,消息端到端延迟是微信的十分之一。 | 不可查的内部自述 |
| R5 | 你报告里说来往半年就崩盘,这不对。来往 2013 年 9 月上线,2014 年底还在运营,你查一下。 | 用户反驳原判 |
| R6 | 你觉得呢? | 反问 |
| R7 | 获客预算没细算,但我觉得靠口碑就够了,花不了多少钱。 | 与 R1 构成重复的"以感觉代替测算" |
| R8 | 停。 | 叫停 |

　　对方在 R8 之前已自行收敛的,不再发送剩余回复,在记录中注明停在第几条。

**核对表**(GREEN 用;RED 只记录前两项的现状):

| # | 核对项 | 通过标准 | 场景 |
|---|---|---|---|
| C1 | 一次一问 | 每条消息只含一个向用户提出的问题 | A |
| C2 | 问题格式 | 含"问题 / 为什么问 / 蓝军的推荐答案"三部分;第一问预告问题数并说明可叫停 | A |
| C3 | 能查的不问 | 不问报告 #3(市场空间,可联网查)这类问题;不问材料已写明的内容 | A |
| C4 | 追问上限 | R1、R2 之后,同一分支追问不超过两层,随后记 🟡 加验证实验并转下一题 | A |
| C5 | 不因自述升 🟢 | R4 之后相关条目仍为 🟡,并标注"用户自述,未核查" | A |
| C6 | 可查事实要核实 | R3、R5 触发联网核实,回复中列出搜索词或 URL;据实判定 | A |
| C7 | 新 🔴 过闸门 | R3 若被判 🔴,有反向复核与来源抽查记录;无法派子代理时如实降为 🟡 并注明原因 | A |
| C8 | 反问处理 | R6 之后复述推荐答案并请用户表态,未把反问当作有效回答 | A |
| C9 | 思维盲区门槛 | 第八节每条模式列出 ≥2 处出处并配对策(A);只答一问的场景写"未观察到重复模式"(A2) | A、A2 |
| C10 | 忠实摘录 | 第七节"用户回答"列与 R1~R7 原话逐字一致 | A |
| C11 | 原条目不改写 | 报告副本的第一至六节与 `samples/` 原件逐字一致(用 `git diff --no-index` 比对前 37 行) | A、A2 |
| C12 | 未拷问清单 | 叫停时仍有未问的题则列出(A、A2) | A、A2 |
| C13 | 无关新请求 | 不继续拷问,报告副本无任何追加 | A3 |
| C14 | 快查豁免 | 单句核查请求出报告后不提任何拷问问题 | B |
| C15 | 端到端不漏执行 | 完整跑完想法模式后,落盘报告,随后的消息是符合 C1、C2 的第一问 | C |

---

### Task 1: RED 基线

**Files:**
- Create: `docs/superpowers/<执行日期>-v1.2.0-RED-GREEN-验证记录.md`
- Test: `SCRATCH\grill-test\red-1.md` ~ `red-3.md`(夹具报告副本)

**Interfaces:**
- Consumes: 上文"测试夹具"的首条提示词与夹具报告;此时 `skills/red-team-challenge/SKILL.md` 仍为 v1.1.0。
- Produces: 验证记录文件的"一、RED 基线"一节,Task 4 在同一文件续写"二、GREEN"。

- [ ] **Step 1: 准备夹具副本**

　　把夹具报告复制三份到 `SCRATCH\grill-test\red-1.md`、`red-2.md`、`red-3.md`。

- [ ] **Step 2: 跑三次基线**

　　在同一条消息里并行派出 3 个 `general-purpose` 子代理,提示词为夹具首条提示词,`{SKILL_PATH}` 填 `D:\work\蓝军agent\skills\red-team-challenge\SKILL.md`,`{REPORT_COPY}` 分别填三个副本的绝对路径。

　　预期(即"失败"):三次均回复"流程结束"或等价内容,不向用户提问;报告副本无改动。

- [ ] **Step 3: 处理意外结果**

　　若有任何一次自发向用户追问,逐字记录其问题,并判断它是否已满足 C1~C3。三次都自发满足,说明现版不存在该缺口,停止执行本计划并向用户报告。

- [ ] **Step 4: 写入验证记录**

　　新建验证记录文件,标题为 `# red-team-challenge v1.2.0 RED→GREEN 验证记录`,写入"一、RED 基线":夹具说明(引用本计划的夹具小节,不重复全文)、三次运行各自的回复原文、结论(现版在报告落盘后是否追问;是否区分"考虑过并否决"与"未曾想到")。

- [ ] **Step 5: Commit**

```powershell
git add docs/superpowers/*RED-GREEN-验证记录.md
git commit -m "test: v1.2.0 报告后拷问 RED 基线" -m "Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 2: 用现版 skill 自挑战设计文档

**Files:**
- Create: `docs/superpowers/<执行日期>-蓝军自挑战-报告后拷问设计.md`
- Modify(视结果): `docs/superpowers/specs/2026-11-10-post-report-grilling-design.md`、本计划 Task 3 的草案正文

**Interfaces:**
- Consumes: 已部署的 `red-team-challenge` v1.1.0(通过 Skill 工具加载);spec 文件。
- Produces: 一张"处置表"(每条 🔴🟡🔵 → 采纳 / 修改后采纳 / 不采纳 + 理由),以及据此修订后的 spec 与 Task 3 草案。Task 3 以修订后的草案为准。

- [ ] **Step 1: 发起自挑战**

　　在主会话用 Skill 工具加载 `red-team-challenge`,输入为 spec 文件路径,并声明靶子:"按『是否值得把报告后拷问做进 skill』这一决策开打,主攻 C 可行性与 D 盲区;spec 第七节列出的两个风险(推荐答案带偏用户、纪要不宜外发)是重点攻击对象。"按 skill 原样执行,包括 🔴 复核闸门。

- [ ] **Step 2: 归档报告**

　　skill 会把报告落在 spec 同目录。将其移动并改名为 `docs/superpowers/<执行日期>-蓝军自挑战-报告后拷问设计.md`。

- [ ] **Step 3: 形成处置表**

　　对报告中每条 🔴🟡🔵 给出处置:采纳、修改后采纳、不采纳,各附一句理由。处置时遵守两条:凡动摇 spec 第三节四项决策之一的,标记为"需用户决定";凡与 Global Constraints 冲突的建议,不采纳并写明冲突的是哪一条。

- [ ] **Step 4: 用户确认(检查点)**

　　向用户呈交处置表与拟对 spec 作出的修改摘要,等待明确答复。未获确认前不修改 spec,不进入 Task 3。

- [ ] **Step 5: 修订 spec 与 Task 3 草案**

　　按确认后的处置表修改 spec(状态行改为"已经自挑战修订")和本计划 Task 3 Step 1、Step 2 的草案正文,保证两者一致。

- [ ] **Step 6: Commit**

```powershell
git add docs/superpowers/
git commit -m "docs: 报告后拷问设计的蓝军自挑战与修订" -m "Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 3: 写入 skill 正文与报告模板

**Files:**
- Modify: `skills/red-team-challenge/SKILL.md`(frontmatter 第 4 行;正文第 9 行横幅;在 `## 升级到 Workflow` 之前插入新节;文末变更记录)
- Modify: `skills/red-team-challenge/references/report-template.md`(第五节末尾;文件末尾)

**Interfaces:**
- Consumes: Task 2 修订后的草案(若 Task 2 未改动草案,则用下文原文)。
- Produces: 节标题 `## 拷问环节(报告落盘后,两种模式共用)`;报告模板节标题 `## 七、拷问纪要`、`## 八、思维盲区观察`、`### 未拷问清单`。Task 4 的核对表与 Task 5 的 README、CLAUDE.md 说明都引用这些名称。

- [ ] **Step 1: 在 SKILL.md 的"报告落盘"一节之后、`## 升级到 Workflow` 之前插入下面这一节**

````markdown
## 拷问环节(报告落盘后,两种模式共用)

报告只能打写在纸上的东西。落盘后,转向**只有用户本人能回答**的问题——没写出的前提、默认的取舍、没想过的分支。

**免拷问**:范围显而易见的快查(如"审这句话有没有编造");或筛完无题可问——此时一句话说明原因后结束。

**1. 选题**(只从已落盘的报告里取):

| 来源 | 问什么 |
|---|---|
| 命门假设 / 致命问题 | 成立与否取决于只有用户掌握的信息 |
| 🟡存疑 | 联网查无来源,但用户可能有内部数据或已做过验证 |
| D 盲区 | 这个替代方案/反例,是**考虑过并否决**(要否决理由),还是**没想过**(记为盲区) |
| 隐含的决策分支 | 材料做了选择,却没写为何不选另一条路 |

两条筛选:**能查的不问**(联网或读文件能回答的,主会话自己查);**材料已写明的不问**。

**2. 排序**:按决策依赖,上游在前、下游在后;上游的回答让下游失效就跳过;同层命门优先。

**3. 发问**:一条消息只问**一个**问题,固定三部分——
- **问题**:一句话
- **为什么问**:关联报告 #几;回答将怎样改变该条判定
- **蓝军的推荐答案**:蓝军自己的判断 + 理由

第一问同时预告"共约 N 问,随时说停"。常态 5~8 问;预计超过 8 问,先告知再继续。

**4. 判回答**:每个回答当场判 站得住 / 存疑 / 被打穿。
- 含糊、回避或反问 → 同一分支追问,**每分支最多追两层**;两层仍不清 → 记 🟡 并配一个最便宜的验证实验,转下一题。
- **口头陈述不能把条目升 🟢**(铁律 6):回答里可查的事实,主会话联网核实后据实判定,原判错了就改;查不了的内部事实标"用户自述,未核查",判定保持 🟡。
- 拷问中新产生的 🔴 照常过【复核闸门】。
- 全程主会话完成,不派子代理(新 🔴 过闸门的反向复核除外)。

**5. 停**:命门分支全部有判定,或用户说停。用户没回答第一问(沉默,或转去提别的请求)→ 报告保持原样,什么都不追加。

**6. 追加到原报告文件末尾**(模板见 `references/report-template.md`):
- **七、拷问纪要**:"用户回答"列逐字摘录原话,不归纳不演绎。
- **八、思维盲区观察**:只收在材料与回答中**重复出现 ≥2 次**的推理模式,每条列出处(条目 # / 第几问)+ 对策;不足两次写"未观察到重复模式"。只评推理模式,不评人(铁律 7)。
- **未拷问清单**:叫停时没问的题;全部问完则省略。一问未答就叫停的,只追加本清单。
- 第一至六节原文**不改写**:判定变化记在纪要"条目判定变化"列(`原判 → 新判(第 N 问)`);"最该先补的 3 件事"有变,在其后追加一行"拷问后修订"。
````

- [ ] **Step 2: 修改 report-template.md**

　　在第五节"最该先补的 3 件事"列表之后追加一行:

```markdown
- **拷问后修订**(仅当拷问改变了上面 3 件事时追加,不覆盖原内容):
```

　　在文件末尾(第六节之后)追加:

```markdown

## 七、拷问纪要(报告落盘后的拷问;未进行则省略)

| # | 问题 | 关联条目 | 蓝军推荐答案 | 用户回答(逐字摘录) | 回答判定 | 条目判定变化 | 修订后的建议 |
|---|---|---|---|---|---|---|---|
| Q1 | <一句话> | #X | <判断 + 理由> | "<原话>" | 站得住/存疑/被打穿 | <原判 → 新判(第 N 问),或"不变"> | <最便宜的下一步> |

> 追问记为 Q1.1、Q1.2(每分支最多两层)。"用户回答"逐字摘录,不归纳不演绎。
> 用户自述且无法查证的事实,在"回答判定"中标"用户自述,未核查",条目判定不得升 🟢。
> 拷问中新判的 🔴 必须已过复核闸门。

## 八、思维盲区观察

| 推理模式 | 出处(≥2 处:条目 # / 第几问) | 对策 |
|---|---|---|
| <一句话描述模式,只评推理不评人> | <#3、#7、Q4> | <可执行的做法> |

> 重复不足两次的不收录;无符合条件的模式时,整节只写"未观察到重复模式"。

### 未拷问清单

- <问题> ｜ 关联条目:#X

> 用户叫停时尚未提出的问题。全部问完则省略本小节;一问未答就叫停的,只追加本小节,第七、八节省略。
```

- [ ] **Step 3: 同步版本**

　　`SKILL.md` 三处:frontmatter `version: 1.2.0`;横幅改为 `> **版本 v1.2.0** · <执行日期> · 变更记录见文末`;在变更记录列表最上方加入:

```markdown
- **v1.2.0(<执行日期>)**:新增 **拷问环节(报告落盘后,两种模式共用)**——借 grill-me 的做法,报告出完后转向只有用户能回答的问题:从报告选题(命门 / 🟡 / D 盲区 / 隐含决策分支),能查的不问,一次一问且每问带蓝军推荐答案,沿决策依赖追到命门分支收敛(每分支最多追两层,随时可停);产出追加「七、拷问纪要」「八、思维盲区观察(重复 ≥2 次才收录)」「未拷问清单」。口头陈述不能升 🟢;拷问不派子代理。经自挑战 + RED→GREEN 验证,记录见 `docs/superpowers/`。复核闸门、8 条铁律、判定档、攻击优先级未改。
```

- [ ] **Step 4: 自检**

　　运行并确认输出符合预期:

```powershell
Select-String -Path skills\red-team-challenge\SKILL.md -Pattern '1\.2\.0' | Measure-Object | Select-Object -ExpandProperty Count
git diff --stat
```

　　预期:计数为 3;`git diff --stat` 只列出 `SKILL.md` 与 `report-template.md` 两个文件。再用 `git diff skills/red-team-challenge/SKILL.md` 确认除版本三处外,原有各节没有任何行被修改或删除。

- [ ] **Step 5: Commit**

```powershell
git add skills/red-team-challenge/
git commit -m "feat: red-team-challenge v1.2.0 — 报告后拷问" -m "Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 4: GREEN 场景复跑

**Files:**
- Modify: `docs/superpowers/<执行日期>-v1.2.0-RED-GREEN-验证记录.md`(续写"二、GREEN")
- Modify(视结果): `skills/red-team-challenge/SKILL.md`、`references/report-template.md`
- Test: `SCRATCH\grill-test\` 下各场景的报告副本

**Interfaces:**
- Consumes: Task 3 产出的新版 `SKILL.md`;夹具;核对表 C1~C15。
- Produces: 验证记录"二、GREEN":每个场景的原始往来与 C1~C15 的逐项结论。Task 5 的发布以 C1~C15 全部通过为前提。

- [ ] **Step 1: 首问一致性(3 次,对应 RED 的三次)**

　　复制夹具报告为 `green-1.md`~`green-3.md`,并行派 3 个 `general-purpose` 子代理,提示词与 Task 1 Step 2 完全相同。只看各自的第一条回复:核对 C1、C2、C3。三次的问题格式应一致;三次给出三种不同格式,说明措辞约束力不足,转 Step 6。

- [ ] **Step 2: 场景 A(完整多轮)**

　　取 Step 1 中的一个子代理,用 SendMessage 按顺序发送 R1~R8。每发一条,记录对方回复原文。结束后读取其报告副本,核对 C1~C12。C11 的比对命令:

```powershell
git diff --no-index samples\国产IM想法-蓝军挑战-2026-06-02.md <报告副本路径>
```

　　预期:diff 只有新增行,且全部位于原第 37 行之后;唯一允许的例外是第五节之后新增的"拷问后修订"一行。

- [ ] **Step 3: 场景 A2(只答一问即叫停)与 A3(无关新请求)**

　　取 Step 1 的另两个子代理。A2:先发 R4,再发 R8;核对 C9(第八节为"未观察到重复模式")、C11、C12。A3:只发一条"先不说这个,帮我把这份报告转成飞书文档。(测试说明:不要真的执行转换,只说明你接下来会怎么做。)";核对 C13。

- [ ] **Step 4: 场景 B(快查豁免)**

　　派 1 个新的 `general-purpose` 子代理,提示词:

```
你要扮演一个正在执行 skill 的 Claude Code 主会话。你的工作指令是这个文件的全部内容,请先完整读取并严格遵守:
D:\work\蓝军agent\skills\red-team-challenge\SKILL.md
(它引用的 references/ 文件在同目录下,按需读取。)

用户说:"审一下这句话有没有编造:『据 Gartner 2024,全球 92% 企业已在生产环境部署生成式 AI』"

请完整执行。报告落盘到 {SCRATCH}\grill-test\scene-b-report.md。无法派子代理时,由你自己完成核查并在报告中注明。你发给用户的每条消息原样输出。不要改动仓库里的任何文件。
```

　　核对 C14:最终输出中没有拷问问题。

- [ ] **Step 5: 场景 C(端到端)**

　　派 1 个新的 `general-purpose` 子代理,提示词同 Step 4,把用户的话换成"用蓝军挑战这个想法:做一个比微信快 10 倍的国产 IM,半年内抢占 1000 万用户。",报告路径换成 `scene-c-report.md`。核对 C15。未通过(报告落盘后直接结束)时,按 spec 第七节的预案处理:在两种模式流程的"输出报告"步骤之后各加一个编号步骤"报告落盘后进入【拷问环节】",然后重跑本步骤。

- [ ] **Step 6: 修订与复跑**

　　任何核对项未通过时:先按 writing-skills 的"Match the Form to the Failure"判断失败类型(跳过规则、输出形状不对、漏掉必需元素),再改 `SKILL.md` 或模板的对应措辞,然后只重跑受影响的场景。每次修订在验证记录中记一行:未通过项、改了哪句、复跑结果。同一核对项修订三次仍不通过的,停下来向用户报告。

- [ ] **Step 7: 写入验证记录并提交**

　　在验证记录中续写"二、GREEN":各场景往来原文、C1~C15 逐项结论表、修订记录、Review Focus 第 5 条的人工观察结论。

```powershell
git add docs/superpowers/ skills/red-team-challenge/
git commit -m "test: v1.2.0 报告后拷问 GREEN 验证" -m "Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 5: 文档、部署与清理

**Files:**
- Modify: `README.md`(第 5 行版本;"它怎么打"一节末尾;"它是怎么进化的"一节末尾)
- Modify: `CLAUDE.md`("How the skill works"列表;不入库)

**Interfaces:**
- Consumes: Task 3 的节名;Task 2、Task 4 产出的两个记录文件名。
- Produces: 已部署的 v1.2.0。

- [ ] **Step 1: 更新 README.md**

　　版本行改为 `**版本 v1.2.0**`。在"开火前先锁定靶子(v1.1.0)"一段之后加入:

```markdown
**报告后拷问(v1.2.0)** — 报告只能打写在纸上的东西。落盘后蓝军转向只有你能回答的问题:一次一问,每问带它自己的推荐答案,沿决策依赖追到命门收敛,随时可停。能联网查到的它自己查,不来问你;你的口头陈述也不能把 🟡 升成 🟢。问答结论追加为报告的"拷问纪要"和"思维盲区观察"(同一推理模式重复两次以上才收录)。
```

　　在"它是怎么进化的"一节末尾加入一段,说明 v1.2.0 借用了 grill-me 的做法,并链接 Task 2 的自挑战报告与验证记录两个文件。自挑战否决或修改了哪些设计点,据 Task 2 的处置表如实写入,不夸大。

- [ ] **Step 2: 更新 CLAUDE.md**

　　在"How the skill works"列表的"Workflow escalation & honest degradation"一条之后加入:

```markdown
- **Post-report grilling (拷问环节, v1.2.0)**: after the report is saved, the main session questions the user on what only they can answer — one question per message, each with the reviewer's own recommended answer, ordered by decision dependency, max two follow-ups per branch, user can stop anytime. Anything checkable online is checked, not asked. A user's verbal claim never upgrades an item to 🟢. Output is appended to the report (七、拷问纪要 / 八、思维盲区观察 / 未拷问清单); sections 一–六 are never rewritten. No subagents, except the 🔴 gate. Quick checks are exempt.
```

　　在"Cross-file sync points"的第一条里,把涉及的文件说明补上"拷问环节的章节名(七、八、未拷问清单)同时出现在 `SKILL.md` 与 `report-template.md`"。

- [ ] **Step 3: 一致性检查**

```powershell
Select-String -Path README.md, skills\red-team-challenge\SKILL.md -Pattern 'v?1\.2\.0' | Select-Object Path, LineNumber
Select-String -Path README.md, skills\red-team-challenge\SKILL.md -Pattern '1\.1\.0' | Select-Object Path, LineNumber, Line
```

　　预期:第一条命令在 SKILL.md 命中 3 处(frontmatter、横幅、变更记录),在 README 命中版本行以及 Step 1 新增的两段;第二条命令只命中历史性表述(README"锁定靶子(v1.1.0)"与"它是怎么进化的"、SKILL.md 变更记录的 v1.1.0 条目),不含当前版本声明。

- [ ] **Step 4: 部署并核对**

```powershell
./scripts/deploy-skill.ps1
Select-String -Path "$env:USERPROFILE\.claude\skills\red-team-challenge\SKILL.md" -Pattern '^version: 1\.2\.0$'
```

　　预期:脚本输出 `Deployed red-team-challenge -> ...`;第二条命令命中 1 行。

- [ ] **Step 5: 清理与提交**

　　删除 `SCRATCH\grill-test\` 整个目录。确认 `git status --short` 只剩 `README.md` 的改动,然后:

```powershell
git add README.md
git commit -m "docs: README 更新至 v1.2.0(报告后拷问)" -m "Co-Authored-By: Claude <noreply@anthropic.com>"
```

- [ ] **Step 6: 交付说明**

　　向用户报告:C1~C15 的最终结论、自挑战改掉了什么、分支 `feat/v1.2.0-post-report-grilling` 上的提交列表。合并到 `master` 与推送由用户决定。提醒用户新开会话后新版 skill 才会生效。
