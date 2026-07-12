# SAW011 notes

- Bundle: `com.aberp.rosteredshift.acceptrequest`
- Use only `sql/install-accept-shift-request.sql` (name-based role grants)
- Do not use `grant-process-access-roles.sql` / `register-accept-shift-request.sql` on other builds (hardcoded role IDs)
- Published status hardcoded `1000040` in Java — confirm on target
