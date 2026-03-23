# GitHub Issue #2: docs: improve README to explain EderaON and repository purpose

**Issue:** [#2](https://github.com/edera-dev/on/issues/2)
**Status:** Reviewed (Approved)
**Date:** 2026-03-23

## Problem Statement

The current README is three lines long and provides no useful context to visitors:

```markdown
# Edera On

Community hub for Edera On.
```

### Current Behavior

- Visitors to https://github.com/edera-dev/on have no idea what EderaON is
- No explanation of what the repository is used for
- No links to the product website or documentation
- The name "Edera On" (spaced) is inconsistent with the product name "EderaON"

### Expected Behavior

- README clearly explains what EderaON is
- README explains what this GitHub repository is for (community hub: issues, bug reports, announcements)
- README links to on.edera.dev for sign-up and getting started
- README links to docs.edera.dev for full technical documentation
- No internal codename language (e.g. "Project Trellis") present
- Product name consistent: "EderaON" throughout

## Current State Analysis

### Relevant Files

- `README.md` — the only file in the repo (3 lines, needs full replacement)
- Content source: `~/git/edera-dev/on-site/main/content/what-is-ederaon.md` — authoritative product description
- Content source: `~/git/edera-dev/on-site/main/content/getting-started.md` — installation overview

### Key Content from on-site

From `what-is-ederaon.md`:

> EderaON is a free-to-use, single-node tier of Edera, designed to give security
> and platform teams hands-on experience with hardened container runtime protection.
> Edera isolates containers using the Xen hypervisor instead of relying on shared
> kernel namespaces. Each container runs in its own lightweight virtual machine
> (zone), providing hardware-level isolation that prevents container escapes.

What users get:
- One-node license valid for 12 months
- Edera runtime with Xen-based container isolation
- Access to Edera container images via `images.edera.dev`
- Community support via GitHub Issues

### Internal Codename Risk

No occurrences of "Project Trellis" or "Trellis" were found in the repository.
The updated README must not introduce this language.

## Solution Design

### Approach

Replace the existing README with a concise, informative document structured around
the two questions every visitor asks:

1. **"What is EderaON?"** — Product description drawn from on-site content
2. **"What is this repository for?"** — Community hub explanation with links to file issues

Keep it short. The website (on.edera.dev) and docs (docs.edera.dev) carry the
detailed content. The README's job is orientation and navigation.

### Trade-offs Considered

- **Long README vs short README:** Chose short — detailed docs live at docs.edera.dev.
  Duplicating install instructions here would create a maintenance burden and drift.
- **Platform table in README:** Omitted — it changes frequently and belongs on the website.
- **Technical depth:** Kept to one paragraph — the Xen/hypervisor detail is important
  for setting expectations but installation detail belongs on the website.

## Implementation Plan

### Step 1: Replace README.md

**File:** `README.md`

**Changes:** Replace the entire file with the following content:

```markdown
# EderaON

EderaON is a free-to-use, single-node tier of [Edera](https://edera.dev),
designed to give security and platform teams hands-on experience with hardened
container runtime protection.

Edera isolates containers using the [Xen hypervisor](https://xenproject.org/)
instead of relying on shared kernel namespaces. Each container runs in its own
lightweight virtual machine (zone), providing hardware-level isolation that
prevents container escapes from reaching other workloads or the host.

EderaON gives you a one-node license valid for twelve months to install and
evaluate this technology on your own infrastructure.

## What you get

- **One-node license** valid for twelve (12) months
- **Edera runtime** with Xen-based container isolation
- **Access to Edera container images** via `images.edera.dev`
- **Community support** via [GitHub Issues](https://github.com/edera-dev/on/issues)

## Getting started

Visit [on.edera.dev](https://on.edera.dev) to create an account and get your
license. Full installation instructions are at
[on.edera.dev/getting-started](https://on.edera.dev/getting-started).

## About this repository

This repository is the community hub for EderaON. Use it to:

- [Report bugs or installation issues](https://github.com/edera-dev/on/issues/new)
- [Browse known issues](https://github.com/edera-dev/on/issues)
- Follow EderaON announcements and releases

For full technical documentation, see [docs.edera.dev](https://docs.edera.dev).
```

## Testing Strategy

### Manual Verification

**Test Case 1: Content completeness**

Read the new README and verify each acceptance criterion:

- [ ] "What is EderaON?" is answered in the opening paragraphs
- [ ] "What is this repository for?" is answered in the "About this repository" section
- [ ] Link to on.edera.dev present
- [ ] Link to on.edera.dev/getting-started present
- [ ] Link to docs.edera.dev present
- [ ] No internal codename language ("Project Trellis", "Trellis")
- [ ] Product name is "EderaON" (no space) consistently

**Test Case 2: Pre-commit hooks pass**

```bash
pre-commit run --all-files
```

Expected: all hooks pass (markdownlint, prettier, trailing-whitespace, etc.)

**Test Case 3: Links are valid**

Verify all URLs in the README are reachable:
- https://edera.dev
- https://xenproject.org/
- https://on.edera.dev
- https://on.edera.dev/getting-started
- https://github.com/edera-dev/on/issues
- https://github.com/edera-dev/on/issues/new
- https://docs.edera.dev

## Success Criteria

- [ ] README clearly answers "what is EderaON?"
- [ ] README clearly answers "what is this repository for?"
- [ ] README links to on.edera.dev for account creation and getting started
- [ ] README links to docs.edera.dev for full documentation
- [ ] No internal codename language present
- [ ] Product name "EderaON" used consistently (no "Edera On" spacing)
- [ ] Pre-commit hooks pass
- [ ] PR created and linked to issue #2

## Files Modified

1. `README.md` — full replacement with informative community hub README

## Related Issues and Tasks

### Related

- Issue #2: https://github.com/edera-dev/on/issues/2
- Content source: edera-dev/on-site `content/what-is-ederaon.md`

### Enables

- Visitors to github.com/edera-dev/on understand the product immediately
- Community members know where to file issues and find help

## References

- [GitHub Issue #2](https://github.com/edera-dev/on/issues/2)
- [EderaON website](https://on.edera.dev)
- [What is EderaON? (on-site)](https://on.edera.dev/what-is-ederaon)
- [Edera Docs](https://docs.edera.dev)

## Notes

### Key Insights

- The README heading should be "EderaON" (camelCase, no space) to match the product brand
- Content should be sourced from on-site, not invented — ensures consistency with the website
- Keep README short: the website carries detail; the README provides orientation
- No internal codenames: "Project Trellis" was an internal name and must not appear publicly

### Alternative Approaches Considered

1. **Copy full what-is-ederaon.md content** — Too long; platform table changes
   frequently and the Hugo shortcodes don't render in GitHub markdown ❌
2. **Add installation instructions** — Creates maintenance burden; getting-started page
   on the website is the canonical source ❌
3. **Short orientation README linking to website** — Chosen: concise, maintainable,
   answers the two key questions visitors have ✅

## Plan Review

**Reviewer:** Claude Code (workflow-research-plan)
**Review Date:** 2026-03-23
**Original Plan Date:** 2026-03-23

### Review Summary

- **Overall Assessment:** Approved
- **Confidence Level:** High
- **Recommendation:** Proceed to implementation

### Strengths

- Plan is tightly scoped to exactly what the issue asks for — no scope creep
- Content sourced from `what-is-ederaon.md` is accurate; every sentence in the
  proposed README maps directly to verified source content
- Trade-offs are well-reasoned and explicitly documented (no platform table,
  no install instructions, short over long)
- Codename risk is proactively addressed; grep of both repos confirms zero
  occurrences of "Project Trellis" or "Trellis"
- "EderaON" (camelCase, no space) used consistently in proposed content —
  confirmed consistent with on-site source (7 occurrences, all "EderaON")
- The "About this repository" section is a genuinely useful addition that the
  source content doesn't have; appropriate original content for a GitHub README

### Gaps Identified

None blocking. One optional wording note below.

### Edge Cases Not Covered

None applicable — this is a pure documentation change with no logic paths.

### Alternative Approaches Considered

Plan's alternatives section is thorough. Independent review agrees with all
three decisions:

1. **Full what-is-ederaon.md copy** — Hugo shortcodes (`{{< callout >}}`,
   `{{< tabs >}}`) would render as raw text on GitHub. Correct to omit. ❌
2. **Install instructions in README** — Getting-started page will evolve
   (image digest, new distros); duplicating it here would immediately drift. ❌
3. **Short orientation README** — Correct choice. ✅

### Risks and Concerns

1. **Risk: URLs become stale**
   - Likelihood: Low
   - Impact: Low (broken links in README are visible and quickly reported)
   - Mitigation: All URLs point to stable top-level domains (on.edera.dev,
     docs.edera.dev, edera.dev, xenproject.org, github.com) — not versioned
     paths or deep links that could move.

### Required Changes

None. Plan is ready to implement as written.

### Optional Improvements

- [ ] Minor wording consistency: the source `what-is-ederaon.md` prose (line 16)
  says "single-node license" while the plan prose uses "one-node license". Both
  forms appear in the source (the bullet uses "One-node license"), so either is
  correct. Consider aligning with the bullet form ("one-node") which the plan
  already uses — no change required, just noting for awareness.

### Verification Checklist

- [x] Solution addresses root cause identified in GitHub issue
- [x] All acceptance criteria from issue are covered
- [x] Implementation steps are specific and actionable
- [x] File paths and code references are accurate
- [x] Security implications considered (no secrets, no user input, static markdown)
- [x] Performance impact assessed (N/A — static file)
- [x] Test strategy covers critical paths (content completeness, no codenames, links)
- [x] No breaking changes (additive replacement of minimal content)
- [x] Internal codename scan performed — clean
