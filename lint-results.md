# Archlint Scan Results

Last scan: 2026-03-26

## promptlint
- Components: 8, Cycles: 0, Max fan-out: 7
- Violations (2):
  - fan_out: cmd::promptlint::main (7 > 5)
  - fan_out: pkg::telemetry::telemetry (7 > 5)

## costlint
- Components: 9, Cycles: 0, Max fan-out: 7
- Violations (2):
  - fan_out: cmd::costlint::main (7 > 5)
  - fan_out: pkg::ab::ab (7 > 5)

## seclint
- Components: 3, Cycles: 0, Max fan-out: 8
- Violations (1):
  - fan_out: cmd::seclint::main (8 > 5)

## Summary
- Total violations: 5
- All fan-out violations (no cycles, no SOLID violations)
- Fix: extract dependencies into sub-packages or facade patterns
