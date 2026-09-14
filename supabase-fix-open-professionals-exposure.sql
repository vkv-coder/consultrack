-- Consultrack (consultrack.professionals) — close a full customer-PII
-- exposure found during a portfolio-wide check.
--
-- "ct_professionals_all" is a FOR ALL USING(true) WITH CHECK(true)
-- policy for anon+authenticated, and the table grant includes SELECT
-- for both roles too - meaning literally anyone with the public anon
-- key (visible in this app's own page source, same as any Supabase
-- app) can directly call
--   GET /rest/v1/professionals?select=*
-- and read every registered professional's name, mobile number,
-- city, profession, trial/block status - no login, no token, nothing.
--
-- Confirmed this isn't needed by the legitimate app at all: every
-- read (login restore, PIN verify, mobile lookup, visits/centres/
-- services) goes through ct_* RPCs, all SECURITY DEFINER (verified
-- before this fix), which bypass table-level grants entirely and are
-- unaffected by revoking SELECT here. The client's only direct table
-- access to professionals is two INSERT calls (trial/waitlist
-- registration), which this does not touch.
--
-- Not fixed here (separate, lower-severity issue - self-registration
-- fraud, not a data breach): the INSERT with_check is still `true`,
-- so a client could self-insert with, say, trial_extended_days set to
-- a large number. Worth tightening separately once the intended
-- registration column set is confirmed against the live app rather
-- than guessed from this one visible code path.

revoke select on consultrack.professionals from anon, authenticated;

-- Also found while fixing the above: DELETE was granted too, combined
-- with the FOR ALL USING(true) policy meaning anyone could delete ANY
-- professional's row outright. The client never deletes a professional
-- directly (account blocking goes through the ct_admin_block RPC), so
-- this is equally safe to close.
revoke delete on consultrack.professionals from anon, authenticated;
