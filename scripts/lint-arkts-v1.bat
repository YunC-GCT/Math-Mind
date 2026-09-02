@echo off
REM lint-arkts.bat — Windows convenience wrapper for ArkTS 1.1 strict lint
REM Usage: scripts\lint-arkts.bat            (default flags)
REM        scripts\lint-arkts.bat --json     (JSON mode)
REM
REM Exit code mirrors node exit: 0 = clean, 1 = errors

setlocal
node "%~dp0audit-arkts-strict.mjs" %*
exit /b %ERRORLEVEL%