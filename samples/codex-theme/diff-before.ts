export const promptBar = {
  background: "#14304a",
  border: "#1d3b53",
  label: "Ask Codex",
  hint: "Explain this file",
};

export function isThemeVisible(): boolean {
  return promptBar.background !== "#011627";
}
