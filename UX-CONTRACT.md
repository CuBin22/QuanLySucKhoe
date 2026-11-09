# UX contract

Source of business policy: `docs/superpowers/specs/2026-10-31-personal-health-design.md`, approved by user. Visual owner: `DESIGN.md` and `lib/ui/app_theme.dart`.

## Canonical UI Map

| Capability | Canonical owner | Source of truth | Allowed variants | Verification |
|---|---|---|---|---|
| Select/Listbox | Flutter DropdownButtonFormField | Material 3 + this contract | authored Material popup | widget test, keyboard/popup check |
| Date | Flutter showDatePicker/showTimePicker | Vietnamese MaterialLocalizations, UTC+7 domain | authored Material picker, optional typed entry | date/time tests and native UI check |
| Form | Form/TextFormField and shared editor route | business rules in health_rules/care_rules | create/edit | validation, dirty-state and busy tests |
| Scrollbar | global ScrollbarTheme/ScrollBehavior | DESIGN.md | mobile touch / desktop pointer | resize/scroll check |
| Toast | shared ScaffoldMessenger SnackBar | this contract | success/warning/error | widget flow tests |
| CRUD | feature repositories and editor routes | approved spec | return to list, refresh from DB | HTTP contract tests and legacy UI regression tests |

## Shared behavior

- Successful create/edit returns to owning list and refreshes persisted values. Failed save keeps form and inline error; save button remains same size while busy and cannot submit twice.
- Cancel/back/tab changes that discard dirty form require app-owned confirmation. Resizing never disposes the form route or changes tab.
- Hard-delete health record confirms object and consequence. Removing care reminder archives it and cancels unresolved occurrences while preserving confirmed history, per spec section 6.
- Empty/error/loading states are explicit. Errors offer retry; never reset DB to hide a failure. Schedule saved but OS notification failed is a persisted warning with retry.
- No authorization roles or login. Notification permission is requested after user action; denied permission does not prevent saving schedules.
- Business data is shared through the SQL Server API; notification state is per device. Form and tab state is local to this installation. No URL search state because this is native Flutter and health filters are sensitive transient UI state. Date filters survive ordinary tab changes.
- Date ranges use UTC+7 calendar dates and half-open UTC query bounds. Existing absolute timestamps are never silently reinterpreted in device timezone.
- No optimistic destructive writes. DB success precedes success feedback. OS effects follow DB and can be retried.
- Accessibility: meaningful labels, tooltips, keyboard focus, 48px minimum action targets, text scale 2 coverage, no color-only statuses. All owned copy is Vietnamese.
- Windows/Mobile use identical business transitions. Notifications are separately verified in real platform conditions.

## Business-context sources

| Area | Source | UI consequence |
|---|---|---|
| Data lifecycle/deletion | approved spec sections 5, 6, 8 | confirm delete, preserve reminder history, cancel stale notifications |
| Permission model | approved spec section 6 | request notification permission intentionally, keep schedules on denial |
| Privacy | approved spec sections 2, 12 | offline, no logs of health values, disclose independent local storage |
| Workflow | approved spec sections 5–6 | two complete processes, no future completion, finite repeating schedule |
| Billing/legal copy | no billing or legal transaction in scope | no invented consent/paywall flow |
