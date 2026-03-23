# Security Policy

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

EderaON is a container runtime security product. Public disclosure of
vulnerabilities before a fix is available could put users at risk. Please use
GitHub's private Security Advisory feature to report vulnerabilities.

**To report a vulnerability:**

1. Go to [github.com/edera-dev/on/security/advisories/new](https://github.com/edera-dev/on/security/advisories/new)
2. Fill in the advisory form with as much detail as you can
3. Submit — the report is visible only to repository maintainers

We will acknowledge your report within **5 business days** and aim to provide
an initial assessment within **10 business days**.

## Scope

The following are in scope for security reports:

- Container escape vulnerabilities in the EderaON runtime
- Privilege escalation within EderaON zones
- Bypass of Xen-based isolation boundaries
- Authentication or authorisation issues in EderaON components
- Vulnerabilities in the EderaON license or image distribution infrastructure

## Out of Scope

The following are **not** in scope:

- Vulnerabilities in the underlying Xen hypervisor (report to the
  [Xen Security Team](https://xenproject.org/developers/security/))
- Vulnerabilities in Kubernetes or your container runtime (report upstream)
- Issues that require physical access to the host
- Denial-of-service issues without a demonstrated security impact
- Social engineering or phishing

## Supported Versions

Security fixes are applied to the latest release of EderaON. We do not
backport security fixes to older releases.
