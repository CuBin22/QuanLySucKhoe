# SQL Server Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. Sequential implementation and one final independent review were already authorized. No further question is needed.

**Goal:** Flutter production uses SQL Server through a private ASP.NET API.
**Architecture:** Repository contracts separate UI from persistence. HTTP repositories and a per-device notification store replace SQLite. Legacy SQLite stays in test adapters and a read-only export tool.
**Tech Stack:** Flutter/Dart, ASP.NET Core9, Microsoft.Data.SqlClient7.1.1, SQL Server.
**Spec:** docs/superpowers/specs/2026-11-02-sql-server-design.md

## Global Constraints
No committed secrets, SQL credentials in Flutter or arbitrary SQL API. Keep files/data, import only into empty target. One profile, UTC milliseconds, fixed UTC+7, at most30 days, server clock authoritative. Offline devices reconcile notifications on reconnect. Old binaries/reports must be labelled SQLite archives.

## Review Focus
Lost create responses cannot duplicate records (idempotency, tasks2/3). Preserve snapshots and profile precision (tasks2/3). Separate device notification state (tasks2/3). Network/auth failure must preserve form and never fall back to SQLite (task3). Import into nonempty target must fail without source/target loss (task4).

### Task1 Repository contracts and legacy tests
Files: lib/features/*/*_repository.dart, lib/data/notification_store.dart, test/support/*, lib/app_services.dart, test/ui/*.
- [ ] Move SQLite implementations to test/support and implement repository contracts.
- [ ] Replace direct DB callers with repository/store operations.
- [ ] Run39 existing tests through legacy adapters; this is not a SQL Server test.

### Task2 API and SQL Server
Files: server/Health.Api/{Health.Api.csproj,Program.cs,Models.cs,SqlStore.cs,schema.sql,SelfTests.cs}.
Interface: authenticated /profile,/health,/care,/occurrences,/notifications, X-Api-Key and X-Device-Id, snake_case JSON.
- [ ] Add failing validation/time tests, then implement.
- [ ] Parameterized SQL and serializable mutations; preserve history, idempotent creates, device state.
- [ ] Restore/build/self-test; attempt live SQL only with accessible local/configured server.

### Task3 HTTP client and bootstrap
Files: lib/data/{api_client.dart,api_repositories.dart,device_identity.dart}, lib/{app.dart,main.dart}, lib/notifications/notification_sync.dart, pubspec.yaml, Android manifests, test/api/*.
- [ ] Add HTTP contract tests for headers, retry key, errors and notification state before implementation.
- [ ] Production exclusively calls API; SQLite becomes dev dependency.
- [ ] Format, analyze, full tests, Windows build; distinguish unavailable platform checks.

### Task4 Transfer and handover
Files: tool/export_sqlite.py, server import CLI, README.md, docs/sql-server.md, docs/testing.md and packaging.
- [ ] Read-only export and transactional import; verify rejection/rollback for malformed or nonempty target.
- [ ] Backend/Flutter commands, emulator/LAN URLs, token/TLS/offline limits.
- [ ] Label old deliverables; package current source/API/scripts and persist.
- [ ] One independent final review; fix Important/Critical and rerun affected checks.
