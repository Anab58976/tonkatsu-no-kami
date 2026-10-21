#!/bin/bash
# Parses every GDScript (autoload-aware: unknown-autoload false positives are filtered).
cd "$(dirname "$0")/.."
AUTOLOADS="Game|InputConfig|SpriteLibrary|AudioDirector|SaveManager|ItemDB|QuestManager|SceneRouter|DialogueManager"
for f in $(find autoload scripts tests -name "*.gd" 2>/dev/null); do
  out=$(timeout 60 ../tools/godot --headless --path . --check-only --script "res://$f" 2>&1 | grep -A1 -E "SCRIPT ERROR" | grep -v -E "Identifier not found: ($AUTOLOADS)$" )
  real=$(echo "$out" | grep "SCRIPT ERROR" | grep -v -E "Identifier not found: ($AUTOLOADS)|Compile Error: $")
  if [ -n "$real" ]; then echo "== $f"; echo "$out" | grep -v -E "Compile Error: $" | head -6; fi
done
echo "check done"
