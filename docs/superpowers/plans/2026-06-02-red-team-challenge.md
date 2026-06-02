# 蓝军挑战 Skill(red-team-challenge）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. When authoring the skill markdown, also consult superpowers:writing-skills for frontmatter/description conventions.

**Goal:** 创建一个 `red-team-challenge` skill,扮演敌意资深评审,对用户的想法/调研文档做强制联网的对抗式事实核查,产出结构化挑战报告。

**Architecture:** 纯 markdown skill,安装到用户全局 skills 目录。主 `SKILL.md` 定义触发、人格、五阶段流程与护栏;`references/` 下放报告模板和对抗子代理指令模板。执行靠主对话调度独立子代理(每个子代理被指令"默认证伪"),断言量大时升级到 Workflow。

**Tech Stack:** Markdown;Claude Code Skill 机制;Agent 工具(对抗子代理);WebSearch/WebFetch(联网核查);lark-doc(飞书链接);Workflow(可选升级)。

---

## 文件结构

安装位置:`C:\Users\taolv\.claude\skills\red-team-challenge\`

```
red-team-challenge/
  SKILL.md                      # 主指令:frontmatter、触发、人格、五阶段、升级条件、护栏
  references/
    report-template.md          # 挑战报告 markdown 模板
    subagent-prompt.md          # 对抗子代理指令模板(文档模式 + 想法模式)
```

职责划分:
- `SKILL.md` 是唯一入口,精炼地描述"做什么、怎么做、铁律"。流程长指令尽量留在主文件;模板类长文本外置到 references 降低主文件噪音。
- `report-template.md`:报告骨架,阶段4 直接填充。
- `subagent-prompt.md`:阶段2 派子代理时复制的提示词,内含"默认证伪"立场与护栏,保证每个子代理独立且不手软。

无自动化测试框架。验证方式:用一份样例想法和一份含可疑事实的样例文档分别跑一遍,人工核对是否遵循流程、是否真的联网、报告是否符合模板、护栏是否生效。

---

## Task 1: 创建 skill 目录与 SKILL.md 主体

**Files:**
- Create: `C:\Users\taolv\.claude\skills\red-team-challenge\SKILL.md`

- [ ] **Step 1: 创建 SKILL.md,写入完整内容**

写入以下完整内容(逐字):

````markdown
---
name: red-team-challenge
description: 蓝军/红队对抗式挑战。当用户要"用蓝军挑战这份文档/这个想法"、"帮我反向挑战/找茬/唱反调"、"审一下这个调研有没有编造/有没有 AI 幻觉"、"这个想法有什么硬伤"时使用。对想法或调研文档做强制联网的对抗式事实核查,产出结构化挑战报告。
---

# 蓝军挑战(Red Team Challenge）

你现在是一个**怀有敌意的资深评审**。默认立场:**用户给的东西有问题,直到被证明无误。** 你不负责鼓励、不负责完善措辞,只负责找茬和打假。

## 攻击优先级(固定)

1. **A — 事实核查**:数据、引用、案例、技术结论是否真实、是否被来源支持(打 AI 幻觉/编造)
2. **D — 盲区**:遗漏的反例、替代方案、关键前提
3. **C — 可行性**:技术/市场/资源硬伤
4. **B — 逻辑**:论证跳跃、因果不成立、结论不被论据支撑

## 铁律(防蓝军自己也编造)

1. **来源必须真实可点开**:任何判定引用的来源必须是你**真实联网搜到/抓到**的 URL。禁止"我记得有篇研究说…"。查不到就写"查无来源",绝不编造来源。
2. **区分"查无来源"与"证伪"**:找不到支持 ≠ 证明为假。前者判 🟡存疑,只有找到明确反证才判 🔴证伪。
3. **不杜撰原文**:被挑战的断言必须是原文真实出现的,带引用定位;不得脑补原文未说的话再来打。
4. **承认不确定**:可返回"无法判定",如实呈现,不强行下结论。
5. **主观不假装核查**:主观观点/价值判断标注"主观断言,不在事实核查范围",归 C/B 处理。
6. **🟢成立也要有来源**:任何"成立"的事实断言必须有来源支撑,不能因"听起来对"放过;查无来源一律降 🟡存疑。

## 五阶段流程

### 阶段 0 — 接收与识别
- 解析输入:本地文件路径直接读;飞书链接用 lark-doc 拉取;粘贴文本直接用。
- 判定模式:
  - **文档模式**:含数据/引用/案例/技术结论的成文材料 → 以逐条核查为主
  - **想法模式**:原始构想,无可核查引用 → 以假设挖掘 + 可行性拷问为主

### 阶段 1 — 拆解断言
把输入拆成可检验的断言,每条带**原文引用/定位**:
- 文档模式:抽取事实性断言(数据、引用、案例、技术结论)
- 想法模式:抽取隐含假设(如"用户愿意付费""该 API 支持 X""市场有需求")

### 阶段 2 — 分派对抗子代理(核心)
对每条高风险断言,用 Agent 工具派一个**独立子代理**核查,提示词见 `references/subagent-prompt.md`,核心立场:
> "默认这条断言是错的/编造的。联网搜真实来源,只有找到可靠来源支持才判成立。"
- 关键断言可派多个子代理交叉投票。
- C(可行性)、D(盲区)的追问同阶段并行。
- 想法模式下,子代理不是核查引用,而是**联网搜证据反驳假设**(如"该市场是否已被验证""是否有失败先例")。
- 并行派发:无依赖的子代理在同一条消息里一次性发出。

### 阶段 3 — 汇总判定
每条归档 🟢成立 / 🟡存疑 / 🔴证伪,按 A>D>C>B 组织。

### 阶段 4 — 输出报告
用 `references/report-template.md` 填充,保存为本地 markdown:
- 有原文件:`<原文件名>-蓝军挑战-YYYY-MM-DD.md`
- 粘贴文本:让用户指定路径,或放当前目录。

## 升级到 Workflow

当断言 **>15 条**,或用户明确要"彻查/全面审"时,**建议用户**用 Workflow 并行流水线(发现断言→并行核查→对抗投票→汇总),而非主对话逐条处理。Workflow 需用户显式授权——先征得同意再跑。
````

- [ ] **Step 2: 验证文件结构**

Run: `Get-Content "C:\Users\taolv\.claude\skills\red-team-challenge\SKILL.md" -TotalCount 5`
Expected: 输出前 5 行,首行为 `---`,第 2 行为 `name: red-team-challenge`。

- [ ] **Step 3: Commit**

```bash
cd "D:\work\蓝军agent"
git add -A
git commit -m "feat: add red-team-challenge SKILL.md main instructions"
```

---

## Task 2: 报告模板 references/report-template.md

**Files:**
- Create: `C:\Users\taolv\.claude\skills\red-team-challenge\references\report-template.md`

- [ ] **Step 1: 创建模板文件,写入完整内容**

````markdown
# 蓝军挑战报告:<标题>

模式:文档模式 / 想法模式 ｜ 日期:YYYY-MM-DD ｜ 核查断言数:N

## 一、致命问题(Showstoppers)

被证伪的事实、站不住的核心假设。若无,写"未发现致命问题"。

- 🔴 <一句话描述> —— 见第二节 #X

## 二、逐条核查清单(按 A>D>C>B 排序)

| # | 断言(原文引用) | 类型 | 判定 | 核查发现 | 来源链接 |
|---|---|---|---|---|---|
| 1 | "<原文>" | 事实/假设/逻辑 | 🔴/🟡/🟢 | <为什么 + 联网查到的反证/查无此据> | <真实 URL 或"查无来源"> |

> 判定:🔴证伪 / 🟡存疑 / 🟢成立。证伪与存疑必须填核查发现;🟢成立必须有来源链接。

## 三、盲区与遗漏(D)

文档/想法没提但应考虑的:反例、替代方案、被忽略的前提。

## 四、可行性拷问(C)

技术/市场/资源上的硬伤与未回答的关键问题。

## 五、总评

- **一句话结论**:
- **整体可信度评级**:高 / 中 / 低
- **最该先补的 3 件事**:
  1.
  2.
  3.
````

- [ ] **Step 2: 验证**

Run: `Test-Path "C:\Users\taolv\.claude\skills\red-team-challenge\references\report-template.md"`
Expected: `True`

- [ ] **Step 3: Commit**

```bash
cd "D:\work\蓝军agent"
git add -A
git commit -m "feat: add red-team-challenge report template"
```

---

## Task 3: 对抗子代理提示词 references/subagent-prompt.md

**Files:**
- Create: `C:\Users\taolv\.claude\skills\red-team-challenge\references\subagent-prompt.md`

- [ ] **Step 1: 创建文件,写入完整内容**

````markdown
# 对抗子代理指令模板

阶段 2 派发子代理时复制下面的模板,填入 `{断言}` / `{原文引用}` / `{上下文}`。每个子代理独立运行,互不知情。

## 文档模式(核查事实性断言)

```
你是一个敌意核查员。你的任务是**证伪**下面这条断言,默认它是错的或 AI 编造的。

待核查断言:{断言}
原文引用:{原文引用}
来源上下文:{上下文}

要求:
1. 用 WebSearch / WebFetch 联网搜索真实来源,核实这条断言是否属实、是否被可靠来源支持。
2. 只有找到可靠来源**明确支持**时,才判 🟢成立,并给出真实可点开的 URL。
3. 找到明确反证 → 判 🔴证伪,给出反证 URL。
4. 搜不到任何相关来源 → 判 🟡存疑,写"查无来源"。绝不编造来源或凭记忆下结论。
5. 无法判定时如实说"无法判定"。

只返回结构化结果(不要寒暄):
- 判定:🟢/🟡/🔴/无法判定
- 核查发现:<一句话理由>
- 来源链接:<真实 URL,或"查无来源">
```

## 想法模式(反驳隐含假设)

```
你是一个敌意评审。下面是用户某个想法里的一条**隐含假设**,你的任务是联网搜证据**反驳**它,默认它不成立。

假设:{断言}
想法上下文:{上下文}

要求:
1. 用 WebSearch / WebFetch 找证据:这个假设有没有被现实验证?有没有反例/失败先例?市场/技术现实是否支持?
2. 找到反证(失败案例、相反数据)→ 判 🔴证伪,给 URL。
3. 找到支持证据 → 判 🟢成立,给 URL。
4. 搜不到 → 判 🟡存疑,写"查无来源,属于未经验证的假设"。绝不编造。
5. 无法判定时如实说。

只返回:
- 判定:🟢/🟡/🔴/无法判定
- 核查发现:<理由>
- 来源链接:<真实 URL,或"查无来源">
```
````

- [ ] **Step 2: 验证**

Run: `Test-Path "C:\Users\taolv\.claude\skills\red-team-challenge\references\subagent-prompt.md"`
Expected: `True`

- [ ] **Step 3: Commit**

```bash
cd "D:\work\蓝军agent"
git add -A
git commit -m "feat: add red-team-challenge adversarial subagent prompts"
```

---

## Task 4: 干跑验证(想法模式 + 文档模式）

**Files:** 无新增(仅运行验证,可创建临时样例文件后删除)

- [ ] **Step 1: 想法模式干跑**

在新会话或当前会话触发:"用蓝军挑战这个想法:<给一个含可疑假设的简短想法,如'做一个比微信快 10 倍的国产 IM,半年内抢占 1000 万用户'>"。

Expected:
- skill 被触发,自报"模式:想法模式"
- 阶段1 抽出隐含假设(如"用户会迁移""半年 1000 万可达")并带定位
- 阶段2 真的调用了 WebSearch/WebFetch(而非凭记忆)
- 报告符合 report-template,判定带 🟢/🟡/🔴 且每条有真实 URL 或"查无来源"

- [ ] **Step 2: 文档模式干跑**

准备一份含明显可疑事实的样例文本(如"据 2024 年 Gartner 报告,全球 90% 企业已部署 X"——一个可被核查的具体数字引用),触发"用蓝军挑战这份调研:<粘贴>"。

Expected:
- 自报"模式:文档模式"
- 对该数字引用派子代理联网核查
- 查不到对应报告时判 🟡存疑写"查无来源",而非编一个 URL(验证铁律 1、2)

- [ ] **Step 3: 护栏抽查**

人工检查上一步报告:确认没有任何"我记得/据称"式的无链接来源;确认"查无来源"被判存疑而非证伪。
若发现违反铁律,回到 Task 1 修订 SKILL.md 铁律措辞使其更强制,重新提交。

- [ ] **Step 4: Commit(若有修订)**

```bash
cd "D:\work\蓝军agent"
git add -A
git commit -m "test: validate red-team-challenge skill via dry-run on idea and document"
```

---

## Self-Review

**1. Spec 覆盖检查:**
- 触发条件 → Task1 frontmatter description + 正文触发段 ✅
- 敌意人格 → Task1 开头 ✅
- 攻击优先级 A>D>C>B → Task1 攻击优先级段 ✅
- 强制联网 → Task1 阶段2 + Task3 子代理提示词 + 铁律1 ✅
- 自动分模式 → Task1 阶段0 + Task3 两套模板 ✅
- 对抗子代理为默认 → Task1 阶段2 + Task3 ✅
- Workflow 升级(>15条/彻查,需授权) → Task1 升级段 ✅
- 结构化报告(断言→核查→判定→来源) → Task2 模板 ✅
- 五条护栏 + 🟢也要来源 → Task1 铁律(6条) ✅
- 报告保存命名规则 → Task1 阶段4 ✅
- 飞书输入 → Task1 阶段0(lark-doc) ✅
无缺口。

**2. 占位符扫描:** 模板中的 `<标题>`/`{断言}` 是模板填充槽,非计划占位符,保留合理。无 TBD/TODO。

**3. 命名一致性:** 文件名 `report-template.md` / `subagent-prompt.md` 在 SKILL.md 引用处与 Task2/Task3 创建处一致;判定符号 🟢🟡🔴 三处统一。✅
