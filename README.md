# 🌴 Vibez Hub

**Free auto-farm script hub for Roblox** — `robloxscripts.com`

Powered by the [jnkie](https://jnkie.com) key system. Secure, HWID-locked, free 12-hour keys.

---

## 🚀 Load it

```lua
if not game:IsLoaded() then game.Loaded:Wait() end
loadstring(game:HttpGet("https://raw.githubusercontent.com/TeddyBruckshott/VibezHub/main/VibezHubLoader.luau"))()
```

Paste into your executor and run. Tap **Get a Key**, finish one quick checkpoint, paste your key — and you're in. The hub **remembers your key**, so it auto-loads next time.

> The `game.Loaded:Wait()` guard makes it safe to drop straight into your **auto-execute folder** — it waits for the game to finish loading before running, so it also resumes cleanly after **server hops**.

---

## 🎮 Supported games

### Grow a Garden 2 — complete auto-farm
- **Farm** — Auto Harvest · Plant · Sell (Daily Deal 5× + Double-or-Nothing) · Favorite — all with **rarity / mutation / weight** filters
- **Night** — Auto Steal (filters · per-cycle · target players) + Defense (panic harvest · lock garden)
- **Garden** — Watering · Sprinklers · Unboxing (eggs / crates / packs) · Auto Expand · Codes · Shovel
- **Pets** — auto equip best · auto tame wild · save/load **Pet Teams**
- **ESP** — fruit ESP with box · name · weight · distance · tracer
- **Server** — server-hop + auto-snipe (plants · pets · night)
- **Comms** — Mailbox gifts + Discord webhook stats

More games coming.

---

## 🔑 Free keys

Grab a 12-hour key at **[jnkie.com/get-key/vibes-hub](https://jnkie.com/get-key/vibes-hub)** — one checkpoint, no payment, ever.

## 🎨 Built with

[VibeUI](https://github.com/RealSlimShady2000/VibeUI) · rasta theme · kill switch · anti-AFK · config save/load · draggable UI

> **Right Ctrl** toggles the menu · **Right Shift** = kill switch

---

<sub>This loader is open source on purpose — it holds no secrets. All farm logic ships obfuscated through jnkie and only runs after a valid, HWID-bound key.</sub>
