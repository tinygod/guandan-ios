export const meta = {
  name: 'guandan-asc-localize',
  description: 'Localize the App Store listing (6 fields) into 12 languages, writing fastlane metadata files',
  phases: [{ title: 'Localize', detail: '12 App Store locales' }],
}

const MASTER = {"name": "Coach Pan: Learn GuanDan", "subtitle": "Master the game, hand by hand", "promotional_text": "Train against an AI tuned by thousands of self-play matches, and master GuanDan one hand at a time — now in 12 languages.", "keywords": "guandan,card game,strategy,tutorial,coach,AI,bomb,tractor,trick,learn,trainer,tichu", "description": "Coach Pan turns GuanDan (掼蛋) — China's most-played card game, with over 100 million players — into a game you can actually master.\n\nMost apps just let you play. Coach Pan teaches you to WIN.\n\nLEARN BY DOING\n• 31 hands-on lessons, from your very first deal to championship-level endgame tactics\n• Scripted real-game scenarios with a coach explaining every single move\n• Quick quizzes that check you truly got it\n\nPLAY A SMART AI\n• Bots tuned by thousands of self-play matches and by studying champion engines\n• Card-counting, tribute strategy, blocking and feeding — the AI plays like a real partner and a real rival\n• Review any hand move-by-move with the coach\n\nWHAT YOU'LL MASTER\n• Striker vs support roles and the all-important opening-lead signals\n• Bombs, straight flushes, tubes and plates — when to build them and when to spend them\n• Tribute and return-tribute, wildcards, and engineering the caught-wind finish\n• Data-backed folk rules the champions actually use\n\nWhether you're sitting down at your very first table or sharpening up for the next tournament, Coach Pan is the partner that makes you better every hand.\n\nNow fully localized in 12 languages.", "release_notes": "Welcome to Coach Pan! Learn and master GuanDan with 31 lessons, a self-play-trained AI, move-by-move review — now fully localized in 12 languages."}
const TASKS = [{"lang": "Simplified Chinese (简体中文)", "asc": "zh-Hans"}, {"lang": "Traditional Chinese (繁體中文)", "asc": "zh-Hant"}, {"lang": "Japanese (日本語)", "asc": "ja"}, {"lang": "Korean (한국어)", "asc": "ko"}, {"lang": "Spanish - Spain (Español)", "asc": "es-ES"}, {"lang": "French (Français)", "asc": "fr-FR"}, {"lang": "German (Deutsch)", "asc": "de-DE"}, {"lang": "Brazilian Portuguese (Português do Brasil)", "asc": "pt-BR"}, {"lang": "Russian (Русский)", "asc": "ru"}, {"lang": "Arabic (العربية)", "asc": "ar-SA"}, {"lang": "Hindi (हिन्दी)", "asc": "hi"}, {"lang": "Indonesian (Bahasa Indonesia)", "asc": "id"}]
const ROOT = "/Users/yorick.w/claudecode/guandan-ios/App/fastlane/metadata"

const SCHEMA = {
  type: 'object',
  properties: {
    locale: { type: 'string' },
    nameLen: { type: 'integer' },
    subtitleLen: { type: 'integer' },
    promoLen: { type: 'integer' },
    keywordsLen: { type: 'integer' },
  },
  required: ['locale','nameLen','subtitleLen','promoLen','keywordsLen'],
  additionalProperties: false,
}

phase('Localize')
const results = await parallel(TASKS.map((t) => () => {
  const dir = `${ROOT}/${t.asc}`
  const prompt = [
    `You are an expert App Store marketing localizer. Localize this iOS app's App Store listing into ${t.lang}.`,
    `The app "Coach Pan" teaches GuanDan (掼蛋), China's most-played card game, with 31 lessons, a self-play-trained AI, and move-by-move review.`,
    ``,
    `Localize MARKETING-STYLE — compelling and natural for native speakers of this market, NOT a literal translation. Keep the energy and the concrete selling points.`,
    ``,
    `HARD CHARACTER LIMITS (App Store will reject if exceeded — count characters, CJK counts as 1 each):`,
    `- name.txt: <= 30 chars`,
    `- subtitle.txt: <= 30 chars`,
    `- promotional_text.txt: <= 170 chars`,
    `- keywords.txt: <= 100 chars, comma-separated, NO spaces between terms; use terms THIS market actually searches; localize them`,
    `- description.txt: <= 4000 chars; keep the bullet structure (• ) and blank lines`,
    `- release_notes.txt: <= 4000 chars`,
    ``,
    `Rules: keep the mascot name "Coach Pan" (transliterate consistently if natural); localize "GuanDan" naturally for the market (transliterate if no common name); keep emoji/• bullets; for Arabic produce natural RTL text.`,
    ``,
    `English master to localize (JSON):`,
    JSON.stringify(MASTER),
    ``,
    `Write SIX UTF-8 text files into the directory ${dir} (create it; use the Write tool), one per field, named exactly:`,
    `name.txt, subtitle.txt, promotional_text.txt, keywords.txt, description.txt, release_notes.txt`,
    `Each file contains ONLY the localized text for that field (no quotes, no labels).`,
    `Double-check name and subtitle are each <= 30 characters before writing.`,
    `Then return { locale: "${t.asc}", nameLen, subtitleLen, promoLen, keywordsLen } with the actual character counts.`,
  ].join('\n')
  return agent(prompt, { label: t.asc, phase: 'Localize', schema: SCHEMA, agentType: 'general-purpose' })
}))

const ok = results.filter(Boolean)
log(`Localized ${ok.length}/${TASKS.length} App Store locales`)
return { done: ok.length, total: TASKS.length, results: ok }
