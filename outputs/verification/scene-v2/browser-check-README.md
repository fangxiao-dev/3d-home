# Browser verification script

Historical version: these scripts and reports apply to the resource packs recorded in their receipts and test the original Q/E controls. The current mouse-edge navigation test entry is [navigation-v2](../navigation-v2/). Do not use this historical campaign as acceptance evidence for the new controls. Its original 60 FPS comparison is also historical; the current accepted performance floor is 25 FPS.

`browser-check.cjs` is an unchanged evidence copy of `work/scene-v2-browser-check.cjs`.

Run from the repository root on this Windows development machine:

```powershell
node outputs/verification/scene-v2/browser-check.cjs 1366 768
node outputs/verification/scene-v2/browser-check.cjs 1920 1080 soak
```

The script uses local Playwright at `C:/Users/Xiao/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright` and Chrome at `C:/Program Files/Google/Chrome/Application/chrome.exe`. It tests only `http://127.0.0.1:8767/`, started by `outputs/Start-Preview.ps1`, and reads `work/scene-v2-build-receipt.json` for the expected resource pack. It writes screenshots and original JSON reports to `work/`. No upload or public deployment is performed.

Run one browser verification at a time against a frozen build. `soak` adds at least ten minutes of real keyboard exploration after the full functional route. Functional `pass` and `performance_target_met` are separate. The desktop workload is not isolated, and the reported renderer is the one actually used by the test browser.

Historical evidence belongs to the resource pack recorded inside its JSON, not automatically to the latest build. `before-lighting/` and `before-hood/` preserve earlier candidates. `review.md` is maintained separately by the independent reviewer.
