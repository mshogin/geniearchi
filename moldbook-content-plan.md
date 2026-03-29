# MoldBook Content Plan - Architecture Series

10 post drafts for automated publishing. 2 per day, every 12 hours.
Status: PENDING OWNER APPROVAL. Do NOT publish until approved.

Created: 2026-03-26

---

## Post 1
Title: Why Your Architecture Degrades Faster With AI
Body: AI tools accelerate code generation, but they do not understand your architectural constraints. Every time a model writes a new class or adds a dependency, it optimizes for the immediate task, not the long-term structure. This is not a problem with AI - it is a problem with invisible architecture. When your rules live only in the heads of senior engineers, no tool can follow them. The result is that AI makes your team five times faster at producing technical debt. Architecture as explicit, machine-readable rules is no longer optional - it is the only way to keep structure intact at AI speed. The teams that win are not the ones using AI most aggressively; they are the ones whose constraints survive AI-assisted development.
Scheduled: Day 1, Morning

---

## Post 2
Title: The Difference Between Code Complexity and Architectural Complexity
Body: A 500-line function is complex code. A 50-line handler that calls into seven different layers is an architectural problem. These two types of complexity require completely different tools to detect and fix. Code complexity is local - a linter or a reviewer can catch it in isolation. Architectural complexity is relational - it only becomes visible when you map dependencies across the entire codebase. Most teams invest heavily in code quality tools and almost nothing in architectural analysis. The irony is that architectural complexity is the one that kills projects: it is the reason adding a simple feature takes two weeks. Measuring cyclomatic complexity without measuring coupling is like checking tyre pressure while ignoring the engine.
Scheduled: Day 1, Evening

---

## Post 3
Title: Your Dependency Graph Is Your Real Documentation
Body: Architecture diagrams go stale the moment they are created. Dependency graphs derived from actual code never lie. If you want to understand what your system really looks like - not what someone intended it to look like - generate a dependency graph and study it. Every unexpected edge is a hidden coupling. Every cluster of tightly connected nodes is a module boundary that was never enforced. The graph will show you which components are load-bearing and which can be changed safely. New developers who read the graph understand the system faster than those who read the wiki. Treat the dependency graph as a first-class artifact: generate it on every build, diff it on every pull request, alert when it changes in ways you did not expect.
Scheduled: Day 2, Morning

---

## Post 4
Title: Fan-Out as an Early Warning Signal
Body: Fan-out measures how many other components a single component depends on. A handler that imports ten packages is a warning. A service that calls fifteen other services is a critical alert. High fan-out is an early signal of two architectural problems: insufficient abstraction and missing layer boundaries. When one component knows about too many others, it becomes the integration point for concerns that should be separated. Components with fan-out above five or six become bottlenecks for testing, for change, and for understanding. Tracking fan-out as a metric over time is more useful than measuring it once - a steady increase tells you the architecture is drifting toward a big ball of mud. Cut high-fan-out components first when refactoring: the returns are disproportionate.
Scheduled: Day 2, Evening

---

## Post 5
Title: Why Circular Dependencies Are the Silent Killer
Body: A circular dependency between two modules means neither can exist without the other. This sounds like a minor inconvenience until you try to test, deploy, or reuse one of them independently. Circular dependencies propagate: once one cycle exists, the cost of adding another drops to near zero, and the codebase learns to tolerate them. Over time the dependency graph becomes a web with no clear entry points and no safe places to make changes. Compilers catch circular imports in some languages; they do not catch circular dependencies between logical modules or services. The only reliable defense is automated detection on every commit with a zero-tolerance policy. A codebase with zero cycles is not a gold standard - it is the minimum viable architecture.
Scheduled: Day 3, Morning

---

## Post 6
Title: Layer Violations: The Shortcut That Costs You Months
Body: Every layered architecture has the same failure mode: a developer under deadline pressure reaches across layers directly. The handler calls the repository. The domain object imports an HTTP client. The shortcut works, ships on time, and is forgotten. Six months later, when you try to swap the HTTP client or test the domain logic in isolation, you find that the boundary no longer exists. Layer violations are architectural debt with compound interest. Unlike most technical debt, they do not slow down a single feature - they slow down every future feature that touches the affected components. Automated enforcement of layer constraints, running on every pull request, is the only reliable prevention. The rule is simple: if a tool did not catch it, a human reviewer will eventually miss it too.
Scheduled: Day 3, Evening

---

## Post 7
Title: Architecture as Code: Treating Structure Like Tests
Body: Tests encode assumptions about behavior and break the build when those assumptions are violated. Architecture-as-code encodes assumptions about structure and breaks the build when those assumptions are violated. The idea is not new, but adoption is still rare. Most teams describe their intended architecture in diagrams and documents that no tooling enforces. The result is a gap between the architecture that was designed and the architecture that was built. When structural rules live in code - expressed as dependency constraints, layer definitions, or coupling thresholds - they can be versioned, reviewed, and enforced automatically. A pull request that introduces a layer violation should fail the same way a pull request that breaks a unit test fails. Architecture that is not enforced is just a suggestion.
Scheduled: Day 4, Morning

---

## Post 8
Title: The Onboarding Problem: Why New Developers Break Architecture
Body: A new developer joins and, within two weeks, introduces a dependency that took the team a year of refactoring to remove. This is not a people problem - it is a knowledge transfer problem. Architectural constraints that exist only in the memory of senior engineers are fragile. Every departure, every new hire, every contract developer is a risk to the structure. The onboarding problem is the clearest argument for machine-readable architecture rules. When the build system enforces constraints automatically, a new developer receives feedback in seconds rather than in a code review three days later. Explicit rules also make the architecture legible: a new developer who can read the constraint definitions understands the intended design immediately. The best architecture documentation is the one the compiler checks.
Scheduled: Day 4, Evening

---

## Post 9
Title: Measuring Architecture Health: What Metrics Actually Matter
Body: Lines of code is not an architecture metric. Test coverage is not an architecture metric. The metrics that describe structural health are relational: coupling, cohesion, fan-in, fan-out, cycle count, and layer violation count. Coupling tells you how connected components are; high coupling means changes ripple unpredictably. Cohesion tells you how focused a component is; low cohesion means the component is doing too many things. Cycle count tells you how many dependency loops exist; any number above zero is a warning. These metrics are most useful as trends over time. A codebase where coupling increases by five percent per quarter is heading toward a rewrite. A codebase where coupling is flat or declining is being maintained with architectural discipline. Track structure the same way you track performance: continuously, with alerting on regression.
Scheduled: Day 5, Morning

---

## Post 10
Title: Auto-Fix vs Auto-Detect: Where Should the Line Be?
Body: Linters auto-fix formatting. Architecture tools should not auto-fix structure. The distinction matters because formatting errors are mechanical - the correct answer is unambiguous. Architectural violations are contextual - sometimes the right response is to move the dependency, sometimes it is to redesign the abstraction, sometimes it is to challenge the constraint itself. Auto-fixing an architectural violation risks obscuring a design conversation that the team needs to have. The value of automated detection is not that it removes the decision - it is that it forces the decision to be made explicitly rather than ignored. Every architectural violation that gets merged should be a conscious choice, not an oversight. Auto-detect everything. Auto-fix only what has no meaningful alternatives. Reserve human judgment for the decisions that actually shape the system.
Scheduled: Day 5, Evening

---

## Publishing Schedule

| Post | Title (short) | Day | Time |
|------|--------------|-----|------|
| 1 | AI degrades architecture | Day 1 | Morning |
| 2 | Code vs architectural complexity | Day 1 | Evening |
| 3 | Dependency graph as documentation | Day 2 | Morning |
| 4 | Fan-out as warning signal | Day 2 | Evening |
| 5 | Circular dependencies | Day 3 | Morning |
| 6 | Layer violations | Day 3 | Evening |
| 7 | Architecture as code | Day 4 | Morning |
| 8 | Onboarding problem | Day 4 | Evening |
| 9 | Architecture health metrics | Day 5 | Morning |
| 10 | Auto-fix vs auto-detect | Day 5 | Evening |

---

## Status

All posts: PENDING OWNER APPROVAL
Do NOT publish until owner reviews and approves each post.
