type Accent = "blue" | "green" | "violet" | "amber";

interface ThemeCheck {
  readonly id: string;
  readonly active: boolean;
  readonly accents: Accent[];
  readonly contrastScore: number;
}

const checks: ThemeCheck[] = [
  {
    id: "syntax-core",
    active: true,
    accents: ["blue", "green", "violet", "amber"],
    contrastScore: 9.4,
  },
  {
    id: "prompt-bar",
    active: false,
    accents: ["blue", "violet"],
    contrastScore: 7.8,
  },
];

class NightflyInspector {
  constructor(private readonly source = "codex") {}

  public summarize(check: ThemeCheck): string {
    const icon = check.active ? "ok" : "review";
    const accents = check.accents.join(", ");
    return `${icon}:${this.source}:${check.id}:${accents}:${check.contrastScore.toFixed(1)}`;
  }

  public needsAdjustment(check: ThemeCheck): boolean {
    return !check.active || check.contrastScore < 8.5;
  }
}

const inspector = new NightflyInspector();
const highlighted = checks
  .filter((check) => check.accents.includes("blue") && /prompt|syntax/.test(check.id))
  .map((check) => ({
    ...check,
    summary: inspector.summarize(check),
    needsAdjustment: inspector.needsAdjustment(check),
  }));

for (const check of highlighted) {
  if (check.needsAdjustment) {
    console.log(`review -> ${check.summary}`);
    continue;
  }

  console.log(`pass -> ${check.summary}`);
}

export function pickAccent(score: number): Accent {
  if (score >= 9) return "blue";
  if (score >= 8.5) return "green";
  if (score >= 8) return "violet";
  return "amber";
}
