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

## Monthly t-shirt drawing

Each month, two "F\*\*K Luck, Trust Edera!" t-shirts go to random winners, at most 24 a year.

1. In the first week of the month, list last month's accepted submissions where the user ticked the
   t-shirt box, and pick two at random. For example, for November 2026:

   ```bash
   gh issue list -R edera-dev/on --label challenge-complete --state all \
     --search "created:2026-11-01..2026-11-30" --json number,title --limit 200 | jq -r '.[].number' | shuf -n 2
   ```

   Check that each pick ticked the box and gave a license ID before announcing it. One t-shirt per person.
2. Post the **Winner** reply on each winning issue.
3. Look up the email on the winner's EderaON account from their license ID, and send the shipping form
   (size and address) there. Never collect the email or address in the issue.

## Reply texts

### Accepted

```markdown
Thanks for taking the EderaON Challenge, @USER! Your submission meets the rules and is now marked `challenge-complete`.

- Listed on COMPLETED.md: <yes, link to the commit / no, you didn't opt in>
- Bug issues from your failures: <#N, #N / none, everything worked>
```

### Winner

```markdown
Congratulations, @USER! Your submission was drawn for this month's "F**K Luck, Trust Edera!" t-shirt. We'll email a short form for your t-shirt size and shipping address to the email address on your EderaON account. We ship worldwide. Please don't post your email or address here.
```

### Needs more

```markdown
Thanks for taking the EderaON Challenge, @USER! Before we can mark it complete, we need:

- <at least three workloads / one workload of your own / the output for workload N>

Edit this issue to add it and we'll take another look.
```
