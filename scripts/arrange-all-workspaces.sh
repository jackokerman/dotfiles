#!/bin/bash
# Phase 5: Master script - Arrange all workspaces at once

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "╔═══════════════════════════════════════╗"
echo "║   Arranging All Workspaces            ║"
echo "╚═══════════════════════════════════════╝"
echo ""

# Workspace B: Browser (Work)
echo "→ Workspace B (Browser - Work)"
"$SCRIPT_DIR/arrange-workspace-b.sh"
echo ""

# Workspace M: Messaging
echo "→ Workspace M (Messaging)"
"$SCRIPT_DIR/arrange-workspace-m.sh"
echo ""

# Workspace N: Notes
echo "→ Workspace N (Notes)"
"$SCRIPT_DIR/arrange-workspace-n.sh"
echo ""

# Workspace P: Personal Browser
echo "→ Workspace P (Personal Browser)"
"$SCRIPT_DIR/arrange-workspace-p.sh"
echo ""

# Workspace T: Tasks
echo "→ Workspace T (Tasks)"
"$SCRIPT_DIR/arrange-workspace-t.sh"
echo ""

echo "╔═══════════════════════════════════════╗"
echo "║   ✓ All Workspaces Arranged           ║"
echo "╚═══════════════════════════════════════╝"

