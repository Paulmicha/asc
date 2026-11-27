# Lightweight local observability

| Field | Value |
|---|---|
| Date | 2026-11-27 |
| Status | Idea for discussion. No tool, license, or install path is approved. |
| Scope | Error tracking, host and service health, and logs, metrics, and traces for local-first development and a single server. |
| Method | Reading upstream docs, licenses, and named third-party write-ups on 27 November 2026. Nothing in this note was installed or benchmarked in this repository. |
| Related ASC behavior | ASC already captures local command output through its logged wrappers, for example [`asc/instance/logged/thread.sh`](../../../../asc/instance/logged/thread.sh). That flat log is a different job from application error grouping or host metrics. |

## Intent

A laptop or one small server can collect exceptions, host metrics, endpoint checks, and a modest amount of logs and traces. The usual hosted products for that work are Sentry and a Prometheus-plus-Grafana stack. Both can be self-hosted. Self-hosted Sentry is a platform. Prometheus itself is already a single binary, and the weight people complain about is usually retention, cardinality, extra components, or the decision to run Sentry's full compose file on a machine that only needed grouped stack traces.

This note records tools that stay small enough to run beside an application on one machine, what protocol they actually speak, and where a lighter reputation is only an easier install of a heavy store. It is a survey. It is not a contract, a provisioning manifest, or permission to add a dependency.

Versions, licenses, and resource figures move. Treat every number below as a snapshot with a source, then re-read the upstream page before acting on it.

## What "lightweight" means here

A tool fits this note when a single developer can run it on localhost, or on one server, without a cluster. Useful shapes are:

- one binary and a data directory
- one application process plus a database the operator already accepts
- one container whose extra services are optional
- a host agent with its own page on localhost

"One command to start" is a separate property from "small when idle". An all-in-one image can hide ClickHouse and PostgreSQL behind a single container name and still want gigabytes of RAM. A single Go binary can also be the wrong tool if it only answers a question the operator does not have.

Four protocol families show up repeatedly. Tools in different families do not replace each other by changing a URL.

| Family | What the application already speaks | What a compatible sink must accept |
|---|---|---|
| Sentry | A DSN and the Sentry envelope, through the official SDK | The subset of that protocol the sink implements. A DSN change preserves the SDK. It does not preserve session replay, profiling, or every transaction feature. |
| Prometheus | Scrapes, remote write, and PromQL | A scrape config and a query API. MetricsQL and PromQL differ on some functions, especially `increase()` and `rate()`. |
| OpenTelemetry | OTLP over HTTP or gRPC | An OTLP receiver. This is the path for Traceway, OpenObserve, GreptimeDB, SigNoz, and the VictoriaMetrics family when OTLP ingest is enabled. It is not a Sentry DSN. |
| Active checks | Nothing in the application, or a cron ping | The monitor calls HTTP, TCP, ICMP, DNS, or waits for a heartbeat. Failure is "the check missed", which is a different event from an exception. |

## The two baselines

### Self-hosted Sentry

Sentry's self-hosted install docs, read for this note, require at least 4 CPU cores, 16 GB of RAM plus 16 GB of swap, and 20 GB of free disk, and recommend 32 GB of RAM. Docker and Compose are required. The compose file runs PostgreSQL, Kafka, ClickHouse, a Valkey or Redis-class cache, Snuba, Relay, Symbolicator, and a long list of workers. A third-party inventory of release 26.10.1 (1 November 2026) counted 53 compose services in the feature-complete profile and 28 remaining with `COMPOSE_PROFILES=errors-only`. The official hardware minimum is stated for the install as a whole. The same docs say official ClickHouse images from 26.6 onward, on x86-64, need the x86-64-v3 feature set, including AVX2. A CPU without AVX2 cannot run that image.

Current Sentry is under the Functional Source License (FSL-1.1-Apache-2.0): use is allowed except a competing use, and a given version becomes Apache-2.0 two years after release. Sentry describes this as Fair Source. It is not an OSI-approved license. That is independent of the operational cost. Even a team that accepts the license still operates Kafka and ClickHouse to store exceptions.

### Prometheus, before replacing it

The Prometheus server is one binary with no external dependencies, under Apache-2.0. It scrapes exporters, stores samples in a local time-series database, and answers PromQL. Default retention in upstream Prometheus is on the order of 15 days. Alertmanager, node_exporter, and Grafana are extra processes. Grafana's current license is AGPL-3.0.

For one machine and a short retention window, Prometheus is already in the "single binary" class. A replacement earns its place when the operator wants longer retention in less RAM and disk, more ingest protocols, or a built-in UI that removes Grafana. It does not earn its place merely because a comparison table says "Prometheus alternative".

Vendor compression claims age badly. VictoriaMetrics' own older benchmark is often quoted as "up to 7x less RAM". An independent lab note from 9 November 2026, on two identical `t3.small` hosts, Prometheus 3.15.1 and VictoriaMetrics 1.155.0, about 27,500 active series, 15-second scrapes, and 7-day retention, measured roughly 2.6x less RSS for VictoriaMetrics after 24 hours (133 MiB against 341 MiB) and about 1.26x less disk (455 MiB against 572 MiB), with VictoriaMetrics using more CPU at a still-small absolute level (about 0.021 cores against 0.011). The same note shows `increase()` diverging sharply on a bursty counter. Plan from a local trial. Keep recording rules and alerts in PromQL if the option to move back matters.

## Error tracking

### Bugsink

[Bugsink](https://www.bugsink.com/self-hosted/) is a Django application aimed at self-hosted error tracking and the Sentry SDK. SQLite is the default database outside containers. MySQL and PostgreSQL are supported. The project describes one process, with background work in-process (Snappea), and no message queue. Python 3.11 or newer is required. PyPI showed 2.6.3 at the time of this survey. A vendor benchmark on a 2 vCPU, 4 GB VPS claims about 1.5 million events per day. That figure is the vendor's.

The Docker story is narrower than "one container with SQLite". The Docker install guide treats a SQLite container as a throwaway. It recommends an external MySQL or PostgreSQL database when data must survive, and it warns that SQLite in WAL mode plus a Docker volume is an unsafe combination. On a bare VM or a laptop venv, SQLite is the path the project calls production-ready. PostgreSQL-in-Docker is described as plausible and less tested than MySQL.

License: [PolyForm Shield 1.0.0](https://github.com/bugsink/bugsink/blob/main/LICENSE) since 15 January 2025, with carved-out bits (a `sentry` tree under BSD-3-Clause, some icons under MIT, one file under the PSF license). PolyForm Shield allows running and modifying Bugsink for your own use. It withholds permission to offer a competing product. It is source-available. It is not an OSI open-source license. Hosted Bugsink exists as a paid convenience product. The founder states that self-hosting stays free for non-competing use, and that Bugsink deliberately stays an error tracker rather than a full tracing, replay, and profiling product.

A third-party drill on 19 October 2026 (Bugsink 2.6.1, `sentry-sdk` 2.72.0) is worth reading before choosing it for grouping behavior. The same 20 Python events became 11 issues in Bugsink and 17 in GlitchTip, because Bugsink normalizes numbers, UUIDs, and dates in the message before grouping, while GlitchTip hashed the title as sent. Bugsink also applied a source map uploaded after the event; GlitchTip resolved maps at ingest, so a late upload missed the original event. The same review lists multiple GitHub advisories, including unauthenticated denial-of-service against the ingest path when the caller has a DSN. A DSN is a bearer token, and browser SDKs embed it. Any of these sinks need a private UI, a current version, and a limit on who can post envelopes.

### GlitchTip

[GlitchTip](https://glitchtip.com/) is the long-standing MIT-licensed Sentry-compatible tracker. The backend is Django. PostgreSQL 15 or newer is required as of the 7.0 release (9 November 2026). Valkey is optional: an empty `VALKEY_URL` keeps the task queue, cache, and sessions in PostgreSQL. Release 7.0 collapses the old web-versus-worker split into one process. `SERVER_ROLE` and the previous embed-worker settings are ignored. Install guidance around the 6.x and 7.x line recommends about 512 MB of RAM, with an all-in-one setup discussed at 256 MB and, in an operator write-up of the install sample (23 November 2026), a carefully tuned floor near 128 MB plus swap. A planning figure from the project is on the order of 30 GB of disk for a million events a month. Those are documentation figures, not a measurement made here.

The SDK story is the same DSN change as Bugsink. GlitchTip implements a subset of the Sentry protocol: errors, breadcrumbs, tags, user context, and basic transactions. Session replay, profiling, and richer trace features are outside that subset. The project also has its own uptime checks, optional OTLP/HTTP logs, and optional cold storage of older data as Parquet. `auto_session_tracking` should stay off. Traces should be sampled. Logs consume disk and are opt-in.

Choose GlitchTip when an OSI license is a hard requirement, when PostgreSQL is already acceptable, or when uptime checks in the same product matter. Choose Bugsink when the license is acceptable and the goal is one application with SQLite on a real filesystem. Neither one is self-hosted Sentry.

### Traceway

[Traceway](https://github.com/tracewayapp/traceway) is an MIT-licensed observability server, first published in December 2025, with on the order of 1,800 GitHub stars by this survey. It is OpenTelemetry-native: logs, traces, metrics, grouped exceptions, experimental profiles, real-user monitoring, session replay, and on-call paging. The project states that the MIT tree has no Business Source or open-core split, and that a commercial cloud is optional. This note did not audit the tree for a paid-only module.

The easy install is one container that runs ClickHouse, PostgreSQL, and the Go server under supervisord. The "minimal" image is about 20–30 MB and contains only the Go binary plus a built-in UI, and it still requires external ClickHouse and PostgreSQL. That is a simpler operations story than Sentry's compose file. It is not a small SQLite process. ClickHouse has a real memory floor, and session replay stores blobs. Reddit comments that describe it as lightweight are describing install shape and the absence of a license gate, not an idle footprint comparable to Bugsink.

Traceway does not speak the Sentry DSN. An application moves to it by exporting OTLP. That is a good fit when the code is already instrumented with OpenTelemetry. It is a poor fit when the only goal is to keep an existing Sentry SDK pointed at localhost.

### Younger Sentry-protocol projects

A cluster of projects from 2026 aims at "one binary, SQLite, Sentry SDK". They are real, and they are young. Star counts below are GitHub figures seen on 27 November 2026. They measure attention, not fitness.

| Project | First seen | Attention | License | Shape the project claims | Why it is in this note |
|---|---|---|---|---|---|
| [Rustrak](https://github.com/rustrak/rustrak) | January 2026 | about 1,365 stars | AGPL-3.0, with a small MIT client package | One process, SQLite by default, PostgreSQL optional. Sentry envelopes for errors, transactions, release health, logs, and AI-agent traces. Vendor burst figure: 20,000 events accepted at about 5,000 per second on 4 cores, peak under 60 MB. | The most visible new all-in-one Sentry-protocol box. AGPL matters if a modified server is offered to others. |
| [urgentry](https://github.com/urgentry/urgentry), Tiny mode | April 2026 | about 99 stars | FSL-1.1-Apache-2.0 (GitHub labels the repo "Other") | One Go binary and SQLite. Vendor reference on an 8 vCPU, 30 GB host: about 400 events/s at roughly 52 MB peak. The same repo's split mode adds PostgreSQL, MinIO, Valkey, and NATS and leaves the lightweight category. | A deliberate "try the DSN on one machine" path. The license matches Sentry's fair-source pattern, not Apache-2.0 today. |
| [soika](https://github.com/lebe-dev/soika) | May 2026 | 3 stars | MIT | One Rust binary, embedded UI, SQLite or PostgreSQL 15+. A published Docker sample sits near 17 MiB idle. | The clearest permissive license among the tiny new trackers. The project is too new to treat as a default. |
| [Bugs](https://github.com/edde746/bugs) | April 2026 | 4 stars | GPL-3.0 | One Rust binary, SQLite, source maps, releases, alerts. The author publishes an idle-RAM table (Bugs about 3 MB, Rustrak about 68–100 MB, Bugsink about 285 MB, GlitchTip about 145–190 MB). | Useful as a reminder that image size and idle RAM vary widely. The table is the author's own measurement. Rustrak's README describes one process, while that table lists three containers, so the table and the upstream README disagree. |

A secondary comparison page has also called Bugsink MIT. The Bugsink `LICENSE` file says PolyForm Shield. Prefer the license file over a competitor's matrix.

Errbit (Airbrake-compatible Ruby) and Exceptionless (.NET, with a larger data stack) still exist. They solve an older or narrower SDK problem. They are poor defaults when the code already uses Sentry SDKs.

## Host metrics and time series

### VictoriaMetrics, VictoriaLogs, and VictoriaTraces

Single-node [VictoriaMetrics](https://docs.victoriametrics.com/victoriametrics/single-server-victoriametrics/) is one Apache-2.0 binary. Data lives in one directory. It accepts Prometheus scrapes, remote write, and several other ingest protocols, and it serves a Prometheus-compatible query API on port 8428, plus its own vmui. The query language is MetricsQL, which upstream calls backward-compatible with PromQL and which has intentional differences. `increase()` is the one most likely to move an alert threshold. MetricsQL-only syntax such as `WITH` will not parse on Prometheus. Downsampling and some long-term features sit in the enterprise build. The single-node server has no multi-tenancy. Cluster mode splits insert, storage, and select, and is still Apache-2.0, and it is outside the local-first shape until one machine is actually full.

[VictoriaLogs](https://docs.victoriametrics.com/victorialogs/quickstart/) is a separate Apache-2.0 binary with no extra services. A local trial is "download, run, open the built-in UI". The current quick start listens on port 9428. The query language is LogsQL. Grafana Loki dashboards written in LogQL do not paste across. [VictoriaTraces](https://docs.victoriametrics.com/victoriastack/deployment/) is the same idea for spans: one Apache-2.0 binary, with a cluster variant if a single machine is no longer enough. Read the current VictoriaTraces query API before assuming a Jaeger or Tempo dialect.

`vmagent` and `vmalert` are optional extra binaries. A single VictoriaMetrics process can scrape from a Prometheus-style config. Alertmanager remains the usual alert sink if rules move out of Prometheus.

Taken together, the three binaries are a local stack with a shared operational style and three data directories. They are not one process. For a laptop that only needs host graphs, one of them is enough, and it may be VictoriaMetrics or it may be Prometheus itself.

### Netdata

The [Netdata agent](https://github.com/netdata/netdata) is GPL-3.0-or-later, written in C. It collects per-second metrics through a large set of integrations, stores them on local disk, runs optional machine learning, alerts, and serves a page on port 19999. Upstream's own FAQ puts a default near 5% of one CPU and 150 MiB of RAM, and under 1% CPU and about 100 MiB when machine learning and alerts are off and storage is ephemeral. Those are vendor figures. The agent can export Prometheus text at `/api/v1/allmetrics?format=prometheus` and can remote-write. It is a collector and a database of its own metrics. It is not a PromQL engine for arbitrary series, and it does not replace Grafana's dashboard model.

The dashboard package is free to use, including offline, and it is under the Netdata Cloud UI License, which is not the GPL. Distribution packages that ship only open-source software can omit it. In that case the agent still collects and alerts, and `http://localhost:19999` has no UI. A single agent shows its own node without a Netdata Cloud login. Multi-node dashboards on the free tier are capped (the October 2026 product note says five nodes of your choice on a parent or on the community cloud plan). Paid plans add topology, logs, tracing, and an on-prem cloud. For one machine, the agent plus the free local dashboard is the relevant slice. Binding port 19999 on a public interface publishes a detailed picture of the host.

### Beszel

[Beszel](https://github.com/henrygd/beszel) is MIT-licensed. A hub, built on PocketBase, and a small Go agent are separate binaries or containers. The hub's install guide uses port 8090. The agent listens on 45876 by default and ships CPU, memory, disk, network, and per-container stats, plus S.M.A.R.T. readings. Alerts, multi-user accounts, and OAuth/OIDC are part of the hub. PocketBase stores the hub's data locally, so there is no separate Prometheus or Influx process to operate.

Beszel answers "how are these few machines and their containers doing, and did a disk start to fail?" It does not answer PromQL, application traces, or Sentry events. It is a strong fit for a single server plus a laptop, and a weak fit as a drop-in for existing Grafana dashboards.

### Glances

[Glances](https://github.com/nicolargo/glances) is an LGPL-3.0 Python monitor in the `top` family: CPU, memory, disk, network, processes, sensors, and containers, in a terminal, a web UI, or a small API. It can export to other databases. It does not keep a serious history by itself. Current releases also expose an MCP endpoint for local inspection. It belongs on a shell account where the question is "what is hot right now". It is not a retention store.

### Prometheus-compatible collectors that are not databases

Grafana Alloy (AGPL-3.0) is one binary that scrapes, receives OTLP, and remote-writes. It replaces older Grafana Agent and Promtail roles. Telegraf (MIT) is one binary that collects and emits Influx line protocol, Prometheus remote write, and other outputs. The OpenTelemetry Collector (Apache-2.0) is the generic OTLP router. None of the three is a UI or a database. Use one when the application and the store disagree about protocol. Skip them when the store already accepts the protocol the application emits.

### InfluxDB 3 Core

[InfluxDB 3 Core](https://github.com/influxdata/influxdb) is a single-node engine under MIT or Apache-2.0, at the user's choice, on Arrow, DataFusion, and Parquet. Upstream describes it as a recent-data engine with SQL and InfluxQL. It is not a PromQL server. Clustering sits outside Core. Telegraf is the usual companion. This is a reasonable local store when collectors already speak line protocol. It is an awkward replacement for a folder of PromQL dashboards. InfluxDB's license has changed in earlier generations, so read the `LICENSE` of the exact release before depending on the dual-license sentence.

### Perses

[Perses](https://github.com/perses/perses) is an Apache-2.0 dashboard project in the Prometheus ecosystem, aimed at a smaller UI than Grafana. It does not store samples. Mentioning it here only because a local VictoriaMetrics or Prometheus can have a UI other than Grafana or vmui. For one person, vmui or the Netdata page is usually enough.

## Endpoint checks, cron, disks, and live container logs

These tools watch from the outside. They do not group exceptions.

### Uptime Kuma

[Uptime Kuma](https://github.com/louislam/uptime-kuma) is MIT-licensed, built with Node.js, and usually one container. SQLite is the default store. MariaDB is optional from the 2.x line. There is no official hosted product. The data directory wants a filesystem with POSIX locks. Configuration is a web UI: HTTP, TCP, ping, DNS, push monitors, Docker, and several other probe types, plus a status page. It is lightweight relative to a monitoring suite. It is not a single static binary, because the runtime is Node.

### Gatus

[Gatus](https://github.com/TwiN/gatus) is Apache-2.0, one Go binary, configured in YAML. Checks are HTTP, ICMP, TCP, DNS, and related probes, with conditions on status, body, latency, and certificates. Alerting covers the usual chat and paging webhooks. Storage defaults to memory, so history vanishes on restart, and SQLite or PostgreSQL are optional. A managed service exists at gatus.io. The managed service is a separate offering. The self-hosted binary is the full Apache-2.0 program, not a cut-down core.

A claim that neither Uptime Kuma nor Gatus has a commercial cloud version is accurate for Uptime Kuma and outdated for Gatus. The existence of gatus.io does not remove features from the binary.

Gatus fits a repository that wants health checks in git. Uptime Kuma fits an operator who wants to click monitors into existence. Both only see the network from the host they run on. A check that shares fate with the service it watches stays green through the outage.

### Healthchecks

[Healthchecks](https://github.com/healthchecks/healthchecks) is BSD-3-Clause. Jobs ping an HTTP URL or send mail on a schedule. A missed ping is the alert. The stack is Django and PostgreSQL, MySQL, or MariaDB. A hosted service exists at healthchecks.io. This is the right shape for cron, backups, and queues that fail by going silent. It is the wrong shape for HTTP uptime, and it is heavier than Gatus because it wants a SQL server. SQLite is not the documented database.

### Checkmate

[Checkmate](https://github.com/bluewave-labs/Checkmate) is AGPL-3.0. One application image plus MongoDB covers HTTP, ping, ports, DNS, heartbeats, Docker, and an optional Go agent (Capture) for CPU, memory, and disk. The project publishes a compose file that listens on port 52345 and reports a small memory footprint on a few hundred monitors. MongoDB is still a second stateful service. Prefer it when one UI must mix status pages, heartbeats, and a bit of host telemetry, and the extra database is acceptable. Prefer Beszel plus Gatus when those jobs can stay separate and smaller.

### Kener, Scrutiny, and Dozzle

[Kener](https://github.com/rajnandan1/kener) is an MIT status page. It overlaps the public page of Uptime Kuma more than it overlaps host metrics. Confirm its current data store before treating it as a one-process monitor.

[Scrutiny](https://github.com/AnalogJ/scrutiny) is an MIT hub for S.M.A.R.T. attributes, with a small collector beside `smartctl`. Disk failure is a local-server failure mode that CPU graphs announce late. Beszel already pulls S.M.A.R.T. into its hub. Scrutiny is the narrower tool when disks are the only question.

[Dozzle](https://github.com/amir20/dozzle) is an MIT live viewer for Docker logs. It does not build a searchable archive. It is the right localhost page when the question is "what is this container printing right now", and the wrong page when the question is last week's error.

## Logs, traces, and one-process platforms

### OpenObserve

[OpenObserve](https://github.com/openobserve/openobserve) is a Rust binary, AGPL-3.0 for the open-source edition. A separate enterprise license covers a different build. Local mode is the default: SQLite for metadata, Parquet on local disk, or Parquet on S3-compatible storage while the process stays single-node. High availability, in the project's docs, wants Kubernetes, object storage, PostgreSQL, and NATS, and does not support local disk. Logs and traces are queried with SQL. Metrics accept SQL or PromQL. Ingest is OpenTelemetry-oriented. The project's comparison table puts logs, metrics, traces, real-user monitoring, dashboards, and alerts in the open-source edition, and keeps federated search, workload management, fuller quotas, and a long audit trail in enterprise.

Upstream's architecture page says a single machine can still ingest on the order of a couple of terabytes a day, and quotes about 31 MB/s on an Apple M2 with default settings. That is their test. The interesting local-first fact is the idle shape: one process, one metadata database, one data directory, no Kafka. AGPL matters if you modify OpenObserve and expose that modification as a network service. Running the unmodified binary for yourself is the ordinary case the license is written to allow, and a lawyer should read AGPL before embedding it in a product.

OpenObserve is the closest match to "one local binary instead of Prometheus plus a log store plus a trace store", with a real UI. It does not speak the Sentry DSN. Feature gates exist. They sit on cluster and enterprise operations more than on the basic three signals.

### GreptimeDB

[GreptimeDB](https://docs.greptime.com/getting-started/installation/greptimedb-standalone/) standalone mode is one Apache-2.0 binary (`greptime standalone start`). Metrics, logs, and traces share a table model. Ingest includes OTLP, Prometheus remote write, Loki push, Elasticsearch bulk, and Influx line protocol. Queries are SQL, PromQL for metrics, and a Jaeger query API for traces. LogQL is not supported. The project states that cluster mode, object storage, and continuous aggregation are in the Apache-2.0 build, with enterprise features limited to things like read replicas, workload isolation, LDAP, and a management console.

The capacity guide, which is the vendor's, asks for at least 8 GB of memory for basic workloads and 32 GB for heavier ones, and gives an example of 8 cores and 32 GB at a few hundred thousand points per second. Standalone mode removes extra processes. It does not make the engine small. Prefer it over OpenObserve when an Apache-2.0 license and one engine matter more than a tiny idle footprint. Prefer OpenObserve when the machine is a laptop and a built-in observability UI is the point.

### Quickwit and Parseable

[Quickwit](https://quickwit.io/docs/deployment/deployment-modes) is Apache-2.0, Rust, one binary that can run indexer, searcher, metastore, and control plane together. Standalone mode may use a file-backed metastore. The search API is Elasticsearch-compatible. Ingest and query cover logs and traces, including OTLP and Jaeger. The README still treats metrics as future work. Official support is Linux, and the binary wants `libssl`. It is a search engine you can run locally, aimed at object storage at larger sizes. It is not yet a Prometheus replacement.

[Parseable](https://www.parseable.com/docs/editions/compare) is an AGPL log store with SQL, dashboards, and alerts in the open-source edition, limited to one query node. The project's own edition table puts PromQL, high availability, automatic error tracking, and APM on the paid cloud and enterprise columns. Treat Parseable as a log product with a commercial tier, not as a local Prometheus substitute.

### Grafana Loki in monolithic mode

[Loki](https://grafana.com/docs/loki/latest/get-started/deployment-modes/) is AGPL-3.0. The same binary can run every microservice target with `-target=all`. Grafana's docs call that appropriate up to roughly 20 GB of logs a day. It still wants a filesystem or object store and, in the usual setup, Alloy or another shipper, plus Grafana for the UI. LogQL is the query language. Monolithic Loki is a legitimate single-server log store when the rest of the stack is already Grafana. VictoriaLogs is the smaller operational cousin when LogQL compatibility does not matter.

Tempo has a similar monolithic mode for traces and the same license family. Jaeger's all-in-one binary (Apache-2.0) remains a common way to look at spans on localhost, with memory or Badger storage. Upstream treats all-in-one as a development shape. Zipkin is the older single-process tracer. For a new local setup, an OTLP-native store above is the more direct path. Jaeger all-in-one still wins when the only need is a waterfall for one app this afternoon.

### Parca

[Parca](https://github.com/parca-dev/parca) is Apache-2.0 continuous profiling: a server and an eBPF agent, flame graphs over time. It is one of the few ways to get profiles on a single machine without Sentry's profiling product. eBPF wants privileges, and the agent is extra weight. It is optional. Error trackers in the first section do not include it.

## Attractive tools that miss the lightweight bar

These are viable single-server products. They are a different size class from Bugsink, Gatus, or VictoriaMetrics.

| Tool | License snapshot | Why it misses this note's bar |
|---|---|---|
| [SigNoz](https://signoz.io/docs/install/docker/) community | MIT for the main tree. `ee/` and `cmd/enterprise/` carry another license. | Docker install asks for at least 4 GB. The host runs ClickHouse, PostgreSQL, and an OpenTelemetry Collector beside the UI. OTLP-native, not a Sentry DSN. A reasonable one-machine APM once 4 GB and ClickHouse are acceptable. |
| ClickStack, formerly HyperDX | MIT for the open stack, from the project's public materials | The all-in-one image packages ClickHouse, a UI, and a collector (and, in current descriptions, MongoDB). One command to start. Several stateful services once it is up. Confirm the image's process list on the release you pull. |
| Coroot community | Apache-2.0 for the open edition | eBPF application metrics with ClickHouse and Prometheus as dependencies. Strong for "why is this service slow" on a server you control. Not a small sidecar. |
| Highlight, PostHog self-hosted, Elastic, OpenSearch, Graylog, Zabbix, Checkmk, LibreNMS | Various, several with ClickHouse, Kafka, or Java heaps | Each can be the right product at a larger size. None is a localhost alternative in the sense of this note. |
| urgentry split mode, OpenObserve HA, VictoriaMetrics cluster, GreptimeDB cluster | As above | The scale-out shapes of tools whose single-node shapes do fit. |

## Corrected comparison

The starting survey's table is a good map of roles. Several cells need a stricter reading.

| Tool | Role it actually fills | What you run | License snapshot | Compatibility, with the limit |
|---|---|---|---|---|
| Bugsink | Grouped exceptions | One Python app. SQLite on a normal filesystem, or MySQL or PostgreSQL. Avoid SQLite-on-Docker-volume. | PolyForm Shield 1.0.0 | Sentry SDKs for errors. Full APM is out of scope. Source-available. |
| GlitchTip | Grouped exceptions, basic performance, optional logs and uptime | Django plus PostgreSQL 15+. Valkey optional. One process as of 7.0. About 512 MB recommended. | MIT | Sentry SDKs for the error subset. Replay and profiling are absent. |
| Traceway | OTel logs, traces, metrics, exceptions, replay | One container that includes ClickHouse and PostgreSQL, or a small Go image plus those databases outside. | MIT, per the repository | OTLP. A Sentry DSN does not point here. "Lightweight" describes the license and the wrapper, not ClickHouse. |
| Rustrak | Younger Sentry-protocol box, including some logs and traces | One process, SQLite by default. | AGPL-3.0 | Sentry envelopes, as far as the current server implements them. Young project. |
| urgentry Tiny | Younger Sentry-protocol box for a trial | One Go binary, SQLite. | FSL-1.1-Apache-2.0 | Sentry SDKs on common paths, by the project's claim. Split mode is a different, heavier product. |
| VictoriaMetrics | Prometheus-compatible metrics | One Go binary, one data directory. Port 8428. | Apache-2.0. Enterprise exists for extra features. | PromQL, with MetricsQL differences on counters. |
| VictoriaLogs | Logs | One binary. Port 9428. | Apache-2.0 | LogsQL. LogQL dashboards do not carry over. |
| VictoriaTraces | Traces | One binary. | Apache-2.0 | Confirm the query API in the current docs. |
| Prometheus | Metrics, and often the thing being replaced | One binary, local TSDB, short default retention. | Apache-2.0 | PromQL and Prometheus scrapers. Already local-first. |
| Netdata | Per-second host and app collectors, local UI | One C agent. Port 19999. On the order of 100–150 MiB. | Agent GPL-3.0-or-later. Dashboard package is free and not GPL. | Built-in collectors and a Prometheus text endpoint. Multi-node UI has a free-tier cap. |
| Beszel | A few hosts and their containers, with history | Hub binary plus an agent binary. | MIT | Its own metrics. Docker stats and S.M.A.R.T. PromQL is absent. |
| Glances | A live `top` in the terminal or browser | Python process. | LGPL-3.0 | Export plugins. History is someone else's job. |
| Uptime Kuma | Endpoint and push checks, status page | One Node container, SQLite. | MIT. No official cloud. | Active probes. No Sentry, no PromQL. |
| Gatus | The same job, as YAML | One Go binary. Memory, SQLite, or PostgreSQL. | Apache-2.0. A commercial cloud exists at gatus.io. | Active probes and conditions. OSS binary is the full check engine. |
| Healthchecks | Silent cron jobs | Django plus PostgreSQL, MySQL, or MariaDB. | BSD-3-Clause. Hosted service exists. | Heartbeats. |
| OpenObserve | Logs, metrics, traces, UI | One Rust binary, SQLite metadata, local or object storage. | AGPL-3.0 open edition. Enterprise build is separate. | PromQL, SQL, OTLP. Sentry DSN is absent. Some cluster features are enterprise-only. |
| GreptimeDB standalone | One engine for metrics, logs, and traces | One Rust binary. Vendor guidance starts near 8 GB for basic production. | Apache-2.0 for the engine, including cluster and object storage. | PromQL, SQL, OTLP, Jaeger query. LogQL is absent. |
| InfluxDB 3 Core | Recent time series | One binary, single-node. | MIT or Apache-2.0. | SQL and InfluxQL. PromQL is absent. |
| Quickwit standalone | Log and trace search | One binary plus `libssl`. | Apache-2.0 | Elasticsearch-compatible API, OTLP, Jaeger. Metrics still on the roadmap in the README read for this note. |
| Loki monolithic | Logs, if Grafana is already the UI | One binary, filesystem or object store, plus a shipper in the usual setup. | AGPL-3.0 | LogQL. Upstream suggests monolithic mode up to about 20 GB/day. |
| SigNoz | One-server OTel APM | ClickHouse, PostgreSQL, collector, UI. 4 GB minimum for the Docker test install. | MIT community tree, enterprise directories separate. | OTLP. Heavier than the rows above. |

## A local-first set, as a discussion proposal

This is one coherent bundle for a later decision. It is not a selection.

1. Keep self-hosted Sentry out of the local and single-server case. The official minimum is a 16 GB class host and a Kafka-and-ClickHouse compose file, including when the useful feature is grouped exceptions. AVX2 is an extra constraint on older x86-64 CPUs.
2. If the application already has a Sentry SDK, point that DSN at GlitchTip when the license must be MIT and PostgreSQL is acceptable, or at Bugsink when one Python app and SQLite on a normal disk are the priority and PolyForm Shield is acceptable. Sample traces. Keep the UI on localhost or a private network. Treat the DSN as a public write token. Re-test grouping with a handful of real exceptions before trusting issue counts. Rustrak is the project to revisit if a single AGPL process that also takes Sentry-shaped logs and transactions becomes mature enough. soika and Bugs are too new to be the default.
3. If the application emits OTLP and the goal is one UI for logs, metrics, and traces, try OpenObserve in local mode and accept AGPL plus an enterprise split. Try GreptimeDB standalone when Apache-2.0 matters and the machine has memory to spare. Try Traceway's all-in-one container when MIT and a broad OTel product matter more than a small idle footprint, and budget for ClickHouse.
4. For host metrics, start from the question. "Is this machine hot, per second, with a page on localhost?" is Netdata or Glances. "A few hosts, containers, and disks, with history and alerts" is Beszel. "PromQL and exporters I already have" is Prometheus until retention or RAM says otherwise, then single-node VictoriaMetrics, with alerts rechecked against MetricsQL. Running Netdata and Prometheus and VictoriaMetrics together on one laptop collects the same CPU three times.
5. For "is the URL up?" use Gatus when the checks belong in git, or Uptime Kuma when they belong in a UI. For "did the backup script run?" use Healthchecks, or a push monitor in Uptime Kuma if a second database is too much.
6. For container tails, use Dozzle. For a week of searchable logs, use VictoriaLogs or monolithic Loki or the log side of OpenObserve. Dozzle will not become that archive.
7. Add Parca only when profiles are an actual question. Add Alloy, Telegraf, or the OpenTelemetry Collector only when a protocol does not already line up.

Privacy follows the same split as the protocols. Self-hosting keeps the bytes on a disk you control. It does not remove names, tokens, or SQL from a stack trace. SDK settings such as `send_default_pii`, `include_local_variables`, and `before_send` are part of the design. GlitchTip has added opt-in server-side scrubbing. Bugsink's author argues that scrubbing is a weak control compared with not sending the data to a third party. Both can be true: locality is the control that self-hosting buys, and a `before_send` hook is still warranted.

## What this does not decide

- No extension, installer, container, or host package is added by this document.
- ASC's logged wrappers stay the mechanism for local command transcripts. None of these products replaces that file.
- A later plan can pick at most one error sink and one metrics path, name the license constraint, and only then talk about install. Until that plan exists, the survey is reference material.
- Resource numbers from vendors, from one independent VM-versus-Prometheus lab, and from one third-party Sentry-versus-GlitchTip-versus-Bugsink drill are leads. They are not a sizing sheet for a particular machine.
- License paragraphs here are a reading of public `LICENSE` files and project announcements. They are not legal advice.

## Sources

Primary pages used for the snapshot:

- Sentry self-hosted requirements: <https://develop.sentry.dev/self-hosted/>
- Bugsink self-hosting, settings, Docker install, and `LICENSE`: <https://www.bugsink.com/self-hosted/>, <https://www.bugsink.com/docs/settings/>, <https://www.bugsink.com/docs/docker-install/>, <https://github.com/bugsink/bugsink/blob/main/LICENSE>, <https://www.bugsink.com/blog/new-license-new-pricing/>, <https://www.bugsink.com/blog/glitchtip-vs-sentry-vs-bugsink/>
- GlitchTip 7.0 and SDK notes: <https://glitchtip.com/blog/2026-11-09-glitchtip-7-0-release/>, <https://glitchtip.com/sdkdocs/python-django/>
- Traceway repository and self-host docs: <https://github.com/tracewayapp/traceway>, <https://docs.tracewayapp.com/server>, <https://docs.tracewayapp.com/server/all-in-one>, <https://docs.tracewayapp.com/server/minimal>
- Rustrak, urgentry, soika, Bugs: <https://github.com/rustrak/rustrak>, <https://github.com/urgentry/urgentry>, <https://github.com/lebe-dev/soika>, <https://github.com/edde746/bugs>
- VictoriaMetrics single-server, VictoriaLogs quick start, VictoriaStack deployment: <https://docs.victoriametrics.com/victoriametrics/single-server-victoriametrics/>, <https://docs.victoriametrics.com/victorialogs/quickstart/>, <https://docs.victoriametrics.com/victoriastack/deployment/>
- Prometheus FAQ: <https://prometheus.io/docs/introduction/faq/>
- Netdata agent and the October 2026 dashboard-license note: <https://github.com/netdata/netdata>, <https://www.netdata.cloud/blog/important-changes-to-the-netdata-agent-dashboard/>, <https://learn.netdata.cloud/docs/exporting-metrics/prometheus>
- Beszel and Gatus: <https://github.com/henrygd/beszel>, <https://beszel.dev/guide/hub-installation>, <https://github.com/TwiN/gatus>
- Uptime Kuma and Healthchecks: <https://github.com/louislam/uptime-kuma>, <https://github.com/healthchecks/healthchecks>
- OpenObserve architecture and edition comparison: <https://github.com/openobserve/openobserve>, <https://openobserve.ai/docs/architecture/>, <https://openobserve.ai/downloads/>
- GreptimeDB standalone and capacity plan: <https://docs.greptime.com/getting-started/installation/greptimedb-standalone/>, <https://docs.greptime.com/user-guide/deployments-administration/capacity-plan/>, <https://greptime.com/product/db>
- Quickwit deployment modes, Parseable editions, Loki deployment modes, SigNoz Docker install, InfluxDB 3 Core, Parca: <https://quickwit.io/docs/deployment/deployment-modes>, <https://www.parseable.com/docs/editions/compare>, <https://grafana.com/docs/loki/latest/get-started/deployment-modes/>, <https://signoz.io/docs/install/docker/>, <https://github.com/influxdata/influxdb>, <https://github.com/parca-dev/parca>
- Checkmate, Glances, Dozzle: <https://github.com/bluewave-labs/Checkmate>, <https://github.com/nicolargo/glances>, <https://github.com/amir20/dozzle>

Third-party write-ups cited by name, each with its own bias:

- Revisit, 19 October 2026, drill of Bugsink 2.6.1 and GlitchTip 6.2.6, plus a reading of Sentry's compose file and advisories: <https://revisit.tech/blog/self-hosted-error-tracking-in-2026-revisit-sentry-glitchtip-and-bugsink-before-you-ship-another-stack-trace-5/>
- Pardha, 9 November 2026, Prometheus 3.15.1 versus VictoriaMetrics 1.155.0 on matched small hosts: <https://pardha.dev/posts/prometheus-vs-victoriametrics-lab/>
- stdout, 30 October 2026, Prometheus versus VictoriaMetrics feature matrix, including the age of the vendor "7x" benchmark: <https://stdout.adegoodyer.com/posts/victoriametrics-vs-prometheus>
- Futurion, 23 November 2026, walkthrough of the GlitchTip 7 compose sample and published RAM figures: <https://futurion.blog/self-hosting-glitchtip-with-docker-compose-one-container-email-and-pointing-a-sentry-sdk-at-it/>
- RealUptime, 1 November 2026, count of Sentry compose services in 26.10.1: <https://realuptime.io/guides/self-hosted-sentry-requirements>
- OpenSourcePicks comparison noting that Uptime Kuma has no official host and that Gatus Technologies runs gatus.io: <https://opensourcepicks.com/compare/uptime-kuma-vs-gatus/>

## Open questions

- Which constraint wins if a tool is chosen later: an OSI license, a single process, or Sentry SDK compatibility? Those three pick different rows.
- Does any application in scope already emit OTLP, or only Sentry envelopes? The answer decides whether Traceway, OpenObserve, and GreptimeDB are even candidates.
- How long must metrics and exceptions be kept on the local disk? Short retention keeps Prometheus and SQLite attractive. Multi-month retention is the case VictoriaMetrics and Parquet stores are arguing for.
- Should endpoint checks live in git (Gatus) or in a UI (Uptime Kuma)?
- For Bugsink specifically, is the process on a VM or inside Docker? That choice decides whether SQLite is the documented happy path.
