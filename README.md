# kvmd-fullscreen

Floating browser-fullscreen button for PiKVM. Clicking enters browser fullscreen so keyboard shortcuts (Alt+Tab, Ctrl+Esc, Win key, etc.) route to the **target** machine instead of the host browser.

## Position

Top-right, 2px margin (coordinates with `kvmd-paste-clipboard` which sits at `right: 34px`).

## CSS customization

Override in `/etc/kvmd/web.css`:

```css
:root {
    --cs-fullscreen-top: 2px;
    --cs-fullscreen-right: 2px;
    --cs-fullscreen-size: 22px;
}
```

## How it works

Patches `session.js` to call `document.documentElement.requestFullscreen()`. Listens for `fullscreenchange` to swap the icon between enter/exit states.
