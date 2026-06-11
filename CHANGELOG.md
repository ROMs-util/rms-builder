# Changelog - builder (Package Builder)

All notable changes to the `builder` tool will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased] - 2026-06-11
### Added
- **SemVer Symbol Support**:
  - **Explicit Equality:** Updated the manifest validator to support the `=` operator in dependency strings (e.g., `helper:=1.0.0`). This enables strict version pinning as part of the SemVer hardening initiative.

## [0.1.0] - 2026-05-31
### Added
- **Industrial Diagnostic Standardization**:
  - **Dual-Target Logging:** Ported the refactored `Write-Log` logic. Level 3 (RAW) now provides Pretty-Printed Magenta JSON in the console while maintaining Tight-Inline compressed JSON in log files.
  - **RAW Telemetry:** Implemented architectural visibility in the router for raw command-line arguments and raw manifest data.
  - **Logic Milestones (DEBUG):** Hardened the logic layer with descriptive DEBUG logs in the Bundler (Smart Exclusion justifications) and Validator (Verification steps and target identification).
  - **File-by-File Physical Truth (TRACE):** Implemented a "Hybrid Visual" standard for compression tracing: a standard TRACE header followed by a clean, vertical property dump for the console, and a JSON audit entry for the log file.
  - **Variable Purity:** Standardized all global variables to use the **`$global:ROMs_`** hierarchy and purged legacy/double-underscore variants.
  - **Anti-Ghost Mandate:** All diagnostic logs are now physically verified via `Test-Path` before emission to ensure honesty.
- **Robustness**:
  - Hardened argument parsing and router logic using array sub-expressions `@($args | ...)` to prevent null-indexing crashes.
  - Explicitly loaded `System.IO.Compression` assemblies to ensure consistent behavior across PowerShell versions.

## [5cc1118] - 2026-05-23
### Added
- **Trinity v1.1.0 Logic Sync**:
  - Hardened validator to enforce mandatory `author` and `architecture` fields.
  - Implemented explicit blocking of deprecated `installDir` field.
  - Upgraded dependency validation to support object-based manifest structures.

---

## [8b6062a] - 2026-05-16
### Added
- **Modular Refactor:** Fully stabilized the multi-file architecture (`core`, `help`, `validator`, `bundler`) for cleaner maintenance.
- **Documentation Overhaul:** Finalized Persona-Driven guides (Creator/Maintainer) and OS Hook specifications.

### Changed
- **Router Logic:** Hardened `builder.ps1` to ensure reliable library sourcing across different execution contexts.

---

## [ff4a877] - 2026-05-15
### Added
- **Wildcard Support:** Manifest-listed files now support standard wildcards (e.g., `lib/*.ps1`).
- **Industrial Strength Bundling:** Upgraded the compression engine to native .NET `[System.IO.Compression.ZipFile]` for performance and reliability.

### Changed
- **Metadata Keying:** Switched to package-name-based identification for consistency with the manager and engine.

### Fixed
- **Duplicate Path Error:** Implemented unique path filtering during file collection to prevent build failures on redundant manifest entries.
- **Assembly Loading:** Explicitly load `System.IO.Compression` to ensure `ZipArchiveMode` availability across all PowerShell versions.
