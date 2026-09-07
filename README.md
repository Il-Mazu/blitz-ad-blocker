# Blitz Ad Blocker

A reversible Windows launcher for the installed Blitz app. No installation or administrator rights are needed. Keep these files together.

Requires Windows, Windows PowerShell 5.1 or later, and an existing Blitz installation. Download this repository using **Code → Download ZIP**, extract it, then follow the steps below. This is an independent project and is not affiliated with Blitz or Riot Games.

## Use

1. Quit Blitz using its system-tray menu. Merely closing its window can leave it running.
2. Double-click **Blitz Ad Blocker.cmd** in this folder.
3. Use this launcher each time you want filtering. You can create a shortcut to the CMD file using Windows Explorer.

If Blitz starts automatically with Windows, quit that instance before using this launcher, or turn off automatic startup in Blitz's settings. An app-initiated restart or update may lose the filtering flags; quit and relaunch through this file afterwards.

To undo: quit Blitz and start it from its normal shortcut. To remove the blocker, delete this folder. Nothing is installed into Blitz or Windows.

## What it does

The launcher passes Electron's `--host-resolver-rules` switch to the original Blitz.exe. It maps the domains in `blocked-domains.txt`, including their subdomains, to `~NOTFOUND` so Chromium cannot resolve them. It disables HTTP caching for this launch to reduce reuse of already cached ad responses; it does not delete your cache or account data.

Cosmetic filtering also hides Blitz's premium promotion banners, the “Remove Ads with Premium” link, and the advertising column. It collapses the left-side ad slots while keeping the rank and analytics cards. Selectors are based on the live app's ad-specific classes and promotion image paths, rather than every occurrence of the word “premium.”

A hidden PowerShell helper checks the desktop renderer every three seconds and reapplies CSS after reloads. CSS automatically covers newly rendered matching panels. A brief flash of promotions can occur during startup or a refresh. The helper exits when the Blitz process it launched exits. `cosmetic-status.json` records its last state and matched-element count; it contains no account or page data.

This uses Electron's debugging interface on a randomly selected **127.0.0.1 (localhost)** port. That interface remains enabled for the session and can be accessed by other local software. No external debugging listener, browser extension, or downloaded dependency is installed.

To use only domain blocking, launch `Start-Blitz-AdBlock.ps1` with `-NoCosmetics`. Quit the existing Blitz instance first. This also avoids starting the debugging interface and helper.

It leaves the executable, app archive, subscription status, system DNS, hosts file, firewall, and League files untouched. It does not unlock paid features. The initial list targets common advertising networks; the launcher rejects entries under Blitz and Riot's protected domains.

## Limitations and verification

The installed app inspected for this project was Blitz **2.1.630**, with desktop interface **v3.0.0-beta.1788479860**. The cosmetic filter was checked against the live League profile: premium promotion images were hidden, rank cards remained visible, and the right ad rail was removed. Rule-builder tests and Windows PowerShell 5.1 helper checks passed. An in-game League session has **not** been verified.

Domain filtering cannot filter ads served from the same host as necessary content or guarantee every ad is blocked. Cosmetic filtering hides known ad panels; it does not stop their underlying code from running. Service-worker responses and requests outside Chromium's resolver may bypass domain filtering. A configured proxy that resolves hostnames remotely may also bypass those rules; this launcher preserves your proxy settings. New providers may require additions to the list, and interface updates may require changes to `cosmetic-filter.js`.

Double-click **Check Setup.cmd** to validate the executable path and domain list. This is not a live network test. After launching, check the pages where you normally see ads and verify analytics and overlays work. If an unrelated feature stops loading, quit Blitz and launch normally to compare, then remove the relevant domain from the list.

For a custom installation path, run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Start-Blitz-AdBlock.ps1 -BlitzPath 'D:\Apps\Blitz\Blitz.exe'
```

The execution-policy option applies only to that PowerShell process; it does not change the saved system policy.

Technical references: [Electron command-line switches](https://www.electronjs.org/docs/latest/api/command-line-switches), [Chromium hostname mapping to NOTFOUND](https://chromiumcodereview.appspot.com/12481010).
