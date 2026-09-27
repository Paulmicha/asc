---
description: Every ASC hook calls must only exist when there are actual variants worth implementing.
globs: '*.sh'
---

# Anti-pattern example (don't)

Do not create hook calls when there won't realistically ever be any chance of needing the implementation to vary.

# Correct example (do)

As soon as it makes sense to have a variant, like per host type, instance type, AI agent role, etc. then yes, it must be considered (and called in a place that best matches its "genericity" - or specificity - level).
