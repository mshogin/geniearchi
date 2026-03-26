#!/bin/bash
# Agent runs this to get a full health report of the entire ecosystem
# Usage: self-scan.sh
# No arguments - scans all known repos

SCRIPTS_DIR="$(dirname "$0")"
ARCHLINT_SCRIPTS=/home/assistant/projects/archlint-repo/scripts

REPOS=(
    "/home/assistant/projects/promptlint:promptlint"
    "/home/assistant/projects/costlint:costlint"
    "/home/assistant/projects/seclint:seclint"
)

echo "{"
echo "  \"scan_time\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
echo "  \"repos\": ["

FIRST=true
for entry in "${REPOS[@]}"; do
    IFS=':' read -r path name <<< "$entry"
    [ "$FIRST" = true ] && FIRST=false || echo "  ,"

    REPORT=$(bash "$ARCHLINT_SCRIPTS/agent-report.sh" "$path" 2>/dev/null)
    BUDGET=$(bash "$ARCHLINT_SCRIPTS/complexity-budget.sh" "$path" 2>/dev/null)

    python3 -c "
import json
report_raw = '''$REPORT'''
budget_raw = '''$BUDGET'''
try:
    report = json.loads(report_raw) if report_raw.strip() else {}
except Exception:
    report = {}
try:
    budget = json.loads(budget_raw) if budget_raw.strip() else {}
except Exception:
    budget = {}
result = {
    'name': '$name',
    'health_score': report.get('health_score', 0),
    'components': report.get('components', 0),
    'violations': report.get('violations', 0),
    'budget_status': budget.get('overall_status', 'unknown'),
    'action_items': len(report.get('action_items', []))
}
print('    ' + json.dumps(result))
"
done

echo "  ],"
echo "  \"summary\": \"self-scan complete\""
echo "}"
