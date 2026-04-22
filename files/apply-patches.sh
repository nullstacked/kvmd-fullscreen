#!/bin/bash
set -e

SHARE_DIR="/usr/share/kvmd-fullscreen"
LOG_PREFIX="kvmd-fullscreen"
WEB_DIR="/usr/share/kvmd/web"

log() { echo "[$LOG_PREFIX] $*"; }
warn() { echo "[$LOG_PREFIX] WARNING: $*" >&2; }

# Copy CSS
dest="$WEB_DIR/share/css/kvm/fullscreen.css"
mkdir -p "$(dirname "$dest")"
if [ -f "$dest" ] && cmp -s "$SHARE_DIR/fullscreen.css" "$dest"; then
    log "SKIPPED (unchanged): fullscreen.css"
else
    cp "$SHARE_DIR/fullscreen.css" "$dest"
    log "PATCHED: fullscreen.css"
fi

python3 <<'PYEOF'
import os, sys
WEB_DIR = "/usr/share/kvmd/web"

# Patch wm.js so it doesn't overwrite our navbar-show-button SVG with "• • •"
wm_path = os.path.join(WEB_DIR, "share", "js", "wm.js")
if os.path.exists(wm_path):
    content = open(wm_path).read()
    old = 'for (let el of $$$("[data-wm-navbar-show]")) {\n\t\t\tel.innerHTML = "&bull;&nbsp;&bull;&nbsp;&bull;";\n\t\t\tel.title = "Show navbar";'
    new = 'for (let el of $$$("[data-wm-navbar-show]")) {\n\t\t\tif (!el.querySelector("svg")) { el.innerHTML = "&bull;&nbsp;&bull;&nbsp;&bull;"; el.title = "Show navbar"; }'
    if old in content:
        content = content.replace(old, new, 1)
        open(wm_path, "w").write(content)
        print("[kvmd-fullscreen] PATCHED: wm.js (preserve SVG in navbar-show-button)")
    elif "if (!el.querySelector(\"svg\"))" in content:
        print("[kvmd-fullscreen] SKIPPED (already applied): wm.js")
    else:
        print("[kvmd-fullscreen] WARNING: wm.js anchor not found")

# Patch index.html
path = os.path.join(WEB_DIR, "kvm", "index.html")
if os.path.exists(path):
    content = open(path).read()
    changed = False

    if "fullscreen.css" not in content:
        last_css = content.rfind('<link rel="stylesheet"')
        if last_css >= 0:
            eol = content.find("\n", last_css)
            if eol >= 0:
                link = '\n\t\t<link rel="stylesheet" href="../share/css/kvm/fullscreen.css">'
                content = content[:eol] + link + content[eol:]
                changed = True

    # Replace empty navbar-show-button with a gear icon
    navbar_old = '<button class="hidden" id="navbar-show-button" data-wm-navbar-show data-wm-on-full-tab></button>'
    navbar_new = ('<button class="hidden" id="navbar-show-button" data-wm-navbar-show data-wm-on-full-tab '
                  'title="Show navbar / settings">'
                  '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">'
                  '<path d="M19.14,12.94c0.04-0.3,0.06-0.61,0.06-0.94c0-0.32-0.02-0.64-0.07-0.94l2.03-1.58c0.18-0.14,0.23-0.41,0.12-0.61 l-1.92-3.32c-0.12-0.22-0.37-0.29-0.59-0.22l-2.39,0.96c-0.5-0.38-1.03-0.7-1.62-0.94L14.4,2.81c-0.04-0.24-0.24-0.41-0.48-0.41 h-3.84c-0.24,0-0.43,0.17-0.47,0.41L9.25,5.35C8.66,5.59,8.12,5.92,7.63,6.29L5.24,5.33c-0.22-0.08-0.47,0-0.59,0.22L2.74,8.87 C2.62,9.08,2.66,9.34,2.86,9.48l2.03,1.58C4.84,11.36,4.8,11.69,4.8,12s0.02,0.64,0.07,0.94l-2.03,1.58 c-0.18,0.14-0.23,0.41-0.12,0.61l1.92,3.32c0.12,0.22,0.37,0.29,0.59,0.22l2.39-0.96c0.5,0.38,1.03,0.7,1.62,0.94l0.36,2.54 c0.05,0.24,0.24,0.41,0.48,0.41h3.84c0.24,0,0.44-0.17,0.47-0.41l0.36-2.54c0.59-0.24,1.13-0.56,1.62-0.94l2.39,0.96 c0.22,0.08,0.47,0,0.59-0.22l1.92-3.32c0.12-0.22,0.07-0.47-0.12-0.61L19.14,12.94z M12,15.6c-1.98,0-3.6-1.62-3.6-3.6 s1.62-3.6,3.6-3.6s3.6,1.62,3.6,3.6S13.98,15.6,12,15.6z"/>'
                  '</svg></button>')
    if navbar_old in content:
        content = content.replace(navbar_old, navbar_new, 1)
        changed = True

    # Don't let wm.js overwrite our navbar-show-button SVG (it replaces innerHTML with bullets on init)
    # This patch makes the wm.js bullet-replacement skip elements that already have SVG content.

    if 'id="kvm-fullscreen-btn"' not in content:
        body_end = content.rfind("</body>")
        if body_end >= 0:
            # Enter-fullscreen icon: four corners pointing outward
            btn = ('\t\t<button id="kvm-fullscreen-btn" class="kvm-fullscreen-btn" '
                   'title="Toggle browser fullscreen (Alt+Tab etc. route to the target)">'
                   '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">'
                   '<path class="fs-enter-path" d="M7 14H5v5h5v-2H7v-3zm-2-4h2V7h3V5H5v5zm12 7h-3v2h5v-5h-2v3zm-3-14v2h3v3h2V5h-5z"/>'
                   '<path class="fs-exit-path" style="display:none" d="M5 16h3v3h2v-5H5v2zm3-8H5v2h5V5H8v3zm6 11h2v-3h3v-2h-5v5zm2-11V5h-2v5h5V8h-3z"/>'
                   '</svg></button>\n'
                   )
            content = content[:body_end] + btn + content[body_end:]
            changed = True

    if changed:
        open(path, "w").write(content)
        print("[kvmd-fullscreen] PATCHED: index.html")
    else:
        print("[kvmd-fullscreen] SKIPPED (already applied): index.html")

# Patch session.js — wire up click → toggleFullscreen
path = os.path.join(WEB_DIR, "share", "js", "kvm", "session.js")
if os.path.exists(path):
    content = open(path).read()
    if "__fsBtnInit" in content and "__navGearToggleInit" in content:
        print("[kvmd-fullscreen] SKIPPED (already applied): session.js")
    elif "__fsBtnInit" in content and "__navGearToggleInit" not in content:
        # Smart upgrade: inject just the nav-gear toggle alongside existing __fsBtnInit
        toggle_code = (
            '\tvar __navGearToggleInit = function() {\n'
            '\t\tlet gear = document.getElementById("navbar-show-button");\n'
            '\t\tif (!gear || gear.dataset.toggleWired) return;\n'
            '\t\tgear.dataset.toggleWired = "1";\n'
            '\t\tgear.addEventListener("click", function(e) {\n'
            '\t\t\tlet navbar = document.getElementById("navbar");\n'
            '\t\t\tif (navbar && !navbar.classList.contains("hidden")) {\n'
            '\t\t\t\te.stopImmediatePropagation();\n'
            '\t\t\t\te.preventDefault();\n'
            '\t\t\t\tlet closeBtn = document.querySelector("[data-wm-navbar-close]");\n'
            '\t\t\t\tif (closeBtn) closeBtn.click();\n'
            '\t\t\t}\n'
            '\t\t}, true);\n'
            '\t};\n'
            '\tdocument.addEventListener("DOMContentLoaded", __navGearToggleInit);\n'
            '\tif (document.readyState !== "loading") __navGearToggleInit();\n\n'
        )
        anchor = '\tdocument.addEventListener("DOMContentLoaded", __fsBtnInit);'
        if anchor in content:
            content = content.replace(anchor, toggle_code + anchor, 1)
            open(path, "w").write(content)
            print("[kvmd-fullscreen] PATCHED (upgrade): session.js nav-gear toggle added")
        else:
            print("[kvmd-fullscreen] FAILED: fsBtnInit anchor not found for upgrade"); sys.exit(1)
    else:
        func_code = (
            '\n\tvar __fsBtnInit = function() {\n'
            '\t\tlet btn = document.getElementById("kvm-fullscreen-btn");\n'
            '\t\tif (!btn || btn.dataset.initialized) return;\n'
            '\t\tif (!document.documentElement.requestFullscreen) { btn.style.display = "none"; return; }\n'
            '\t\tbtn.dataset.initialized = "1";\n'
            '\t\tlet updateIcon = function() {\n'
            '\t\t\tlet active = !!document.fullscreenElement;\n'
            '\t\t\tlet enter = btn.querySelector(".fs-enter-path");\n'
            '\t\t\tlet exit = btn.querySelector(".fs-exit-path");\n'
            '\t\t\tif (enter && exit) {\n'
            '\t\t\t\tenter.style.display = active ? "none" : "";\n'
            '\t\t\t\texit.style.display = active ? "" : "none";\n'
            '\t\t\t}\n'
            '\t\t};\n'
            '\t\tdocument.addEventListener("fullscreenchange", updateIcon);\n'
            '\t\tbtn.addEventListener("mousedown", function(e) { e.preventDefault(); });\n'
            '\t\tbtn.addEventListener("click", async function() {\n'
            '\t\t\ttry {\n'
            '\t\t\t\tif (document.fullscreenElement) {\n'
            '\t\t\t\t\tawait document.exitFullscreen();\n'
            '\t\t\t\t} else {\n'
            '\t\t\t\t\tawait document.documentElement.requestFullscreen({navigationUI: "hide"});\n'
            '\t\t\t\t}\n'
            '\t\t\t} catch (e) {\n'
            '\t\t\t\twm.error("Fullscreen failed: " + (e && e.message ? e.message : e));\n'
            '\t\t\t}\n'
            '\t\t});\n'
            '\t\tupdateIcon();\n'
            '\t};\n'
            '\tvar __navGearToggleInit = function() {\n'
            '\t\tlet gear = document.getElementById("navbar-show-button");\n'
            '\t\tif (!gear || gear.dataset.toggleWired) return;\n'
            '\t\tgear.dataset.toggleWired = "1";\n'
            '\t\tgear.addEventListener("click", function(e) {\n'
            '\t\t\tlet navbar = document.getElementById("navbar");\n'
            '\t\t\tif (navbar && !navbar.classList.contains("hidden")) {\n'
            '\t\t\t\te.stopImmediatePropagation();\n'
            '\t\t\t\te.preventDefault();\n'
            '\t\t\t\tlet closeBtn = document.querySelector("[data-wm-navbar-close]");\n'
            '\t\t\t\tif (closeBtn) closeBtn.click();\n'
            '\t\t\t}\n'
            '\t\t}, true);\n'
            '\t};\n'
            '\tdocument.addEventListener("DOMContentLoaded", __fsBtnInit);\n'
            '\tdocument.addEventListener("DOMContentLoaded", __navGearToggleInit);\n'
            '\tif (document.readyState !== "loading") { __fsBtnInit(); __navGearToggleInit(); }\n\n'
        )
        target = '\tvar __wsJsonHandler = function(ev_type, ev) {'
        if target in content:
            content = content.replace(target, func_code + target, 1)
            open(path, "w").write(content)
            print("[kvmd-fullscreen] PATCHED: session.js")
        else:
            print("[kvmd-fullscreen] FAILED: session.js anchor not found"); sys.exit(1)
PYEOF

log "Done"
