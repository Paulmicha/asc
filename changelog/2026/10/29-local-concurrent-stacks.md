# Concurrent local Compose stacks

| Field | Value |
|-------|-------|
| **Date / research review** | 2026-10-29 |
| **Status** | **Experimental plan / options review. No final choice or implementation approval.** |
| **Goal** | Run independent Compose projects concurrently on one Debian laptop, without conflicting host listeners, while editing the existing bind-mounted trees with VSCodium. Evaluate optional smartphone testing over LAN Wi-Fi and security exposure. |
| **Delivery constraint** | Any eventual ASC implementation belongs in one or more opt-in extensions under `scripts/asc/contrib/asc/`, installed later in the participating instances. |
| **This revision** | Correct technical claims, broaden the comparison, identify migration contracts and propose experiments, including smartphone access and listener security. No stack changes, installation, gates-row changes, or README rewrite. |

Project names, private hostnames, paths, and site-directory values are deliberately absent. The two inspected examples are **multisite** and **labeled**. Examples such as `site-a.localhost`, `nested.site-a.localhost`, `project-b.home.arpa`, and `/path/to/project-a` are invented. Actual inventories and route declarations stay in the owning instances or private host state.

`$subject`, `$action`, and `$extension` are ASC conceptual placeholders; `$HOME` denotes the user's home directory. Names of possible extensions below are proposals, not existing paths.

## Review conclusions and provisional shortlist

A single shared HTTP/S entry point is the strongest candidate for preserving today's browser URLs. It can forward directly to application containers, to project proxies, or to host ports. Those are separate decisions from choosing Traefik, Caddy, or nginx. DNS alone does not multiplex services sharing one address and port.

Three lightweight candidates deserve a fair comparison before narrowing:

1. **Containerized Traefik with explicit route files and Docker DNS aliases.** No Docker API access in the proxy; ASC manages a small route inventory. DDEV demonstrates the file-provider architecture.
2. **Containerized Traefik with opt-in Docker labels.** Automatic discovery and reuse of existing labels; fewer route files, but Docker API privileges and global discovery scope need consideration.
3. **Native Caddy managed by its packaged systemd unit, with loopback backends.** No additional proxy container, shared Docker network, or Docker socket. Fixed or Docker-assigned backend ports are both viable. ASC must register routes and reload configuration.

These are recommendations for experiments, not decisions. Caddy inside Docker on a shared network, native nginx, an address split, and retaining a project proxy are also credible variants. Larger platforms remain in the catalog because exploration and learning are explicit goals. Their lower priority reflects the preference for minimal tools, not technical impossibility.

Security and smartphone access are now explicit evaluation criteria; see [listener exposure](#security-and-listener-exposure) and [Wi-Fi testing](#smartphone-testing-over-lan-wi-fi). Host-only operation remains the proposed default, with sharing enabled deliberately.

No RAM or CPU winner is established. Count daemons, background processes, configuration ownership, integration work, and failure recovery first; measure actual resources on this laptop during an authorized experiment.

## Corrections to the first draft

| Issue | Correction and consequence |
|-------|----------------------------|
| Drupal supposedly requires changing every multisite key when adding a URL port | Its site lookup tries a port-specific identifier, then less-specific identifiers, including the hostname alone. A port can affect absolute URLs and OIDC settings without requiring changes to this existing hostname-only map. |
| Cookie domains supposedly acquire ports | Cookies are not isolated by port. Browser origins are. Two versions of a site on different ports can still share cookies. |
| Argo CD supposedly overwrites live bind-mounted source | Argo CD reconciles Kubernetes resources, not arbitrary files inside a `hostPath`. A mount can preserve editor changes while manifests remain Git-managed. |
| Tilt grouped with Kubernetes-only tools | Tilt supports existing Compose files directly; it still needs a routing solution. |
| Environment managers supposedly replace bind mounts and require renamed sites | Linux bind mounts and custom hostnames are possible. Adoption requires adapting their project model, not necessarily abandoning the editor or every image. |
| Dokploy / Coolify described as unable to serve an editor tree | Bind mounts are possible, with platform-specific deployment-path rules. An externally edited directory needs a deliberately designed and tested mount and redeploy workflow. |
| File-provider routes supposedly need rewriting after every container recreation | Stable unique DNS aliases can survive recreation without changing the route file. DNS and connection recovery must be tested. IP-address or ephemeral-host-port routes do need refreshing when their target changes. |
| Read-only Docker socket described as meaningful API restriction | `:ro` does not make Docker API requests read-only. Use no socket, or an actual API authorization/filter boundary when one is wanted. |
| Loopback split dismissed after an expected hairpin failure | The unchanged `host-gateway` mapping fails with loopback-only listeners, but a container-network alias to the project proxy can avoid hairpinning. This remains worth evaluating. |
| Socket access incorrectly attributed to every proxy / UI | Nginx Proxy Manager can use explicit upstreams without the Docker socket; stock Caddy, nginx, and file-provider Traefik also need none. |
| Host registry treated as a port allocator | It stores strings. It neither reserves a socket nor provides an atomic allocation transaction. |
| Contrib override described as automatically merged by ASC | The current ASC lookup selects one source per basename and copies it. Extension fragments are not automatically composed. |
| First draft reports active Docker listeners | In this review, no containers were running and no listeners on 80, 443, 8080, or 1025 were observed. The conflict is established from configuration; concurrency and routing remain untested. |

The Drupal correction is supported both by the inspected local `DrupalKernel::findSitePath()` and its [upstream API documentation](https://api.drupal.org/api/drupal/core%21lib%21Drupal%21Core%21DrupalKernel.php/function/DrupalKernel%3A%3AfindSitePath/11.x). Other corrections are explained with their primary sources below.

## Evidence and present constraints

### What was checked

- The two requested Compose definitions, including the labeled project's local override; their associated proxy configuration; the multisite `sites.php`; and `/etc/hosts`.
- Read-only Compose JSON renders, with environment values suppressed from the review output. Both configurations render successfully with Docker Compose v5.6.1. Docker CLI reports Engine package version 29.9.2; no daemon-version compatibility test was performed.
- Listening TCP sockets and the Docker container inventory: neither project was running. This is not a claim that another process can never take a port later.
- Loopback is configured as `127.0.0.1/8`. The first draft's successful `127.0.0.2` bind probe was not repeated; Docker address-specific publishing still needs a runtime test.
- A temporary, synthetic Compose rendering check: clearing ports with `!reset` worked; replacing ports with `!override` worked; merely appending a new binding retained the original 80/443 mappings. No containers or images were created.
- The existing leaf certificate's SAN structure: a parent name plus its wildcard. Presence on disk does not establish browser or container trust.
- Relevant mother implementations, conventions, gates, templates, and anti-pattern records, linked later in this document. No pull, bootstrap, reinit, service restart, or project-file edit was performed.

This is static review and research, with one configuration-rendering fixture. There is no runtime acceptance, browser, OIDC, systemd, reboot, or resource-benchmark evidence yet. The later smartphone/security additions are documentation research only; no phone, router, DNS, firewall, certificate store, or sharing setup was changed or tested.

### Multisite example

The web service publishes `80:80` and `443:443` without an interface restriction. Source is bind-mounted into the PHP and web services. Publishing 443 is not proof that a usable certificate or HTTPS listener exists inside the image.

The Drupal map has 28 hostname aliases, all under `.localhost`, including nested names. There are no corresponding `/etc/hosts` rows. Some container-based browser tools have an explicit mapping of one public site hostname to `host-gateway`; ordinary container resolution must therefore be evaluated separately from desktop-browser resolution.

Additional host ports are 3307 (database), 6081/6082 (cache HTTP/management), 8025 (mail UI), 8080/8081/8888 (HTTP tools), 8983 (search HTTP), and 9000 (database UI). PHP-FPM also commonly uses an internal port numbered 9000; a port number alone does not identify the protocol.

### Labeled example

A project-local Traefik v2 service publishes 80, 443, and 8080. It enables opt-in Docker discovery, mounts the Docker socket without `:ro`, loads local certificate files, redirects its HTTP entrypoint to HTTPS, and exposes an insecure dashboard on 8080.

Six `.home.arpa` names in `/etc/hosts` point to `127.0.0.1`. They cover two Drupal front doors, an API, an identity provider, a mail UI, and a database UI. Preserve the separate direct-front and cache-proxy routes. The route through the cache must not silently become the direct web-server route during migration.

PHP and API services map public API / identity-provider names to `host-gateway`. Their server-side requests therefore depend on reaching the project's HTTPS ingress from Docker. The source trees are bind-mounted. The certificate root is provisioned into application images, but actual current trust and OIDC behavior have not been tested in this review.

SMTP is published on host 1025. Database ports are private. The mail and database UIs are available through routes, not their own published host ports.

### Configured collisions

| Host TCP port | Multisite | Labeled | Required treatment |
|---------------|-----------|---------|--------------------|
| 80 | web service | project Traefik | shared ingress, separate addresses, or distinct ports |
| 443 | web service | project Traefik | same, including TLS ownership |
| 8080 | HTTP tool | dashboard | give the tool a route; remove, route, or relocate the dashboard |
| 1025 | not published | SMTP | no present conflict; review future stacks and interface binding |
| 3307, 6081, 6082, 8025, 8081, 8888, 8983, 9000 | published | not published | no present pairwise conflict; retain, remove, or allocate deliberately |

The eventual inventory must cover host address, port, protocol, all enabled profiles, extra override files, project names, explicit container names, and external network/volume names. Compose's ordinary project prefixes protect many resources; explicit global names can still collide even after the ports are fixed.

## DNS, URLs, TLS, and container callers

### Hostname resolution

[RFC 6761 §6.3](https://datatracker.ietf.org/doc/html/rfc6761#section-6.3) reserves `localhost` and names beneath it for loopback. Browser implementations can synthesize loopback answers without consulting the hosts file. Do not design around moving the existing `.localhost` names to a different address using `/etc/hosts`. Validate Chromium/VSCodium browser tooling and Firefox separately; libc, curl, and browser resolvers are not interchangeable.

`.home.arpa` is the home-network special-use namespace defined by [RFC 8375](https://www.rfc-editor.org/rfc/rfc8375). It does not automatically mean loopback: existing hosts-file entries provide that mapping here. Preserve unrelated hosts-file rows, including machine and VPN entries, if any later experiment modifies the file.

The [Secure Contexts specification](https://www.w3.org/TR/secure-contexts/#localhost) permits localhost origins to be treated as potentially trustworthy. This is not TLS encryption, a blanket cookie exception, or permission to ignore an application's HTTPS / OIDC requirements. Leave existing plain-HTTP multisite URLs usable unless a TLS migration is chosen independently.

Keep both IPv4 and IPv6 in view. A route that works at `127.0.0.1` can fail when a browser chooses `::1`. An address-split experiment must give `.localhost` traffic a working IPv6 destination or explicitly establish and document its IPv4-only behavior.

### TLS and identities

A certificate for `*.localhost` covers `site-a.localhost`, not `nested.site-a.localhost`, and does not cover the bare parent. Use explicit SANs or suitable per-parent wildcards when TLS is needed. [RFC 9525 §6.3](https://datatracker.ietf.org/doc/html/rfc9525#section-6.3) defines the wildcard matching rule.

Keep the existing mkcert CA initially. The proxy receives only leaf certificates and leaf private keys. Client trust requires the public CA certificate; never mount or copy the CA signing key into the proxy or application images. Browser, OS, PHP/OpenSSL, Java, and Node trust may need separate verification. [mkcert documentation](https://github.com/FiloSottile/mkcert) describes its trust and key-handling model.

Caddy's internal CA is a valid alternative if deliberately adopted. It does not have to create a second trust root: Caddy can serve externally supplied certificates. Containerized Caddy cannot assume that installing its own root inside the container makes the host browser trust it. Configure intended plain HTTP explicitly and redirect only domains with usable HTTPS. See [Caddy automatic HTTPS](https://caddyserver.com/docs/automatic-https).

Public ACME certificates do not fit these reserved local names. A privately owned real domain with split DNS and DNS-01 is another possible design, but adds domain/DNS credentials and network dependencies. A local CA service such as step-ca becomes useful for multiple developers/devices or automated issuance; it is optional infrastructure for a single laptop.

OIDC requires preserving the public issuer, discovery metadata, callback URLs, token-endpoint access, and certificate verification from both browser and server-side clients. Changing a DNS answer without changing the URL can preserve the issuer. Changing a URL port changes the origin and may require identity-provider client updates. Cookies remain independent of port; see [RFC 6265 §8.5](https://datatracker.ietf.org/doc/html/rfc6265#section-8.5).

### Host-to-container and container-to-ingress paths

Docker's `host-gateway` normally identifies a host bridge address, not host loopback; it can also be overridden in daemon configuration. A listener published only on `127.0.0.1` is not automatically available through it. See [Compose networking and host mappings](https://docs.docker.com/compose/how-tos/networking/).

Two viable container-caller designs should be compared:

- **Keep the host gateway path.** Bind the shared ingress to the necessary host addresses and test reachability. All-interface publishing is simple but also exposes the laptop on other networks; use deliberate interface selection or tested firewall rules when limiting access.
- **Use container DNS.** Give the ingress public-hostname aliases on a network reachable by the callers, remove conflicting `extra_hosts` rows for those callers, and retain the same public URLs and TLS SNI. For `.localhost`, browser special handling may still defeat a Docker alias; test the actual container browser. An explicit proxy/host-resolver configuration or the host-gateway path may remain necessary there.

Never map an HTTPS issuer directly to a plain-HTTP backend and assume the port/protocol will follow. The alias must reach a listener serving the required HTTPS identity. [Docker port-publishing documentation](https://docs.docker.com/engine/network/port-publishing/) explains address-specific publishing; container route details still require a local test.

## Security and listener exposure

Security is a decision criterion alongside minimal tools, resource usage, URL compatibility, editor workflow, and recovery. Compare the actual reachable services and privileges of each candidate, rather than assuming that a local development stack is private.

### `127.0.0.1`, `0.0.0.0`, and specific addresses

| Binding | Reachability and smartphone implications | Security consequence |
|---------|------------------------------------------|----------------------|
| `127.0.0.1` | IPv4 loopback in the listener's network namespace; a phone cannot directly reach the laptop's listener | good default for host-only backends; not authentication against local processes or browser-originated requests |
| `::1` | IPv6 loopback; separate from IPv4 loopback | pair with IPv4 deliberately so an IPv6 wildcard does not undermine the intended scope |
| `0.0.0.0` | all local IPv4 addresses, including Wi-Fi, Ethernet, VPN, and bridges where traffic is permitted | broadens exposure and can make services reachable on newly joined networks; not limited to the trusted home Wi-Fi |
| `::` | IPv6 wildcard; whether a native socket also accepts IPv4 depends on socket/OS settings | review IPv6 independently; public IPv6 addressing can make assumptions about IPv4 NAT irrelevant |
| A specific laptop Wi-Fi address | reachable through that destination address when routing and filtering permit | narrower than a wildcard, but still requires source/interface rules; binding an IP is not an authorization policy |
| No host publish | services remain reachable on their permitted Docker networks and from the Docker host under the bridge configuration | reduces externally reachable ports; other permitted containers/host processes still form a trust boundary |

The Linux [IPv4](https://man7.org/linux/man-pages/man7/ip.7.html) and [IPv6](https://man7.org/linux/man-pages/man7/ipv6.7.html) socket manuals describe wildcard and loopback semantics. A Docker publish without a host address normally makes the port available on host addresses, potentially IPv4 and IPv6. Distinguish the **host publish** from the listener **inside** a container: a web server listening on `0.0.0.0` inside its container is ordinary and does not itself publish a host port. Conversely, binding the server only to the container's loopback usually prevents the reverse proxy from reaching it. See [Docker port publishing](https://docs.docker.com/engine/network/port-publishing/), including its warning that Engine releases before 28.0.0 could expose localhost-published ports to same-L2 peers. Verify the actual daemon version and configuration rather than relying only on the CLI version.

`0.0.0.0` is a listening wildcard, not the address to type into a phone. Use the laptop's reachable address or a hostname resolving to it. A wildcard does not by itself create Internet access: routing, router forwarding, VPN routes, IPv6, and firewall rules determine who can connect. Do not assume a NAT router or an obscure hostname is access control. IP routing can also make a specific destination address reachable from another interface.

Loopback reduces network exposure, but does not protect against a compromised local account/process, all browser-based attacks, or an intentionally configured proxy/tunnel. Keep authentication, request validation, and Drupal's trusted-host restrictions. Host/SNI allowlists select routes; another LAN user can supply the same Host/SNI, so these are not user authentication.

### Docker firewall caveat

Docker-published container traffic follows forwarding/NAT rules that may bypass ordinary host input rules. A UFW deny policy alone is not evidence that a published database or dashboard is blocked. Inspect the actual Docker firewall backend before selecting rules. Docker documents [UFW interaction](https://docs.docker.com/engine/network/packet-filtering-firewalls/#docker-and-ufw), [iptables filtering through `DOCKER-USER`](https://docs.docker.com/engine/network/firewall-iptables/), and [nftables filtering](https://docs.docker.com/engine/network/firewall-nftables/); the nftables backend has no equivalent automatically created `DOCKER-USER` chain. Native host proxies follow a different input path. Verify both from another device; do not disable Docker's firewall management as a shortcut.

### Security comparison by architecture

| Candidate family | Security considerations to score |
|------------------|----------------------------------|
| Traefik file provider / stock Caddy / nginx / HAProxy | no runtime Docker API needed; restrict proxy admin listeners, certificate-key access, forwarded-header trust, and frontend-network membership |
| Docker-discovery proxies / docker-gen | discovery privileges add a host-control boundary; `docker.sock:ro` does not restrict API operations; scope discovery and assess a filtering proxy |
| Address split / distinct published backend ports | no discovery privilege needed; every published service needs a binding/filter decision; separate IPs/ports are not authentication or browser-cookie isolation |
| UI platforms / environment managers / clusters | inventory management APIs, credentials, daemon privileges, extra ingress/DNS services, and update duties; convenience or a cluster boundary is not proof of lower exposure |
| Direct LAN sharing | local path without a cloud intermediary; allow only selected routes and intended clients, with trusted HTTPS for sensitive flows |
| Private overlay / Tailscale Serve | device identity and policy can restrict access; adds an account/client/control-plane dependency; verify policy and that public sharing is off |
| Public tunnel | may expose an otherwise loopback-only backend to the Internet; require deliberate sharing, authenticated access, and an assessment of third-party transit/logging |

Proposed default: host-only ingress and private backends, plus whatever separately restricted Docker-caller path is required. Smartphone sharing is an explicit, reversible mode exposing only selected website routes. Bind the sharing entry point to the chosen LAN address and limit its source/interface scope; do not open databases, SMTP, cache management, Docker APIs, mail/database UIs, or proxy dashboards just to test a webpage. TLS protects traffic and server identity; it does not restrict who may use a development application. Use an application login or suitable edge authentication when the data requires it.

A separate LAN listener/entrypoint or a source-aware route policy may be needed: adding a LAN publish to an existing ingress port otherwise exposes every route on that listener. Preserve container callers when applying client-IP restrictions, and derive client identity only through trusted proxy hops. Expire/disable sharing explicitly, and fail closed if a configured LAN address disappears rather than falling back to wildcard binding.

## Smartphone testing over LAN Wi-Fi

This is an additional optional use case, not permission to change the laptop network or install a phone certificate now. It should work with the same bind-mounted source and selected ingress. Record the phone OS/browser during experiments; Android Chrome, iOS Safari, and embedded app browsers have different resolver, trust, and debugging behavior.

### Names and URLs must be reachable from the phone

On the phone, `127.0.0.1`, `::1`, and `.localhost` identify the **phone**, not the laptop. The laptop's `/etc/hosts` file is not distributed to the phone. DNS pointing an existing `.localhost` name at a LAN IP cannot reliably defeat browser special handling; use a non-localhost alias for ordinary Wi-Fi access. See [RFC 6761 §6.3](https://datatracker.ietf.org/doc/html/rfc6761#section-6.3).

For the multisite example, give a chosen site an invented-equivalent alias such as `site-a.dev.home.arpa`, route it through ingress, and add the corresponding alias to the instance's Drupal multisite map/trusted-host configuration. Both names must select the same intended site directory. Check canonical redirects, absolute asset/API URLs, cookie scope, and browser API/CORS settings; rewriting only the incoming Host header is not a general fix for URLs emitted by the application.

For the labeled example, split DNS can preserve its public `.home.arpa` URLs: the phone resolves them to the laptop LAN address while the laptop or containers resolve them through their existing working paths. Make every browser-facing dependency reachable, including the identity provider and API. If mobile aliases change the issuer or callback origins, configure dedicated development OIDC clients/redirects and consistent discovery metadata; do not change only the phone's callback URL. Avoid routing users into a production identity provider by accident.

### Tools and approaches to compare

| Approach | Tools / setup | Fit and limits |
|----------|---------------|----------------|
| Laptop LAN IP plus port | chosen LAN listener, narrow firewall permission; browser opens the laptop's address | cheapest connectivity probe; an IP Host usually selects the wrong Drupal multisite, HTTPS needs an IP SAN, and HTTP on a private LAN IP is not a localhost secure context |
| Local DNS plus named ingress | router DNS overrides, or DNS-only dnsmasq; phone uses that DNS; local CA trusted on phone | preferred minimal named-site experiment; preserve `.home.arpa` URLs and add multisite mobile aliases |
| mDNS name | Avahi/Bonjour announces a name such as `dev-laptop.local`; ingress route and Drupal alias still required | can avoid custom DNS for a simple site; does not automatically provide arbitrary multisite subdomains, certificate trust, or consistent support across all clients |
| Public wildcard DNS to a private IP | nip.io / sslip.io-style alias, named ingress, suitable certificate | quick alias experiment; Internet DNS/cache/rebinding-filter dependencies and metadata disclosure; does not grant access through a firewall |
| Owned real domain plus split DNS and DNS-01 | actual controlled domain, local DNS answer, ACME DNS credentials, ingress | publicly trusted HTTPS without installing a phone CA or exposing inbound WAN ports; adds domain ownership, issuance/renewal, DNS API secrets, and certificate-transparency disclosure |
| Tailscale Serve | laptop and phone clients in a restricted tailnet, Serve to a loopback backend, HTTPS enabled | private overlay alternative when router/DNS setup is awkward; Serve URLs use its tailnet domain and need application hostname/URL integration; not a pure LAN-only/offline design |
| Cloudflare Tunnel / similar public tunnels | tunnel client, authenticated sharing policy, temporary or configured public name | no router port forwarding needed; Internet access and third-party transit, different URLs and OIDC implications; not the default for private Wi-Fi testing |
| Android USB forwarding / custom-domain proxy | Android debugging authorization and Chrome DevTools port forwarding; proxy for custom-domain mapping where needed | useful fallback without opening LAN ports; not a Wi-Fi test or an iPhone/Safari equivalent; custom-domain and TLS behavior need separate validation |

[Avahi](https://avahi.org/) implements mDNS/DNS-SD. [Tailscale Serve](https://tailscale.com/docs/features/tailscale-serve) restricts sharing to the tailnet under its access policy; keep Funnel/public sharing off. [Cloudflare Quick Tunnels](https://developers.cloudflare.com/tunnel/get-started/quick-tunnels/) produce a temporary public URL; do not treat an unguessable URL as authentication. [Chrome's forwarding guide](https://developer.chrome.com/docs/devtools/remote-debugging/local-server) documents Android USB forwarding and a proxy-based custom-domain workflow. None of these tools removes application hostname and TLS requirements.

### Proposed minimal Wi-Fi experiment

1. **Network path:** use a trusted LAN with client-to-client traffic allowed. A matching SSID alone is insufficient: guest/AP isolation, VLANs, VPNs, or phone cellular fallback can prevent or change the path. Give the laptop a stable DHCP reservation if possible; record the intended phone source address and account for changes. No router WAN port forwarding or automatic UPnP exposure is needed.
2. **DNS:** use the router's existing local DNS first; otherwise evaluate a DNS-only dnsmasq instance with explicit selected names or a deliberately bounded development suffix. Configure the phone's Wi-Fi DNS to use it, or distribute it through the router's DHCP. Check effective resolution with phone VPN/encrypted-DNS profiles and browser DNS settings. Do not disable these protections globally just to make the test pass. dnsmasq need not become the DHCP server; bind/filter UDP and TCP 53 only where required. See the [dnsmasq manual](https://dnsmasq.org/docs/dnsmasq-man.html).
3. **Ingress and application:** expose only the intended LAN entry point and selected routes, preserving the host-only and Docker-caller paths. Register the multisite alias and all needed API/identity-provider names in their owning instances. A shared proxy is convenient here; a host loopback-address split cannot simply be exported as several services on one Wi-Fi IP at the same ports.
4. **HTTPS trust:** issue a leaf certificate with all mobile names, using the existing development CA initially. Transfer only the public CA certificate by a trusted channel, verify its identity, and install it on the test phone with explicit user consent during that future experiment. On iOS, a manually installed root also needs full SSL/TLS trust enabled in Certificate Trust Settings; see [Apple's instructions](https://support.apple.com/en-us/102390). Android app trust is application-dependent: modern apps do not necessarily accept user-installed roots; see [Android network security configuration](https://developer.android.com/privacy-and-security/security-config). Test the actual browser; do not bypass certificate errors. Installing a development root expands the phone's trust to certificates signed by that CA; protect its signing key, consider a dedicated test device, and record how to remove the temporary root afterward.
5. **Alternative TLS:** if installing a development CA is undesirable, compare an owned-domain DNS-01 certificate or Tailscale Serve. [DNS-01](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge) does not need the website exposed to ACME validation over the Internet. Real public certificates publish naming information in transparency logs; never use private project identifiers in public DNS/certificates. Tailscale also documents [certificate-name disclosure](https://tailscale.com/docs/how-to/set-up-https-certificates). These options add external dependencies; they are not mandatory for the LAN approach.
6. **Functional checks and cleanup:** load the correct site, assets and API on the actual phone; test touch/reflow plus OIDC if applicable. Inspect secure-context-dependent features, mixed content, WebSockets/HMR endpoints and any [local-network browser permissions](https://developer.chrome.com/blog/local-network-access/) separately. Disable sharing afterward, remove experiment-only DNS/trust entries as agreed, and verify the website/admin backends are no longer reachable over Wi-Fi while laptop and container access still work.

Local Wi-Fi HTTPS should cover every required mobile origin. A desktop page loading through `http://site-a.localhost` is not evidence that a phone opening an HTTP LAN alias can use service workers, camera APIs, or secure authentication flows.

## Comparison of all options considered

Weight is qualitative incremental operational and integration cost, not measured memory. **Shortlist** means compare first; **experiment** means viable with a caveat; **optional** means useful alongside routing; **low priority** means supported in principle but more change than this goal presently justifies.

| Criterion | What to compare / demonstrate |
|-----------|-------------------------------|
| Security exposure | host addresses/protocols and reachable routes, unintended LAN/VPN/IPv6 access, firewall behavior, authentication, management APIs, Docker privileges, certificate keys, and third-party data transit |
| Minimal tools | extra daemons/containers, runtimes, config ownership, dependency updates, and installation/removal work |
| Resources | measured idle CPU/RAM/disk and startup overhead on the same laptop |
| Existing behavior | URLs, Drupal multisite selection, cache/direct fronts, OIDC, container callers, and bind-mounted editor/build workflow |
| Smartphone testing | actual phone/browser access, DNS setup, required aliases, trusted HTTPS, optional phone software, and reversible sharing |
| Isolation and recovery | independent project start/stop, route collisions, recreation/reboot, and preserved project networks/data |
| Offline operation and portability | cached-image startup, local DNS versus Internet services, changing Wi-Fi addresses, and repeatable installation in other ASC instances |

| Option | Extra weight | Existing editor tree | Existing URLs | Assessment |
|--------|--------------|----------------------|---------------|------------|
| Traefik container, file provider, container aliases | low | retained | retained | shortlist; explicit registration, no runtime socket |
| Traefik container, Docker provider, opt-in labels | low | retained | retained | shortlist; automatic discovery, API privileges |
| Native Caddy + loopback backend ports | low | retained | retained | shortlist; no extra container/network, route registration |
| Caddy container + Docker network | low | retained | retained | experiment; same network contracts as Traefik files |
| Native or containerized nginx | low | retained | retained | experiment; explicit config and DNS/reload policy |
| caddy-docker-proxy | low–medium | retained | retained | experiment; labels and Docker API, custom Caddy build |
| nginx-proxy / docker-gen | low–medium | retained | retained | viable label/env discovery alternative |
| Nginx Proxy Manager | medium | retained | retained | viable UI alternative; no socket required for explicit upstreams |
| HAProxy / Envoy | low–medium / medium–high | retained | retained | capable; lower priority unless already familiar |
| Shared ingress forwarding to an existing project proxy | low–medium | retained | retained | migration experiment; extra hop, less project reconfiguration |
| HTTP routing plus TLS SNI passthrough | low–medium | retained | retained where TLS already works | migration experiment; retain project certificate ownership |
| Separate loopback IPs for projects | almost none | retained | potentially retained | experiment; container callers and IPv6 need a solution |
| Fixed distinct host ports, no ingress | none | retained | ports added | valid baseline / debugging fallback |
| Fixed distinct backend ports + shared ingress | low | retained | retained | viable; explicit port assignment rather than network sharing |
| Docker-assigned backend ports + shared ingress | low | retained | retained | viable; discover mapping and update registration on recreation |
| Portless / similar dev URL launchers | low–medium | retained | custom-domain fit to verify | experiment; Node runtime and loopback-caller limitation |
| One stack at a time / profiles to alternate | none | retained | retained | fails the concurrency goal |
| Combined top-level Compose project | low tool cost, high coupling | retained | ingress still needed | possible orchestration model; not a port fix alone |
| DDEV | medium integration | Linux bind mounts supported | custom names possible | viable environment migration, not the smallest routing change |
| Lando | medium integration | bind mounts supported | custom names possible | viable Compose adaptation and lifecycle layer |
| Docksal | medium integration | bind mounts supported | custom names possible | viable environment migration; shared DNS/proxy pattern |
| Warden | medium integration | Linux bind mounts supported | custom names possible | useful global-services model, broader runtime adoption |
| docker4drupal presets | low–medium adaptation | bind mounts supported | can retain | Compose/image starting point; still needs a shared ingress or port policy |
| Dokploy | high for this goal | conditional mount design | custom routing possible | local PaaS experiment; deployment-path caveats |
| Coolify | high for this goal | explicit host bind possible | custom routing possible | local PaaS experiment; deploy/build and edit loops differ |
| Portainer | medium | bind mounts supported | no routing fix by itself | optional management UI |
| Native k3s | high | node `hostPath` possible | ingress can preserve names | viable Kubernetes learning branch; workload conversion |
| k3d / kind / minikube | high | node mounts / driver-dependent sharing | ingress can preserve names | extra cluster/VM layer; workload conversion |
| Argo CD on a local cluster | high | mounted source can remain live | ingress can preserve names | viable GitOps learning branch; not a Compose router |
| Istio service mesh | high | depends on workload mounts | gateway can preserve names | learning branch; service-to-service policy is broader than ingress |
| Tilt with Compose | medium | existing mounts can remain | routing still required | optional dev orchestration; no Kubernetes requirement |
| Skaffold / DevSpace with Kubernetes | high for current stacks | node mounts or sync | ingress can preserve names | useful if Kubernetes becomes a separate goal |
| Incus / systemd-nspawn / separate namespaces | medium–high | host directory mounts possible | `.localhost` still constrains routing | isolation experiment; integration and nested-runtime work |
| Podman / Quadlet | medium–high migration | bind mounts supported | possible | viable runtime alternative; does not multiplex HTTP alone |
| MicroVM per project | high | sharing/sync required | ingress or new addresses required | strongest isolation, little immediate benefit |
| macvlan / ipvlan / dedicated non-loopback addresses | medium networking | retained | `.localhost` cannot simply move | experimental; laptop LAN/Wi-Fi and host reachability issues |
| nftables redirects / systemd socket activation / host networking | variable | retained | not sufficient alone | cannot replace hostname-aware routing on one listener |
| Browser PAC / explicit forward proxy | low–medium | retained | browser-dependent | partial workaround; does not cover PHP, CLI, or all test tools |
| Selected LAN ingress + local DNS | low | retained | mobile aliases for `.localhost` | optional phone access; narrow listener/client/route scope and trusted HTTPS |
| Private overlay / Tailscale Serve | medium | retained | Serve hostname differs | optional phone access with device policy; external account/client dependency |
| Android USB forwarding | low–medium | retained | custom-domain setup may be needed | phone-testing fallback without LAN publication; not Wi-Fi or iOS parity |
| Public tunnels / remote development host | medium | local bind or sync depending on design | usually changes access | optional sharing/offloading, not offline local routing |
| Public wildcard DNS: nip.io / sslip.io / traefik.me / lndo.site | no daemon | retained | usually renamed | DNS companion; offline/rebinding/privacy considerations |
| `/etc/hosts` / dnsmasq / systemd-resolved routing | none–low | retained | can retain | DNS companion, not ingress |
| Shared Mailpit / database UI | low | retained | utilities get shared routes | optional service consolidation; isolation trade-off |

### Direct ingress: Traefik files or labels

A containerized edge joins one external frontend network, or joins one frontend network per project. Only HTTP frontends and required caller/ingress endpoints join; databases and PHP-FPM need not be exposed there. A single common network is simplest; separate frontend networks reduce cross-project connectivity at the cost of more network memberships.

When attaching a previously default-network-only service to a new network, explicitly retain its project network too. Otherwise it may lose access to PHP, cache, or the database. Use project-unique aliases, not plain shared names such as `nginx` or `web`. With Docker discovery, select the backend network explicitly using the provider setting or `traefik.docker.network`. With file routes, target the unique DNS alias and container port, not a captured container IP.

The [Docker provider](https://doc.traefik.io/traefik/reference/install-configuration/providers/docker/) supports opt-in exposure, network selection, and label constraints. Separate proxy containers do not inherently conflict: competing published host sockets and overlapping discovery scopes cause the conflicts. Scope every Docker-discovering proxy deliberately, including any project proxy kept during migration. Names for routers, services, and middlewares must be unique within the provider configuration.

A read-only socket mount is still a privileged Docker API connection. Compare direct socket access, a private socket-filtering proxy, and no socket. A filter adds a service and must permit the exact read/event endpoints discovery needs. Do not expose its unauthenticated endpoint to application or LAN networks. See [Traefik's Docker API security guidance](https://doc.traefik.io/traefik/reference/install-configuration/providers/docker/#docker-api-access) and [Docker socket protection](https://docs.docker.com/engine/security/protect-access/).

With the [file provider](https://doc.traefik.io/traefik/reference/install-configuration/providers/others/file/), mount and watch the parent directory so atomic replacement of a snippet remains visible. Route membership changes require registration updates; ordinary backend recreation need not change a stable-alias route. Test reconnection after address changes and after starting the edge before any backends exist. ASC lifecycle commands may query Docker without giving the long-running proxy a Docker socket.

[DDEV's router customization](https://docs.ddev.com/en/stable/users/extend/traefik-router/) explicitly uses the file provider instead of Docker discovery. That supports the architecture, not every proposed ASC detail. The first draft's version/date story about DDEV dropping nginx-proxy is not needed and is not retained as evidence.

Treat a Traefik v2-to-v3 transition as a migration with [configuration checks](https://doc.traefik.io/traefik/migrate/v2-to-v3/), not a promise that every v2 rule remains equivalent. Select a supported pinned release when implementing, consult the [support table](https://doc.traefik.io/traefik/deprecation/releases/), and check Docker API compatibility. As checked on 2026-10-29, that table lists 3.7 as supported and dates 2.11 security support to 2026-09-07; the existing floating v2 tag is not a suitable new long-term default. Do not copy a floating `v2`, `v3`, or `latest` tag into the final host service.

### Caddy and nginx: native or containerized

Native Caddy can use its [official systemd service](https://caddyserver.com/docs/running#linux-service) and forward to project services published on distinct loopback ports. This is a serious lightweight candidate, not merely a fallback after implementing Traefik. The host process cannot use Docker's embedded service DNS directly, which is why backend host ports are attractive here. A Caddy container can instead use Docker aliases and publish no backend ports.

A short generated Caddyfile or imported per-project fragments can be validated and gracefully reloaded. Caddy does not watch arbitrary Caddyfile edits automatically. Define one serialized update/reload owner and preserve the last valid configuration if a candidate fails validation. Its [reverse proxy](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy) supports WebSockets and configurable upstream/header handling; Docker-DNS recreation behavior remains an experiment requirement.

[caddy-docker-proxy](https://github.com/lucaslorentz/caddy-docker-proxy) provides label discovery through a plugin build and Docker API access. It is viable, but entails translating existing Traefik labels and maintaining the plugin image.

nginx can run natively with loopback backends or as a container with Docker aliases. Keep Host and forwarded scheme/port correct. A literal container IP in `proxy_pass` becomes stale after recreation; a hostname also needs an intentional re-resolution policy. Modern nginx offers upstream `resolve` and `resolver` in open source; check the installed package version rather than assuming this requires nginx Plus. See [proxy directives](https://nginx.org/en/docs/http/ngx_http_proxy_module.html) and [upstream DNS resolution](https://nginx.org/en/docs/http/ngx_http_upstream_module.html).

[nginx-proxy](https://github.com/nginx-proxy/nginx-proxy) automates configuration with docker-gen and Docker metadata; it is still a viable alternative. [Nginx Proxy Manager](https://nginxproxymanager.com/setup/) adds a UI and persistent configuration database, with SQLite available: it does not inherently require a second database container or Docker socket. Its UI would become another configuration owner alongside ASC. [HAProxy](https://www.haproxy.org/) is also a credible small native proxy; [Envoy](https://www.envoyproxy.io/docs/envoy/latest/start/start) adds more configuration concepts. Neither needs a cluster just to route these sites. They are lower-priority choices because no current stack already uses their configuration.

### Retain a project proxy, or flatten everything

**Flat ingress** routes directly to the web/cache/API/identity-provider/UI services. One TLS owner, fewer proxy hops, more project route migration.

**Chained ingress** forwards a project's names to its existing proxy on an internal network or distinct backend ports. This preserves more project behavior initially. Options include HTTP Host routing on port 80 and TLS SNI passthrough on 443, leaving the project's existing TLS termination and certificate in place. Another option terminates TLS at the edge and forwards HTTP or verified HTTPS inward; then redirects and forwarded-header trust must be configured at both layers.

Passthrough cannot apply HTTP middlewares inside encrypted traffic. It requires TLS/SNI-capable routing and a backend with working HTTPS. The multisite service's unused or unconfigured 443 mapping does not qualify automatically. Avoid forwarding back to the public ingress and creating a loop.

A project proxy can be retained even when the eventual preferred architecture is flat. Compare migration effort, idle resources, and OIDC behavior before deleting it. Do not combine a proxy migration, a TLS-owner migration, and a major-version upgrade in one mandatory first experiment.

### Address split, fixed ports, and random ports

An address split can leave `.localhost` on `127.0.0.1` / `::1` and publish the labeled proxy on `127.0.0.2`, with only its invented-equivalent `.home.arpa` hosts entries moved. Port 8080 needs the same address split. Every old wildcard binding must actually be replaced, not supplemented.

Unchanged `host-gateway` callers would fail against loopback-only publishes. That is a limitation of that caller path, not proof the whole approach is impossible. Test internal public-hostname aliases to the labeled proxy, or explicitly allocated reachable host addresses. Do not attempt to assign IPv6 `::1` to both independent stacks. The address split has almost no extra software but more per-project address, caller, and IPv6 rules.

Distinct fixed host ports are the no-proxy baseline. They allow concurrency immediately, with URL and OIDC configuration costs. Drupal's hostname-only multisite aliases may still match after the port is stripped during lookup; validate actual redirects and absolute links. Cookie isolation does not follow port isolation. Preserving portless URLs is a preference to test against this baseline, not an additional hard constraint invented by the review.

With an ingress, fixed backend ports are invisible to browser URLs. A host registry can record them, but another application may still occupy them: detect the conflict at startup, report it, and choose a new assignment through an explicit workflow.

Docker-assigned ephemeral backend ports avoid a hand-maintained allocation list and are a valid interpretation of the initial proposal. Discover the mapping after creation, register the route, and refresh it when recreation changes the port. A native proxy can reach loopback publishes; a bridge-network proxy cannot use its own `127.0.0.1` to reach the host. Preserve a correct host address or choose direct Docker-network routing. The extra registration step is the trade-off, not grounds to reject this option categorically.

[Portless](https://github.com/vercel-labs/portless) offers named URLs, static aliases to backend ports, local TLS, custom suffixes, and OS-startup integration. It warrants a small comparison with native Caddy. Its documented default loopback binding and custom-domain versus LAN-mode behavior are material for Docker callers; Node.js is also an extra runtime dependency. Exact preservation of both naming schemes and the container-caller path is unproven here. It still owns 80/443 and requires removing competing publishes.

### Orchestration and environment managers

One combined Compose definition can start services from different trees, but two services publishing the same address and port still conflict. It therefore also needs port remapping or ingress and globally unique service names. Relative mount paths and environment files must retain each owning project's meaning. This couples lifecycle without inherently solving routing.

[DDEV](https://docs.ddev.com/en/stable/users/usage/architecture/) provides a shared Traefik router, local TLS, and a PHP/Drupal-oriented project model. It is compatible with editing host files on Linux. [Custom hostnames](https://docs.ddev.com/en/stable/users/extend/additional-hostnames/) can preserve local names, including multisite needs, subject to DNS/TLS setup. Existing bespoke images, builds, and services need adaptation through its configuration and custom Compose support. It is viable if standardizing whole environments becomes valuable, but broader than this port-conflict task.

[Lando's proxy](https://docs.lando.dev/landofile/proxy.html) routes custom hostnames; its [Compose integration](https://docs.lando.dev/getting-started/what-it-do.html) can consume existing Compose files with Lando's environment/network additions. It is inaccurate to require replacing every Dockerfile. Adoption still adds a CLI, lifecycle, and network model to reconcile with ASC. Custom names need appropriate host resolution, which may be existing hosts rows rather than a new DNS daemon.

[Docksal](https://docs.docksal.io/core/system-vhost-proxy/) supplies shared proxy/DNS services and arbitrary custom domains; its project model and `fin` would need integration. Optional auto-start/stop is an energy-saving idea for later, not a requirement to run both current stacks. Do not add a privileged watcher merely to save an idle proxy.

[Warden](https://docs.warden.dev/architecture.html) separates global services from per-project Compose environments, including shared Traefik, DNS, mail, and database tools. That architecture is relevant even if Warden itself is not adopted. Linux bind mounts suit the editor workflow. Evaluate complete adoption only if its environment conventions provide value beyond what ASC already manages.

[docker4drupal](https://github.com/wodby/docker4drupal) is another Compose/image starting point rather than a host-wide routing owner. Evaluate its current proxy conventions if adopting presets; do not assume its default files match the modified multisite stack or require a particular URL-port workaround.

### Dokploy and Coolify

**Dokploy is technically viable on a Linux laptop, with significant operational change.** Its [installation model](https://docs.dokploy.com/docs/core/manual-installation) involves Docker/Swarm management and a deployment control plane; the [architecture](https://docs.dokploy.com/docs/core/architecture) is broader than one proxy. It must own ingress ports or sit behind a separately designed edge.

Its [Compose documentation](https://docs.dokploy.com/docs/core/docker-compose) warns that repository-relative files can disappear during fresh deployments and prescribes persistent `../files` mounts or named volumes. The same page warns against absolute host paths. Its [application mount settings](https://docs.dokploy.com/docs/core/applications/advanced) nevertheless expose host bind mounts. Treat this as a workflow-specific caveat to resolve in an isolated experiment; do not assume any arbitrary existing checkout is either safely supported or categorically impossible. A route-only use of its Traefik is possible in principle but adds a platform to obtain a proxy.

**Coolify explicitly supports an existing host directory as a bind source.** If the deployment server is the laptop, that directory can be the VSCodium working tree. See [bind mounts](https://coolify.io/docs/core/persistent-storage/storage-mounts/bind-mounts). Its [Compose deployment](https://coolify.io/docs/applications/builds/docker-compose) still has its own resource directory, build context, generated configuration, and networking. Mounting source at runtime does not automatically make an image build consume the same uncommitted files. Raw Compose mode leaves more ownership with the author, not less.

For either platform, start with a disposable sample and prove: an unsaved-to-git edit is served through the mount, image builds use the intended context, a redeploy preserves that tree and permissions, URLs and CA trust work from containers, and uninstall restores the previous ingress without touching project data. Measure background processes, RAM, disk, startup time, and privileges. These are legitimate learning experiments, lower priority for minimal daily routing.

Portainer can manage Docker resources and bind mounts, but does not make two unchanged port-80 publishes coexist. It is an optional management layer, not the routing architecture.

### Kubernetes, Argo CD, and developer loops

Native k3s, Docker-node clusters such as k3d/kind, and minikube are viable local platforms. Services need conversion from Compose, persistent-data migration choices, and an ingress configuration. Existing hostnames can be retained if DNS and ingress are configured accordingly; Kubernetes does not intrinsically require renaming them. Budget cluster/control-plane resources as well as application resources.

[Kubernetes `hostPath`](https://kubernetes.io/docs/concepts/storage/volumes/#hostpath) mounts a node directory into a pod. On native Linux this can be the editor tree. A containerized node needs the host directory mounted into the node first, then into the pod; [kind extra mounts](https://kind.sigs.k8s.io/docs/user/configuration/#extra-mounts) document that layer. Validate UID/GID, file watchers, mount propagation where needed, and database persistence. File sync is an alternative, not mandatory merely because Kubernetes is used.

[Argo CD](https://argo-cd.readthedocs.io/en/stable/getting_started/) adds GitOps reconciliation of Kubernetes manifests. It can manage the manifests that declare local source mounts while VSCodium edits those files. [Self-heal](https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/#automatic-self-healing) concerns live resource drift, not arbitrary mounted application-file contents. Image-baked source updates still need a build/deploy workflow. Argo CD is viable if learning or matching a Kubernetes deployment environment becomes a goal; it offers no direct solution for two unchanged Compose stacks.

[Tilt supports Compose directly](https://docs.tilt.dev/docker_compose.html), with optional UI, lifecycle control, and live-update features. It can retain existing bind mounts and be wrapped by an ASC extension; it does not remove the ingress requirement. [Skaffold](https://skaffold.dev/docs/filesync/) and [DevSpace](https://www.devspace.sh/docs/configuration/dev/connections/file-sync) offer optional sync/build loops and are especially relevant to a Kubernetes branch; Skaffold also documents a Docker deployer. The decision to adopt them should follow the runtime choice.

[Istio](https://istio.io/latest/docs/setup/getting-started/) is a further service-mesh experiment if learning traffic policy becomes a goal. Its control/data-plane concepts and gateway setup add work beyond a single ingress; it is not a prerequisite for running Envoy or for local hostname routing.

### Other experimental branches

- **[Incus](https://linuxcontainers.org/incus/docs/main/explanation/instances/) / systemd-nspawn / explicit namespaces:** separate addresses and source mounts can isolate projects, but running existing Docker stacks inside another container or namespace adds daemon/storage/network work. `.localhost` still reaches host loopback, so isolation alone does not preserve those URLs. [systemd-nspawn](https://www.freedesktop.org/software/systemd/man/latest/systemd-nspawn.html) documents directory binding and network namespace choices. A conventional VM or microVM such as [Firecracker](https://github.com/firecracker-microvm/firecracker) adds guest management and file-sharing work; lightweight guest virtualization does not itself solve hostname routing.
- **Podman Quadlet:** [Quadlet](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html) integrates containers with systemd. It is a viable alternative runtime/service manager, not hostname multiplexing. Running just the proxy on Podman while apps stay on Docker loses shared Docker DNS/network convenience. Rootless privileged-port and user-session/linger behavior need deliberate setup.
- **Dedicated IPs / macvlan / ipvlan:** independent service addresses avoid socket conflicts, but `.localhost` cannot simply be reassigned. Docker documents [macvlan host-to-container restrictions](https://docs.docker.com/engine/network/drivers/macvlan/); laptop Wi-Fi, VPN, LAN changes, and host-side shim/routing can add fragility. Network namespaces with routed veth addresses are another version of this trade-off.
- **nftables / host networking / socket activation:** destination-IP/port rules cannot decide between arbitrary HTTP hosts sharing the same address and port. A hostname-aware process is still needed. Host networking removes network namespaces and therefore does not solve competing binds. Socket activation can improve process lifecycle only when supported by the selected proxy.
- **Browser forward proxy / PAC:** may preserve browser URLs, but needs HTTPS CONNECT handling and client-specific setup. CLI, PHP, Java, and container browsers must all be configured consistently; some bypass localhost. This is a partial workaround, not a transparent replacement for ingress.
- **Public tunnels or a remote development host:** useful for sharing or moving heavy workloads off the laptop. They introduce network dependency, access controls, and possibly file synchronization. They do not improve this offline-capable local routing case by themselves.

## DNS and service consolidation companions

| Companion | Useful role | Limitation |
|-----------|-------------|------------|
| Existing `.localhost` behavior | preserve multisite browser access without new names | validate each resolver and container browser |
| Existing `/etc/hosts` | retain the small explicit `.home.arpa` inventory | no wildcard matching; laptop entries do not configure the phone; preserve unrelated entries |
| dnsmasq | synthesize local wildcard answers and optionally serve containers | one more daemon, port-53 ownership and VPN/resolver integration |
| systemd-resolved | route a chosen suffix to a local DNS server | a routing drop-in alone is not a wildcard zone that synthesizes arbitrary answers |
| Public wildcard DNS | quick new names aimed at a chosen IP | offline/cache behavior, rebinding filters, lookup disclosure; does not preserve existing names automatically |
| Shared Mailpit / database UI | fewer repeated utility services and published ports | mixes captured mail / database visibility unless deliberately separated |

[dnsmasq's manual](https://dnsmasq.org/docs/dnsmasq-man.html) documents local address synthesis; [systemd-resolved](https://www.freedesktop.org/software/systemd/man/latest/systemd-resolved.service.html) documents resolver and routing behavior. Inspect the laptop's actual NetworkManager/resolved setup before proposing a DNS installation. `.test` is another reserved naming option but entails deliberate migration; `.local` participates in mDNS and is not a drop-in replacement.

Solr, mail UIs, validator APIs, and cache HTTP endpoints are HTTP even if they use unusual ports; they can receive ingress routes. MySQL, Redis, SMTP, and a cache management interface are different protocols. An HTTP reverse proxy cannot multiplex them by an HTTP Host header. TCP routing is possible but usually still needs distinct entrypoint ports unless the clients offer a suitable discriminator such as TLS SNI.

Prefer private project-network access for non-HTTP services. Publish only when a host GUI or CLI needs it, choose an interface deliberately, and distinguish a recorded preferred port from an actually acquired port. The extension should report conflicts rather than stopping an unrelated service or silently remapping a documented endpoint.

## Existing ASC contracts and integration gaps

Read against the current mother; these references are not promises that stubs already work:

- [`remote_traefik`](../../../scripts/asc/contrib/asc/remote_traefik/) is a remote ACME-oriented implementation. Its systemd template uses one project docroot, the old `docker-compose` executable name, and `down -v` before start and on stop. Its setup script references an obsolete template location and checks a different variable during substitution. Do not reuse it unchanged or expand this review into repairing it.
- [`compose`](../../../asc/extensions/compose/) defaults to generation. `f_dc_write_yml()` selects the most-specific source for each configured basename and copies it; it does not merge all contrib and instance YAML fragments. It can regenerate root Compose files, including legacy basenames. Hand edits to generated output are not an integration strategy.
- [`file_registry`](../../../asc/extensions/file_registry/) provides one string per key and host scope defaulting to `$HOME/.local/state/asc/registry`. Reuse it for references or preferred assignments; do not silently turn it into a second manifest database or atomic allocator.
- [`hosts_file`](../../../asc/extensions/hosts_file/) currently contains empty actions. Do not make functional DNS/hosts management depend on them.
- [`.asc_extensions_ignore`](../../../.asc_extensions_ignore) disables Compose, hosts-file, Docker helper, and remote Traefik in this mother checkout. The nested-Docker helper is not a local ingress implementation.
- [`README.md`](../../../README.md) owns the thin-glue, opt-in extension model. [`gates.core.yml`](../../../gates.core.yml) owns approval state. This research revision does not grant implementation or a cross-instance rollout.

The key integration decision is how an extra local-ingress configuration reaches Compose **without replacing an existing instance override**. Options to evaluate during narrowing:

1. Have the existing instance-owned selected definition express the integration using generic parameters/contracts supplied by the contrib extension.
2. Pass an additional explicit Compose override file after the instance's own base and override files through the actual lifecycle invocation path. Verify every relevant ASC and direct CLI entry point uses it.
3. If neither fits, propose a focused change to Compose assembly separately. Do not assume a core merge feature or add a second generator silently. The user's required delivery location remains `scripts/asc/contrib/asc/`; any need to change core is an unresolved design constraint to discuss.

A contrib definition cannot hard-code private hostnames or assume all projects have an `nginx` service. Instance declarations must supply public names, backend service/alias, internal port, protocol/TLS policy, and any caller-network needs. Prefer an explicit small inventory to a generic parser translating every Traefik label or executing arbitrary `sites.php` code in the mother. An instance-side export can use its own PHP environment when appropriate; it must not copy its map into this repository.

## Proposed extension responsibilities

One extension may be enough; split host-ingress and backend-specific adapters only if the experiments justify it. Possible labels such as `local_ingress` or `local_traefik` remain provisional. All eventual extension code goes under `scripts/asc/contrib/asc/`, opt-in and disabled by default in the mother. Client service choices and names stay in instance configuration. Dependencies are installed through host tools, not vendored into ASC.

### Host ingress lifecycle

- Exactly one explicit host ingress owner, independent of either project checkout. Choose a stable host state/config directory, explicit Docker context/project name if containerized, and a single selected proxy backend.
- Compare three startup modes: native packaged systemd service; container restart policy after initial creation; or an explicit systemd-managed Compose deployment. Do not require a custom systemd wrapper merely because Docker is involved.
- System units can order after `docker.service`; user units belong to another manager and cannot gain that ordering with the same dependency name. User services need explicit readiness/retry and a choice between login-only and lingering behavior. Boot startup versus desktop-session startup is a user preference, separate from hairpin routing.
- Detached Compose start is not a supervised foreground process. A `Type=oneshot` / `RemainAfterExit=yes` deployment unit tracks setup, not ongoing container health. Alternatively supervise attached Compose, or use Docker's restart policy. Assign crash recovery to one clear owner and test Docker restart behavior. See [Docker automatic starts](https://docs.docker.com/engine/containers/start-containers-automatically/) and [systemd service types](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html).
- Use absolute executable/config paths in units, the intended user/context, directory/key permissions, and no dependency on shell aliases or a checkout remaining at its original location. Install privileged service files explicitly; keep runtime route writes unprivileged where possible.
- Detect an occupied listener and name the conflicting address/port without killing its owner. Check IPv4, IPv6, and UDP 443 if HTTP/3 is enabled; disable unused listeners.
- Provide explicit host-only versus selected-LAN sharing scope, including chosen address, allowed clients, selected instance routes, visible status, and disable/expiry behavior. Keep the Docker-caller path functional, never widen to a wildcard automatically, and remove only owned firewall/DNS configuration on cleanup.
- Keep proxy admin endpoints private or disabled. Reject unknown hosts without routing them to an arbitrary project. Permit opt-in LAN access only after addressing DNS, trust, and interface scope.
- Stop/start/rollback never removes database volumes. No `down -v`, prune, broad network deletion, or automatic CA replacement. Shared networks are removed only when no participating project uses them.

### Per-instance registration

- Use a stable unique instance identity, explicit hostnames, and project-unique backend aliases. Reject duplicate hostname ownership, conflicting route identifiers, and invalid configuration before publishing a new generation.
- Keep original project networks, mounts, cache routes, application environments, and database volume identities. Preserve Drupal trusted-host restrictions; trust forwarded headers only from the intended ingress hops. Check the effective Drupal reverse-proxy settings and identity-provider forwarded-header behavior rather than globally trusting clients. Clear or replace the intended published ports in the **effective** merged configuration. Empty plain lists do not erase inherited ports; `!reset` / `!override` semantics and minimum supported Compose versions must be checked. See [Compose merge rules](https://docs.docker.com/reference/compose-file/merge/).
- Serialize shared route updates. Stage and validate candidates, publish atomically, and verify the selected proxy accepted the configuration. A successful shell exit or file write alone is not acceptance.
- A project updates/removes only its own registration. Starting/stopping it must leave other projects routable. Define behavior for crashes, direct `docker compose` use bypassing ASC, deleted/moved checkouts, and stale files after reboot. Static registrations may legitimately remain while a backend is stopped and return a controlled unavailable response; do not build an event daemon unless required.
- Register mobile hostnames only in the owning instance, with correct multisite selection, trusted-host and canonical URL settings. Include dependent API/identity-provider names; DNS aliases alone do not update application origins or OIDC clients.
- Preserve the existing CA initially. Certificate replacement/renewal and provider-specific reload behavior need tests. Do not translate a successful host-browser test into assumed PHP/Java/Node trust.
- Keep explicit `extra_hosts` only where the chosen container-caller path needs them; they override DNS aliases. Do not weaken certificate checks to mask routing/trust failures.

Before code is written, recheck the [builder subject templates](../../../asc/extensions/builder/subject/), the [anti-pattern catalog](../../../data/entities/anti-pattern/), and the ASC authoring skills. Actions, hook implementations, and optional includes must justify their existence; this plan does not call for new eager helpers, a second registry, or a generic orchestration framework.

## Proposed experiments and acceptance evidence

None of these experiments was executed here. They are alternatives to authorize later; the order does not force a proxy/provider choice. Preserve uncommitted changes and record the original effective Compose, hosts entries, mount sources, network membership, and data-volume identities privately before any probe.

1. **Cheap baseline:** compare an address split and explicit high URL ports using disposable local overrides. Test host access and a server-side identity-provider call. If unchanged host-gateway fails, test the supported caller-network alternative before rejecting the address split.
2. **Native Caddy:** one multisite HTTP route and one labeled HTTPS route, distinct loopback backends, existing CA. Compare fixed backend ports with Docker-assigned ports and route registration. Test container callers; a purely loopback ingress needs an additional reachable path for them.
3. **Traefik files:** the same routes over a frontend network, retaining project networks and unique aliases. Start the edge before backends, recreate backends, atomically replace a route file, and verify recovery. No Docker socket in the proxy.
4. **Traefik Docker discovery:** only if comparing automatic discovery is valuable. Reuse scoped labels, select the frontend network, test a pinned supported version and Docker API behavior, and record the chosen API access boundary.
5. **Migration comparison:** retain the existing project proxy behind ingress, then compare direct application routes. For passthrough, test actual SNI/certificate behavior. For edge termination, test redirect chains and trusted forwarded headers. Preserve cache versus direct-front behavior.
6. **Smartphone and exposure:** on a trusted Wi-Fi network, compare selected-LAN ingress plus router DNS/dnsmasq and trusted HTTPS, with a private overlay or Android USB forwarding as optional alternatives. Verify correct multisite/OIDC behavior and both allowed and denied access. Record phone/browser versions, actual resolver/CA setup, whether all traffic remained local, and sharing cleanup.
7. **Optional learning branches:** independently evaluate Portless, a DDEV/Lando adaptation, Dokploy/Coolify on disposable trees, or Kubernetes plus Argo CD. Do not require these before the minimal candidates can be judged.

For each candidate, collect fresh results rather than checking only that a container is running:

| Area | Required evidence |
|------|-------------------|
| Concurrent routing | both stacks up; every declared multisite hostname reaches its intended site, including nested names; every labeled hostname reaches its intended backend |
| Complete port inventory | no duplicate effective address/port/protocol tuples; 8080 resolved; optional profiles and non-HTTP host access exercised |
| Browser and CLI | IPv4 and IPv6 where supported, browser resolver behavior, host curl, container CLI, and container browser tools checked separately |
| Drupal / proxy semantics | intended multisite directory, Host, scheme, absolute URLs, redirects, assets, uploads, cookies, cache route, and direct-front route correct |
| TLS and OIDC | trusted chain/SAN/SNI; discovery and issuer equality; browser login, callback, code exchange and server-side token/JWKS/API access without bypassing TLS verification |
| Security exposure | test from an allowed phone and a denied client; selected website routes only, unknown/unselected hosts blocked, no reachable management/database/debug ports; verify IPv4/IPv6 and Docker firewall behavior, network changes, and disable/expiry cleanup |
| Smartphone workflow | trusted HTTPS, correct multisite and dependency URLs, touch/reflow/assets/API/login on the real phone; no certificate bypass; phone DNS/CA changes and removal documented |
| Editor workflow | a reversible edit through the host tree is served immediately; bind source, UID/GID, file watching, and rebuild context stay correct |
| Isolation and recovery | stop one project while the other remains usable; backend recreation, proxy restart, Docker restart, reboot or login as selected, and offline startup after images are cached |
| Registration errors | duplicate hostname rejected, malformed candidate does not disrupt other routes, concurrent updates serialized, stale registration behavior documented |
| Lightweight operation | comparable idle CPU/RAM, process/container count, disk, startup time, and number of files/actions needed to add a project; no invented benchmark numbers |
| Rollback | restore only this experiment's files and bindings after releasing ingress listeners; original direct stack access returns; database volume identity/data and unrelated hosts entries preserved; sharing listeners, owned firewall/DNS changes, and temporary phone trust removed as agreed |

A browser response from the default Drupal site is not proof that every multisite route is correct. An HTTP 200 is not proof of OIDC success, certificate trust, or cache correctness.

Rollback must be possible after an interrupted experiment as well as a clean stop: keep a private record of temporary files, service units, networks, routes, hosts changes, and port mappings. Release shared ingress listeners before restoring the conflicting original publishes; the original stacks will again require separate start times unless the experiment is retained deliberately.

## Open decisions for narrowing later

- [ ] Which phone OS/browser needs Wi-Fi testing, and should sharing be temporary per site or a persistent trusted-LAN feature?
- [ ] Router DNS or an optional local DNS service; install the development CA on the test phone, or use an externally trusted certificate/private overlay?
- [ ] Which routes, client identities/addresses, listener addresses and IPv6 policy may be shared; how are access, expiry, and revocation verified?
- [ ] Is keeping every existing URL without a port worth the added proxy, compared with address splitting or high-port baselines?
- [ ] Native proxy with host ports, container proxy with frontend networks, or staged forwarding through existing project proxies?
- [ ] Explicit route files or Docker discovery; if discovery, which API boundary and scope?
- [ ] Preserve host-gateway callers or use network aliases; which container browser needs special treatment for `.localhost`?
- [ ] One shared frontend network or separate project frontend networks?
- [ ] Boot startup, login/session startup, or on-demand start; who owns crash recovery?
- [ ] Keep HTTP for current multisite domains, or separately add complete trusted TLS coverage?
- [ ] Which utility ports move behind ingress, and which non-HTTP ports remain published?
- [ ] How does the selected per-instance Compose integration survive regeneration and direct CLI use without a core change?
- [ ] Are environment/PaaS/GitOps learning benefits valuable enough to justify a broader branch?
- [ ] Select the extension name(s), minimal configuration contract, installation/rollback ownership, and scoped implementation approval only after comparing evidence.

## Research notes

Primary documentation was consulted on 2026-10-29 and linked next to the claims it supports. Architectural rankings and the experiment shortlist are this review's judgments. Documentation establishes capabilities and caveats, not successful operation on this laptop. Current release support, platform storage rules, and tool requirements must be checked again at implementation time.

The comparison intentionally keeps all considered alternatives, including lower-priority and partial solutions. No installation or migration decision follows merely from appearing in this catalog.
