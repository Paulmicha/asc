---
name: asc-mother-guard
description: "Use before changing or publishing public ASC mother content, or preparing a patch or transfer from a client instance into the mother repository."
---

# Keep client information in its owning instance

The public ASC mother and private client instances are separate repositories.
Identify the repository owning each destination before writing, deleting,
staging, committing, or publishing content. Apply this guard to proposed files,
patches, commit messages, and issue, pull request, or release text as well.

## Before writing mother content

1. Identify whether any source material comes from a private client instance.
   Keep client names, ticket identifiers, private hostnames, domains, docroots,
   email addresses, and identifying narrative details in that instance.
2. For client-derived material, read the source instance's local privacy
   instructions and use its existing search procedure on the proposed content.
   Keep its search list, agreements, and plans inside the client repository;
   never copy them into mother documentation or tool output. If that procedure
   is unavailable, report the missing check and pause the client-derived transfer.
   Ordinary mother-only work needs no invented client search list.
3. Extract the generic change using neutral examples. Review the proposed text
   as an outside reader: removing a name is insufficient when surrounding facts
   still identify a client or a person associated with that client.
4. When the need arises to mention a path in the host that contains a private
   name outside of its repo, it is possible to use registry keys as anonymized
   pivots to those paths : see the `asc/extensions/file_registry/` extension.

## Before delivering or publishing

Inspect the actual unstaged and staged diffs, including removed lines, plus new
untracked files intended for delivery. For client-derived work, run the instance's
search on these contents too. Exclude `asc/vendor/**` from that instance-specific
search. Review the final public message separately; a clean search does not
replace reading for indirect identification.

A hit on mother-bound content stops that write or publication until the content
is made generic. Report the affected path and category without repeating private
values. A hit confined to the client repository stays there. Do not silently
rewrite unrelated files or Git history to repair an existing disclosure.

State which checks were performed and any limits. This guard does not itself
authorize copying files, committing, pushing, or publishing.
