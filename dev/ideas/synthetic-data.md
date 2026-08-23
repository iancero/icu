# synthetic data — schema-faithful fake data for AI code development

**Status:** backlog — design discussion needed; downstream of codebook_md().
Deliberately NOT part of create_project(). No function name yet.
**Proposed file:** R/synthetic.R (placeholder)
**Depends on:** codebook-md.md — by design, this should consume the
codebook (schema) rather than the data. See "Safety by construction".

## Motivation

In the chat AI workflow, Claude writes code against data it never sees. A
synthetic dataset with the same columns, types, and levels lets Claude
*run and test* that code — catching errors before the code touches real
data — instead of writing it blind against the codebook alone.

Structural fidelity is the goal: names, types, factor levels, labelled
codes. Distributional fidelity is explicitly NOT a goal — this is for
"does the pipeline run", not "do the estimates resemble anything".
Simulation-quality synthesis is a different, much harder problem and out
of scope.

## Safety by construction

The naive version is dangerous: resampling real values into shuffled fake
rows *is* disclosure (real values, real uniques, real rare levels — just
reordered). The design principle that prevents an entire class of leaks:

**The generator consumes the codebook, not the data.** If the function
never touches real values, it cannot leak them. Numeric columns get
arbitrary plausible-typed values (e.g. standard normal, or 0–100
integers — it does not matter); factors sample from the codebook's listed
levels; labelled columns sample from the label codes; free-text columns get
lorem-style filler; dates get an arbitrary fixed range. Everything
inherits codebook_md()'s conservatism for free — a level the codebook
excluded as rare/identifying never appears in the synthetic data either.

Corollary: this function is only as good as the codebook, and that is a
feature — one artifact to audit for safety, not two.

## Open questions

1. Input: the codebook .md file (parse it), or a schema object that
   codebook_md() also returns invisibly (cleaner — parsing markdown is
   fragile; lean the shared-object design, which affects codebook_md()'s
   return-value spec and should be decided there).
2. Output: data frame return vs. write a csv into `ai/`? Chat workflow
   needs a pasteable/attachable file; Claude Code workflow wants a file
   too. Lean: return the df AND offer a write path.
3. Row count argument (default ~100?), and a seed argument for
   reproducibility (house randomness-testing rules apply).
4. Missingness: inject NAs so na.rm handling gets exercised? Lean yes —
   pipeline-testing is the purpose, and NA handling is where pipelines
   break. Rate/argument design TBD.
5. Name: `synthetic_data()`? `fake_data()`? Decide at design time; check
   conflicts (note `synthpop`, `fabricatr`, `simstudy` exist as prior art —
   review whether any is worth wrapping vs. the from-codebook approach,
   though none consumes a redaction-first codebook, which is the actual
   requirement here).

## Validation (per package conventions)

- Strict on parameters (n, seed, paths). Schema/codebook input validated
  per whatever open question 1 resolves to.

## Testing notes

- Randomness rules per house convention: probability-1 facts only (column
  names/types/levels match schema; n rows; values within declared level
  sets; NA injection present when enabled) plus one set.seed
  reproducibility test. Never distributional tests.
- The safety contract is testable as a negative: construct a schema from a
  fixture whose codebook excluded a known real value/level; assert that
  value can never appear (it isn't in the schema, so assert generation
  draws only from schema contents).
