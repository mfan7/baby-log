-- Migration: add diaper_size to care_logs
-- Date: 2026-11-12
--
-- Adds an optional size for diaper entries (small | medium | large) so the
-- amount can be tapped as a button instead of typed into notes. Nullable, so
-- existing diaper rows and non-diaper rows are unaffected.
--
-- How to apply: run this once in Supabase -> SQL Editor BEFORE deploying the
-- frontend that writes diaper_size (otherwise diaper inserts that include the
-- column would be rejected until it exists).

alter table care_logs add column if not exists diaper_size text;

alter table care_logs drop constraint if exists care_logs_diaper_size_check;
alter table care_logs add constraint care_logs_diaper_size_check
  check (diaper_size is null or diaper_size in ('small', 'medium', 'large'));
