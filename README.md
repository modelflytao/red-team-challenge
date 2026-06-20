# 蓝军挑战 · red-team-challenge

> A hostile senior reviewer for your docs and ideas — it assumes everything you wrote is wrong until proven otherwise, and does exactly one job: find the holes. A Claude Code skill.

**版本 v1.1.0** · Claude Code skill · 中文

## 这是什么

`red-team-challenge`(蓝军挑战)是一个 [Claude Code](https://claude.com/claude-code) skill,扮演一个**怀有敌意的资深评审**。默认立场:**你给的东西有问题,直到被证明无误。** 它不负责鼓励、不负责帮你润色措辞,只负责找茬、打假、挖盲区——并逼想法进化,而不是杀死它。

名字呼应华为"蓝军"机制:倡导自我批判,用一支专职唱反调的力量去攻击自己的方案。

## 它怎么打

**固定攻击优先级**:`A 事实核查 > D 盲区 > C 可行性 > B 逻辑`

**判定档**:

| 符号 | 含义 |
|---|---|
| 🟢 成立 | 有真实来源支撑 |
| 🟡 存疑 | 查无来源,既不能证实也不能证伪 |
| 🔴 证伪 | 找到明确反证(必过复核闸门) |
| 🔵 可优化 | 事实成立,但有更省/更快/更高杠杆的更优解 |

**两种模式(自动识别)**:

- **文档模式** — 逐条抽取事实性断言(数据/引用/案例/技术结论),派对抗子代理联网核查,逐条定级并给反哺动作。
- **想法模式** — 五步法:拆假设 → 三视角围攻(对手/用户/资源)→ 事前验尸(Pre-mortem)→ 对抗定级(标出"命门"假设)→ 反哺(为每条 🔴🟡 设计最便宜的验证实验或 Plan B)。

**开火前先锁定靶子(v1.1.0)** — 材料涉及某个决策、或有多种读法时,先一句话声明"挑战范围 + 对齐的决策 + 主攻轴",再立即开打(非阻塞),避免打错靶。

## 防"蓝军自己也编造"

对抗式评审最大的风险,是评审自己开始幻觉、为反对而反对。本 skill 用两道防线压制:

- **8 条铁律** — 来源必须真实可点开、区分"查无来源"与"证伪"、不杜撰原文、对事不对人、不许为反对而反对……
- **🔴 复核闸门** — 任何"证伪"写进报告前,必过 ① 反向复核子代理(立场反转,默认这是错杀)+ ② 主会话 WebFetch 来源抽查。任一不过,降级为 🟡。

> 这套闸门不是摆设。v1.1.0 升级时,我们用本 skill 去挑战它自己的升级建议(dogfood),复核闸门当场两次拦下对抗子代理的过度证伪——包括一次张冠李戴的引用和一次虚增的反证细节。

## 怎么用

对 Claude Code 说:

- "用蓝军挑战这份文档 / 这个想法"
- "帮我反向挑战 / 找茬 / 唱反调"
- "审一下这个调研有没有编造 / 有没有 AI 幻觉"
- "这个想法有什么硬伤"

输入支持:本地文件路径、粘贴文本、飞书文档链接(经 lark-doc 拉取)。产出一份结构化挑战报告,落盘为 `<原名>-蓝军挑战-YYYY-MM-DD.md`。

**部署**:仓库 `skills/` 是唯一事实来源,`~/.claude/skills/` 只是部署产物。改完同步:

```powershell
./scripts/deploy-skill.ps1
```

依赖:Claude Code(需 Agent 子代理 + WebSearch/WebFetch);可选 lark-doc(飞书链接)、Workflow(断言 >15 条时的并行彻查)。

## 看个真实例子

`samples/` 里有两份真实输出:

- **《生成式 AI 调研》** — 抓出"据 Gartner 2024,全球 92% 企业已在生产环境部署生成式 AI"系**编造**:真实 Gartner 数据为 29% 已部署,92% 疑为把"到 2026 年超 80%"的未来预测篡改成现状。
- **《比微信快 10 倍的国产 IM》** — 证伪"半年抢 1000 万用户"(来往、子弹短信、米聊的历史失败反复证伪),并指出攻击点选错了战场:壁垒是社交关系链,不是速度。

## 仓库结构

```
skills/red-team-challenge/   # skill 本体(唯一事实来源)
  SKILL.md                   #   主指令:人格、攻击优先级、8 铁律、复核闸门、两模式
  references/                #   子代理提示词、报告模板、Workflow 脚本模板
docs/superpowers/            # 设计文档、实现计划、自挑战复盘
samples/                     # 两份真实挑战报告
scripts/deploy-skill.ps1     # 部署到 ~/.claude/skills/
```

## 它是怎么进化的

v1.1.0 的两个新能力(🔵可优化、锁定靶子)不是拍脑袋加的,而是把一份"升级建议"喂给这个 skill 自己跑(dogfood),让 4 个独立对抗子代理去打。结果 8 条建议里 6 条被否决或缩水——增子代理的"增效 pass"、死台账 + 采纳率 KPI、阻塞式前置契约、🟢 普查复核……只留下两条"便宜版"(复用已有机制、零额外子代理)。

全过程按 `superpowers:writing-skills` 的 RED→GREEN 纪律:先看现版在哪失败,再改,再复跑验证。复盘见 [`docs/superpowers/2026-06-20-蓝军自挑战-升级建议复盘.md`](docs/superpowers/2026-06-20-蓝军自挑战-升级建议复盘.md)。

## 变更记录

见 [`skills/red-team-challenge/SKILL.md`](skills/red-team-challenge/SKILL.md) 文末。

---

*这是一个个人 Claude Code skill 项目,部署脚本面向 Windows / PowerShell。*
