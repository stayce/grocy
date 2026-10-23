# Grocy · Prism Kitchen

A persistent, additive theme for Grocy 4.7.1: rainbow glass, expressive typography, clearer forms and quick navigation. Grocy continues to own inventory, shopping, recipes and other data actions.

## Files and deployment

This theme uses Grocy's persistent `data/` customisation hooks. The included deployment helper supports the existing macOS host layout under `~/Library/Application Support/Grocy`:

| Source | Deployed hook |
| --- | --- |
| `theme/prism.css` + local WOFF2 fonts, bundled by `build_theme.py` | `data/custom_css.html` |
| `theme/custom_js.html` | `data/custom_js.html` |

Build locally with `python3 build_theme.py`. This needs Python's standard library only. The generated `theme/custom_css.html` embeds Fraunces and Space Grotesk as data URLs. Both fonts are local and licensed under the SIL Open Font License; notices are in `theme/fonts/*-OFL.txt`. The theme makes no runtime requests to external font, image or analytics services.

From this directory, build with `python3 build_theme.py`, then install the generated `theme/custom_css.html` and `theme/custom_js.html` into your Grocy instance's persistent `data/` directory. Reload the page to apply them. Preserve any existing custom hooks before replacing them.

For the macOS installation with the existing backup helper, run `GROCY_DEPLOY_HOST=user@host ./deploy.sh`. The host must already have Grocy installed and the backup script described below. Local instance details are kept in ignored `deployment.local.md`. Run one deployment at a time. The script:

1. Runs the existing remote backup script with `/opt/homebrew/bin/python3` and requires `restore_integrity: ok`.
2. Saves the previous theme hooks under `theme-rollbacks/<unique-run-id>/`.
3. Uploads to a temporary directory beside the deployed hooks and verifies SHA-256 hashes.
4. Replaces each hook with an atomic rename, verifies the deployed hashes, and prints them.

The two replacements are individually atomic. A failure during installation restores the previous hooks. The deployment script does not write the database or change Grocy application files. The existing backup script creates a consistent full backup and applies its existing retention policy of 14 archives.

## Disable or restore

To disable the theme, rename both `data/custom_css.html` and `data/custom_js.html` to unused names that Grocy will not load, then reload the page. Keep the files so the change is reversible. Do not rename or replace the database.

To restore an earlier theme, use the two hooks in the desired `theme-rollbacks/<run-id>/` directory. A `<filename>.absent` marker means that hook did not exist before that deployment. `backup.json` records the associated full backup. No rollback is executed merely by building or reading this repository.

## Verification record

The initial backup was `grocy-20261022T222115Z.tar.gz`, with `restore_integrity: ok` and counts of `products: 0`, `stock: 0`. These are the recorded initial snapshot, not a statement about future inventory.

The independent review covered theme source, Grocy markup, keyboard/search/filter behaviour, mobile navigation rules, permissions and preservation of data actions. Live desktop/mobile browser checks, screenshots, deployment hashes and the final backup receipt are recorded in [evidence/verification.md](evidence/verification.md). The reusable deployment script passed Bash syntax validation; this initial installation used direct staged uploads.

`evidence/` contains the verification record and UI captures. It is not deployed. Generated CSS is ignored by Git and rebuilt from the tracked stylesheet and WOFF2 fonts.

![Dark stock overview](evidence/desktop.png)

The original task workspace is retained as a safety copy; this directory is the maintained source in the Grocy repository.
