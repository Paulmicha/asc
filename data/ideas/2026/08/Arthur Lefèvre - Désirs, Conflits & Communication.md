# Arthur Lefèvre \- Désirs, Conflits & Communication

## une approche ludo-narrative du jeu de rôle

[https://chatgpt.com/share/6a7c6cce-5a5c-83e9-babc-db3d9e002307](https://chatgpt.com/share/6a7c6cce-5a5c-83e9-babc-db3d9e002307)

Arthur Lefèvre’s 2020 thesis, ***Désirs, Conflits & Communication : une approche ludo-narrative du jeu de rôle***, is much more interesting for AI-agent theory than its subject matter initially suggests. Its central contribution is not really a theory of role-playing games; it is a theory of **autonomous action emerging from an asymmetric dialogue between an agent and an environment that is itself capable of responding, remembering, constraining, and changing**. That makes it a potentially powerful conceptual bridge between role-playing, complex systems, interactive narrative, and agent autonomy.

The thesis starts from a deliberately non-trivial conception of tabletop RPGs. A role-playing game is not fundamentally a story being told by one person to others. It is a **communication loop** between two functional voices: the players, who decide, and the game master (*meneur*), who describes and resolves. The basic loop is therefore:

       WORLD / CONTEXT  
             │  
             ▼  
       \[ DESCRIPTION \]  
             │  
             ▼  
          PLAYER  
             │  
        intention \+  
          means  
             │  
             ▼  
        \[ DECISION \]  
             │  
             ▼  
          GM / WORLD  
             │  
          resolution  
             │  
             ▼  
       \[ CONSEQUENCE \]  
             │  
             └──────────► new description

The important point is that **none of the three stages has meaning independently**. Description creates the decision space; decision expresses an intention using available means; resolution transforms the context and thereby determines what can be described next. The result is not a predetermined narrative but a continually modified state of the shared world.

### **1\. The decisive concept: autonomy comes from the loop, not from isolated decision-making**

This is where the thesis becomes highly relevant to AI agents. Lefèvre explicitly distinguishes the **player's intention** from the **character's means**. The intention comes from the player's desire; the means belong to the character's situation within the fictional world. The player therefore does not select an action from a closed API of possibilities. They formulate an intention, and the world determines what means exist and what consequences follow.

This is almost the inverse of the dominant tool-calling model of agents:

Typical tool-oriented agent

goal  
  ↓  
choose tool  
  ↓  
tool(parameters)  
  ↓  
result  
  ↓  
LLM

Lefèvre suggests something closer to:

agent desire  
     ↓  
interpret current situation  
     ↓  
form intention  
     ↓  
propose action using situated means  
     ↓  
environment resolves action  
     ↓  
observe transformed environment  
     ↓  
reinterpret situation  
     ↓  
new intention

The distinction matters enormously. **Autonomy is not simply the capacity to choose among available actions. It is the capacity to formulate intentions against an incompletely known, resistant world whose response modifies the subsequent action space.** That is a much richer definition of agent autonomy than "LLM \+ tools."

**Confidence: 0.95** — this interpretation follows directly from the thesis's description/decision/resolution model, although the application to AI is my extrapolation rather than Lefèvre's own subject.

---

### **2\. The world is not a database; it is an interlocutor**

One of the strongest ideas in the thesis appears in the treatment of the *meneur*. Lefèvre describes the game master as an **institution**: a structure produced by the collective of players which subsequently acquires a relative autonomous power over them. More importantly, the world prepared by the game master is not merely a collection of possibilities. It is conceived as **"un monde à affecter"** — a world that the players can affect.

This provides a very useful reinterpretation of agent environments.

A conventional agent architecture tends to represent its environment as:

STATE  
 ├── objects  
 ├── resources  
 ├── available tools  
 └── constraints

Lefèvre's conception is closer to:

             WORLD  
        ┌───────┼────────┐  
        │       │        │  
     objects  actors   rules  
        │       │        │  
        └── relationships ┘  
                 │  
          latent possibilities  
                 │  
             tensions  
                 │  
          consequences

An environment becomes interesting for autonomy when it contains **things that want things**. In the thesis, NPCs and factions are therefore not merely data structures. Their desires collide with those of the players, and those collisions generate scenes. The complexity of the world consequently depends less on how many objects it contains than on **how many interacting desires and relations it contains**.

That is an important architectural distinction for AI agents:

> **An autonomous agent needs an environment with affordances, constraints and competing dynamics—not merely a large tool catalogue.**

**Confidence: 0.93.**

---

### **3\. The environment should be generative rather than completely specified**

Perhaps the most interesting passage for agent architecture concerns incomplete information. Lefèvre argues that the game world's information cannot and should not be completely enumerated. The framework establishes a generative structure from which details can be produced when they become relevant. The game master may even create parts of the environment in response to the unfolding campaign.

This has a direct correspondence with **open-ended agent environments**.

A naive architecture attempts to maintain:

complete world model  
        ↓  
perfect planning  
        ↓  
action

The Lefèvre model implies:

partial world model  
       ↓  
current situation  
       ↓  
desire / intention  
       ↓  
action  
       ↓  
new information  
       ↓  
world-model revision  
       ↓  
new possibilities

The unknown is therefore not simply a deficiency in the agent's knowledge. **It is structurally productive.**

This is especially important because much current agent design treats uncertainty as something to eliminate through retrieval, tool calls, or increasingly comprehensive context. Lefèvre's model suggests a different principle: **a useful degree of incompleteness is constitutive of autonomy because it creates the need for exploration, interpretation and action.**

**Confidence: 0.94.**

---

### **4\. The "present" is an operational concept for agents**

Another unusually powerful idea is Lefèvre's treatment of time. Every decision happens in a **shared present**. The past supplies the conditions of the current decision; the future remains genuinely uncertain because it depends on the decision and its resolution. Each loop therefore transforms the context for the next loop. The apparent cyclicity of the loop produces a non-cyclic historical process because the world is permanently altered by each iteration.

This gives a much better model for an agent loop than:

observe → think → act → repeat

because "observe" is not passive observation of an immutable world.

Instead:

      PAST  
        │  
        ▼  
  current state  
        │  
        ▼  
 interpretation  
        │  
        ▼  
   intention  
        │  
        ▼  
     action  
        │  
        ▼  
 environmental  
 transformation  
        │  
        ▼  
 NEW PRESENT  
        │  
        └──────► interpretation

The key is the **irreversibility of contextual transformation**. A good agent should not simply repeat a planning cycle against the same state representation. Each action should change the semantic conditions under which future actions become intelligible.

This resonates strongly with your earlier interest in **Donella Meadows, complex systems, and agent autonomy**: the agent is not merely optimizing inside a state-space; it is participating in the production of the state-space in which its subsequent optimization takes place.

**Confidence: 0.92.**

---

### **5\. Desire → quest → scene → campaign gives a hierarchy of agency**

Lefèvre does not stop at the atomic loop. He builds a hierarchy:

DESIRE  
  │  
  ▼  
QUEST  
  │  
  ▼  
SCENES / CONFLICTS  
  │  
  ▼  
DECISIONS  
  │  
  ▼  
RESOLUTIONS  
  │  
  ▼  
CONSEQUENCES  
  │  
  └──────────────┐  
                 ▼  
             CAMPAIGN  
                 │  
                 ▼  
        transformed character  
        \+ transformed world

A desire is not yet an action. It becomes a **quest**, which organizes a sequence of possible scenes. Each scene confronts different desires. Resolution progressively reduces the space of possible futures until one becomes actual. Lefèvre describes this explicitly as a movement from **virtuality toward actuality**: success and failure initially constitute a space of possible scenarios, and each resolved scene progressively contracts that space.

This is highly relevant to long-running agents because it suggests that **goals should exist at multiple temporal scales**.

Instead of:

user request → task → completion

one could have:

values / persistent drives  
        ↓  
long-term objectives  
        ↓  
current quests  
        ↓  
situational intentions  
        ↓  
actions  
        ↓  
observations  
        ↓  
revised quests

The agent's autonomy would then reside partly in its ability to **transform intentions into intermediate quests**, rather than waiting for a human to specify every subtask.

**Confidence: 0.96.**

---

## **6\. The most important reinterpretation: autonomy is relational**

The thesis's deepest contribution, in my reading, is that **autonomy is not independence**.

The *meneur* is autonomous in one sense: it has its own desires, preferences and way of interpreting the world. But its function exists only through its relation with the players. It is simultaneously **produced by the collective and capable of subsequently affecting that collective**. Lefèvre explicitly describes this institutional structure as a power that is produced by the collective and then affects it as an autonomous force.

This gives us a very different definition of agent autonomy:

> **An autonomous agent is not an entity that stops depending on external input. It is an entity whose internal dynamics can transform external input into new constraints, possibilities, priorities and actions, thereby altering the future interaction itself.**

That is much closer to **relational autonomy** than to classical notions of independent execution.

For multi-agent systems this becomes even more interesting:

       Agent A  
       desires A  
           │  
           ▼  
       interaction  
           │  
     ┌─────┴─────┐  
     ▼           ▼  
 Agent B       WORLD  
desires B     dynamics  
     │           │  
     └─────┬─────┘  
           ▼  
      transformed  
       situation  
           │  
           ▼  
   new desires / goals

The intelligence of the system is therefore partly **between agents**, not exclusively inside them.

**Confidence: 0.96.**

---

## **7\. The thesis also provides a critique of current "agent" architectures**

There is a particularly revealing argument concerning *metagaming*. Lefèvre criticizes systems where the game master attempts to determine what a player is "allowed" to decide based on what the character supposedly knows. His argument is that this can destroy the fundamental sovereignty of the player: the player is precisely the entity responsible for deciding what the character attempts. The system should provide information and consequences, not secretly take over the decision.

Translated into AI:

**Environment should constrain action through consequences rather than through excessive pre-filtering of intention.**

Bad agent architecture:

LLM proposes X  
     ↓  
policy says "X isn't allowed"  
     ↓  
X disappears

More interesting architecture:

LLM proposes X  
     ↓  
environment evaluates X  
     ↓  
constraints \+ uncertainty \+ consequences  
     ↓  
resolution  
     ↓  
agent observes what actually happened

This preserves the agent's **sovereignty of intention** while preserving the environment's **sovereignty of consequence**.

That distinction could be extremely useful for designing agents that are allowed to be genuinely autonomous without being allowed to violate system boundaries.

---

## **8\. Drama, karma and fortune are three different kinds of agent environment**

The thesis distinguishes three fundamental modes of resolution:

* **Drama** — the authority decides what happens.  
* **Karma** — the result follows from the adequacy of the means.  
* **Fortune** — the result is determined by chance.

Lefèvre explicitly connects these modes to the larger genres of scenes, quests and campaigns.

For AI agents, this becomes a useful taxonomy of **environmental causality**:

| Environment | Resolution | Agent consequence |
| ----- | ----- | ----- |
| **Authoritative** | external decision | agent negotiates with an authority |
| **Causal** | action follows world mechanics | agent learns the world's regularities |
| **Stochastic** | probability/randomness | agent manages uncertainty |
| **Hybrid** | combination | agent must infer which regime applies |

This is important because an agent's autonomy depends heavily on whether its environment is **predictable, negotiable, stochastic, or opaque**.

A tool returning deterministic JSON is a karma-like environment.

A human approving a request is closer to drama.

A financial market is closer to fortune plus karma.

A social organization is a hybrid of all three.

The architecture of the agent should differ accordingly.

**Confidence: 0.94.**

---

## **9\. "The game master as institution" could become an architecture for agentic orchestration**

This is perhaps the most concrete reinterpretation.

Lefèvre's *meneur* performs several functions simultaneously:

                 MENEUR  
                    │  
       ┌────────────┼────────────┐  
       ▼            ▼            ▼  
   maintains     resolves      exposes  
   context       conflicts     information  
       │            │            │  
       └────────────┼────────────┘  
                    ▼  
             transforms world  
                    │  
                    ▼  
             next decision

He is therefore neither simply:

* a planner,  
* a tool executor,  
* a narrator,  
* a memory system,  
* nor a controller.

He is the **institutional layer connecting agent desires to environmental consequences**.

That maps surprisingly well onto an architecture for autonomous agents:

┌─────────────────────────────────────────┐  
│             AGENT / DESIRE               │  
│ goals · values · intentions · memory     │  
└───────────────────┬─────────────────────┘  
                    │  
                    ▼  
┌─────────────────────────────────────────┐  
│          INTERACTION / DECISION          │  
│ interpret situation → formulate action   │  
└───────────────────┬─────────────────────┘  
                    │  
                    ▼  
┌─────────────────────────────────────────┐  
│        INSTITUTIONAL ENVIRONMENT         │  
│ rules · norms · actors · resources       │  
│ hidden state · causal dynamics           │  
└───────────────────┬─────────────────────┘  
                    │  
                    ▼  
┌─────────────────────────────────────────┐  
│              RESOLUTION                  │  
│ causal · stochastic · negotiated          │  
└───────────────────┬─────────────────────┘  
                    │  
                    ▼  
┌─────────────────────────────────────────┐  
│          UPDATED SHARED WORLD             │  
│ new facts · new constraints · new goals  │  
└───────────────────┬─────────────────────┘  
                    │  
                    └──────────► next loop

This is much closer to a **complex adaptive system** than to an LLM wrapped in a while-loop.

---

## **10\. The thesis's "theory-practice" relationship is itself relevant to agents**

There is one final idea that deserves particular attention given your previous questions about agent frameworks.

Lefèvre argues that RPG theory is not simply an abstract description imposed on practice. The community's accumulated practice becomes theory, and that theory subsequently modifies practice. The manual itself becomes a kind of **compressed institutional memory of previous play**: an "arsenal" of tested arbitration forms and an encyclopedia of worlds already played and made playable.

That suggests an important agent principle:

experience  
    ↓  
reflection  
    ↓  
abstraction  
    ↓  
policy / skill / model  
    ↓  
future action  
    ↓  
new experience

This is considerably richer than ordinary episodic memory.

An agent that merely stores:

> "I previously did X."

has memory.

An agent that derives:

> "In situations of type X, strategy Y tends to work because of structural condition Z."

has **praxis**.

And an agent that subsequently modifies its own operating procedures from that abstraction begins to resemble Lefèvre's theory-practice cycle.

This connects directly to the kind of **agent self-improvement through reflection, skill formation, and environmental feedback** that you have been examining in other contexts.

**Confidence: 0.95.**

---

# **The resulting reinterpretation of AI-agent autonomy**

The thesis can therefore be compressed into a surprisingly strong alternative model:

                ┌─────────────────────┐  
                 │  PERSISTENT DESIRES  │  
                 │ values / objectives  │  
                 └──────────┬──────────┘  
                            │  
                            ▼  
                  ┌──────────────────┐  
                  │      QUESTS      │  
                  │ temporal projects│  
                  └────────┬─────────┘  
                           │  
                           ▼  
                ┌─────────────────────┐  
                │ CURRENT SITUATION   │  
                │ incomplete context  │  
                └─────────┬───────────┘  
                          │  
                     interpret  
                          │  
                          ▼  
                ┌─────────────────────┐  
                │     INTENTION       │  
                │ "what I want to do" │  
                └─────────┬───────────┘  
                          │  
                    situated means  
                          │  
                          ▼  
                ┌─────────────────────┐  
                │       ACTION        │  
                └─────────┬───────────┘  
                          │  
                     WORLD RESOLUTION  
                          │  
             ┌────────────┼────────────┐  
             ▼            ▼            ▼  
           causal      stochastic    social  
             │            │            │  
             └────────────┼────────────┘  
                          ▼  
                ┌─────────────────────┐  
                │  CHANGED WORLD      │  
                │ new facts, tensions │  
                │ possibilities       │  
                └─────────┬───────────┘  
                          │  
                    reinterpretation  
                          │  
                          ▼  
                   NEW PRESENT  
                          │  
                          ▼  
                     NEW QUESTS

The conceptual shift is substantial:

**Current agent paradigm**

> autonomy \= ability to independently execute a plan.

**Lefèvre-inspired paradigm**

> autonomy \= ability to maintain and transform a trajectory of desires through continuous interaction with a partially known, resistant, institutionally structured environment.

The second definition makes autonomy **emergent, relational, temporal and situated**.

It also explains why an agent can become more autonomous without necessarily becoming less dependent on its environment. In fact, the opposite may be true: **the richer the environment's resistance, memory, actors, norms and causal structure, the more meaningful the agent's autonomy becomes.**

---

## **The most interesting connection with your earlier agent research**

Placed alongside the concepts we have discussed around **Meadows, Morin, Le Moigne, Lévy, Monnin and Csikszentmihalyi**, Lefèvre supplies something that those perspectives do not quite provide by themselves:

| Perspective | Main contribution to agents |
| ----- | ----- |
| **Meadows** | where intervention changes system behavior |
| **Morin** | recursive organization, autonomy/dependence, complexity |
| **Le Moigne** | modeling an evolving system rather than merely representing it |
| **Lévy** | collective intelligence / distributed cognitive production |
| **Monnin** | technological trajectories, redirection, infrastructural constraints |
| **Csikszentmihalyi** | adaptive matching between challenge and capability |
| **Lefèvre** | **how autonomous agency is produced through recursive desire → action → consequence → reinterpretation within a shared world** |

That makes Lefèvre particularly valuable as a **micro-theory of agency** within the broader complex-systems picture.

And there is a striking consequence: **the "agent" may not be the LLM at all.**

The more faithful abstraction would be:

            ┌──────────────────────────┐  
             │       AGENT SYSTEM       │  
             │                          │  
             │  desires                 │  
             │  memory                  │  
             │  interpretation          │  
             │  intentions              │  
             └────────────┬─────────────┘  
                          │  
                    ↕ recursive dialogue  
                          │  
             ┌────────────┴─────────────┐  
             │     WORLD / INSTITUTION  │  
             │                          │  
             │  constraints             │  
             │  affordances             │  
             │  other agents            │  
             │  hidden state            │  
             │  norms                   │  
             │  causal dynamics         │  
             └──────────────────────────┘

**Autonomy is a property of the coupling**, not merely of the model inside the upper box.

That is, in my assessment, the thesis's most valuable reinterpretive potential for AI agents.

**Overall confidence: 0.94.** The thesis-derived concepts are strongly grounded in the uploaded text; the AI-agent architecture and terminology are analytical extrapolations rather than claims made by Lefèvre himself.

