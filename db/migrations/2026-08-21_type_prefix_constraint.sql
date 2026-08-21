-- Migration: relax care_logs.type validation to a prefix pattern
-- Date: 2026-08-21
--
-- Why: the previous CHECK constraint listed every allowed `type` value
-- explicitly, so adding a new category in the app (e.g. activity_medication)
-- failed with "violates check constraint care_logs_type_check" until the DB
-- was updated by hand. This replaces the exact list with a namespace pattern:
--   - 'feed'
--   - any 'diaper_<x>'   (wet | dirty | both | future)
--   - any 'activity_<x>' (play | study | soothe | medication | other | future)
-- New subtypes now require NO database change, while typos in the top-level
-- namespace are still rejected. All existing rows already match this pattern.
--
-- How to apply: run this once in Supabase -> SQL Editor.
-- If the constraint has a different name in your project, find it with:
--   select conname, pg_get_constraintdef(oid) from pg_constraint
--   where conrelid = 'care_logs'::regclass and contype = 'c';

alter table care_logs drop constraint if exists care_logs_type_check;

alter table care_logs add constraint care_logs_type_check
  check (type ~ '^(feed|diaper_[a-z]+|activity_[a-z_]+)$');
