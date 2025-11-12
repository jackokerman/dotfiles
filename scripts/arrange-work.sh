#!/bin/bash
# Arrange all work workspaces using aerospace-layout-manager

echo "╔═══════════════════════════════════════╗"
echo "║   Arranging Work Workspaces           ║"
echo "╚═══════════════════════════════════════╝"
echo ""

echo "→ Workspace B (Browser)"
aerospace-layout-manager browser
echo ""

echo "→ Workspace M (Messaging)"
aerospace-layout-manager messaging
echo ""

echo "→ Workspace N (Notes)"
aerospace-layout-manager notes
echo ""

echo "→ Workspace T (Tasks)"
aerospace-layout-manager tasks
echo ""

echo "╔═══════════════════════════════════════╗"
echo "║   ✓ All Workspaces Arranged           ║"
echo "╚═══════════════════════════════════════╝"

