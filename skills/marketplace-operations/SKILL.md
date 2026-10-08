---
name: marketplace-operations
description: Manage Tarik's Trendyol, Shopier, Hepsiburada via Pazarus, and Shopify stores using verified API, MCP, or browser connections. Use for store products, inventory, orders, setup, and multi-device marketplace operations.
---

# Marketplace operations

Locate the marketplace-control project and read connections.json. If it is not available, ask for the project location; do not invent credentials or assume authentication carries across devices.

## Route by provider

- Trendyol: direct Partner API, seller 421646. Use scripts/Invoke-MarketplaceRead.ps1 for GET; writes need current official endpoint/schema verification and the user's requested mutation. Legacy Desktop apikey-trendyol.txt contains seller ID at zero-based line 4 and Basic token at line 12. Never display these lines.
- Shopier: direct REST API, Bearer token, https://api.shopier.com/v1. GET helper is available. Lavanta DIY kit was created as product 51623831; check it before creating another. Official docs: https://developer.shopier.com/llms.txt.
- Hepsiburada: merchant 0864116b-07ca-48bc-91e9-1b2893970611, authorized Pazarus integrator hubsan_dev. Pazarus tenant 1158 API connection tested successfully on 2026-10-08. Preserve existing birfatura_dev; its service key is not transferable to other integrators.
- Pazarus: OAuth MCP https://pazarus.io/mcp, scope mcp:use. ChatGPT plugin URL is in connections.json. OAuth connection was NOT completed. Do not claim tools are usable until connected and a read call passes. Live panel exposed optional write permissions despite public listing calling it read-only; inspect current tools/permissions. Initially keep AI writes and marketplace sync disabled. 434 HB products were previewed; import started but completion unverified.
- Shopify: browser admin session observed for hizli-uygun-satis-com-tr, no Admin API token/scopes or MCP connection configured. Verify official integration availability and authorize the specific store before requesting keys. Do not scrape cookies or reuse session tokens as API credentials.
- Other marketplaces: verify official docs and least-privilege authentication before adding to connections.json. KobiConnect was investigated but no verified HB integrator identity was established; do not reuse another company's key there.

## Credentials and execution

Prefer OAuth for supported MCP services and direct API for verified provider mutations. Never store keys in this skill, Git, GitHub issues, logs, or tracked configuration. Read local encrypted vault via scripts/Get-MarketplaceSecrets.ps1; environment variables can override it. Existing Desktop files are a legacy fallback, not a cross-device solution.

Use GET for connection checks; never verify setup by changing production inventory. Read the current product/state before writing, avoid duplicate creates, verify the response and a follow-up read. Historical setup approval does not authorize unrelated sales, replies, sync activation or future writes.

## Another computer

Clone the confirmed GitHub repository, open its marketplace-control folder as a Codex project, run scripts/Install-Skill.ps1, provision API secrets on that computer or reconnect OAuth, and run read checks. Local encrypted credentials are machine/user-bound, not synced by this project. Do not promise that signing into the same Codex account alone restores local files, browser sessions or this vault.
