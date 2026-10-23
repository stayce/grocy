# Prism Kitchen verification — 23 October 2026

Target: Grocy 4.7.1 on the existing household server. Instance addresses and SSH configuration are kept outside the tracked package.

Installed only the supported persistent custom CSS/JS hooks. Remote SHA-256 hashes match the local build:

- custom_css.html: `4f2b5a187b33ef7a140858ad7b417b2b7c3cb4155a6335374205ca90585daab7`
- custom_js.html: `93b309b80d823a7b2022cc818c9a879cc26d1a283ff415dde54ac667d9c2d0f3`

Live browser checks:

- Authenticated stock overview, shopping list, recipe list and product-entry form rendered successfully.
- Shopping Add item opens the original embedded form; required-field feedback remains visible. No item or product was saved.
- Cmd-K opens quick navigation. Searching filters its real links; Enter opens the selected route. The new-product route loaded successfully.
- Slash focuses the stock search. Search-clear removes the query and restores focus.
- Enter on the Due soon status card sets the actual status dropdown and pressed state. Clear filter restores All and clears the pressed state.
- Phone viewport 390 × 844: navigation opens and follows a recipe link; labels remain visible; document width equals viewport width, with no horizontal overflow. Viewport override reset after testing.
- Light and dark stock views inspected. Appearance temporarily changed through Grocy's UI to inspect light mode, then restored to the original Use system setting preference. Dark mode resumed.
- Login layout inspected after correcting centring and legacy background styles.
- Reduced-motion and print rules present; not separately emulated.
- JavaScript syntax passes `node --check`.
- Browser log had one XMLHttpRequest error from initial sign-in at 22:15:59 UTC, before theme installation; no later error was observed during theme checks.

Snapshots: before.png, desktop.png, mobile.png, light.png, login.png. The final desktop screenshot includes the complete empty stock table.

Before-theme backup `grocy-20261022T222115Z.tar.gz` and after-theme backup `grocy-20261022T222809Z.tar.gz` both passed extracted restore integrity checks. Both report 0 products, 0 stock entries, 1 user and 257 migrations. The after-theme archive contains the deployed hooks.

Scope: visual and navigation changes, with no inventory data writes. Populated inventory transactions and physical mobile-device testing were not performed. The temporary appearance preference was restored; desktop-only shortcut behaviour was verified in the browser.

Repository packaging: moved the maintained source to `themes/prism-kitchen/` in the existing Grocy fork. The original task workspace remains as a safety copy. Rebuilding the CSS from the packaged stylesheet/fonts reproduces the deployed checksum above; the JavaScript is unchanged. The deploy helper now requires an explicit `GROCY_DEPLOY_HOST` instead of storing a household SSH destination. Generated CSS, local instance notes, Python environments and upstream reference snapshots are excluded from Git.
