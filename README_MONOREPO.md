# Campus Lost & Found Monorepo

This repository contains two Flutter applications:

- `campuslf/` — The user-facing Campus Lost & Found app (Android, iOS, Web)
- `campuslf_admin/` — The admin portal (Web) for moderation and analytics

Key notes:
- Both apps are independently runnable. See their respective `README.md` files for platform-specific steps.
- Common patterns like build outputs and local caches are excluded from version control via the root `.gitignore`.

Deployment references:
- User app (web hosting): `wsucampuslf` Firebase project
- Admin app (web hosting): `wsulostfound` Firebase project

If you add new modules, please update this document to reflect the monorepo structure.