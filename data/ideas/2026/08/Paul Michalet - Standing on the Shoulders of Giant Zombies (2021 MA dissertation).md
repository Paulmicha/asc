# Paul Michalet — Standing on the Shoulders of Giant Zombies (2021)

An opinionated compass, not a substitute for the dissertation. Written so a human or an agent can use it to decide *what is worth building* — including, but not only, a semantic environment on top of ASC. Broader than Projet Complexe: it is a stance toward digital work in the Anthropocene.

Source: MSc *Strategy and Design for the Anthropocene* (ESC Clermont / Strate, Origens Medialab), 2020–2021, submitted early 2022. Full title: *Standing on the Shoulders of Giant Zombies — Redéfinir la réalisation de services numériques dans l’Anthropocène*.

**How to read.** The 166-page PDF is the terrain. This file is the operator: what still binds, what figures to replace, what not to betray. Operators (zombie, situated digital, clair-obscur, redirection, rebound, systemic obsolescence) outlive numbers. When a statistic appears, treat it as dated unless a 2026 update is given beside it.

**Contents.** Versions → how to use → title/thesis → terrain → posture → essay (three chapters) → annex field (definitions, footprint methods, regulation, seven pillars, survey, Weever, workshop) → 2026 commitments → aged figures → generative AI as missing giant → relation to current practice (without shrinking to it) → open questions → actionable list.

---

## Which file is the complete version?

Both files the user named are the **same work**, not two drafts of different length.

| File | Date | Form | Pages / size |
| ----- | ----- | ----- | ----- |
| `… Giant Zombies (mémoire), 2022, Paul Michalet - v03.odt` | 21 Jan 2022 | Working text (LibreOffice). Footnotes inlined. ~69k words. | Complete TOC: essay + three annexes + bibliography |
| `… Giant Zombies (mémoire formatté), 2022, Paul Michalet - v06.pdf` | 14 Jan 2022 | InDesign layout, 166 A4 pages. Cover is a *visual* of `ecometrics` source (Svelte stores: `co2Store`, `selectionStore`, `carbonIntensityStore`…). ~62k extracted words (cover code pollutes pdftotext). | Same TOC. This is the designed submission |

The ODT is seven days *later* than the formatted PDF. Structure matches. Treat **v06 PDF as the public complete mémoire** and **v03 ODT as the same text** (minor late tweaks possible; no missing chapter).

Earlier artefacts (Mémoire-v01…v13, Compte-rendu V01–V05, unformatted PDF of 3 Jan 2022 at 237 pages, Dec 2021 InDesign at 122 pages) are drafts. The complete architecture is:

1. **Essay** (~pp. 5–33 of v06) — free discussion, slightly distanced from the field.
2. **Annexe 1** (~pp. 36–149) — full *compte-rendu* of the commission (state of the art, situated survey, design-fiction workshop).
3. **Annexe 2** — questionnaire.
4. **Annexe 3** — comparison of measurement tools.
5. **Bibliography**.

The essay exists because the school capped page count. The field work was too large to fit. That split is itself a design decision: the essay is the *compass*; the annex is the *terrain*.

---

## How to use this note

The dissertation starts from a disillusioned stance toward **écoconception de services numériques**, then looks for something stronger: **redirection écologique**, **numérique situé**, conflict, imaginaries, and the question *what is feasible, desirable, conceivable?*

Five years later (2026), that question is still the right one. Generative AI, hyperscale training, and “AI agents” were not the object of the 2021 field. They **intensify** the zombie diagnosis. They do not cancel it.

This compass is **opinionated**. It says what the mémoire still commits its author to, what has aged as *figure*, and what must not be betrayed by a personal computational environment, a documentary tool, or a swarm of agents.

It is **not** a second-brain ontology. The 2021 work already refuses to treat documentation as a neutral cloud. A “second brain” that forgets materiality, territory, closing-down, and conflict would be a relapse into the spectral world the mémoire quotes from Byung-Chul Han: *we no longer inhabit earth and sky; we inhabit Google Earth and the Cloud.*

---

## The title, which is the thesis

Bernard of Chartres: dwarves on the shoulders of giants — transmission of knowledge. Jeremy Keith (2016): *giants all the way down* (turtles, infinite regress). The mémoire adds **zombie**, after Diego Landivar:

> A technology that is alive because it is injected with investment, publicly and politically supported, supported by projective imaginaries… and on the other side condemned from an ecological point of view, or simply by the availability of raw materials and energy. Alive and dead: zombies.

José Halloy (2017), quoted as the physical verdict: *current computing technologies are not sustainable in the long term. Tensions on energy and matter will occur during this century.*

**Standing on the shoulders of giant zombies** therefore means two inheritances at once:

- intellectual: we work with knowledge, tools, and infrastructures we did not invent;
- material: those tools rest on extractive, energetic, and imaginary supports that are already condemned as *durable* practices, even while they still run.

A project that only celebrates “open knowledge” or “personal infrastructure” without asking which giants are already dead is not in this lineage.

---

## Terrain (what the work actually did)

Commission from the MSc, extended as a final internship, coordinated via Origens Medialab.

**Stakeholders**

- **Atelier Luma** (Arles) — experimental cultural centre (art, environment, education, research), territorial networks.
- **Mnémotix** — SCIC, knowledge engineering. Documentary tool **Weever** (semantic/documentary app: projects, events, memos, thesaurus). Parallel object: possible redesign of atelier-luma.org.

**Actions (Annexe 1)**

1. State of the art of digital environmental footprint, regulation, ecodesign, systemic obsolescence, rebound.
2. Situated survey: questionnaires and interviews (“ma journée numérique”), inventory of machines and third-party services at Luma and Mnémotix, technical dependencies of Weever (Docker, packages, hosting diagram), manufacturing-phase and use-phase estimates, snapshot of automated front-end tests (GreenIT Analysis CLI / EcoIndex, 22 Nov 2021).
3. Interactive static infographic **ecometrics** (Svelte) — temporary URL in the text: `https://msc.paulmichalet.com/ecometrics`. Equipment list (49 devices at writing time), 21 services, geographic carbon intensity (demo: France 38 gCO2e/kWh vs Hong Kong 755).
4. Hybrid **design fiction** workshop: three scenarios (green growth, authoritarian management, triumph of the commons), inspired by Etalab/Design Friction *Nos Algorithmes*, Fing *Numérique tous risques*, *Fresque du renoncement*. Only two scenarios were actually played (time). Organisation as a single “character.”

The mémoire is explicit: it is **not** a history of Weever (that was Soumann, 2019, at Fondation Lafayette). It is not a synthesis of everything the author read before the MSc. It is a **partial retrospective** from resignation toward a practice at the crossroads of digital technology and design, *radically questioned*.

Author’s prior practice: ~12 years as a web developer, specialised in the Drupal commons. The critique includes that practice.

**What this is not** (the mémoire is explicit):

- not a history of Weever (Soumann, 2019, Fondation Lafayette);
- not a synthesis of everything read before the MSc;
- not a consultant’s green checklist;
- not a complete ontology of “the digital”;
- not a claim that the comments apply to Google-scale.

It is a **partial retrospective** from resignation toward a practice at the crossroads of digital technology and design, *radically questioned*. The essay exists because the school capped page count; the annex is the terrain. That split is itself a design decision.

---

## Posture (still binding)

Not technolatry, not technophobia. Halloy: *ni technolâtre, ni technophobe.* Méliorist position (Hennion & Monnin): beyond beatific tech-positivism and simplistic techno-critique.

**Designer prudent** (Huyghe, via Sylvia Fredriksson): *phronesis*, care for what is not written in advance. Prudence ≠ precaution. Precaution closes possibles to increase system efficiency. Existence is hesitation in situations without law.

**Co-inquirer**, not consultant delivering a green checklist. Participatory design as dissensus (Gourlet), not as harmony workshop. Hard questions kept: who constitutes the collective? who is excluded? does prefiguring a future actually change action?

**Between mediator and researcher** (Nouveaux commanditaires / Coopair; 27e Région). Support organisations that already work for habitability and an economy of resource rather than growth — *without* becoming their manager, their activist costume, or their IT department.

**Pragmatist inquiry**: attachments (*ce à quoi l’on tient et ce qui nous tient*, Hennion), attention to attention, the inquirer is not neutral. The whole internship ran **remotely** — a limit the text names.

Compass implication: any environment built now (notes, agents, indexes, GitOps, a dedi) must remain **inquiète**. A dashboard that closes hesitation is managerial precaution, not prudence.

---

## Essay — three chapters

The essay answers *À quoi bon?* — why bother with digital sobriety when kilobytes look ridiculous next to Google, when the sector is “not the biggest emitter,” when it promises avoided emissions elsewhere, when optimisation risks losing the “wow” to a competitor?

Answer, compressed:

- Share of global emissions is not (yet) among the largest, **but no other sector had that growth rate** (2021 claim — see ageing notes). Extractivism and end-of-life are invisible if one only watches GHG.
- Silo thinking cannot meet the situation. Françoise Berthoud (2021): ecodesign reductions *will not be huge* — *il ne faut pas se leurrer*.
- Scale still matters: a few hundred KB on a rural municipal site ≠ a few bytes on a platform with millions of weekly views. Counter-example: unused 7 MB file in VSCode updates, >14 million developers, ~100 TB transferred (2021 incident). Discernment, not a religion of the kilobyte.
- The useful questions are: what is **feasible, conceivable, desirable** — and what strategies answer the temptation of flight among people whose careers looked “traced”?

### Chapter 1 — What digital did to the Anthropocene, what the Anthropocene does to digital

Title borrowed from Monnin & Allard on design (2020).

**Roots of techno-solutionism.** Calculation (Jacquard, Babbage, Lovelace): hardware/software split, conditional loops, generality of application. Post-war: Shannon–Weaver information as measurable magnitude, Bell’s practical problem of cheap reliable transmission, the bit. Abstraction climbing from punched cards to high-level languages. GUI, mouse. The French word *ordinateur* (Perret to IBM France, 1955) already dreamed of order.

Consequence: digital is commonly received as an **horizon of solutions** — dematerialised, general, infinitely abstractable. Han: spectral world, Cloud.

**Myths.** Immateriality. Neutrality of technique (Kranzberg’s first law: technology is neither good nor bad nor neutral). Affordance (Benayoun & Régnauld): a knife is not innocent. Digital is **enchâssé** in an economic logic that currently runs opposite to environmental imperatives (Longaretti & Berthoud).

**Conflict.** 5G antenna sabotage in France as a signal that “digital” is already a **territorial and political** object, not a cloud. The mémoire does not romanticise sabotage; it refuses to treat conflict as noise around a managerial problem.

**Numérique situé** (Nova & Roussilhe, 2020). Two requirements:

1. **Materialise** infrastructures and impacts (Low-tech Magazine’s battery gauge; salvage, reuse, making conditions of operation explicit).
2. **Territorialise** — a solar server in Barcelona is tied to Catalan weather. *El paquete* / sneakernet as a practice that takes territory seriously.

Situated work does not dissolve the unknown (opaque supply chains, cloud footprints). It **bounds** it. Speaking of what is near makes the invisible speakable. Local/global round-trips later, not a jump to “the Cloud” as non-place.

Same chapter links repair, documentary maintenance, and **care** (Lassere). A knowledge practice that only produces new content and never maintains, migrates, or refuses, is not care.

**Conflict is not noise.** After the myth of neutrality: waves of **5G antenna sabotage** in France (Reporterre, d’Allens & Cholez, late 2021). The mémoire does not instruct sabotage. It reads the gesture: when people have no say in deployment, they strike what is **rooted near them**. Territory is the interface. Ambivalence about **open cartographic data** (antenna locations): documentation as resistance (Vigneron et al.) *and* as input to anti-terror measures (Cholez & d’Allens). Situated digital is already a security and political object.

5G as rebound textbook (Longaretti & Berthoud): optimistic energy-per-bit announcements hide that **older radios stay on** for years; extra capacity will not stay unused. Indirect rebound: to *enjoy* 5G you must replace the smartphone.

Compass: name machines, mounts, jurisdictions, mixes, dependencies. A personal stack that pretends to live “in the cloud” repeats the myth the chapter dismantles. A dedicated server in a named city, wrappers that refuse anonymous git, inspectable agents: these are *situated* gestures, not greenwashing by themselves. Mapping the home stack is the Landivar alternative — *map or be mapped*. Publishing that map is not always innocent. Rarefy what is public. Do not treat “more bandwidth / more context / more agents” as free.

### Chapter 2 — Justifications and uses of measurement, beyond the managerial paradigm

Cigref report title (Dec 2021) as exhibit: *Sobriété numérique : Piloter l’empreinte environnementale du numérique par la mesure.* Steering-by-measurement is the hegemonic managerial paradigm.

Monnin (2019): numbers matter, but any given figure can be contested. **Long-term trends and the reasons for them** are harder to techno-fix.

Two angles:

1. **How much measurement is enough?** Paris Agreement as a single-indicator trap (GHG). Compensation and monetisation of “ecosystem services” as permits to kill nature (Solón). Scopes 1–2–3, ecological rucksack, LCA: all useful, all limited. Opacity is structural (Roussilhe). Manufacturer data partial; 70% of WEEE trafficked, no reliable end-of-life factors (Bordage et al. 2019).
2. **Clair-obscur** (Roussilhe, 2021): what is lit (dashboards, labels, voluntary certs) vs what is kept dark. Regulation lagging; non-binding instruments. Transparency without constraint is a genre of theatre.

**Enough measuring is how much?** Mandil / Guillaud: indicators become ends — calorie-counting while eating the same cheeseburgers. Courboulay: LCA as anti-greenwash weapon; the mémoire: sophistication is itself a bias. Perimeter of a React app’s dependencies is arbitrary (who maintains the 700 packages?). Corporate accounting: take into account, count, render account, be accountable — to shareholders (climate → business plan, financial materiality) or to the world (integrated accounting, double materiality: CARE, EP&L). Equipment is an asset; Scope 3 stays inconsistent.

Meadows (1999): tinkering that does not structurally challenge the system is the **least** effective of twelve leverage points — and gets ~99% of attention. Measurement-as-symbolic-capital: “we regret the desertification caused by our datacentres, but look at our Scope 3 transparency.” Overshoot (species, soils, Amazon) may be harder to deny than climate saturation. **None of this is binding.** Strong vs weak sustainability: manufactured capital cannot substitute for critical natural capital — and states still sell green growth (Flipo) against decoupling critiques. Nudges and markets will miss Paris. IPCC reports would have sufficed if data produced action. COVID: shared science, different doctrines. The demand to “have the data first” is the hammer that makes every problem a nail (Mager & Katzenbach: tech firms absorb public capacity to govern futures). Spotlight analogy: some fight to widen the beam; others only to shine *harder* on the same disk. Calculable forms dispossess the public and environmental struggles that opened the data (Fressoz on engineers; SystEx as counter-example, gold mine in Guyane).

Compass: measure to **situate and rarefy**, not to pilot a soul. An index, an EcoIndex score, a carbon widget, a vector store of “impact facts” can all restore Cigref’s title. Trends (more devices, more abstraction, more automatic updates, more dependencies) beat a precise wrong number. Do not wait for a complete LCA of a notes app before deciding what not to build. Do not confuse lighting the same disk harder with widening what counts.

### Chapter 3 — From redirecting imaginaries to ecological redirection

Why imaginaries: because measurement-management is itself an imaginary of control. Design practices that produce **récits** (design fiction, speculative design, debate) try to move values. Limits (Gourlet): prefiguring a future does not reliably produce action. Distant futures drift. Attachments live in the near present.

The mémoire reviews typologies of stories (Chateauraynaud & Debaz; Lenz) and the workshop’s three scenarios (see annex). Then it names **redirection écologique** (Bonnet, Landivar, Monnin, Origens; Fry’s *redirective practice*):

1. Reflexive movement: historical understanding of what structured the practice; uncomfortable proximity of “education to error” and “material desires.”
2. Reorient existing practice toward ongoing confrontation with unsustainability in the immediate environment.
3. Distinguish design actions that bring forth “things” from actions that **close down**, maintain, or redirect what already exists.

Figure 1 in the essay (Bonnet et al. 2021, p. 86) situates ecological redirection among other strategies — not as “more ecodesign.”

Green IT alone has no **force** (the *À quoi bon* returns). It needs alignment across spheres (Jancovici’s “alignment of planets”; Dion: battle of imaginaries *and* political battle). A “diplomat” posture: e.g. arguing a static site rebuild as *both* smaller attack surface *and* lighter footprint — not as a sermon.

Political opening: sobriety is a public question of *assez, c’est combien?* (Villalba & Semal). One laptop per household in a “decent living energy” study is already a political statement. Negative commons (Monnin): inheritances we did not choose and must still govern (nuclear waste, platforms, zombie stacks). We are far from a “parlement des choses” (Roux).

**Diplomat** (essay conclusion): Green IT lacks *force* without alignment of spheres (Jancovici’s “alignment of planets”; Dion: battle of imaginaries *and* political battle — stories do not impose themselves by circulation; they need to break the pillars of power). Example: argue a static site rebuild as *both* smaller attack surface *and* lighter footprint — not as a sermon. Doise’s four levels (intra, inter, positional, ideological) were named as missing development: do not reduce behaviour to brains (Bohler & Lordon: neurosciences as science of conditioning). Compass: a knowledge environment that only addresses the intra-individual (“my productivity,” “my second brain”) has already lost the mémoire.

Compass: building is not only adding. **Closing, refusing, not spawning, stopping agents, not indexing everything, not wrapping every task in a model** are design actions in Fry’s third movement. A capability that cannot be turned off is not redirected; it is another zombie injection.

---

## Annexe 1 — the field, in a form a compass can carry

### What “digital” was allowed to mean (working definition)

Not a complete ontology. For this work:

- online services in a broad sense (communication, commerce, leisure, research, documentation, management);
- hosting of those services and of data;
- availability and maintenance of infrastructure and devices on a **given territory**;
- in a situation of dependence on net giants and fragile supply chains.

Flipo: digital as both material stake and signifying stake. The word is anxious, fast-moving, overlapping *informatique* / *digital*. AI appears in the 2021 list as one evocation among others — not yet as the organising fact of the sector.

### Anthropocene (as used)

Debatable name (others exist). Kept as the relatively shared word for a transformation of conditions of collective existence. Not only a geological unit: justice, order, meaning (Zalasiewicz et al. 2021).

Figures then used (see ageing): Elhacham et al. 2020 — technosphere mass (~1154 Gt manufactured 1900–2020) overtaking dry living biomass (~1120 Gt); ~30 Gt/year human-made mass, “each human’s weight created each week”; heading toward 3× living mass by 2040. Stephant: metals to produce in the next 35 years ≈ all metals since antiquity. Pitron / Vidal: next generation will consume more minerals than 70,000 years / 500 generations; 7.5 billion contemporaries vs 108 billion humans ever. Planetary boundaries: 5 of 9 crossed (Persson et al. 2022, cited as “recent”). COP26 ongoing while writing. Semiconductor shortages 2021.

Halloy: need a **power transition** first; energy transition is a consequence. Reviving a zombie technology would be a scientific challenge without measure. Most modern systems sit outside biogeochemical cycles (purity of materials, concentration of energy).

### Sobriety

Not stinginess. Question of sense of consumption (Guillard & Ben Kemoun): frugality, voluntary simplicity, anti-consumption. Macro: Illich’s conviviality — *the human controls the tool*. Meso: frugal innovation. Micro: attachments.

Millward-Hopkins et al. 2020: a “decent” life with fridge and phone at energy levels below 19th-century peasants — used to kill the stone-age cliché. The same numbers (one phone per person 10+, one laptop per household, network energy) immediately become **political**: *assez, c’est combien*, given interdependence of over-consumption and deprivation.

### Footprint — what was known, and the method of not-knowing

Three poles (consensus / ISO 14040–44, ITU L.1410): **datacentres, telecom networks, user equipment.**

Bordage et al. 2019 (world, LCA, GreenIT.fr), reused by Roussilhe’s teaching figures:

- Environmental footprint driven first by **quantity of equipment manufactured**.
- 34 billion devices including 15 billion IoT/embedded; 1.3 billion network devices (incl. >1 billion ADSL/fibre modems); 67 million servers.
- Digital universe **×5 in number of devices 2010–2025**; impacts ×2 to ×3 in 15 years.
- Share of humanity’s footprint: on the order of **2.5% (2010) → a little under 6% (2025)**.
- GHG: **2.2% (2010) → 5.5% (2025)**.
- Users: 56–69% of impacts; e.g. **62% of digital GHG at user equipment**.

Manufacturing vs use: manufacturing often dominates for devices. Wifi routers: small share of manufacturing emissions in the Luma inventory, larger in use (text’s local observation).

Water: mining ~70% of mining water in grinding/concentration (Roussilhe); a “standard” semiconductor fab 7.5–15 million litres purified water/day; TSMC 58 million m³/year, concentrated territorially (Taiwan drought 2021 is used in the workshop); a 15 MW California datacentre up to 1.6 million litres/day for cooling; France ~4 L freshwater per kWh (nuclear evaporation); France digital water footprint 559 million m³, **10.2% of French consumption** (Roussilhe 2020); world digital infrastructure 7.8 billion m³ in 2018, 0.2% of available freshwater.

Cloud investment 2020: $150 billion by giants, half for new datacentres; order Amazon, Microsoft, Google, Facebook, Apple, Alibaba, Tencent; 541 hyperscalers cited for 2020.

**Green IT vs IT for Green** (Flipo). Neighbouring research names: environmental informatics, computational sustainability, sustainable HCI, ICT for sustainability, benign computing, collapse informatics, permacomputing, small technology, salvage computing, low-tech (de Valk 2021).

Ecodesign: Brooks (1975) already — the most radical way to build software is not to. RGESN (Mission interministérielle Green Tech, 2021): ask whether the service should exist **before** criteria. Roussilhe’s **7 pillars** (mutually reinforcing; best service with least resources), first of which: **extend equipment lifetime** — application choices *do* age hardware (heavier updates, FS, runtime). Then: lifetime of the *service* itself (pertinence), etc.

**Systemic obsolescence**: 15-year laptop has the hardware; commercial software and the web have moved (De Decker / Low-tech Magazine). Function depending on a software layer, a network, a vendor: resilience defect (Longaretti & Berthoud). Dell’s concept-PC article used as a symptom of the industry narrating its way out without slowing software. Interviews at Luma/Mnémotix: local repairers exist; **fragility and software power demand** still drive replacement. Alternatives named: other software, other OS, reconditioned supply, spare parts — not as a shopping list, as a redirection of *what we sustain*.

**Rebound** (Parrique et al., *Decoupling Debunked*, EEB 2019; Jevons). Direct (efficiency reinvested in more of the same), indirect, structural. Digital specificities: time saved becomes more digital use; “dematerialisation” of a conference transfers impacts; telework is not a free lunch.

### How we know, and why we still do not (scopes, rucksack, LCA, extractivism)

The annex spends a long time on *method of not-knowing*. That is not a humility ritual. It is the condition of the object.

**Scopes (GHG Protocol).** Scope 1: direct. Scope 2: purchased energy (easy to attribute, hence over-reported). Scope 3: the rest of the value chain — the “fatal flaw” of GHG reporting (the mémoire quotes this diagnosis). Most digital organisations produce almost no Scope 1. A dashboard of 1+2 is a theatre of control. Compass: if a stack only reports “our server’s electricity in France,” it is Scope-2 piety. Models, training, foreign DCs, device manufacturing, WEEE: Scope 3 or out of frame.

**Ecological rucksack / MIPS** (Schmidt-Bleek, via the annex): the multiplier of matter moved for a finished object. Average ~30×. A 2 kg computer: ~22 kg chemicals, 240 kg fuel, 1.5 t clean water. A smartphone: MIPS ~1200/1 (183 kg raw materials for 150 g finished). The operator: objects are *larger than they look*. GHG-only is Konietzko’s tunnel vision. ADEME 2025 still flags **abiotic resource depletion (minerals & metals)** as a relevant criterion beside carbon — the mémoire was already there.

**LCA (ISO 14040–44).** Iterative, boundary-dependent, allocation-dependent. Useful and structurally incomplete. Manufacturer data sit behind IP. NegaOctet (then: ~1500 components, up to 30 impact factors, four granularities, into EIME) is named as a compilation, not as omniscience. The mémoire **rejected a full LCA of Weever**: too hard, too opaque, too easy to techno-fix. Compromise: inventory + interviews + third-party list + static infographic + CLI wrapping heterogeneous page tools.

**Three physical tiers** (ISO / ITU L.1410): terminals, networks, datacentres. Satellites: **no public integration** in the studies used (Roussilhe 2021e), even ~1% of traffic, Starlink/OneWeb already rising. Clair-obscur of the sky.

**Extractivism.** Growth of digital is growth of mines, water, purity, territorial sacrifice. The mémoire does not treat this as a preface to recycling. Recycling and the 5 R do not cancel primary extraction at the rates involved; WEEE is largely trafficked (70% of WEEE / World Bank ~80% illegally shipped — mixed sources in the text; **order of scandal, not a frozen percent**). Forti 2020: 53.6 Mt e-waste in 2019 (~7.3 kg/person); 74.7 Mt projected for 2030. Update UNITAR/Forti before quoting.

**Avoided emissions / decoupling.** The *À quoi bon* already contains the industry’s favourite alibi: digital will save emissions elsewhere. The annex: possible to track *impact transfers* (hybrid conference: less transport, more abiotic; rebound via more attendees). Decoupling as a thesis is a risky-to-suicidal bet (Parrique et al.; Mossé & Ramos). GreenIT.fr / NegaOctet NumEU even boxed: *Le numérique est une ressource non renouvelable. Économisons-le !* Compass: “AI will dematerialise knowledge work” is the 2026 form of the same alibi.

**PUE** (Roussilhe): electricity in use of a facility; says nothing about manufacturing energy, mix, or absolute growth. Looking only at use-phase electricity is looking at **25–40%** of the energy footprint. Compass: a “green PUE” dedi or a “efficient” local GPU is not a power transition.

**Accounting as imaginary.** Corporate measurement: take into account, count, render account, *be accountable*. To shareholders (financial materiality: climate → business plan) vs impact of the firm on the world (the inverse). Compensation and monetised “ecosystem services” as permits to kill nature (Solón). Paris as single-indicator trap. Compass: more official numbers since 2022 did not dissolve this imaginary; they refined the lighting in the clair-obscur.

### Survey results (orders of magnitude, not a model to copy)

- Interviews: daily activities vs “if I could keep only three.”
- 49 devices in the shared inventory (living list).
- 21 third-party services in the use-phase selection.
- Weever: hosting diagram (complementary tools / storage / Mnémotix apps). Each brick is a full application with its **own dependency tree** (npm/Docker). Once the framework is chosen, weight and complexity are largely locked.
- Automated tests on four screens (project, event resources, memos, thesaurus) on a **dev instance**, 22 Nov 2021 — a snapshot, not a science of the product.
- Documentary tool sits between **task-oriented** (explore, categorise, collaborate) and **information-oriented** (document, archive), after Garrett / Olsen. Immersion (metaverse) is the third pole, rejected as the centre of this object. Pointer to Monnin’s PhD (2013) on the Web and knowledge engineering — Weever’s semantic layer is not naively “just a CMS.”

Workshop outcomes (partial play): Luma-as-organisation appeared adaptable — solar partnerships for servers, phyto-mining expertise, willingness to question digital uses, osmotic energy as a speculative lead, fire/evaporative cooling, capacity to restructure as an archipelago under social tension. Method note: starting with “triumph of the commons” as a warm-up was a mistake; hostile scenarios should come first or the group stays in comfort.

Feasible/desirable for Weever: integrate measurement tools into continuous improvement **without** believing they redirect the service. Framework choice dominates page-weight piety. Distinction from “ecodesigned showcase sites” (lowww.directory) is essential — a documentary/collaborative app is not a brochure.

### Questionnaire (Annexe 2) — still a good interview spine

Five blocks, meant for people inside Luma / Mnémotix, not for a census of France:

1. **Situation** — role, place, remote/on-site, what “a digital day” is.
2. **Réalisation** — what is produced, with whom, which tools feel indispensable.
3. **Hébergement** — where things live, who decides, what is unknown.
4. **Maintenance applicative** — who keeps software alive, updates, lock-in.
5. **Appareils** — what is on the desk, what was replaced, why, repair vs buy.

Concrete questions already in Annexe 2 that still work as an audit of *any* stack: is the workplace near a backbone? wifi / 4G / RJ45? electricity supplier (mix)? hours to build? how many machines, including those taken home? screens per machine, test devices? GitLab only? how many environments (dev/test/preprod/prod)? deploy frequency? duration of CI tests and load tests? all instances on Amazon, which region? self-hosted machines, specs? expected connections per minute? daily transfer? backup frequency and retention (data lifecycle)? 

The interview also asked: daily activities vs “if I could keep only three.” Repair testimonies: local repairers exist; fragility and **software power demand** still drive replacement. Compass: any new environment should be able to answer these blocks about *itself*. If it cannot say where it is hosted, who maintains it, how often it deploys, how long data is kept, and which devices it ages, it is spectral. Retention is already Fry’s third movement: **closing data** is design.

### Ecometrics — situated visualisation, not a product

Static Svelte site (temporary URL in the text: `https://msc.paulmichalet.com/ecometrics`). Cover of the formatted PDF is a *visual* of its source (`co2Store`, `selectionStore`, `carbonIntensityStore`…). Pedagogical operators:

- organisation-scale **pictograms** (49 devices as a living list);
- **21** third-party services in the use-phase cut;
- **geographic carbon intensity** as a demo (France 38 gCO2e/kWh vs Hong Kong 755 — **mix is a time series; do not hardcode 38**);
- static: no always-on app for the pedagogical layer (diplomat: smaller attack surface *and* lighter footprint).

A parallel, more territorial experiment: dynamic map for the *Comitê de Combate à Megamineração no RS* (south Brazil extractivism), aggregating open mining data. Free hosted services were a prerequisite under time pressure — the mémoire flags that choice as morally unfinished. Compass: making extractivism *speakable on a map* is numérique situé; putting the map on an unmarked SaaS is the contradiction to keep visible.

Author’s CLI wrapper: `ecowetrics` (provisional), AGPL-3.0, `github.com/Paulmicha/ecowetrics` — **single entry point** to EcoIndex / Yellow Lab / Lighthouse, not a new science. Snapshot: four Weever screens on a **dev instance**, 22 Nov 2021 (GreenIT Analysis CLI HTML). Monument, not a KPI.

**What the interviews actually said (operators, not a census).** Paper notebooks still carry research on materials; the computer is for clarity, and “we could do less on the computer.” COVID normalised visio that used to be travel. At Luma, **Nextcloud** is the intended document centre (permissions); **Google Drive** remains for sharing with outsiders and for collaborative writing — convenience vs control. Expectations of a documentary tool: centralisation, autonomy, access, aesthetics (not only developer aesthetics in free software), density, Zotero portability, coherence with free-software values, *and* a willingness to drop the visual perfectionism of graphic suites for meetings. Fears: the usual organisational ones around a new tool. End-of-life: local repairers exist; software power still kills machines.

**Weever’s shoulder (dependencies as a picture of the zombie).** Hosting diagram: complementary tools (green) / storage (red) / Mnémotix apps (blue). Each brick is a full application (Keycloak identity, MinIO files, …) with its own languages and licences. Weever consumes them invisibly. Node tree dated **25 Mar 2021** (`weever-core` release): a blurry thick line that is the full npm graph — ~**90,000** files/folders, ~**355 MB** `node_modules`, ~**700** modules, ~**600** people, **13** licences, duplicate versions of the same package. That is Nadia Eghbal’s maintenance problem, Buytaert/Woodman governance, and the limit of any “complete” LCA of a documentary tool. Compass: an agent runtime + index + UI that pulls another 700 modules has already chosen its giant. Thin pivots are a way not to freeze that tree as destiny.

**ecometrics numbers (period photographs).** 49 devices → **12,337 kg eq.CO2** manufacturing (then). Wifi routers: small share of manufacturing, large share of use (often 24/7; and home routers of remote workers were **not** all counted). Use-phase 21 services: largest fragments in the demo **AWS, Netlify, Scaleway** — estimates the text itself calls *very imprecise*. Mix slider: France 38 vs HK 755. Network tier: weekly transfer guesses. Escape hatch: enter W/h per month if you have a better number. Opacity of hosting/redundancy is constitutive. Cloud Carbon Footprint and Software Carbon Intensity were named as futures.

### Gupta’s stack (why page piety is small)

Figure 13 in the annex (Gupta et al. 2021): carbon reduction requires the whole stack — chips, architecture, languages, VMs/containers, OS, browsers, then the application. The developer of a site only owns the top. Framework choice locks weight. Compass: choosing Cursor + a frontier API + Docker + an index is a **stack decision** in Gupta’s sense. Ecodesigning the markdown export is the top millimetre.

---

## Compass — what this still commits the author to (2026)

These are not features. They are **refusals and orientations** the mémoire would recognise.

### 1. Inherit zombies with open eyes

Every stack (Drupal, Svelte, Docker, Cursor, an LLM, a dedi, Nextcloud, Argo CD) is a giant. Some are already dead as durable practices and still walk. Use them **as heritage to govern**, not as a future to scale. Negative commons: we do not get to un-invent GPUs or hyperscalers; we get to decide what we still feed.

### 2. Do not confuse three different jobs

| Job | 2021 name | Failure mode |
| ----- | ----- | ----- |
| Lighten a given service | Écoconception / Green IT | Religion of the kilobyte; “wow” blackmail; thinking it will be *énorme* |
| Use digital to green something else | IT for Green | Avoided-emissions storytelling, rebound |
| Change what we sustain, close, or redirect | Redirection écologique | A new product that is only a more virtuous zombie |

A personal knowledge environment, an agent runtime, a GitOps dedi: all three jobs can be mixed dishonestly. The compass says: **name which job you are doing.** Ecodesign of a notes pipeline is legitimate and small. Redirecting what counts as a “necessary” agent run is the larger job.

### 3. Situation before spectrum

Prefer: named machines, named jurisdictions, named mixes, named mounts, inspectable processes, local-first files, territorial constraints (this house, this dedi, this Nextcloud path).

Refuse: “the cloud” as a non-place; anonymous generation; unstoppable occupancies; indexes that pretend to be the world.

The 2021 *ecometrics* experiment (static site, geographic intensity, organisation-scale pictograms) is the ancestor of “make the invisible ecological *speakable* without a complete LCA.” Do not wait for NegaOctet-on-everything.

### 4. Measurement is a means of inquiry, not a cockpit

Inventory, EcoIndex snapshots, dependency graphs, energy mix: use them to **see orders of magnitude and trends**. Do not “pilot the footprint” as if the Anthropocene were a crisis that management can close.

Opacity is constitutive, not a data-quality bug. Confidential manufacturer data, trafficked WEEE, unverifiable avoided emissions: the unknown is part of the object.

### 5. Software is a material of obsolescence

Heavier runtimes, automatic updates, dependency floods, “just add a model” age the hardware of *others* (users, future maintainers, the dedi). Brooks still applies: the most radical software is the software not built. After a framework is chosen, piety about image weight is secondary. **Choose stacks as if they were territorial infrastructure.**

### 6. Imaginaries without prophecy

Design fiction, scenarios, SSP affinities: tools to test attachments *now*, not to predict 2040. Hostile scenarios are not “negative vibes”; they are a way not to stay in green-growth comfort. Distant utopia/dystopia both incapacitate. Near present + attachments > 2050 slide decks.

### 7. Conflict is data

5G sabotage, ecofascist signals, who is in the workshop, who is not, remote internship, commissioning relations (Luma / Mnémotix / school): digital is already a field of force. A “neutral” productivity app that denies conflict will take a side anyway (usually the side of more automation).

### 8. Sobriety is political, not a UX theme

*Assez, c’est combien?* cannot be answered by a personal dashboard. It requires public instances, and it immediately hits inequality. A second brain that maximises capture of “everything I might need” is an *assez* of plenitude — the opposite of the mémoire’s rarity of the conceivable.

### 9. Documentation is not innocent

Weever was a documentary/semantic tool for situated knowledge (projects, events, memos, thesaurus). The MSc question was: can such a tool be realised *in* the Anthropocene without lying about its conditions? The same question now hits any knowledge environment: notes, agents, indexes, published PDFs. Knowledge transmission was the *giant* in the title. Zombie infrastructure is the *shoulder*. A documentary practice that hides the shoulder is propaganda of immateriality.

### 10. Scale of organisation

The essay claims its comments remain relevant beyond Luma/Mnémotix, for a range of sizes of organisations, collectives, communities — **not** for “Google.” Discernment of scale (VSCode vs communal website) is still the first intelligence. A home-scale environment must not copy hyperscale imaginaries (always-on agents, unbounded research, complete archive).

---

## What has aged (figures, laws, objects) — keep the operator, replace the number

The mémoire’s **operators** (zombie, situated, clair-obscur, redirection, rebound, systemic obsolescence) have not aged. Many **illustrative figures** have.

### Global / French digital footprint

- **Bordage et al. 2019** (world): 2.5% → ~6% of humanity’s footprint 2010–2025; GHG 2.2% → 5.5%; user equipment ~62% of digital GHG; 34 billion devices, etc. These were already **projections and contested LCAs**, not measurements of 2025. Do not quote them as current fact.
- **ADEME–Arcep 2022** (France, year 2020) — *published after the mémoire*: 17.2 MtCO2e, **2.5%** of France’s carbon footprint. Terminals dominated; foreign datacentres hosting French uses were **out of scope** (a clair-obscur the mémoire would have recognised).
- **ADEME update Jan 2025** (France, **year 2022**): **4.4%** of national carbon footprint, **29.5 MtCO2e** (a bit less than heavy goods vehicles). Terminals **50%**, datacentres **46%** (vs ~16% in the 2022 study), networks **4%**. Two causes named together: **method** (foreign DCs now in; ~**53%** of French uses hosted abroad) **and** growth (new DCs). Electricity: **51.5 TWh** national uses (**11%** of French electricity), **65 TWh** with foreign DCs (~Île-de-France). Manufacturing still **~60%** of digital carbon; **117 Mt** of resources mobilised per year, **~1.7 t per person**. Abiotic depletion (minerals & metals) kept as a relevant criterion — the mémoire’s anti-GHG-myopia. Generative AI is **not yet in the 2022 numbers**; ADEME/IEA treat it as the next driver. IEA (cited in the ADEME update): world DC electricity toward **~1000 TWh by end 2026** (order of Japan). Microsoft and Google environmental reports: emissions up; carbon-neutrality pledges strained. The 2022 ADEME–Arcep *prospective* (on the narrower 2020 scope) already warned of **×3 GHG by 2050** in a tendential scenario — keep as *that study’s* warning, not as a 2025 re-run.

The 2021 claim “not (yet) among the largest sectors, but unique growth” must be rewritten: **datacentre/AI growth is now the official French story**; user-device manufacturing remains huge (**50%** of carbon, still first if one looks at materials); **scope choices still move the headline percentage more than piety**. The mémoire was already right that GHG-only is myopia. The jump 2.5% → 4.4% is partly *turning the light on* in the clair-obscur (foreign DCs), which is exactly Roussilhe’s game.

### Carbon intensity demo (ecometrics)

France **38 gCO2e/kWh** vs Hong Kong **755** (2021 demo). The French mix is **not** a constant: 2022 nuclear unavailability spiked intensity; later years recovered. Any UI that hardcodes 38 g is outdated. The **operator** remains: geography of electricity changes the use phase more than a few widgets. Scaleway-in-France vs AWS-elsewhere was already the right pedagogical contrast.

### Water, TSMC, Taiwan drought

2021 drought as workshop signal: still valid as *type* of territorial shock. TSMC volumes need checking before reuse; semiconductor water intensity remains a live constraint (also Arizona, elsewhere). Do not freeze 58 million m³/year as eternal.

### Hyperscalers and capex

$150B (2020) and “541 hyperscalers” are period photographs. Capex has grown, AI training clusters have changed the shape of “a datacentre.” Facebook ≠ Meta’s AI buildout. Update the postcard; keep “half of giant capex into new DCs.”

### Devices and population

34 billion devices / 15 billion IoT: order-of-magnitude 2019 LCA world, not a 2026 census. Human population 7.5 billion in the Pitron quote → ~8.2 billion. Technosphere-vs-biomass (Elhacham 2020) has been discussed and sometimes criticised methodologically; still a useful shock-image, not a legal fact. Planetary boundaries: more than 5 of 9 are now commonly reported as transgressed — the 2022 “five” is already behind.

### Labour and “Big Quit”

4 million US resignations Apr–Jul 2021: a pandemic-era snapshot, not a law of meaning-loss. The **operator** (crisis of sense, temptation of flight among the comfortably trained) remains, including among engineers now building agents.

### VSCode 100 TB

A good 2021 parable of automatic updates × millions of users. Do not recycle as a current CVE. The operator: **distribution × waste in the toolchain of developers** — still true of models, container pulls, npm, IDE auto-updates, agent toolchains.

### Law and labels (France)

The mémoire writes from **regulatory lag** (REEN in discussion / just arriving). Since then: REEN law, RGESN evolution, Arcep annual digital environmental surveys, ADEME–Arcep studies, some datacentre and terminal display duties. Constraint is **less absent**, still far from a power transition. Clair-obscur mutated: more official numbers, still voluntary cores, still foreign-DC tricks until 2025’s correction.

### Tools named

GreenIT Analysis CLI, EcoIndex, NegaOctet, Cigref, Fing, lowww.directory, Labos 1point5: some evolved, some weakened (Fing’s institutional life was already fragile). Do not treat Annexe 3 as a 2026 buying guide. The **need** for a single entry point to heterogeneous measures remains.

### Field objects

Weever, atelier-luma.org redesign, `msc.paulmichalet.com/ecometrics`, 49 devices, 21 services, 22 Nov 2021 EcoIndex HTML: **historical monuments**, not live specs. If ecometrics is offline, that is part of the heritage problem (services die; the mémoire already worried about service lifetime as a pillar).

### COP26, 2.7 °C, 500 ppm in a fiction

COP26 is archive. Current-policies warming in the high-2 °Cs is still the right *order*. The green-growth scenario’s 500 ppm in 2049 is fiction, not a forecast. Authoritarian-ecology / ecofascist signals: unfortunately not outdated as a *type*.

### The hole the mémoire could not see: generative AI

This is the main **missing giant**. 2021 mentions AI as one market among “frontier technologies” (UNCTAD 2021 figure). 2022–2026: training and inference as a new datacentre regime; agents that generate plenitude (tokens, images, “research”) as a rebound machine; “knowledge work” automated as commentary (the history of ideas at scale).

The compass, applying 2021 operators without pretending the mémoire said “LLM”:

- An agent that indexes everything and researches without budget is **anti-sobriety**.
- An agent that cannot be inspected or stopped is **spectral** (Han) and **unoccupied** (no prudent subject).
- A local-first, named-runtime, stoppable agent on a known machine is closer to **numérique situé**.
- Using a frontier model as default cognition is standing on a **new zombie** (alive with investment and imaginary; condemned on energy/materials if scaled as the new normal).
- Ecodesigning prompts is Green IT. Asking whether the occupancy should exist is redirection.

---

## Relation to the computational environment being built (without shrinking the compass to it)

The 2021 terrain was a **documentary/semantic tool** in a cultural-research organisation, plus a static infographic, plus a fiction workshop. The 2026 terrain includes a **home-scale computational vocabulary (ASC)**, a **semantic environment (Projet Complexe)**, thin pivots, a dedi, agents.

Analogies that hold:

- Weever’s lock-in after framework choice ≈ choosing an agent/runtime/index stack.
- Ecometrics as situated visualisation ≈ making files, processes, machines, and occupancies *speakable* (ASC’s question: what is this, where, what can be done) without claiming a science of knowledge.
- Workshop’s “organisation as character” under shock ≈ an environment that can **close** functions when energy, parts, or legitimacy fail — not only add `run-agent`.
- Negative commons ≈ nested git, Nextcloud, models, the dedi: inheritances to govern.
- Co-inquiry ≈ agents as occupancies in a practice, not as a replacement inner life.

Analogies that must **not** be forced:

- Projet Complexe is not Weever.
- ASC is not NegaOctet.
- A second brain is not an archive of the Anthropocene.
- Personal productivity is not ecological redirection (it can serve it or betray it).

The mémoire’s first interpretation of the commission was: inventory + recommendations on what is feasible, desirable, conceivable. That trio remains the acceptance test of any new pivot, model, or always-on worker.

---

## Open questions the mémoire left (still open)

- How to keep participatory work from excluding the inaudible.
- How to articulate imaginaries with actual power (Dion: stories are not enough).
- How to map without being mapped (Landivar et al. 2015: ontology/cartography).
- How far measurement can go before it becomes the object.
- What a *convivial* (Illich) digital tool is when the tool is a network of zombies.
- How a documentary practice names its own shoulder (energy, metals, vendors, models).
- What to **close** in a knowledge environment, not only what to add.

---

## One-page remainder (if an occupancy has ten minutes)

Digital services in the Anthropocene stand on giant zombies: living by investment and imaginary, dead as durable material practice. Ecodesign is not nothing and not enough. Measure to situate, not to pilot. Localise and materialise; the Cloud is a myth of place. Software ages hardware; not building is a design act. Imaginaries test attachments in the near present; they do not replace politics. Redirection means closing and governing heritage, not only shipping greener features. Sobriety is a public *assez*. Conflict is part of the object. Generative agents raise the same problems at higher metabolic rate. A knowledge environment worth making is one that can name its machines, rarefy what it keeps, stop what it started, and remain hesitant.

The rest is in the 166-page PDF.

---

## Essay, continued — measurement will not save us (Ch. 2, thicker)

If IPCC reports were enough, action would already have followed. The mémoire’s sharpest sentence in this zone: **better data do not automatically produce better decisions.** The COVID period is used as proof: shared science, different thresholds, different doctrines. The managerial demand to “have the data first” is itself an imaginary — the hammer that makes every problem a nail (Mager & Katzenbach: tech firms absorb public capacity to govern futures).

That is why chapter 2 does not end in a better dashboard. It ends by handing the problem to imaginaries (ch. 3). Compass: do not stall a closing-down decision on the absence of a complete LCA. Trends (more devices, more abstraction, more automatic updates, more model calls) are already enough to refuse *some* things.

### Regulation as it stood in late 2021 (then vs now)

The annex distinguished **regulation / certification / label**. Global décor: SDGs (with known incoherences — Hickel, Kroll, Wackernagel). Sachs et al. 2019 even listed universal broadband and “mobilising digital for all SDGs” as levers — a document that **IT-for-Green** can quote forever. Basel Convention on hazardous waste: World Bank estimate **~80% of WEEE illegally shipped** to developing countries; legal management could be a €360bn market; trafficking profits >€17bn in 2015 (Courboulay 2021). Forti 2020: **53.6 Mt e-waste in 2019** (~7.3 kg/person, “350 cruise ships”); Asia 24.9 Mt; **74.7 Mt projected for 2030**.

France then:

- **AGEC** (10 Feb 2020): repairability index (to become durability index in 2024); ISPs to display data volume **and GHG equivalent from 1 Jan 2022**; public bodies to favour energy-light software and reuse.
- **SNBC**: carbon neutrality 2050, carbon budgets. HCC yearly reports — **no dedicated digital section** in 2021.
- Government roadmap *Numérique et Environnement* (23 Feb 2021): know the footprint; soberer digital; digital as lever of ecological growth (the third pillar is IT-for-Green in state clothes).
- **REEN** voted by the Senate **2 Nov 2021** (while the mémoire was being finished): sobriety in education; commercial practices; software obsolescence as an offence; freedom to install other OS/software after the 2-year legal guarantee; reuse of equipment.

Labels cited: Uptime Tier I–IV (availability, not ecology), Green Web Foundation, Collectif Green IT QCM cert, Lucie “numérique responsable.”

**What aged:** REEN became law; RGESN lived; Arcep/ADEME produced the numbers the mémoire said were missing; repairability index exists in shops; ISP GHG-on-the-bill is uneven in practice. The **operator** holds: more light, still little constraint on *volume of equipment* and on *whether a service should exist*. Tier IV is still a certificate of not-going-down, which is the opposite of intermittent, territorial computing.

Compass: do not collect labels as a substitute for redirection. A Green Web tick on a hyperscale-backed app is clair-obscur.

---

## Essay, continued — imaginaries and redirection (Ch. 3, thicker)

### Non-utopia

Sophie Keller / Emile Hooge: stay away from incapacitating dystopia *and* from utopia that cannot backcast. Climate faster than expected: **1.5 °C likely around 2033** (Rohde 2022, cited); staying under 2 °C after 2050 only if CO₂ halved by 2030 (Giaccone). Paris may not be held — that possibility must stay *inside* the cone of futures, not as a forbidden thought.

**Why imaginaries at all?** Collapse of clichés that block other ways of living; Graeber (2011): a bureaucratic apparatus of despair that destroys the sense of alternative futures; we can imagine catastrophe more easily than another arrangement. Saint-Simonism / Comtean industrial aristocracy of talent as the ancestor of techno-solutionist metanarrative. Aim: so that **sense-making does not depend only on organisation, expert knowledge, and control models** — without collapsing into anti-science. Critique administrative *management* of science, not inquiry.

### Three sustainabilities (Lenz 2021) — still a useful grille

1. **Sustainability as modernisation** — market, consumer, green capitalism, ethical finance. Green growth scenario.
2. **Sustainability as transformation** — degrowth / post-capitalist; convivial techniques; “soft” or “sustainable” digitalisation as reaction to incompatibility of digitisation and sustainability. Commons scenario.
3. **Sustainability as control** — authoritarian, state, digital as preventive shield against collapse. Authoritarian-management scenario.

### Four régimes (Chateauraynaud & Debaz 2019)

1. Systemic collapse (collapsology’s cousin).
2. Technological rupture (geoengineering, generalised digital, algorithmic governmentality).
3. Regulation (agencies, composite norms, public/private force).
4. Pragmatist recomposition (coalitions that mix bits of catastrophism, instruments, and innovation — transition towns, alternative agricultures). The mémoire’s sympathy sits here, with a warning: Ponts-et-Chaussées engineers in 19th-century Naples already believed their *moral* superiority over “barbarous prejudices” authorised moving populations. Technical bodies produce exceptionalist virtue. Redirection is not a new corps of saviours.

Landivar (2021): the battle over **what counts, what is, what is worthy of support, what we are ready to renounce**.

Gourlet’s limits, again: who produces the stories, who accesses them, whose issues?

### Fry’s three movements (quoted in the mémoire)

1. Historical understanding of what structured the practice; uncomfortable meeting of “education to error” and “material desires.”
2. Reorient existing practice toward unsustainability in the **immediate** environment.
3. Distinguish design that brings forth durable things from design that **denies** things structurally unsustainable.

Origens’ ecological redirection adds **heritage** and **closure**. It is not “act for the environment ASAP inside current firm logic” (greenwash). It is not “hack from inside” as spectacular reversal. It **states what must be done**, including that some activities are condemned. Examples: workshop with Centre des jeunes dirigeant·e·s d’Occitanie (Deutsch 2021); *Fresque du renoncement* (dependencies, supply chains, attachments, difficulty of giving up).

Open question the essay leaves: does redirection, beyond closing unsustainable futures, also **open** futures that cannot be determined in advance, to be co-invented?

Compass: yes — but opening is not “add another agent.” Opening is keeping hesitation (Huyghe) after something has been closed.

### Essay conclusion — what the author asked of himself next

- Focus participation on **situated understanding of digital** and of the milieu.
- Cartography: *either you map or you are mapped* (Landivar et al. 2015). Ontology is already political.
- Stories need a political battle, not only circulation (Dion).
- Doise’s four levels (intra, inter, positional, ideological) were named as missing development — do not reduce behaviour to brains (Bohler & Lordon: neurosciences as science of conditioning).
- Green IT lacks force without alignment of spheres.
- Diplomat posture: static architecture as *both* smaller attack surface *and* lighter footprint.
- Political sequel: negative commons, participatory democracy, parlement des choses — not a personal knowledge graph.

---

## Seven pillars (Roussilhe / Gauthier), still too small and still necessary

Objective: best possible service with least resources. Pillars **reinforce each other**. Inverting their order is Green IT as displacement activity. The mémoire’s practical trio if one must pick three page-level acts: minimise requests and transfer; minimise client JS (size and complexity); reduce what the browser loads. Those three sit **under** pillar 1–3, not above them.

1. **Lifetime of equipment.** Manufacturing usually dominates use. Hardware does not really “slow down”; software and OS debris do (Tatoute on Windows system directories; SSD spare blocks; dusty cooling). Mobile updates that demand more RAM exile older phones. Filesystems, bloatware, preinstalled Android OEM apps (Gamba et al.): application choices **age other people’s hardware**. VSCode’s accidental 7 MB × 14 million automatic updates ≈ 100 TB is the parable. A 15-year laptop is often hardware-fine and software-exiled (De Decker / Low-tech Magazine).
2. **Reduce non-renewable resource use and e-waste** — typically the server side: compute for features, number and spec of connected devices, volume collected or transferred, short-lived or inefficient hardware.
3. **Lifetime of the service itself** — pertinence. If it answers a durable need, what would make us abandon or rebuild it? Needs, documentation, complexity, code quality, standards, living community (security, skills), external shocks (new management). Brooks (1975): the most radical software is not building it. RGESN: ask whether the service should exist **before** criteria.
4. **Optimise for the worst conditions** — weak networks, old or cheap terminals. Same logic as accessibility: do not punish those without unlimited bandwidth or frequent replacement. A carousel that only works with a mouse is the anti-pattern; a simpler interface helps everyone (Kalbag: accessibility is usability — visual, auditory, motor, cognitive).
5. **Ecodesign inside a wider web ethics** — security, data governance (GDPR; Fing Self Data Territorial), performance, attention (against dark patterns). Ecodesign is not a budget line any more than “make it fast” is.
6. **Durable, known, maintained tools; document and open the work** — collaboration, method improvement. Free software is named as a later discussion, not as automatic virtue (commons can be zombies too: Drupal).
7. **Sensitise; relegate ecodesign to support of a wider organisational strategy** — infographics, equivalents, a shared EcoIndex-like reference. The *ecometrics* site was this pillar as a static object.

Compass for a knowledge environment: heaviest choice is **whether an occupancy exists**, then **which runtime**, then **which dependencies**, then image weight. Pillar 4 (worst conditions) argues against default frontier-model cognition. Pillar 7 argues against a private carbon widget that never becomes a public *assez*.

---

## Three scenarios (workshop) — keep as a test kit

Each was given SSP affinities (IPCC shared socioeconomic pathways) as a graphic, not as a prediction engine.

**Croissance verte.** Business as usual with decoupling taken seriously *as the ruling belief*. SNBC, *France 2030*, innovation as growth, not frugal innovation. Weak signals of tech-as-prosperity. Risk: Paris-in-name, extractivism offstage.

**Gestion autoritaire.** The mémoire *knew* dystopia can incapacitate (Kerspern et al.) and still built this scenario: current-policies ~**2.7 °C**, hostile to universalist human rights, green dictatorship / ecofascist ecology (race, identity). Weak signals: attack on a Lyon anarchist bookshop (March 2021), colonial lineages (Kempf). Purpose: force an organisation like Luma to imagine concrete consequences, not to enjoy gloom.

**Triomphe des communs.** After *La vie low-tech en 2040* (Institut Paris Region, 2020): progress re-tied to common utility; simple, cheap, local, repairable techniques; COVID as a teacher of vulnerability. Not a hippie postcard: supply-chain breaks (Taiwan water → chips; copper) and energy rationing were *inside* the play.

**Workshop machinery (keep as a method, not as a product).** Inspired by Etalab/Design Friction *Nos Algorithmes*, Fing *Numérique tous risques*, *Fresque du renoncement*. Organisation as a **single character**. Hybrid format. 20–30 minutes per scenario was too short; only two boards actually played. Starting with commons was too kind — hostile boards first, or the group stays in comfort.

Commons scenes actually played: (1) mechanisms of the game; (2) supply-chain break echoing **Taiwan 2021 drought** — relocate semis to Europe, surprise that **copper** was not already in the script; (3) energy rationing / cuts (Bihouix: abandon the horizon of performance; chosen sobriety with a less dispatchable mix; delayed appliances; *Nos Algorithmes*’ fake public display of algorithmic-service availability). Authoritarian scenes: (1) violent fires in the **bioregion**; (2) social unrest (yellow vests / black vests), Luma vandalised; (3) new pandemic, international desolidarisation, hyperinflation, **local currencies**. Green-growth board was prepared and **not played**. The vertical axis of the game was meant to push proposals from micro (firm survival / turnover as “hit points”) toward **meso** (territory, sector) without floating into empty macro.

Method notes: yellow post-its as on-board memory of decisions; dice; a tendency to “seek oneself” in the framing; evocative images always diverge. Starting on Fing’s *ressourcerie* needed more clarification. A missed concrete lead: Sailcoop Mediterranean flotillas + Luma’s trans-Mediterranean network → documentary access **on a sailing crossing** (variable network) as a real test of ecodesign vs other ways to carry the research. That is numérique situé as a *crossing*, not as a slogan.

Compass: a project that cannot survive the *authoritarian* and *commons* boards — only the green-growth board — is not redirected. Ask of any new always-on service: what happens when the mix spikes, when the GPU quota dies, when the vendor closes, when the group splits into an archipelago? Keep the three boards as a **test kit**. Distant 2049 ppm numbers are fiction. Attachments in the near present are the real material. Intermittence (Low-tech Magazine; Bihouix; fake availability displays) is a design material, not an outage to hide.

---

## Weever as a type, not as a product to resurrect

Task + information (Garrett/Olsen), not immersion. Semantic/documentary: projects, events, memos, thesaurus. Once the framework is chosen, EcoIndex on four screens is **hygiene**, not strategy. Complementary tools / storage / Mnémotix apps: each brick a world of packages.

The mémoire already pointed to Monnin 2013 on the Web and knowledge engineering: a documentary tool is never “just notes.” It is an ontology in use. Landivar: if you do not map your ontology, you will be ontologised.

Compass: a semantic environment on ASC inherits this exact problem. Thin pivots are a way not to freeze a total ontology. Closing a pivot is Fry’s third movement. Indexing the whole Nextcloud is a 34-billion-devices instinct at home scale.

---

## Drupal, twelve years, and the author’s own zombie

The essay’s “what this is not” includes a critique of the author’s practice: Drupal as a **software commons** that is also a giant (modules, PHP, hosting, the culture of more contrib). The internship’s remote condition and the developer’s deformation (wanting a process that implies its results) are named as risks of inquiry.

Compass: CWT, ASC, home-as-git, a dedi, Cursor agents — same pattern. Commons + zombie. Méliorist: neither dump them nor baptise them as the future. Govern the heritage. Do not add a module (or an agent) because the commons makes it easy.

---

## Power transition (Halloy), not only energy transition

Figure 4 in the annex: schematic of a **power** transition (Murphy et al. 2021, adapted). Energy transition, as currently researched, is a consequence. High energy concentration + extreme material purity = systems outside planetary biogeochemical cycles. “Reviving” a zombie is a scientific task beyond anything done yet.

Compass: efficiency (Green IT) and fuel substitution (green electricity for the dedi) are not the same as lowering **power** (watts × time × number of occupancies). An always-on local LLM at home is a power decision. A stoppable occupancy is a power decision. Intermittence (Low-tech Magazine’s weather-tied server) is a territorial power decision. The 2021 ecometrics geographic mix was a toy version of that.

---

## Water as the forgotten indicator

The mémoire insisted water against GHG myopia. Digital water competes with agriculture and drinking water **on territories far from users**. Taiwan 2021 was the pedagogical shock. France: 559 million m³, 10.2% of national freshwater consumption (Roussilhe 2020 figure — **check before reuse**; operator: imported footprint of devices).

Compass: a “green” European host can still sit on a watershed in drought. Geography is not a theme; it is the referential of the use phase.

---

## What “feasible, desirable, conceivable” meant on the field

First interpretation of the commission: (1) inventory of the existing, maybe a baseline; (2) recommendations on tools and implementations. Two objects: Weever and atelier-luma.org.

The plan then simplified to three parts (art / survey / fiction) because a full “orientations of thought” chapter would have duplicated the essay. Recommendations that survive:

- Integrate measurement into CI **as a mirror**, not as a score to game.
- Do not copy brochure ecodesign onto a task+information app.
- Framework choice dominates.
- Sensitise at organisation scale (pictograms, mix, 49 devices) rather than global 4%.
- Fiction to test attachments, with enough time, and with a hostile board.
- Static public sites when the job is publication (diplomat: security + weight).
- Hosting: a comparative LCA of “cloud vs Fondation Luma’s datacentre” was named as *thinkable* and probably **not justified** at the traffic then expected — discernment of scale again. Collaborative volume (people online at once, data) already locks a class of hosting; brochure-site piety does not transfer.
- Equipment is still where the mass is: repair, reuse, lifetime, salvage. That pairs with asking, at foundation scale, **whether a project or a purchase should exist**.
- Licences: open the sensitisation materials, methods, tools, and even this kind of report — not as a brand of virtue, as a way the work can outlive a URL.

Annex “future research” already pointed beyond the internship: more situated cartography, more time for fiction, less faith in page scores. Five years later the missing chapter is generative occupancies.

**A light public door, and a local fragment (still a live problem).** One field suggestion: an ultra-light **public entry** to Weever data, stripped of authoring-UI dependencies, possibly offline for degraded mobile networks. Text is light; media is not. Experiment: local copy of a DB fragment in the browser (`msc.paulmichalet.com/msc-search-index`) — whole DB loaded into device memory (Giammarchi 2021), sync later. Prototype: <2000 tabular rows. Filtering with joins already felt heavy. Tens of thousands of notes/concepts/projects offline would likely be prohibitive on modest hardware. Compass: a “second brain” that indexes everything locally in the client repeats this failure at home scale. **Rarefy what is copied; keep the heavy store on a named machine; do not pretend the browser is a datacentre.** Public read-paths without the authoring giant: still the right diplomat move (Sailcoop crossing, intermittent energy, pillar 4).

---

## Aged figures — checklist for humans and agents

Do **not** quote as current without a date:

| 2021–early 2022 figure | Status in 2026 |
| ----- | ----- |
| Bordage 2019 world 2.2%→5.5% GHG, 34 billion devices, 62% user GHG | Period LCA/projection. Superseded as *the* number; operator (equipment count drives impact) holds, but **AI/DC share has jumped in French official accounting** |
| France 38 vs HK 755 gCO2e/kWh | Mix is a time series. Recalculate |
| $150B cloud capex 2020; 541 hyperscalers | Postcard. Capex and AI clusters grew |
| 4 million US quits Apr–Jul 2021 | Pandemic snapshot |
| VSCode 14M users, 100 TB | Parable, not a live incident |
| 7.5 billion humans | ~8.2 billion |
| 5 of 9 planetary boundaries | More now commonly listed as crossed |
| 53.6 Mt e-waste 2019 → 74.7 Mt 2030 | Order still right; update Forti/UNITAR if citing |
| WEEE 70% trafficked / 80% illegal (sources mixed in the text) | Order-of-magnitude of the scandal; do not freeze the percent |
| REEN “just voted” | In force; still weak on volume |
| HCC without digital section | ADEME–Arcep filled part of the hole |
| EcoIndex snapshot 22/11/2021 | Monument |
| 49 devices, 21 services | Monument |
| COP26, 1.5 °C in 2033 (Rohde) | 1.5 °C breach is now a live statistical argument, not a 2033 remote |
| UNCTAD 2021 frontier-tech market sizes | AI column exploded |
| ecometrics URL, Weever-as-current | Historical |
| “No other sector has such growth” | Rewrite: DC/AI is the growth story; aviation recovered; still do not minimise |

Keep quoting **as 2021 claims**, then add the ADEME 2025 4.4% / 29.5 MtCO2e / 46% datacentres (method + growth) if a current French public number is needed. Always say **scope**.

---

## A broader practice this compass would recognise

Not only Projet Complexe. The mémoire would recognise (and audit) at least:

- Keeping a **named** personal and collective infrastructure (home git, dedi, Nextcloud) instead of an unmarked SaaS pile.
- Publishing notes as **monuments** (source + PDF) rather than only chat.
- Refusing workspace-root tricks and raw nested git: small rarefactions of what may be said/done.
- Using agents as **occupancies** with stop, not as a new inner voice.
- Not building a second Weever by accident (total ontology of the self).
- Ecodesign where it is cheap (static export, original figures, no extra conversion pipelines that destroy information).
- Closing: unbounded research, index-everything, always-on models, persona-as-subject.
- Diplomacy: arguments that ally sobriety with maintainability, security, inspectability — not sermons.
- Remaining capable of **conflict and hesitation**.

It would **not** recognise: a personal AGI; a complete archive of the self; carbon offsets for tokens; “AI will dematerialise knowledge work”; a knowledge graph as parlement des choses.

### How an agent should use this file

Do not treat this as a feature backlog. Treat it as a **filter**.

Before proposing a new occupancy, pivot, index, model, or always-on worker, answer:

1. Which of the three jobs is this (ecodesign / IT-for-green / redirection)?
2. Which giant does it stand on (runtime, vendor, mix, metal, imaginary)?
3. Can it be named, inspected, budgeted, and **stopped**?
4. Does it age someone else’s hardware or attention?
5. What would the authoritarian board and the commons board do to it?
6. Is this closing something, or only adding?
7. Are you quoting a 2021 figure as if it were 2026? If yes, stop.

If the answer to 3 is no, or to 6 is “only adding,” the mémoire’s compass says refuse or rarefy. If you only have a carbon widget, you are in chapter 2’s managerial trap.

Humans: the 166-page v06 PDF is still the place for figures, workshop boards, and the tone of the original. This file is the operator you can carry into a project.

---

That is the compass. The 166 pages remain the terrain.

---

## Conflict, maps, care (pointer)

Chapter 1 already carries 5G sabotage, cartographic ambivalence, and care/maintenance. Do not treat those as a later optional appendix. They are the political body of *numérique situé*. The later field notes (workshop, Brazil mining map, Weever ontology) are instances of the same operator: **map or be mapped**; documentation is never only documentation.

---

## How the survey was actually done (methods as compass)

Already stated in the annex field: measure to sensitise at organisation scale (Labos 1point5 reflexivity: the inquirer is in the inventory); to have a baseline knowing it will be attacked; to make the invisible speakable without completeness. LCA of Weever rejected. Compromise: Annexe 2 spine + inventory + static infographic + `ecowetrics` CLI. Annexe 3 is 2021 shopping, not 2026 truth.

Compass: a personal environment needs something *like* that entry point for **what runs** (processes, models, exports) more than another carbon widget on a webpage.

---

## Rebound, induced effects

Direct: efficiency spent on more of the same. Indirect: re-spending. Structural: markets, purchasing power. Digital extras: time saved → more digital; telework and videoconferencing as **impact transfers**; 5G as mandatory device replacement. Induced effects: digital changes other sectors’ metabolisms in ways LCA of “a page” will never see.

Compass: an agent that “saves time” so you can run more agents is a textbook rebound. Budget and `stop-agent` are anti-rebound devices. So is not wrapping every note in a model.

---

## Green IT / IT for Green / neighbouring names

Flipo’s split remains the cleanest. Neighbouring research the annex listed so the author would not pretend to have invented a field: environmental informatics, computational sustainability, sustainable HCI, ICT for sustainability, benign computing, collapse informatics, permacomputing, small technology, salvage computing, low-tech (de Valk 2021).

Compass: if you build at home scale, you are closer to permacomputing / salvage / small tech than to “AI for SDGs.” Do not steal the latter’s prestige. Do not romanticise collapse. Méliorist: work the stack you inherit.

---

## Figures in the mémoire (what they were)

The formatted PDF is image-heavy (cover of ecometrics source; Bonnet et al. zombie/living table; Halloy power-transition schematic; SDG wedding cake; Roussilhe/Bordage emission splits; activity diagrams from interviews; Weever hosting boxes; ecometrics UI; EcoIndex HTML dumps; SSP affinity cards; game boards). This compass **does not reprint them**. They are in v06. Several are **period photographs** (EcoIndex 22/11/2021, 49 pictograms, France 38 g). The redirection strategy diagram (Bonnet et al. 2021, p. 86) and the zombie/living characteristics table (p. 21) are the ones still worth opening the PDF for.

---

## Sequence of versions (for the archive of this work)

- 2021 drafts: Mémoire-v01…v13.odt, Compte-rendu V01–V05.
- 4 Dec 2021: InDesign PDF 122 pages (earlier layout).
- 3 Jan 2022: unformatted PDF 237 pages + matching ODT.
- 8 Jan 2022: ODT v02.
- 12 Jan 2022: formatted PDF v05 (165 p.).
- **14 Jan 2022: formatted PDF v06 (166 p.) — complete designed submission.**
- **21 Jan 2022: ODT v03 — same structure, working copy slightly later.**

If a citation is needed: Michalet, P. (2022). *Standing on the Shoulders of Giant Zombies*. Mémoire MSc Strategy and Design for the Anthropocene.

---

## Last compass list (actionable)

1. Name the giant (runtime, vendor, mix, metal, imaginary).
2. Say which job you are doing (ecodesign / IT-for-green / redirection).
3. Prefer situation (machine, path, jurisdiction) to spectrum (Cloud, “the model”).
4. Measure for inquiry and rarefaction, not for a cockpit.
5. Treat software as something that ages other people’s hardware.
6. Close what is unsustainable; do not only add greener features.
7. Keep hostile scenarios in the kit; do not only play commons.
8. Sobriety is a political *assez*, not a dark-mode toggle.
9. Documentation maps ontologies; someone will be mapped.
10. Generative occupancies are new zombies until proven otherwise: inspect, budget, stop.
11. Diplomat: ally metabolic cost with maintainability and security.
12. Stay méliorist, prudent, capable of hesitation.

---

## Closing

The 2021 dissertation is complete in the formatted 166-page PDF (v06) and the v03 ODT. Its centre is not a number. It is a **stance**: disillusioned about Green IT, neither technolater nor technophobe, committed to situated digital, to measurement-as-inquiry, to imaginaries that do not replace politics, and to redirection as heritage and closure.

The giants have grown a new head (generative models). The shoulders are still bone and diesel and drought. Standing on them, the work is to decide what to keep walking, what to stop feeding, and what knowledge practice is still worth the metabolic cost.

This file is only the compass. The 166 pages remain the terrain.
