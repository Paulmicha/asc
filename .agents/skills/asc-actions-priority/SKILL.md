---
name: asc-actions-priority
description: Use when working in an ASC project and a task may involve project, environment, service, application, database, test, build, deployment, or other operational actions.
---

# Use existing ASC actions first

In an ASC project, look for an existing action or entry point before constructing an ad hoc command or script for a project operation. This keeps execution aligned with the instance's configuration and gives humans a more predictable set of entry points.

1. From the project root containing `asc/bootstrap.sh`, consult the instance instructions and README, relevant actions in `scripts/asc/extend/`, `scripts/asc/contrib/`, `asc/extensions/`, and core, and the generated entry-point inventory when available. Check which extensions and implementations are active in this instance; an action present on disk is not necessarily enabled or the implementation that runs.
2. Choose the existing action that satisfies the requested operation and scope. A purpose-specific instance action is often more suitable than a generic service action. Use a Make entry point or direct action according to the documented contract; verify that it preserves the necessary arguments.
3. Inspect the selected action and relevant configuration and hooks before execution. Check target environment, side effects, arguments and quoting, working directory, input/output, and interactivity. Do not assume an action is safe or suitable merely because its name matches. Verify the outcome.
4. If no available action supports the required behavior, use the narrowest suitable direct command or tool. Explain the missing capability or observed incompatibility and the fallback. A sandbox or permission failure alone does not establish that the action is unsuitable: follow the applicable approval process. Do not invent an action for a one-off command merely to avoid a fallback.

Direct user instructions take precedence. An action is not authorization to perform destructive operations or affect remote systems; follow the applicable permissions and scope. Ordinary file discovery and inspection do not require an ASC wrapper. Do not modify generated ASC state to make an action appear.

For Compose stacks, check the application's own wrappers and `asc/extensions/compose/service/` and `stack/` actions. Service `exec` targets an existing container; `run` creates a separate one. They are not interchangeable. Inspect the action's argument forwarding before passing flags or compound commands.
