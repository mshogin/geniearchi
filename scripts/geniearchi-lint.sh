#!/bin/bash
# Cross-tool pipeline CLI for GenieArchi ecosystem
# Usage: echo "text" | geniearchi-lint.sh [--project /path]
# Runs: seclint -> promptlint -> costlint -> archlint (if project given)
# Output: unified JSON report

TEXT=$(cat)
PROJECT=""
GO=/home/assistant/bin/go/bin/go

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --project|-p)
            PROJECT="$2"
            shift 2
            ;;
        *)
            # Positional arg treated as project path (legacy compat)
            PROJECT="$1"
            shift
            ;;
    esac
done

# Run all linters in parallel using temp files
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

SEC_OUT="$TMPDIR/sec.json"
PROMPT_OUT="$TMPDIR/prompt.json"
ROUTE_OUT="$TMPDIR/route.json"
COST_OUT="$TMPDIR/cost.json"
ARCH_OUT="$TMPDIR/arch.json"

# Launch linters in parallel
echo "$TEXT" | (cd /home/assistant/projects/seclint && $GO run ./cmd/seclint rate 2>/dev/null) > "$SEC_OUT" &
PID_SEC=$!

echo "$TEXT" | (cd /home/assistant/projects/promptlint && $GO run ./cmd/promptlint analyze 2>/dev/null) > "$PROMPT_OUT" &
PID_PROMPT=$!

echo "$TEXT" | (cd /home/assistant/projects/promptlint && $GO run ./cmd/promptlint route 2>/dev/null) > "$ROUTE_OUT" &
PID_ROUTE=$!

echo "$TEXT" | (cd /home/assistant/projects/costlint && $GO run ./cmd/costlint estimate --model sonnet 2>/dev/null) > "$COST_OUT" &
PID_COST=$!

# Wait for all linters
wait $PID_SEC $PID_PROMPT $PID_ROUTE $PID_COST

# Optional: archlint scan if project path given
if [ -n "$PROJECT" ]; then
    bash /home/assistant/projects/archlint-repo/scripts/agent-report.sh "$PROJECT" 2>/dev/null > "$ARCH_OUT"
else
    echo "null" > "$ARCH_OUT"
fi

# Merge all results into unified report
python3 - "$SEC_OUT" "$PROMPT_OUT" "$ROUTE_OUT" "$COST_OUT" "$ARCH_OUT" << 'PYEOF'
import sys
import json

def load_json(path):
    try:
        with open(path) as f:
            content = f.read().strip()
            if not content:
                return None
            return json.loads(content)
    except Exception:
        return None

sec_path, prompt_path, route_path, cost_path, arch_path = sys.argv[1:]

sec = load_json(sec_path) or {}
prompt = load_json(prompt_path) or {}
route = load_json(route_path) or {}
cost = load_json(cost_path) or {}
arch = load_json(arch_path)

# Build unified report
report = {
    "pipeline": "geniearchi-lint",
    "text_length": len(open(sys.argv[0]).read()) if False else None,
    "security": {
        "rating": sec.get("rating"),
        "safe": sec.get("safe"),
        "score": sec.get("security_score", {}).get("total"),
        "breakdown": sec.get("security_score", {}).get("breakdown"),
    },
    "prompt": {
        "complexity": prompt.get("complexity"),
        "action": prompt.get("action"),
        "domain": prompt.get("domain"),
        "words": prompt.get("words"),
        "questions": prompt.get("questions"),
        "readability_score": (prompt.get("nlp_metrics") or {}).get("readability_score"),
    },
    "routing": {
        "recommended_model": route.get("model"),
        "tier": route.get("tier"),
        "confidence": route.get("confidence"),
        "reasoning": route.get("reasoning"),
    },
    "cost": {
        "model": cost.get("model"),
        "input_tokens": cost.get("input_tokens"),
        "output_tokens": cost.get("output_tokens"),
        "total_tokens": cost.get("total_tokens"),
        "cost_usd": cost.get("cost_usd"),
    },
    "architecture": arch,
}

# Remove None values at top level
report = {k: v for k, v in report.items() if v is not None}

print(json.dumps(report, indent=2))
PYEOF
