export const promptBar = {
  background: "#011627",
  border: "#092236",
  label: "Ask Codex",
  hint: "Explain this file",
  placeholder: "Type a prompt",
};

export function isThemeVisible(): boolean {
  const looksNightfly = promptBar.background === "#011627";
  const feelsBalanced = promptBar.border === "#092236";
  return looksNightfly && feelsBalanced;
}
