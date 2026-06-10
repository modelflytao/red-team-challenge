# Workflow 脚本模板(文档彻查)

断言 >15 条或用户要"彻查"且已显式授权 Workflow 时,用下面的脚本调用 Workflow 工具。调用时把文档全文通过 `args` 传入:`args: { document: "<文档全文>", topN: 30 }`。

脚本已内置:拆解→风险分级→并行敌意核查→🔴 强制反向复核→汇总。复核不通过的 🔴 自动降 🟡。

```js
export const meta = {
  name: 'red-team-document-audit',
  description: '蓝军文档彻查:拆解断言→并行敌意核查→🔴反向复核→汇总',
  phases: [
    { title: '拆解', detail: '抽取可检验断言并风险分级' },
    { title: '核查', detail: '每条断言一个敌意核查子代理' },
    { title: '复核', detail: '所有 🔴 判定反向复核' },
  ],
}

const CLAIMS_SCHEMA = {
  type: 'object',
  properties: {
    claims: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          quote: { type: 'string', description: '原文引用' },
          claim: { type: 'string', description: '可检验断言' },
          risk: { enum: ['高', '低'] },
        },
        required: ['quote', 'claim', 'risk'],
      },
    },
  },
  required: ['claims'],
}

const VERDICT_SCHEMA = {
  type: 'object',
  properties: {
    verdict: { enum: ['成立', '存疑', '证伪', '无法判定'] },
    finding: { type: 'string', description: '一句话理由' },
    urls: { type: 'array', items: { type: 'string' }, description: '真实可点开的来源 URL' },
    queries: { type: 'array', items: { type: 'string' }, description: '实际使用过的搜索词' },
  },
  required: ['verdict', 'finding', 'urls', 'queries'],
}

const REVIEW_SCHEMA = {
  type: 'object',
  properties: {
    pass: { type: 'boolean', description: '证伪是否成立' },
    reason: { type: 'string' },
    queries: { type: 'array', items: { type: 'string' } },
  },
  required: ['pass', 'reason', 'queries'],
}

phase('拆解')
const { claims } = await agent(
  `从下面材料中抽取可检验的事实性断言(数据/引用/案例/技术结论),每条带原文引用,` +
  `并按风险分级:支撑核心结论、数字精确、引用具体来源 = 高,其余 = 低。\n\n材料:\n${args.document}`,
  { schema: CLAIMS_SCHEMA }
)
const topN = args.topN || 30
const deep = claims.filter(c => c.risk === '高').concat(claims.filter(c => c.risk === '低')).slice(0, topN)
if (deep.length < claims.length) log(`共 ${claims.length} 条断言,仅深查前 ${deep.length} 条,其余将在报告中标注"未深查"`)

const results = await pipeline(
  deep,
  c => agent(
    `你是敌意核查员,默认下面断言是错的或 AI 编造的。用 WebSearch/WebFetch 联网搜真实来源核查:` +
    `只有可靠来源明确支持才判"成立";找到明确反证判"证伪";查无来源判"存疑"。绝不编造来源或凭记忆下结论。\n` +
    `断言:${c.claim}\n原文引用:${c.quote}`,
    { label: `核查:${c.claim.slice(0, 20)}`, phase: '核查', schema: VERDICT_SCHEMA }
  ),
  async (v, c) => {
    if (!v) return null
    if (v.verdict !== '证伪') return { ...c, ...v }
    const review = await agent(
      `你是复核员。前一个核查员把断言"${c.claim}"判为证伪,理由:${v.finding},反证:${v.urls.join(' ')}。` +
      `你的任务是推翻这个证伪(默认它是错杀):用 WebFetch 打开反证 URL 验证真实性与相关性,` +
      `并用 WebSearch 独立搜索支持原断言的可靠来源。反证打不开/内容不符/找到可靠支持来源 → pass=false。`,
      { label: `复核:${c.claim.slice(0, 20)}`, phase: '复核', schema: REVIEW_SCHEMA }
    )
    if (review && !review.pass) return { ...c, ...v, verdict: '存疑', finding: `${v.finding}(🔴复核不通过降级:${review.reason})` }
    return { ...c, ...v, reviewNote: review ? review.reason : '复核子代理失败,保守降级' , verdict: review ? v.verdict : '存疑' }
  }
)

const skipped = claims.filter(c => !deep.includes(c)).map(c => ({ ...c, verdict: '存疑', finding: '未深查', urls: [], queries: [] }))
return { checked: results.filter(Boolean), skipped }
```

主会话拿到返回值后,按 `references/report-template.md` 渲染报告:`checked` 进逐条清单,`skipped` 逐条标注"未深查"。
