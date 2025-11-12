#!/bin/bash
# Phase 1: Test script to see what aerospace reports
# This ONLY lists windows - it doesn't change anything

echo "=== All Open Windows ==="
echo ""
/opt/homebrew/bin/aerospace list-windows --all --format '%{window-id}|%{app-name}|%{window-title}|%{workspace}'
echo ""
echo "=== End of List ==="

