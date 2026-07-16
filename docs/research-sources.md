# Research sources

This inventory records sources used in the initial product research. Primary
vendor and platform documentation is preferred. Time-sensitive observations
were last checked on 2026-07-16 and must be revalidated before external
publication.

## macOS and distribution

- [Apple: Add functionality to Finder with Action extensions](https://developer.apple.com/documentation/appkit/add-functionality-to-finder-with-action-extensions)
  — native Finder integration model.
- [Apple: NSItemProvider](https://developer.apple.com/documentation/foundation/nsitemprovider)
  — data exchange used by extensions, pasteboard and drag-and-drop workflows.
- [Apple: Notarizing macOS software before distribution](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
  — distribution requirements outside the Mac App Store.
- [Homebrew Cask Cookbook](https://docs.brew.sh/Cask-Cookbook)
  — packaging and maintenance conventions for macOS applications.

## Direct competitors

- [Dropshare](https://dropshare.app/)
- [Dropshare getting-started guide](https://kb.dropshare.app/start.html)
- [Dropover](https://dropoverapp.com/)
- [Dropover Cloud](https://dropoverapp.com/services/dropover-cloud)
- [Dropover AWS S3 integration](https://dropoverapp.com/services/aws-s3)
- [Dropover FAQ](https://dropoverapp.com/faq)
- [Dropover privacy policy](https://dropoverapp.com/privacy-policy)
- [Dropover Cloud terms](https://dropoverapp.com/dropover-cloud-terms)

## Adjacent products

- [CleanShot Cloud](https://cleanshot.com/product/cloud)
- [CleanShot pricing](https://cleanshot.com/pricing)
- [Zight file sharing](https://zight.com/file-sharing/)
- [Zight plans](https://zight.com/plans/)
- [Jumpshare file sharing](https://jumpshare.com/file-sharing)
- [Apple: Share files and folders in iCloud Drive](https://support.apple.com/guide/icloud/share-files-and-folders-mm708256356b/icloud)

## Infrastructure

- [Cloudflare R2 pricing](https://developers.cloudflare.com/r2/pricing/)
- [Cloudflare R2 presigned URLs](https://developers.cloudflare.com/r2/api/s3/presigned-urls/)
  — scoped direct PUT/GET behavior and bearer-token cautions.
- [Cloudflare R2 public buckets](https://developers.cloudflare.com/r2/buckets/public-buckets/)
  — public development URLs, custom domains and production access behavior.
- [Cloudflare Workers Static Assets](https://developers.cloudflare.com/workers/static-assets/)
  — static-asset deployment and routing modes to compare with an R2-backed site
  router.
- [Rails Active Storage overview](https://guides.rubyonrails.org/active_storage_overview.html)
  — S3-compatible endpoints, private objects and direct uploads.
- [Kamal deployment documentation](https://kamal-deploy.org/)
  — container deployment and production accessory model.
- [PostgreSQL continuous archiving and point-in-time recovery](https://www.postgresql.org/docs/17/continuous-archiving.html)
  — WAL archival, base backups and recovery.
- [MinIO container documentation](https://min.io/docs/minio/container/index.html)
  — local S3-compatible object-store container.
- [Docker Compose startup order](https://docs.docker.com/compose/how-tos/startup-order/)
  — health-check-aware dependency readiness.

On 2026-07-15, Cloudflare documented R2 Standard storage at $0.015 per GB-month,
Class A operations at $4.50 per million, Class B operations at $0.36 per
million, direct egress without an R2 egress charge, and a monthly free tier.
These figures are planning inputs, not a promised product cost.

## Authentication and billing

- [Clerk pricing](https://clerk.com/pricing) — observed 2026-07-16: the Hobby
  plan is free and lists 50,000 monthly retained users per application. This is
  sufficient for early validation but must be rechecked before budgeting.
- [Dodo Payments introduction](https://docs.dodopayments.com/introduction) —
  merchant-of-record positioning and supported billing models.
- [Dodo Payments subscriptions](https://docs.dodopayments.com/features/subscription)
  — subscription lifecycle and webhook-driven integration.

## Research gaps

Before public launch, add and verify:

- current App Store sandbox constraints for global shortcuts, Finder extensions
  and arbitrary S3 endpoints;
- competitor trials covering setup time, shortcut behavior and failure states;
- S3-compatible behavior across R2, AWS S3, Backblaze B2 and MinIO;
- current storage, egress, malware-scanning and transactional-email costs;
- applicable privacy, copyright, takedown and data-residency obligations;
- user interviews and observed workflow recordings.

Do not present this source list as a legal, security or financial review.
