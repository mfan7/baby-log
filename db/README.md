# Database

The Baby Log app stores everything in a single Supabase (Postgres) table,
`care_logs`. The database schema lives **only in Supabase** — this folder exists
so that schema changes are written down and version-controlled instead of being
applied by hand and forgotten (which is what caused the
`care_logs_type_check` failure when the Medication feature shipped).

## The `type` column convention

Every row's `type` follows one of three namespaces:

| Namespace     | Examples                                                        |
| ------------- | --------------------------------------------------------------- |
| `feed`        | `feed`                                                          |
| `diaper_<x>`  | `diaper_wet`, `diaper_dirty`, `diaper_both`                     |
| `activity_<x>`| `activity_play`, `activity_study`, `activity_soothe`, `activity_medication`, `activity_other` |

A CHECK constraint enforces these **namespaces** with a pattern rather than an
exact list:

```sql
check (type ~ '^(feed|diaper_[a-z]+|activity_[a-z_]+)$')
```

**Consequence:** adding a new activity or diaper subtype in `index.html` needs
**no database change** — the pattern already allows it. You only need a
migration when you change the shape of the data (new column, new namespace,
new constraint, an index, RLS policy, etc.).

## Migration workflow

When you *do* need a schema change:

1. Add a new file here named `migrations/<YYYY-MM-DD>_<short_description>.sql`
   containing the exact SQL.
2. Run that SQL once in **Supabase → SQL Editor**.
3. Commit the file. The folder is then an ordered, readable history of every
   change the database has had.

Migrations are plain SQL and free to run — they do not require a paid Supabase
plan.

## Backups

Schema is captured here; **data** is backed up separately by the
`.github/workflows/backup.yml` GitHub Action (a weekly `pg_dump` uploaded as a
private workflow artifact). See that file's comments for setup. Do **not** commit
database *data* into this repo — it is public, and the logs contain personal
information.
