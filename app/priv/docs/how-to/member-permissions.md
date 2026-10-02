%{
  title: "Manage member permissions",
  summary: "Grant individual permissions or select whole product areas for organization members.",
  category: "how-to",
  section: "platform",
  order: 9
}
---

Organization administrators can choose the product areas each member can access. Start with basic read access and grant additional permissions as needed.

## Change a member's access

1. Open your organization and go to **Organization → Members**.
2. Find a non-administrator member and select **Permissions**.
3. Select individual permissions within an area, such as **Project → Write**. Select **Select all** to enable every available permission in that area. Selecting it again clears the area; a partially selected area shows an indeterminate checkbox.
4. Select **Save permissions** at the top right of the page, above the title. A confirmation appears when the permissions have been saved. Checkbox changes take effect only after saving.
5. Select **Members**, with the left arrow above the title, to return to the member list.

The permissions are grouped into compact rows in one card. On narrow screens, each area's permissions wrap below its label. Navigation and Save remain above the page title.

## Start new members with basic access

New non-administrator members, including people joining through [organization sign-in](/docs/how-to/organization-sign-in) or accepting an invitation, receive read access to the account, organization, projects, voice, glossary, discussions, and tickets. They do not receive write, delete, or administrator permissions by default.

Existing members keep their previous role-based permissions until an administrator saves explicit permissions for them. Saving replaces that access with the selected permissions. Clearing every checkbox and saving removes the member's delegated permissions; it does not remove their membership.

## Keep administrator responsibilities separate

Administrators use the administrator role and cannot have their permissions edited through this screen. Member invitations and management, access credentials, language model editing, and organization deletion remain administrator responsibilities. They cannot be delegated by selecting member permissions.

Removing a member is a separate action in the member list. Removal also blocks automatic enrollment through organization sign-in until an administrator explicitly adds or invites the person again.
