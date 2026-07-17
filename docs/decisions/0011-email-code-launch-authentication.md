# 0011: Launch managed cloud with email-code authentication

- Status: Accepted for initial production launch
- Date: 2026-07-17

## Context

Clerk's development configuration had Apple, Google and X connections enabled
without the production OAuth credentials those providers require. GitHub was
not enabled. Completing those provider registrations would delay the first
production deployment and does not improve the core upload-and-share
validation.

Wirecopy already requires a verified email address for managed accounts, and
Clerk's production domain, SSL and mail DNS are verified.

## Decision

Launch the managed service with required email addresses and Clerk email
verification codes as the only authentication method.

- Disable Apple, Google and X OAuth connections in both Clerk development and
  production instances.
- Leave GitHub disabled for the initial launch.
- Keep the Rails integration provider-neutral: it consumes the verified Clerk
  session and does not depend on an OAuth provider.
- Reconsider Apple and GitHub after the production website and account flow are
  operating end to end.

This decision narrows the initial authentication surface. It does not reject
social authentication as a later convenience.

## Consequences

### Positive

- Production authentication can launch without third-party OAuth secrets.
- Development and production use the same visible sign-in methods.
- Email ownership is verified before Rails creates or synchronizes an account.
- Fewer external identity providers reduce configuration and support surface
  during bring-up.

### Negative

- Users must receive and enter an email code.
- Apple and GitHub one-click sign-in are deferred.
- Email delivery becomes part of the critical sign-in path.

## Revisit when

- production sign-in and account creation have been exercised successfully;
- users show meaningful friction with email codes;
- Apple or GitHub sign-in materially improves the developer workflow;
- the required provider credentials and callback-domain review are complete.
