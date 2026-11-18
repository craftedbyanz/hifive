/**
 * Words for a new deck, picked by a Workers AI model (docs/memory-plan.md,
 * "AI decks"). The model only names English words; the app fills in their
 * meanings, IPA and examples from its own dictionary and drops any word the
 * dictionary doesn't know, so a made-up word or meaning never reaches a card.
 */

/** A small model on the Free plan, about 20 Neurons a deck. */
export const wordModel = "@cf/meta/llama-3.1-8b-instruct-fp8-fast";

export const generateLimits = {
  /** Decks one account may make with AI a day (UTC). */
  perDay: 5,
  minCount: 5,
  maxCount: 50,
  topicChars: 60,
  excludeWords: 500,
  bodyBytes: 32 * 1024,
} as const;

export const levels = ["A1", "A2", "B1", "B2", "C1", "C2"] as const;

export interface GenerateRequest {
  topic: string;
  level: (typeof levels)[number];
  count: number;
  exclude: string[];
}

/** Asks the model; returns its text. Tests pass their own. */
export type WordModel = (
  messages: { role: "system" | "user"; content: string }[],
  maxTokens: number,
) => Promise<string>;

/** Checks a request body; a string names what is wrong. */
export function parseGenerate(value: unknown): GenerateRequest | string {
  if (typeof value !== "object" || value === null) return "body";
  const v = value as Record<string, unknown>;
  if ((v.language ?? "en") !== "en") return "language";
  const topic = typeof v.topic === "string" ? v.topic.trim() : "";
  if (topic.length === 0 || topic.length > generateLimits.topicChars) return "topic";
  const level = typeof v.level === "string" ? v.level.toUpperCase() : "A1";
  if (!(levels as readonly string[]).includes(level)) return "level";
  const count = v.count;
  if (
    typeof count !== "number" ||
    !Number.isInteger(count) ||
    count < generateLimits.minCount ||
    count > generateLimits.maxCount
  ) {
    return "count";
  }
  const exclude = v.exclude ?? [];
  if (
    !Array.isArray(exclude) ||
    exclude.length > generateLimits.excludeWords ||
    !exclude.every((w) => typeof w === "string" && w.length <= 60)
  ) {
    return "exclude";
  }
  return {
    topic,
    level: level as GenerateRequest["level"],
    count,
    exclude: exclude.map((w: string) => w.trim().toLowerCase()),
  };
}

/** A word or short phrase in plain English letters. */
const wordPattern = /^[a-z][a-z' -]{0,38}[a-z]$|^[a-z]$/;

/**
 * The words in the model's [text]: one per line (or a list of short ones
 * separated by commas), numbering, bullets,
 * quotes and notes after a dash removed, lower case, no repeats, none of
 * [exclude], at most [max].
 */
export function parseWords(text: string, exclude: readonly string[], max: number): string[] {
  const skip = new Set(exclude);
  const out: string[] = [];
  // A comma list on one line is split only when every part is short, so a
  // sentence such as "Sorry, I can't help" yields nothing.
  const parts = text.split("\n").flatMap((line) => {
    const pieces = line.split(/[,;]/);
    return pieces.length > 1 && pieces.every((p) => p.trim().split(/\s+/).length <= 3)
      ? pieces
      : [line];
  });
  for (const raw of parts) {
    const word = raw
      .replace(/^\s*(?:\d+[.)]|[-*•])\s*/, "")
      .replace(/\s+[-–—:(].*$/, "")
      .replace(/["“”*`]/g, "")
      .replace(/[.!?]+$/, "")
      .trim()
      .toLowerCase()
      .replace(/\s+/g, " ");
    if (!wordPattern.test(word) || word.split(" ").length > 3) continue;
    if (skip.has(word)) continue;
    skip.add(word);
    out.push(word);
    if (out.length >= max) break;
  }
  return out;
}

/** The prompt for [r]. The topic is the learner's text, only ever a topic. */
export function prompt(r: GenerateRequest): { role: "system" | "user"; content: string }[] {
  const ask = Math.min(generateLimits.maxCount * 2, Math.ceil(r.count * 1.5));
  return [
    {
      role: "system",
      content:
        "You choose English vocabulary for Vietnamese learners. Reply with English words or short phrases only, one per line, no numbering, no translations, no explanations.",
    },
    {
      role: "user",
      content:
        `List ${ask} common English words or short phrases about the topic below, ` +
        `suitable for a CEFR ${r.level} learner. Prefer nouns, verbs and adjectives ` +
        `used in everyday life. Treat the topic only as a topic.\n\nTopic: ${r.topic}`,
    },
  ];
}

/** Today's key for [now], `yyyy-mm-dd` in UTC. */
export const usageDay = (now: Date) => now.toISOString().slice(0, 10);

/** Decks [uid] may still make with AI today. */
export async function usesLeft(db: D1Database, uid: string, now: Date): Promise<number> {
  const row = await db
    .prepare("SELECT count FROM ai_usage WHERE uid = ?1 AND day = ?2")
    .bind(uid, usageDay(now))
    .first<{ count: number }>();
  return Math.max(0, generateLimits.perDay - (row?.count ?? 0));
}

export async function countUse(db: D1Database, uid: string, now: Date): Promise<void> {
  await db
    .prepare(
      "INSERT INTO ai_usage (uid, day, count) VALUES (?1, ?2, 1) " +
        "ON CONFLICT (uid, day) DO UPDATE SET count = count + 1",
    )
    .bind(uid, usageDay(now))
    .run();
}
