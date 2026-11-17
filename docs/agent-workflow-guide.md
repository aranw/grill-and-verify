# Agent runbook: choosing and using Grill-and-Verify

Use this guide when deciding whether a task deserves the full Grill-and-Verify
workflow, which parts to run, and how to carry the work through to a useful
handoff. The canonical pipeline instructions are in
[`skills/grill-and-verify/SKILL.md`](../skills/grill-and-verify/SKILL.md); this
document adds selection guidance and examples so agents apply it where it has
leverage rather than to every change.

To invoke the full workflow, use `/skill:grill-and-verify` in pi or
`/grill-and-verify:grill-and-verify` in Claude Code. If the skill is not
available in the current harness, read the canonical skill and follow its
stages manually.

## What this workflow is for

Grill-and-Verify prepares a design or a risky existing behavior for reliable
implementation. It makes decisions explicit, models relevant user and
system actions, checks promises against that model, and makes failures
understandable as paths through states. It is most valuable when a small
number of ordering, failure, or lifecycle cases can cause serious harm or
expensive rework.

It is **not** a default ceremony for every coding task, a replacement for
unit/integration tests, or a proof that the whole production system is correct.
A model check proves properties only of the model and bounds that were
actually checked.

## Decide whether to use it

First scope the task to one behavior or flow. Ask:

1. **Does behavior span states or steps?** Examples: start, pending, retry,
   cancel, complete; a user leaves while a save is in flight; a session
   expires during a request.
2. **Can events arrive in different orders or without the user's action?**
   Examples: timeouts, retries, duplicate callbacks, offline/online changes,
   another user/device acting, process restart, or late responses.
3. **Would a broken promise cause meaningful harm?** Examples: duplicate
   charges, lost data, unauthorized access, stranded work, or a costly
   migration/rebuild.
4. **Are the important cases hard to cover with ordinary tests?** This is
   often true of races, retries, cancellation, stale state, and combinations
   of external failures.
5. **Is the design still unsettled, so finding a bad path now could prevent
   expensive implementation work?**

A high-impact security, money, safety, or data-loss risk can justify the
workflow by itself. Otherwise, several “yes” answers are a good signal. If
only one narrow question matters, use a single skill rather than the full
pipeline. If none of these apply, use ordinary design discussion and tests.

### Choose full, partial, or no workflow

- **Full pipeline:** A high-impact feature or architecture has meaningful
  state, external events, or unresolved tradeoffs; or existing code has a
  high-cost property that tests may not reach. Use this before implementation
  or before changing the risky behavior.
- **`grill-me` only:** The main risk is unclear requirements or decisions, but
  a formal model would add little. Use it to expose assumptions and settle
  the decision tree.
- **`flow-promises` only:** A new, important flow needs mocks and checked
  promises, but the broader board/handoff loop is unnecessary.
- **`statechart` only:** A TLA+ model already exists, or the need is to inspect
  state transitions and counterexample paths.
- **No Grill-and-Verify:** The change is small, deterministic, reversible,
  well covered by direct tests, and has no consequential ordering or lifecycle
  behavior. Do the normal implementation and tests instead.

If the user asks for only one part, honor that scope. Do not silently expand a
partial request into the full pipeline.

## Good use cases

These examples are intentionally scoped to a flow and its promises, not an
entire product.

### 1. Payment or checkout with retries

**Why it fits:** A timeout may happen after the provider charged the customer
but before the app received confirmation. The user can retry, close the page,
or return later. Incorrect ordering can double-charge or lose the order.

**Possible promises to agree with the product owner:**

- “Retrying a timed-out payment never charges the customer twice.”
- “Leaving checkout does not erase a confirmed order.”
- “The user can tell whether payment is pending, succeeded, or failed.”

Model only the relevant app/provider boundary, callback outcomes, and retry
rules. Do not pretend the model proves the payment provider itself correct.

### 2. Editing with autosave, navigation, and offline recovery

**Why it fits:** Saves can finish out of order; the user may edit again, navigate
away, lose connectivity, or close the app while a request is pending. A happy
path test is unlikely to cover all the orderings.

**Possible promises:**

- “A late save never overwrites a newer edit.”
- “Leaving the editor never silently loses the latest confirmed draft.”
- “When a save fails, the user can recover or retry without re-entering work.”

The model should include pending requests, revisions, failures, navigation,
and the minimum persistent state needed to check those promises.

### 3. Access control, invitations, and revocation

**Why it fits:** Invitations expire, roles change, sessions remain open, and
requests may already be in flight. A mistake can expose data, not merely show
the wrong screen.

**Possible promises:**

- “A revoked user cannot start a new protected action.”
- “An expired invitation cannot grant access.”
- “A role change takes effect at the promised point in an active session.”

Keep the model explicit about the authorization boundary and what an
in-flight operation means. Do not claim to model every identity-provider or
network behavior unless those are represented.

### 4. Background jobs, leases, or distributed work

**Why it fits:** Workers crash, leases expire, duplicate messages arrive, and
retries overlap. The properties are about ownership and ordering, so a state
model can expose paths that example-based tests miss.

**Possible promises:**

- “At most one worker can commit a result for a job.”
- “An expired lease can be recovered without losing completed work.”
- “Canceling a job prevents later side effects, or the product explicitly
  defines which side effects may still complete.”

Bound the model to the coordination protocol and the failure modes that matter.

### 5. Pre-build onboarding or device setup

**Why it fits:** The flow may include permissions, asynchronous setup, denial,
timeouts, app restarts, and alternate entry points. The design is cheaper to
change before implementation.

**Possible promises:**

- “The user can skip optional setup from every relevant step.”
- “Denying a permission does not strand the user.”
- “Returning after the app closes resumes safely or gives a clear restart path.”

Use `flow-promises` to mock the screens and check agreed promises before
building. Do not create an app-driving verification skill until there is an
actual app to drive.

## Bad or low-value examples

These usually do not justify a full formal-model workflow. Use focused tests,
review, or a partial grill instead.

- **Copy, spacing, color, or icon changes.** These are visual/product-quality
  decisions, not state-ordering problems. Use visual review or screenshot
  tests where appropriate.
- **A simple synchronous preference toggle.** If it has no persistence race,
  permissions, or consequential side effect, a small unit or UI test is more
  direct.
- **A pure formatter or validation helper.** For example, formatting a date or
  rejecting an empty field is usually best checked with table-driven or
  property-based tests. Formal workflow overhead is unlikely to pay off.
- **A routine CRUD screen with a straightforward success/error path.** If
  there are no retries, concurrent edits, destructive effects, or tricky
  lifecycle transitions, ordinary integration tests are clearer and cheaper.
- **“Rework the whole app” with no bounded behavior or promise.** This is too
  broad to model. Start by identifying one user journey, one failure mode, and
  the harm to prevent; otherwise grill only the product direction.
- **Trying to prove that a UI is attractive or that all production behavior is
  correct.** A state model cannot judge aesthetics, and a bounded model cannot
  prove behavior it does not represent. Use the right review and test methods
  alongside any formal check.
- **A tiny, already-understood bug with a direct reproducer and regression
  test.** Add the focused test and fix it. Consider formal modeling only if
  investigation reveals a broader race or invariant that the single test
  misses.

“Already has tests” is not, by itself, a reason to skip the workflow; the
question is whether important cases involve behavior the tests cannot
reasonably enumerate. Conversely, a severe bug does not automatically need a
formal model if a direct test fully captures the risk.

## Agent instructions for a full run

### 1. Establish the task boundary

Before grilling, inspect the repository and available documentation yourself.
Facts visible in code, tests, logs, and project docs are the agent's job to
find; reserve questions for product decisions and facts that cannot be
observed.

Write down:

- the user journey or risky behavior in one sentence;
- who or what can act (user, service, timer, another device, process restart);
- the state/data that could be lost, duplicated, exposed, or stranded;
- the point where the behavior starts and the intended end states;
- what is explicitly out of scope.

If the scope still covers several unrelated features, narrow it before
modeling.

### 2. Grill decisions before designing a solution

Run `grill-me` in rounds. Ask the whole current frontier of independent
questions at once, include a recommended answer, and wait for the user's
answers before asking dependent questions. Do not ask the user to look up
facts the agent can discover.

For the full pipeline, explicitly settle:

- the system's user-facing promises (retain the user's wording);
- actions that happen without the user, including success, failure, hanging
  requests, time, app closure, and other actors;
- the scope, entry points, exit points, and data-loss/security consequences.

Do not begin modeling while decisions that affect the model remain open. Do
not treat silence as approval.

### 3. Model and check the smallest useful system

Choose the branch based on the behavior being prepared, not merely whether the
repository contains code:

- **New behavior not built yet:** follow `flow-promises`. Mock every relevant
  screen/state, including loading, empty, failure, saving, and offline states
  where they matter. List candidate promises and get the user's agreement on
  which to check before encoding them. Model user actions and world actions
  separately. Keep mocks and model aligned.
- **Risky behavior already exists in code:** use the target/tool-selection
  guidance in `create-formal-verification-skill`, but first run the check in a
  temporary working area. Pick a property that is both consequential and
  poorly reached by tests. Connect each modeled action to actual code, and be
  honest about what is abstracted away. Do not create a persistent project
  skill yet.

Use the Dockerized checker when available; build `verify-toolbox` once if
needed. Keep constants and bounds small enough to run, but never shrink them
just to hide a counterexample. State the bound and assumptions. Never weaken a
user-approved promise to make the check pass. If a promise is wrong, ask the
user to change it and record why.

For each counterexample, replay the steps in the user's words. Decide whether
the model is inaccurate, the design has a hole, or the promise should change.
Update the model and mocks together where applicable, then rerun **all**
selected promises because one fix can break another.

### 4. Explain the state graph and findings

Use `statechart` to present the reachable flow and the shortest counterexample
path for each broken rule. Label states and actions in user language, not
variable names. Explain any hidden/merged transitions, state limits, or rules
that were not checked. A model-only counterexample is not automatically a
product bug: first confirm each step is possible in the real code or the
intended design.

Update the visual board after each check/fix round if the environment has a
live-board skill. Otherwise, show the same information inline and save a
Markdown handoff beside the design seed. Include the task, settled decisions,
promises/statuses, chart, replayable bug paths, and remaining questions.

### 5. Pass the validation gate before creating skills

Do not package a reusable project-local skill until all of the following are
true:

- every selected promise is checked and has a clear result. If bounds or a
  tool limitation leave one unchecked, report that honestly and do not pass
  the gate or package skills until the scope is revised and checked;
- every break has a counterexample, and every counterexample has been judged
  against the model/code;
- each actionable finding was addressed and rechecked, or the user explicitly
  accepted the remaining break;
- the model represents the agreed design or the code it claims to cover;
- the checker has demonstrated it can fail: use a deliberate broken model for
  a pre-code flow, or a safe scratch variant for existing code when there was
  no natural counterexample.

A useful result can be an actionable finding that changed the design/code, or
confirmation of an important promise with a check that has demonstrated
sensitivity to a violation. If the result is surprising, incomplete, or
untrustworthy, investigate it instead of creating a skill. Preserve the
user's unrelated/uncommitted changes when making any scratch variant; never
leave a deliberate break in product code.

### 6. Create only the reusable skills that apply

Skill generation is last and conditional:

- If the validated property applies to existing code and should be rerun on
  future changes, follow `create-formal-verification-skill`. The generated
  skill must name covered code, assumptions/bounds, and a cheap rerun command,
  and it must catch a deliberate break before handoff.
- If a real app exists and a scripted user-level proof would be valuable,
  follow `create-verification-skill`. Run its launch, doctor, one mapped
  feature, evidence capture, and cleanup end to end. Keep proof artifacts after
  cleanup.
- For a pre-code design, do not generate an app-driving skill yet. Preserve
  the checked design seed and list app-level verification as follow-on work
  after implementation.
- If no useful reusable check emerged, skip skill creation and say why.

Do not create both skills automatically: formal-model verification and
real-app driving solve different problems. Generate only the one(s) that fit
and are useful.

### 7. Handoff

Before concluding, give a plain-language summary of:

- what was checked, the property wording, tool, bounds, assumptions, and
  important omissions;
- which promises hold, which break, and which remain unchecked;
- each finding and its path, resolution, or explicit acceptance;
- where the model, chart, mocks, or reports were saved and the one command to
  rerun the formal check. For pre-code flows, keep the design seed under
  `docs/flows/FLOW/` by default, following `flow-promises`;
- which reusable skills were created, or why generation was skipped;
- acceptance tests to add: one for each promise, plus a replay test for every
  path that changed the design.

Never imply that a bounded model proves the whole application. Once code
changes without rerunning its checks, use the relevant maintenance skill to
reconcile verification with the current code and classify failures as drift
or bugs.

## Quick prompt to hand another agent

> Read [`docs/agent-workflow-guide.md`](agent-workflow-guide.md) and the
> canonical `skills/grill-and-verify/SKILL.md` before preparing this task.
> First decide whether the full workflow, one component, or ordinary tests are
> appropriate, and explain why. If you use the full workflow, keep the scope to
> the consequential behavior, settle decisions before modeling, preserve the
> user's promise wording, validate the formal check before creating any
> project-local skills, and finish with the bounds, findings, artifacts, and
> rerun command. Do not implement the feature until the design and findings
> have been handed back for the user's decision.
