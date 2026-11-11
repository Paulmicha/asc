# Discover and provision host software dependencies

| Field | Value |
|---|---|
| Date | 2026-11-11 |
| Status | Idea for discussion; no implementation or provider choice is approved. |
| Scope | Discover host-level software requirements in active ASC extensions and instance configuration, select applicable installation methods, inspect state, and provision the current host. |
| Related ASC concepts | [Purpose and scope](../../../../README.md#purpose); [host capabilities](../../../../README.md); [active extensions](../../../../asc/core/core.manual-inc.sh). |

## Intent

An ASC extension may need software installed on the host. A user may also maintain a personal set of host tools independently of any extension. The idea is to express those requirements in discoverable files and use a memorable entry point such as `make host-provision` to inspect and satisfy them. A suitable method can depend on the operating system, distribution, release, architecture, package provider, and local policy.

The aim is a small, understandable ASC composition built around existing shell actions and hooks. It should reuse a system package manager or an upstream installer where appropriate; it need not become a general configuration-management system. Application-instance installation, container images, and host software are distinct scopes, although a future design may explicitly connect them.

This document records research and options, not a settled contract, an implementation plan, or authorization to run installers. All observations about current code are static inspection, not runtime verification.

## Existing ASC behavior

- [`asc/host/provision.sh`](../../../../asc/host/provision.sh) bootstraps ASC and calls the `host/provision` hook using `HOST_OS`, `HOST_TYPE`, and `PROVISION_USING` as variants. The entry point is abstract: enabled hook implementations determine its effect.
- The optional [`software` extension's hook](../../../../asc/extensions/software/host/provision.hook.sh) invokes its existing [provisioning helpers](../../../../asc/extensions/software/host/provision.opt-inc.sh). The helpers load manifests, build and print a status diff, apply installs, and optionally prune managed extras. [`software-status`](../../../../asc/extensions/software/software/status.sh) uses the status path.
- The manifest loader currently checks a fixed instance manifest, a fixed extension manifest, and an optional local overlay. It does **not** discover declarations across active extensions. Its YAML parser produces shell text subsequently passed to `eval`; assess supported YAML and the trust boundary before extending the sources it reads. The present sequential parsing should also be tested to establish actual merging and precedence instead of assuming an overlay contract.
- Existing code contains handling for apt, pipx, tarballs, AppImages, selected `ensure` methods, and user systemd units. The `ollama_install_sh` ensure method is a special case that checks command availability and invokes the Ollama installer. A command being present does not prove an expected version, service state, or model is present.
- [`software.dependencies.yml` in docling](../../../../scripts/asc/contrib/asc/docling/software.dependencies.yml) and [tesseract](../../../../scripts/asc/contrib/asc/tesseract/software.dependencies.yml) are discoverable examples of a filename, but currently contain TODO comments, not an implemented dependency schema.
- The [`host/dependency` actions](../../../../asc/host/dependency/) are currently empty files. Their presence in an action inventory does not establish working install, list, status, update, or uninstall behavior. The historical [stub inventory](../../../../changelog/2026/09/20-stub-gap-inventory.md) made the same distinction.
- [`ASC_EXTENSIONS`](../../../../asc/core/core.manual-inc.sh) records active core, contrib, and instance extensions. Discovery should reuse ASC's actual extension paths and enablement/override rules, rather than scan every directory on disk or assume a cached inventory is always fresh.
- [`f_host_os`](../../../../asc/host/host.inc.sh) currently derives a combined slug from the OS release `NAME` and `VERSION_ID`, with fallbacks. Replacing or changing that value could affect existing hook variants. Additional host facts should be designed without silently breaking existing `HOST_OS` consumers.

The mother checkout lists `software` and `asc/ollama` in its extension ignore file. On-disk implementations alone therefore do not imply that they run in a particular instance.

## Earlier personal-instance work

A separately maintained home-directory ASC instance has a historical provisioning design for multiple Debian machines. It used a tracked personal manifest, an optional local overlay, status comparison, pinned pipx packages, a versioned tarball, an AppImage, an optional user service, and an Ollama ensure method. Its intended default was to install or upgrade missing or outdated declared items and remove managed extras only on explicit request. It deliberately favored Bash and YAML over Ansible for a small, relatively homogeneous fleet.

That material demonstrates an actual use case and existing implementation lineage, not a current cross-platform contract. Its README still contains historical CWT names and paths. At inspection time its root ignore file and cached active extension inventory excluded `software` and the Ollama extension, so the documentation alone does not establish that provisioning is active. This public idea intentionally keeps personal manifest contents and instance-specific paths in their owning instance.

Relevant mother historical notes include [lazy includes and the provision hook](../../../../changelog/2026/09/11-lazy-opt-inc-and-entry-point-extraction.md), [software-related naming inventory](../../../../changelog/2026/07/31-array-dict-naming-plan.md), and the [agent plan's optional Ollaya integration](../../../../changelog/2026/11/10-agent-plan-cursor-codex-ollaya.md). That Ollaya plan discusses integration rather than host installation. Historical plans and completion statements must be compared with current code.

## Research: small installers and providers

- [Ollaya's distribution documentation](https://github.com/ollaya-dev/ollaya/blob/main/docs/distribution.md) describes an upstream shell installer, a version selector, an installation prefix, optional service setup, and an option to avoid CUDA downloads. Its [installer source](https://github.com/ollaya-dev/ollaya/blob/main/scripts/install.sh) detects platform details and checks downloaded release files against the release checksum list. A checksum obtained from the same source as an artifact helps detect corruption; it is not independent authentication. Installer version, artifact provenance, download size, privilege, service behavior, and upgrade semantics need to be visible to the operator. Ollaya and Ollama are separate products.
- [Rust's installation guide](https://doc.rust-lang.org/stable/book/ch01-01-installation.html) presents `rustup` as a toolchain manager and calls out linker requirements. Checking only for a `rustc` executable may not establish that the requested toolchain or components are installed; the provider and desired toolchain need explicit semantics. Windows installation also follows a different path from the Unix shell installer.
- [Homebrew Bundle](https://docs.brew.sh/Brew-Bundle-and-Brewfile) illustrates a useful separation between declarations, checking requirements, installation, and upgrade policy. It also illustrates delegating package lifecycle to an established provider rather than reproducing its internals.
- [Flatpak's documentation](https://docs.flatpak.org/en/latest/using-flatpak.html) distinguishes an application ID, a remote such as Flathub, and installation scope. Flatpak is the provider; Flathub is a remote. User and system installations are different states and may have different configured remotes.
- The [os-release specification](https://www.freedesktop.org/software/systemd/man/250/os-release.html) recommends machine identifiers such as `ID` and `VERSION_ID`, with `ID_LIKE` as a possible fallback; version information can be missing. A compatibility family is evidence for matching, not proof that a package manager or installation method is appropriate.
- [Bluefin's administrator guide](https://docs.projectbluefin.io/administration/) describes an image-based system and recommends Flathub for desktop applications. A Fedora-like identity alone is insufficient reason to select a conventional host package installation. An image channel/build identifier such as `bluefin-stable-20261023` is an illustrative requested variant; where a specific Bluefin installation exposes that information remains to be verified.

Upstream installers change. Before implementing an adapter, inspect the exact supported release and installer behavior rather than relying on a mutable URL or this historical snapshot.

## Approaches

| Approach | Strength | Cost or limitation |
|---|---|---|
| Extend the existing `software` extension with active-extension declarations and provider dispatch | Reuses the host hook, personal manifest, status/diff structure, and ASC extension model. Makes one combined preview possible. | The existing implementation has fixed paths and specialized branches; changes need to preserve or deliberately migrate current behavior. |
| Independent extension hook implementations | Small initial code surface; each extension controls its own probe and installation. | A combined preview, shared dependencies, conflicts, and consistent provider policy are harder to coordinate. |
| Delegate the complete task to an external configuration or bundle tool | Reuses an established ecosystem and providers. | Adds a host dependency and another configuration model; may be excessive for small ASC instances. |

**Recommendation for discussion:** extend the existing software path, keeping the coordinator small and delegating concrete installation to selected providers. Keep a direct hook available where a requirement cannot reasonably be represented, but do not let independent hooks silently undermine the consolidated preview. The choice remains open.

## Proposed flow

1. **Discover:** collect declarations from active extension roots and the instance's personal manifest and local configuration. A convention such as `software.dependencies.yml` is a candidate, not a finalized schema. Core, contrib, instance `extend`, overrides, ignore files, and stale generated inventories must follow actual ASC resolution rules. A disabled extension must not contribute requirements merely because its files exist.
2. **Normalize:** create a requirement for a recognizable capability or software item, with its requesting source, optional desired version or toolchain, and one or more applicable installation methods. Keep an explicit instance-level way to express personal tools that do not belong to an extension. Decide whether an extension's requirements are always host requirements or must be marked optional or conditional on the action being used.
3. **Determine host facts:** collect OS family, distribution ID, release, architecture, and, where available and relevant, image channel/build. Keep unknown values explicit. Distinguish the OS of a container or WSL environment from the host being modified. Retain existing `HOST_OS` behavior until a compatible migration has been designed.
4. **Choose one method:** consider instance policy, exact OS/release or image matches, broader distribution/family matches, installed provider availability, architecture, and scope. Specify precedence and fallback behavior before implementation. A distribution family match must not automatically authorize an unsuitable provider. Report equally ranked alternatives, unsupported platforms, and contradictory policies instead of silently choosing or running all alternatives.
5. **Probe and preview:** show each requirement, requesting source, chosen provider and remote, user/system scope, expected version where meaningful, current state, intended action, and anything unresolved. Status must not mutate the host. Distinguish missing, satisfied, mismatched, unknown, and unsupported where the provider can establish them. Do not represent an unperformed or weak probe as a verified install.
6. **Apply the resolved plan:** `host-provision` invokes the selected implementations and checks their results. Decide whether it always shows the plan first and how interactive and unattended use differ. Fail clearly when a required provider or prerequisite is unavailable. Preserve source attribution and meaningful exit status; do not claim success after a failed probe or install.
7. **Keep upgrades and removal explicit:** distinguish satisfying a missing requirement from upgrading a satisfied installation. The historical home behavior included upgrades and opt-in pruning; any change to that behavior requires an explicit compatibility decision. Removing an extension is not proof that a package is safe to remove: it might have other consumers or predate ASC. Initially avoid extending pruning to discovered extension requirements.

This is a conceptual sequence, not a promise that current ASC supports it. It leaves open whether planning should produce an in-memory structure or a persisted artifact. A persisted plan would need freshness checks because installed state, host facts, and declarations can change between preview and apply.

## Requirements, variants, and provider boundaries

A declaration needs to distinguish at least:

| Concern | Examples and questions |
|---|---|
| Requirement identity | A tool or capability and the extension(s) requesting it; stable identity must not be confused with a package name. |
| Host match | Linux, macOS, or Windows; distribution and version; architecture; optional image channel/build. Specify exact matching and what unknown facts mean. |
| Provider | apt, Flatpak, Homebrew, pipx, rustup, or a specific upstream installer. Provider availability and applicability are separate questions. |
| Provider source | Flatpak remote such as Flathub, package repository, or upstream release. Establish whether setup of a missing source is in scope. |
| Scope | User or system install, target prefix, and privileges. For Flatpak, the same application may be installed in more than one scope. |
| Desired state | Presence, exact or compatible version, toolchain/components, or other provider-specific state. Define whether a package's version is comparable across providers. |
| Effects | Install, upgrade, service creation or start, GPU downloads, environment/PATH changes, reboot, and interactive prompts. An upstream installer may perform more than copying a binary. |
| Source and conflicts | Which active extensions and instance declarations requested the same item; how duplicate compatible requirements merge and incompatible requirements fail. |

A version selector such as `debian-13` and an image identifier such as `bluefin-stable-20261023` need not occupy the same field or imply the same matching rules. Avoid constructing an elaborate selector language before testing real requirements. The existing ASC hook variant mechanism may supply some dispatch, but its ranking and combination behavior should be examined before relying on it for multi-axis provider resolution.

Use declarative data for supported choices and maintained ASC provider implementations for execution. Do not treat arbitrary shell embedded in distributed YAML as ordinary data. If a custom installer needs unusual behavior, a specific implementation can make its inputs and side effects reviewable. Provider-native package resolution remains the provider's job; ASC only needs enough ordering to express real prerequisites such as a package manager needed by a later requirement. Detect cycles and report prerequisites that cannot be met instead of inventing an extensive dependency solver up front.

## Installer considerations

The upstream shell-installer pattern can be lightweight, but an ASC adapter should establish its precise contract: source and version of the installer, artifact version, download and integrity checks, supported architecture and libc, installation directory, PATH visibility, privileges, interactive flags, and post-install verification. Fetching a script for inspection or pinning it separately makes the actual executed content easier to review; choose an explicit trust and update policy rather than assuming HTTPS or same-origin checksums establish independent authenticity.

For Ollaya, decide whether ASC manages only the executable or also its service, GPU support, and models. Its upstream options allow some of these to be separated, and the CUDA payload can be substantial. For Rust, decide whether ASC ensures `rustup`, a default toolchain, or project-specific components; a host toolchain should not silently override a project's own Rust configuration. Neither adapter exists merely because its upstream installer exists.

Windows, macOS, WSL, and image-based Linux are potential targets, not verified ASC execution environments. Define the shell/runtime and elevation model for each supported platform. A Linux container's `/etc/os-release` describes that environment unless an explicit, trustworthy host-facts source is selected; do not assume running inside it grants access to the outside host.

## Incremental investigation and validation

These are candidate stages, not an approved implementation plan:

1. **Establish the current baseline.** Inspect the active extension path and override rules, current YAML parser behavior and manifest precedence, existing tests, provider status probes, and how arguments reach the entry points. Exercise current software status only in an appropriate isolated setup; do not run a real installer merely to document behavior.
2. **Define a narrow declaration and selection contract.** Work through one shared requirement, one apt package on Debian, one Flatpak/Flathub choice on an image-based system, and one upstream-installer case. Decide schema, identity, optionality, precedence, unsupported cases, local overrides, and whether install and upgrade are separate operations. Keep existing personal manifests usable or describe an explicit migration.
3. **Prototype discovery and read-only status.** Use fixture extension trees, known host facts, and fake provider probes. Verify that enabled, ignored, overridden, and instance-level declarations are handled as intended. Display origin, selection, conflict and unknown state without changing the host.
4. **Add the smallest useful apply path.** Implement only providers justified by real needs, with fake executables and isolated state for automated checks. Cover prerequisite ordering, provider absence, command failures, repeated runs, partial failure, version mismatch, and privilege/scope handling. Verify installer completion with a meaningful provider-specific probe.
5. **Validate real providers separately.** If explicitly authorized, use disposable environments appropriate to each target and record exact versions, privileges, side effects, and limitations. Test Debian and image-based Linux separately; do not infer macOS or Windows support from Linux fixtures. Never use the live home installation as a test fixture by default.
6. **Document actual behavior.** Update maintained reference material only after a contract is chosen and behavior is verified. Mark unsupported targets and provider-specific limits. Existing stale home-instance documentation belongs in that instance, not in the public mother.

Useful acceptance cases include no active requirements, disabled extensions, duplicate compatible requirements, conflicting versions or providers, missing/unknown OS facts, unsupported OS or architecture, absent provider or remote, user versus system scope, local override precedence, installer failure, and a second run that makes no unnecessary change. Check that preview itself has no side effects and that no removal occurs unless specifically requested and supported.

## Open decisions

- Should `software` own discovery and dispatch, or should a smaller independent hook-based design come first?
- Are all requirements of an enabled extension mandatory on the host, or should they be optional, feature-specific, or selected per action?
- Which declaration format and merge semantics fit ASC's existing parser, and what trust boundary is acceptable for extension-provided YAML?
- What is the exact precedence among extension defaults, instance choices, local overrides, host facts, and provider availability? What happens on ties or missing facts?
- Should provisioning install missing software only, or retain the historical install-and-upgrade behavior? How are upgrades requested and version constraints interpreted?
- Which initial providers and host targets are supported by real use cases? How are Flatpak remotes, system services, and upstream installers authorized and configured?
- How should shared requirements, pre-existing software, managed ownership, and optional future removal be represented without deleting something another user or application needs?
- Should one combined dry-run or status action cover every `host/provision` hook, and how can the system avoid presenting an incomplete preview as complete?

The next useful step is to choose an approach and resolve the first narrow declaration and provider-selection contract. Implementation, host changes, and any public transfer or publication remain separate actions.
