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

**Never commit database *data* into this repo — it is public**, and the logs
contain personal information. (Note: GitHub Actions artifacts on a *public* repo
are also downloadable by any signed-in GitHub user, so they are not a private
place for this data either.)

Data is backed up from **inside the app** instead. The header has an **⇩ Export**
button that reads all of the signed-in user's rows (Row Level Security scopes the
query to that user) and opens a panel showing the full backup as text. From there:

- **Save to Files / Share** opens the OS share sheet — on iPhone choose *Save to
  Files* to write a real `baby-log-backup-<date>.json`. (This is used instead of
  a silent browser download, which on iOS Safari often saves an empty file.)
- **Copy to clipboard** copies the whole backup to paste anywhere (Notes, email).

Nothing is uploaded to GitHub or any third party — the data only leaves via the
share/copy action you choose, to a destination you pick.

### Restore from an export

The export is JSON: `{ app, exported_at, count, rows: [ …care_logs rows… ] }`.
To load it back into an empty/new `care_logs` table, insert the `rows` array.
For this small dataset the simplest path is Supabase → SQL Editor, e.g. with the
JSON pasted into a `jsonb` literal:

```sql
insert into care_logs
select * from jsonb_populate_recordset(null::care_logs, '<paste the rows array here>');
```

Restore into the **same Supabase project** so each row's `user_id` still matches
your auth user. This is app data only, not a full project clone.
