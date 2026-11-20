# Reviewing EderaON Challenge submissions

Submissions arrive as issues with the `challenge` label, opened from the
[Challenge results form](ISSUE_TEMPLATE/ederaon_challenge.yml). This page is for maintainers.

## Labels

| Label | Meaning |
| --- | --- |
| `challenge` | A submission. Added by the form. |
| `challenge-complete` | The submission meets the rules. |
| `workload-failure` | A bug issue split out from a submission: a workload that failed or partly worked. |

## Checklist

1. **Secrets.** If the output shows a license key or anything private, edit the issue to remove it first.
   If a license key was exposed, ask the user to rotate it on [My License](https://on.edera.dev/).
2. **Rules.** At least three workloads, one of them the user's own, each with real output
   (an Edera version, a kernel and zone or pod listings that fit together).
3. **Failures.** For each workload marked *Failed* or *Partly worked*, open a `bug` issue with the
   `workload-failure` label. Copy the image, the steps and the output, and link back to the submission.
4. **Reply** with one of the texts below.
5. If accepted: add the `challenge-complete` label. If the user ticked the COMPLETED.md box,
   add a row to [COMPLETED.md](../COMPLETED.md) (GitHub user, backend, link to the issue, date).
6. Close the submission issue. The bug issues stay open until they're fixed.

## Reply texts

### Accepted

```markdown
Thanks for taking the EderaON Challenge, @USER! Your submission meets the rules and is now marked `challenge-complete`.

- Listed on COMPLETED.md: <yes, link to the commit / no, you didn't opt in>
- Bug issues from your failures: <#N, #N / none, everything worked>
```

### Needs more

```markdown
Thanks for taking the EderaON Challenge, @USER! Before we can mark it complete, we need:

- <at least three workloads / one workload of your own / the output for workload N>

Edit this issue to add it and we'll take another look.
```
