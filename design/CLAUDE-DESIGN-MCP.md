# Claude Design MCP — configurazione per CleanMyMela

Questo progetto include la configurazione MCP per importare e verificare il design spec direttamente da Claude Design.

## Progetto Design

- **URL:** https://claude.ai/design/p/01426ecb-a6c6-4e85-a686-1f1e6174ee9e
- **File spec:** `CleanMyMela Design Spec.dc.html`
- **Link diretto:** https://claude.ai/design/p/01426ecb-a6c6-4e85-a686-1f1e6174ee9e?file=CleanMyMela+Design+Spec.dc.html

## Setup in Cursor

La config MCP è già presente in [`.cursor/mcp.json`](../.cursor/mcp.json):

```json
{
  "mcpServers": {
    "claude_design": {
      "url": "https://api.anthropic.com/v1/design/mcp",
      "auth": {
        "scopes": ["user:design:read", "user:design:write"]
      }
    }
  }
}
```

### Passi

1. **Riavvia Cursor** (Cmd+Shift+P → “Developer: Reload Window”).
2. Apri **Cursor Settings → Tools & MCP** (o Customize → MCP).
3. Trova **`claude_design`** — deve comparire come **Needs authentication**.
4. Clicca **Connect** e completa il login nel browser (account Anthropic con accesso a Claude Design).
5. Attendi che lo stato diventi **Connected** (non “Failed”).
6. In chat, chiedi all'agente di importare il progetto con:

   ```
   Use the claude_design MCP to import this project:
   https://claude.ai/design/p/01426ecb-a6c6-4e85-a686-1f1e6174ee9e?file=CleanMyMela+Design+Spec.dc.html

   Implement: CleanMyMela Design Spec.dc.html
   ```

## Troubleshooting

### Errore: `Unexpected token '<', "<!doctype "... is not valid JSON`

**Causa:** Cursor sta tentando la connessione OAuth **prima** di avere un token valido. Durante la discovery, interroga `claude.ai/v1/design/mcp` e riceve una pagina HTML (Cloudflare / login) invece di JSON.

**Non è un URL sbagliato** — l’endpoint `https://api.anthropic.com/v1/design/mcp` è corretto (senza auth risponde `401 unauthorized`, che è atteso).

**Fix (in ordine):**

1. **Non fare affidamento sulla connessione automatica.** Vai manualmente in Settings → Tools & MCP e clicca **Connect** su `claude_design`.
2. **Prima apri claude.ai nel browser** e verifica di essere loggato e di vedere il progetto Design.
3. **Reset token MCP:** Cmd+Shift+P → cerca **“Clear MCP”** o **“MCP: Clear All Tokens”** → riavvia Cursor → Connect di nuovo.
4. **Disabilita VPN/proxy** temporaneamente (possono intercettare le richieste OAuth con HTML).
5. Controlla **Output → MCP Logs** (Cmd+Shift+U): dopo Connect riuscito, `auth` non deve restare `unknown`.

Se dopo Connect manuale continua a fallire, è un bug noto lato Anthropic/Cursor (token OAuth Design vs login generico). In quel caso usa l’export manuale sotto.

### Errore: `404 page not found` su `/v1/design/mcp`

Bug noto su alcuni account/build. Traccia: [anthropics/claude-code#69317](https://github.com/anthropics/claude-code/issues/69317). Usa l’export manuale.

## Export manuale dello spec (fallback consigliato se MCP fallisce)

1. Apri il link del progetto Design nel browser.
2. Esporta o scarica `CleanMyMela Design Spec.dc.html`.
3. Salvalo in `design/CleanMyMela Design Spec.dc.html` in questo repo.
4. L'agente potrà confrontare pixel-per-pixel senza MCP.

## Palette implementata (Design Spec v2)

Riferimento locale in `Sources/CleanMyMela/Theme/Theme.swift`:

| Token | Light | Dark |
|---|---|---|
| Accent | `#1F9D58` | `#34C87E` |
| Window BG | `#EFF4F1` | `#171918` |
| Text primary | `#1D1F1E` | `#F1F4F2` |
| Text secondary | `#6E7673` | `#9BA39F` |
| Success | `#1F9D58` | `#34C87E` |
| Warning | `#C4830F` | `#E3A23C` |
| Danger | `#D0453E` | `#E4635C` |

## SF Symbols moduli (Design Spec v2)

| Modulo | Symbol |
|---|---|
| Smart Scan | `sparkles` |
| Pulizia sistema | `internaldrive` / `.fill` |
| Cestino | `trash` / `.fill` |
| Disinstallatore | `app.dashed` |
| Avvio | `power` |
| Manutenzione | `wrench.and.screwdriver` |
| File grandi | `doc.badge.clock` |
| Duplicati | `doc.on.doc` |
| Space Lens | `rectangle.3.group` |
| Protezione | `checkmark.shield` / `.fill` |
