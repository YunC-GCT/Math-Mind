@echo off
REM lint-arkts-ast.bat — Windows convenience wrapper for arkts-lint v0.3 (AST-based)
REM Usage: scripts\lint-arkts-ast.bat            (default flags)
REM        scripts\lint-arkts-ast.bat --json     (JSON mode)
REM
REM Exit code mirrors node exit: 0 = clean, 1 = errors

setlocal
node "%~dp0arkts-lint\index.mjs" %*
exit /b %ERRORLEVEL%