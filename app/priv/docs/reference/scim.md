%{
  title: "SCIM API",
  summary: "Supported SCIM 2.0 resources, attributes, filters, and limits.",
  category: "reference",
  section: "platform",
  edition: "enterprise",
  order: 10
}
---

The Enterprise SCIM base path is `/scim/v2`. For connection instructions, see
[Configure SCIM provisioning](/docs/how-to/scim-provisioning).

## Authentication and media type

All endpoints require `Authorization: Bearer <SCIM token>`. Organization
administrators generate and revoke tokens under **Organization → Authentication**.
Ordinary API tokens are not accepted. Send JSON using `application/scim+json`;
responses use the same media type and are not cacheable.

## Resources

| Resource | Methods |
|---|---|
| `/Users` | `GET`, `POST` |
| `/Users/:id` | `GET`, `PUT`, `PATCH`, `DELETE` |
| `/Groups` | `GET` |
| `/Groups/:id` | `GET`, `PATCH` |
| `/ServiceProviderConfig` | `GET` |
| `/ResourceTypes`, `/ResourceTypes/:id` | `GET` |
| `/Schemas`, `/Schemas/:id` | `GET` |

User IDs are Glossia UUIDs. Group IDs are `admins`, `members`, and `linguists`,
with display names **Admins**, **Members**, and **Linguists**. A user has one
organization role. Group removal returns administrators and linguists to basic
member access; removing a member from the Members group leaves membership intact.
Deactivate or delete a user to revoke organization membership. Deletion preserves
an inactive SCIM resource for reactivation and does not delete the global user.
Removing or demoting the last administrator returns `409 invalidValue`.

## User attributes

| Attribute | Contract |
|---|---|
| `userName` | Required on `POST` and `PUT`; email, at most 254 bytes; immutable after creation. |
| `displayName` | String, at most 255 bytes; updates are organization-scoped. |
| `externalId` | String, at most 255 bytes; unique within the organization. |
| `active` | Boolean; defaults to true for new resources. |
| `roles` | One value: `[{"value":"admin"}]`, `[{"value":"member"}]`, or `[{"value":"linguist"}]`; defaults to member. |
| `emails` | Read-only projection of `userName`, with work type and primary true. |

Existing organization members can be provisioned idempotently. An email belonging
to an existing user outside the organization returns `409 uniqueness`; invite
that user first. Provisioning never overwrites OAuth identities.

## Filters and pagination

User filters support `userName eq "email@example.com"` and
`externalId eq "provider-id"`. Group filters support `displayName eq "Admins"`.
Unsupported filters return `400 invalidFilter`.

Lists use one-based `startIndex` (default 1) and `count` (default 100), capped at
200 results per page. `count=0` returns only the total. Negative values are clamped
to 1 for `startIndex` and 0 for `count`; noninteger values return `400 invalidValue`.

## PATCH

Requests require `schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"]`
and an `Operations` array containing 1–100 operations. Operations apply atomically;
unsupported operations fail instead of being silently ignored.

User PATCH supports `add` and `replace` for `active`, `displayName`, `externalId`,
`userName` (only its existing value), and `roles`. The `path` can name one attribute
or be omitted with an object of supported attributes as `value`.

Group PATCH supports `add`, `replace`, and `remove` for `members`, with a list of
`{"value":"user-id"}` objects. Omit `path` with `{"members":[...]}` as the value,
or use `members[value eq "user-id"]` for single-member removal.

## Limits

Requests are limited to 300 per minute per client IP and per organization;
`429` responses include `Retry-After` in seconds. Bulk operations, arbitrary
groups, password changes, sorting, and ETags are not supported.
