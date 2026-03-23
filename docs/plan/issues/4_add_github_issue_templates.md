# GitHub Issue #4: Add GitHub issue templates

**Issue:** [#4](https://github.com/edera-dev/on/issues/4)
**Status:** Planning
**Date:** 2026-03-23

## Problem Statement

The repository currently has no GitHub issue templates, meaning the "New Issue"
button drops users into a blank text box. Contributors — security and platform
engineers evaluating EderaON — often omit the diagnostic information needed to
triage effectively, resulting in back-and-forth to gather environment details,
version numbers, and reproduction steps.

### Current Behavior

- `issues/new` opens a blank form
- No guidance on what information to include
- Security vulnerability reports would land as public issues alongside bugs

### Expected Behavior

- Contributors are guided through four structured templates:
  - Bug report
  - Feature request
  - Installation / setup help
  - Documentation issue
- Blank issues are disabled
- Security vulnerabilities are redirected to a private disclosure channel
- All fields are optional (contributors are not blocked from submitting)
- Templates link to `on.edera.dev` and `docs.edera.dev` for self-service

## Current State Analysis

### Relevant Files

- `.github/CODEOWNERS` — exists; owners are `@denhamparry` and `@jspeed-meyers`
- `.github/ISSUE_TEMPLATE/` — does not exist
- `SECURITY.md` — does not exist
- `README.md` — currently links to `issues/new` with no template hint

### Repository Context

- **Product:** EderaON — single-node tier of Edera container runtime using
  Xen-based isolation
- **Audience:** Security and platform engineers; comfortable with technical
  detail but benefit from structured prompts
- **Support channel:** GitHub Issues (stated in README)
- **Docs:** `docs.edera.dev` and `on.edera.dev`

## Solution Design

### Approach

Use GitHub's YAML-based issue form templates (`.github/ISSUE_TEMPLATE/*.yml`)
rather than legacy Markdown templates. YAML forms render as proper HTML forms
with labelled fields, dropdowns, and checkboxes, which produce more consistent
and scannable reports than free-text markdown templates.

A `config.yml` disables blank issues and adds a security advisory contact link.
A `SECURITY.md` provides private disclosure instructions.

### Trade-offs

| Approach | Pros | Cons |
|---|---|---|
| YAML forms (chosen) | Structured fields, better UX, optional enforcement | Slightly more verbose to author |
| Markdown templates | Simpler to write | Freeform, no field validation, harder to parse |

### Field Design Principles

- All fields `required: false` — contributors must not be blocked from
  submitting
- Each template opens with a description pointing to docs for self-service
- Environment fields (version, OS, k8s distro) use `textarea` not `input` so
  users can paste multi-line output
- Labels are auto-assigned per template type

## Implementation Plan

### Step 1: Create `.github/ISSUE_TEMPLATE/` directory

No files yet exist in `.github/ISSUE_TEMPLATE/`. Create it by adding the first
template file (directory is implicit).

### Step 2: Create `bug_report.yml`

**File:** `.github/ISSUE_TEMPLATE/bug_report.yml`

Fields (all optional):

- `environment` textarea — EderaON version, host OS/kernel, k8s distro/version
- `steps` textarea — Steps to reproduce
- `expected` textarea — Expected behaviour
- `actual` textarea — Actual behaviour
- `logs` textarea — Relevant logs or error output

Pre-fill description with links to getting-started and docs.

Auto-label: `bug`

### Step 3: Create `feature_request.yml`

**File:** `.github/ISSUE_TEMPLATE/feature_request.yml`

Fields (all optional):

- `problem` textarea — Problem being solved
- `solution` textarea — Proposed solution
- `alternatives` textarea — Alternatives considered
- `context` input — Use case (security team, platform team, etc.)

Auto-label: `enhancement`

### Step 4: Create `installation_help.yml`

**File:** `.github/ISSUE_TEMPLATE/installation_help.yml`

Fields (all optional):

- `step` input — Getting-started step where stuck
- `environment` textarea — Host environment details
- `error` textarea — Error output or logs

Pre-fill description pointing to `on.edera.dev/getting-started`.

Auto-label: `question`

### Step 5: Create `documentation.yml`

**File:** `.github/ISSUE_TEMPLATE/documentation.yml`

Fields (all optional):

- `url` input — URL of the affected page
- `problem` textarea — What is incorrect or missing
- `suggestion` textarea — Suggested improvement

Auto-label: `documentation`

### Step 6: Create `config.yml`

**File:** `.github/ISSUE_TEMPLATE/config.yml`

```yaml
blank_issues_enabled: false
contact_links:
  - name: Security vulnerability
    url: https://github.com/edera-dev/on/security/advisories/new
    about: >
      Report a security vulnerability privately via GitHub Security Advisories.
      Do not open a public issue for security vulnerabilities.
```

This disables the blank issue option and surfaces a security advisory link
instead of a public issue form.

### Step 7: Create `SECURITY.md`

**File:** `SECURITY.md` (repository root)

Content:

- Scope: what constitutes a security vulnerability in EderaON
- How to report: GitHub Security Advisories (private)
- Response commitment: acknowledgement timeline
- Out-of-scope items

## Testing Strategy

### Manual Verification

**Test 1: Template picker renders**

1. Navigate to `https://github.com/edera-dev/on/issues/new/choose`
2. Confirm four templates are shown
3. Confirm no "Open a blank issue" link appears

**Test 2: Bug report form**

1. Select Bug report template
2. Confirm all fields are present but not required
3. Submit with only title filled in — confirm it succeeds
4. Confirm `bug` label is auto-applied

**Test 3: Security redirect**

1. On the template picker page, confirm a "Security vulnerability" contact link
   appears pointing to the private advisory form
2. Confirm clicking it does not open a public issue

**Test 4: SECURITY.md**

1. Navigate to `https://github.com/edera-dev/on/security/policy`
2. Confirm `SECURITY.md` content is rendered

### Lint / Validation

GitHub validates YAML form templates on push. Any schema errors will appear
in the repository's Actions tab or as a banner on the issues page.

```bash
# Local syntax check (optional — requires yamllint)
yamllint .github/ISSUE_TEMPLATE/*.yml
```

## Success Criteria

- [ ] `bug_report.yml` created with environment, steps, expected, actual, logs fields
- [ ] `feature_request.yml` created with problem, solution, alternatives, context fields
- [ ] `installation_help.yml` created with step, environment, error fields
- [ ] `documentation.yml` created with url, problem, suggestion fields
- [ ] `config.yml` disables blank issues and adds security advisory contact link
- [ ] `SECURITY.md` created at repo root with private disclosure instructions
- [ ] All template fields are `required: false`
- [ ] Bug report and installation help templates reference `on.edera.dev` and `docs.edera.dev`
- [ ] Pre-commit hooks pass

## Files Modified

1. `.github/ISSUE_TEMPLATE/bug_report.yml` — new file
2. `.github/ISSUE_TEMPLATE/feature_request.yml` — new file
3. `.github/ISSUE_TEMPLATE/installation_help.yml` — new file
4. `.github/ISSUE_TEMPLATE/documentation.yml` — new file
5. `.github/ISSUE_TEMPLATE/config.yml` — new file
6. `SECURITY.md` — new file

## Related Issues and Tasks

### Closes

- [#4](https://github.com/edera-dev/on/issues/4) — Add GitHub issue templates

### Enables

- Faster triage of bug reports (structured environment/reproduction info)
- Private security vulnerability disclosure
- Consistent labelling of incoming issues

## References

- [GitHub Issue #4](https://github.com/edera-dev/on/issues/4)
- [GitHub docs: Configuring issue templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository)
- [GitHub docs: Syntax for issue forms](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms)
- [GitHub docs: Security advisories](https://docs.github.com/en/code-security/security-advisories/working-with-repository-security-advisories/creating-a-repository-security-advisory)
- [on.edera.dev/getting-started](https://on.edera.dev/getting-started)
- [docs.edera.dev](https://docs.edera.dev)

## Notes

### Key Insights

- YAML form templates require `name`, `description`, and `body` at minimum.
  The `body` array holds the field definitions.
- `required: false` must be set explicitly on each field — the default for
  `checkboxes` is `false` but for `input`/`textarea` it is also `false`;
  being explicit is clearer.
- GitHub Security Advisories provide a built-in private disclosure mechanism
  at `github.com/<org>/<repo>/security/advisories/new` — no need for an
  email address or external tool.
- The `contact_links` entry in `config.yml` is the cleanest way to surface
  the security advisory link on the template picker page without creating a
  fake "template" that opens a public issue.

### Alternative Approaches Considered

1. **Markdown templates** — simpler but freeform; chosen approach (YAML) is
   strictly better for structured triage data ❌
2. **Single combined template** — reduces choice but makes the form unwieldy
   for unrelated issue types ❌
3. **Email-based security disclosure** — requires maintaining an inbox; GitHub
   Advisories is purpose-built and keeps disclosure in-platform ❌
