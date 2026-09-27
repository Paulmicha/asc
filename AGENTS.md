# ASC project instructions

For every task that creates, changes, proposes, or reviews ASC code in this
project, read and follow [.agents/skills/asc-author-code/SKILL.md](.agents/skills/asc-author-code/SKILL.md)
before writing code, including code examples in responses. This is required even
when the skill is not automatically selected or the change seems small.

Use the current templates in `asc/extensions/builder/subject/` and review the
applicable records in `data/entities/anti-pattern/` before editing and again
against the final changes. Keep these requirements active throughout the task;
revisit the sources when scope changes. Pass this requirement to any delegated
agent working on ASC code.

The README defines ASC concepts and scope. Direct user instructions take
precedence over this guidance. Historical changelogs are context, not automatic
authorization to implement their proposals.

For ASC documentation, README proposals, changelogs, and project instructions,
read and follow [.agents/skills/asc-author-docs/SKILL.md](.agents/skills/asc-author-docs/SKILL.md).
Preserve human-written README text through adjacent dated proposals unless the
user explicitly authorizes a direct rewrite.

Before changing or publishing public mother content, or preparing a transfer
from a client instance, read and follow
[.agents/skills/asc-mother-guard/SKILL.md](.agents/skills/asc-mother-guard/SKILL.md).
Client-identifying information, private search lists, agreements, and plans stay
in the owning client repository. Keep instance-specific policies and knowledge
in that instance; only generic, reusable changes belong in the mother.

When acting on a gated proposal, read the applicable project gates file and its
scope and approval rules. Do not infer authorization from a changelog or silently
repair contradictory gate fields. Direct user instructions and existing session
authorization take precedence; ask only when authorization for the relevant
scope is genuinely missing or ambiguous. Adding a loader, hook implementation,
wrapper, or global within an already authorized task needs no second approval
merely because it belongs to that category.
