# AC Ham Radio - Power Checking Implementation

## Overview
This implementation adds proper AC power checking to the AC Ham Radio mod, ensuring radios only function when placed near active generators that provide electricity.

## How It Works

### Server-Side Power Monitoring (`server.lua`)

**PowerMonitor System:**
- Maintains a registry of all AC radios placed in the world
- Checks power status every ~1 second (10 ticks)
- Automatically turns off radios when AC power is lost
- Cleans up references to removed/picked up radios

**Key Functions:**
1. `registerRadio(item)` - Adds a radio to monitoring when placed
2. `hasACPower(item)` - Checks if the radio's square has electricity
3. `updateRadio(radioData)` - Updates individual radio power state
4. `onTick()` - Main update loop that checks all registered radios

**Power Loss Handling:**
- When a generator runs out of fuel → Radio turns off automatically
- When a radio is turned on without power → Server prevents it
- When power state changes → Radio state is synchronized to clients

### Client-Side Power Display (`client.lua`)

**Visual Feedback:**
- Green status box: "AC Powered (ON/OFF)" when electricity available
- Red status box: "No AC Power" when no electricity
- Status updates in real-time as power state changes

**Interaction Prevention:**
- Overrides the power button to check for AC power first
- Shows message to player: "This radio requires AC power from a generator"
- Plays denial sound effect when trying to use without power

### Shared Utilities (`shared.lua`)

**Helper Functions:**
- `isACRadio(item)` - Validates if item is an AC radio
- `getRadioTypeName(item)` - Returns display name for radio type
- `validateRadio(item)` - Checks radio configuration is correct
- `debugInfo(item)` - Prints detailed radio state for troubleshooting

## Installation

### For Build 42.13.2+

**Replace these files:**

1. **Server Logic:**
   - Replace: `Contents/mods/AC_Ham_Radio/42/media/lua/server/server.lua`
   - With: The new `server.lua` containing PowerMonitor system

2. **Client Logic:**
   - Replace: `Contents/mods/AC_Ham_Radio/42/media/lua/client/client.lua`
   - With: The new `client.lua` with enhanced UI and validation

3. **Shared Code:**
   - Replace: `Contents/mods/AC_Ham_Radio/42/media/lua/shared/shared.lua`
   - With: The new `shared.lua` with utility functions

### File Structure
```
Contents/mods/AC_Ham_Radio/
└── 42/
    ├── mod.info
    ├── poster.png
    └── media/
        ├── lua/
        │   ├── client/
        │   │   └── client.lua          ← Replace
        │   ├── server/
        │   │   └── server.lua          ← Replace
        │   └── shared/
        │       └── shared.lua          ← Replace
        └── scripts/
            ├── items_ACRadio.txt
            └── recipes_ACRadio.txt
```

## Key Fixes Applied

### 1. Server Context Check
**Old (Broken):**
```lua
if isClient() then return end  -- Fails in single-player and host MP
```

**New (Fixed):**
```lua
if not isServer() then return end  -- Works in all contexts
```

### 2. Power Monitoring
**Old:** No power checking - radios work anywhere

**New:** Active monitoring system:
- Checks power every second
- Forces radio off when power is lost
- Prevents turning on without power
- Syncs state to all clients

### 3. Client Validation
**Old:** Only visual display, no prevention

**New:** 
- Prevents power button from working without AC
- Shows clear feedback to player
- Updates display in real-time

## Compatibility

✅ **Single Player** - Works correctly
✅ **Local Host Multiplayer** - Works correctly  
✅ **Dedicated Server** - Works correctly
✅ **Join Server as Client** - Works correctly

## Testing Checklist

1. **Craft an AC Radio** using the recipe
2. **Place it in world** near a generator
3. **Turn on generator** and verify radio can turn on
4. **Turn off generator** and verify radio turns off automatically
5. **Try to turn on radio** without power - should be prevented
6. **Pick up radio** while on - should turn off
7. **Open radio UI** - should show correct AC power status

## How AC Power Works in Project Zomboid

**Electricity System:**
- Generators provide electricity to the building they're in/near
- `square:haveElectricity()` returns true when power is available
- Power is checked per grid square
- Radios must be placed in world (not inventory) to access building power

**Power Flow:**
1. Generator is fueled and turned on
2. Generator provides electricity to connected squares
3. Radio checks its square for electricity
4. Radio only functions if electricity is present

## Troubleshooting

**Radio won't turn on:**
- Check generator has fuel and is running
- Verify radio is placed in same building as generator
- Check radio is placed in world (not in inventory)
- Use `/debuginfo` command if available to check power state

**Radio doesn't turn off when generator stops:**
- Server-side monitoring may be delayed up to 1 second
- Check server console for errors
- Verify server.lua is loaded correctly

**UI doesn't update:**
- UI updates every ~2 seconds on client
- Close and reopen radio panel to force refresh
- Check client.lua is loaded correctly

## Debug Commands

Add to your mod if needed:
```lua
-- In client.lua or server.lua
Events.OnCustomUIKey.Add(function(key)
    if key == Keyboard.KEY_F9 then
        local player = getPlayer()
        local item = player:getPrimaryHandItem()
        if item and ACHamRadio.isACRadio(item) then
            ACHamRadio.debugInfo(item)
        end
    end
end)
```

## Performance Considerations

- Power checks run every 10 ticks (~1 second at 10 TPS)
- Minimal performance impact even with many radios
- Automatic cleanup of removed radios prevents memory leaks
- World scan on game start may cause brief delay with many radios

## Future Improvements

Potential enhancements:
1. Add power consumption that drains generator faster
2. Add "low power" state with reduced range
3. Add battery backup system (UPS style)
4. Add visual/audio indicators when power is lost
5. Add configuration options for power check frequency

## Credits

Power monitoring system designed for Project Zomboid Build 42.13.2+
Compatible with single-player, host multiplayer, and dedicated servers.
