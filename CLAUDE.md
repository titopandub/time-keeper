# CLAUDE.md - Repository Navigation Guide

## Project Overview

**time-keeper** is a Progressive Web App (PWA) that displays Islamic prayer times (Waktu Sholat) based on the user's geographic location. The application is built with Elm 0.19.1 and features offline capabilities through Service Workers.

### Key Features
- Real-time clock display (shows local time)
- **Iqomah countdown** - 5-minute countdown after each prayer time
- Automatic prayer time calculation based on astronomical algorithms
- Geolocation support for accurate prayer times (via JavaScript ports)
- **Test mode** - URL parameters to simulate prayer times for testing
- Offline-first PWA with Service Worker caching
- Responsive design for mobile and desktop
- Default location: Senayan City, Jakarta (lat: -6.2276252, lng: 106.7947417)

### Tech Stack
- **Language**: Elm 0.19.1 (upgraded from 0.18)
- **Dependencies**: elm/browser, elm/core, elm/html, elm/time
- **PWA**: Service Worker with cache-first strategy
- **Styling**: Inline CSS with responsive breakpoints
- **Geolocation**: JavaScript ports (Elm 0.19 doesn't have core geolocation)

---

## Repository Structure

```
/home/tito/workspace/time-keeper/
├── src/
│   ├── Main.elm              # Main application logic, UI, and ports (~434 lines)
│   └── PrayTime.elm          # Prayer time calculation algorithms (~344 lines)
├── index.html                # Application entry point with geolocation JS (~200 lines)
├── elm.js                    # Compiled Elm application (generated, ~140KB)
├── elm.json                  # Elm 0.19 package configuration
├── manifest.json             # PWA manifest configuration
├── service-worker.js         # Service Worker for offline functionality (v23)
├── serviceworker-cache-polyfill.js  # Service Worker polyfill
├── script.sh                 # Simple build/test script
├── .gitignore                # Git ignore file (includes elm binary)
└── README.md                 # Project documentation
```

**Note**: `elm-package.json` was replaced by `elm.json` in the Elm 0.19 upgrade.

---

## Core Files and Their Purposes

### Application Logic

#### `src/Main.elm` (~434 lines)
**Purpose**: Main application entry point, UI rendering, and port communication

**Architecture**: Port module for JavaScript interop

**Key Components**:

1. **Ports** (lines 12-16):
   - `requestLocation : () -> Cmd msg` - Request geolocation from JavaScript
   - `receiveLocation : (LatLong -> msg) -> Sub msg` - Receive location from JavaScript

2. **Flags** (lines 19-22):
   - `testIqomah : Maybe String` - Prayer name for test mode
   - `testOffset : Int` - Minutes offset for test mode

3. **Model** (lines 41-47):
   - `time : Posix` - Current timestamp (from Time module)
   - `zone : Time.Zone` - User's local timezone (auto-detected)
   - `location : LatLong` - User's coordinates (default: Senayan City)
   - `testMode : Maybe String` - Active test mode (if any)
   - `testOffset : Int` - Test mode time offset

4. **Messages** (lines 58-62):
   - `Tick Posix` - Updates every second
   - `AdjustTimeZone Time.Zone` - Sets local timezone
   - `RequestLocation` - Triggered by "Cek Lokasi" button
   - `ReceiveLocation LatLong` - Receives location from JavaScript port

5. **View Function** (lines 99-202):
   - Displays current time as HH:MM:SS (local time)
   - Shows 6 prayer times (Subuh, Terbit, Zuhur, Ashar, Magrib, Isya)
   - Renders **Iqomah countdown** when within 5 minutes after prayer time
   - Shows **test mode indicator** (red banner) when in test mode
   - Renders "Cek Lokasi" button for geolocation

6. **Key Functions**:
   - `getTestTime` (lines 282-333): Calculates simulated time for test mode
   - `formattedTime` (lines 238-240): Formats time to HH:MM:SS
   - `toHtmlClock` (lines 243-247): Renders clock display
   - `htmlTimeStructure` (lines 250-260): Renders each prayer time card
   - `htmlIqomahCountdown` (lines 393-408): Renders Iqomah countdown component
   - `findIqomahStatus` (lines 345-378): Determines if Iqomah countdown should appear
   - `timeInfoToSeconds` (lines 340-342): Converts time to seconds for comparison
   - `formatIqomahTime` (lines 381-388): Formats countdown as "X min Y sec"

**Iqomah Countdown Logic**:
- Checks if current time is within 5 minutes after any prayer time
- Excludes "Terbit" (sunrise) as it's not a prayer time
- Displays prayer name and countdown timer
- Updates every second

**Test Mode Logic**:
- Accepts URL parameters: `?testIqomah=subuh&offset=1`
- Overrides clock display to show simulated time
- Calculates time as: prayer time + offset minutes
- Shows red banner indicating test mode is active

**Hard-coded Values**:
- Timezone: 7 (GMT+7, but clock shows local time)
- Elevation: 0 meters
- Iqomah duration: 5 minutes (300 seconds)
- Default test offset: 1 minute

---

#### `src/PrayTime.elm` (~344 lines)
**Purpose**: Astronomical calculations for Islamic prayer times

**Key Changes from Original**:
- Now uses `TimeInfo` type instead of `Date` (Elm 0.19 change)
- `toString` replaced with `String.fromInt`
- Removed dependency on `Date` module

**Key Components**:

1. **Data Types**:
   - `TimeInfo` (lines 4-11): Replaces Date type
     - year, month, day, hour, minute, second (all Int)
   - `PrayTimes` (lines 25-32): Raw prayer times as Float (hours)
   - `FormattedPrayTimes` (lines 68-75): Formatted prayer times as String (HH:MM)
   - `SunPosition` (lines 303-304): Declination and equation of time

2. **Main Calculation Pipeline**:
   ```elm
   calculatePrayTimes -> adjustTimes -> formatTimes -> toTimeList
   ```

3. **Core Functions**:
   - `calculatePrayTimes` (line 35): Master function that calculates all prayer times
     - Parameters: latitude, longitude, elevation, timeZone, **TimeInfo** (not Date)
     - Uses sun angle calculations for each prayer

   - `sunAngleTime` (line 160): Calculates prayer time for given sun angle
     - Used for Fajr (20°), Sunrise (0.833°), Maghrib (1°), Isha (18°)

   - `calcAsrTime` (line 139): Special calculation for Asr prayer
     - Uses shadow length factor (default: 1 = Shafi'i method)

   - `midDayTime` (line 204): Calculates Dhuhr (midday) time

   - `adjustTimes` (line 111): Adjusts times for timezone and longitude
     - Adds 2-minute correction for most prayers
     - Adds -2 minute correction for sunrise

4. **Astronomical Utilities**:
   - `toJulianDate` (line 238): Converts TimeInfo to Julian date
   - `sunPosition` (line 307): Calculates sun's declination and equation of time
   - `riseSetAngle` (line 216): Calculates angle adjustment for elevation
   - `fixAngle` (line 334): Normalizes angles to 0-360°
   - `fixHour` (line 339): Normalizes hours to 0-24
   - `twoDigitsFormat` (line 103): Formats numbers as two digits (uses String.fromInt)

5. **Prayer Time Labels** (lines 14-22):
   - Subuh (Fajr) - Dawn prayer
   - Terbit (Sunrise) - Not a prayer, but important marker
   - Zuhur (Dhuhr) - Midday prayer
   - Ashar (Asr) - Afternoon prayer
   - Magrib (Maghrib) - Sunset prayer
   - Isya (Isha) - Night prayer

**Calculation Method**:
- Fajr angle: 20° below horizon
- Isha angle: 18° below horizon
- Maghrib: 1° (very close to sunset)
- Asr: Shadow length = object length + 1 (Shafi'i method)

---

### Frontend and PWA

#### `index.html` (~200 lines)
**Purpose**: Application shell, Service Worker registration, and geolocation handling

**Structure**:
- **Head** (lines 5-134):
  - Meta tags for viewport and theme color (#81F781 - light green)
  - Inline CSS with responsive breakpoints at 1000px
  - **Iqomah countdown styles** (golden/yellow background)
  - PWA manifest link

- **CSS Classes**:
  - `.time` - Main container
  - `.time__clock` - Clock display
  - `.time__iqomah` - **Iqomah countdown container** (background: #FFD700)
  - `.time__iqomah-label` - Iqomah label (e.g., "Iqomah Zuhur")
  - `.time__iqomah-countdown` - Countdown timer display
  - `.time__shalat` - Prayer time card
  - `.time__location-button` - Geolocation button
  - `.test-mode-indicator` - Test mode banner (red, inline styles)

- **Responsive Design**:
  - Mobile: 300px width, stacked layout
  - Desktop (1000px+): 90% width, 3-column grid for prayer times
  - Iqomah countdown: Larger on desktop (3em font, 600px max-width)

- **Body** (lines 136-200):
  - `#main` div for Elm app mounting
  - `#status` div for Service Worker status messages
  - Elm initialization with flags: `Elm.Main.init({ node: node, flags: flags })` (lines 171-174)
  - **URL parameter parsing** for test mode (lines 162-169)
  - **Geolocation port subscription** (lines 177-195)
  - Service Worker registration with fallback (lines 198-210)

**JavaScript Features**:

1. **Test Mode Parameters** (lines 162-164):
   ```javascript
   var testIqomah = urlParams.get('testIqomah');  // Prayer name
   var testOffset = parseInt(urlParams.get('offset')) || 1;  // Minutes
   ```

2. **Geolocation Handler** (lines 177-195):
   ```javascript
   app.ports.requestLocation.subscribe(function() {
     navigator.geolocation.getCurrentPosition(
       function(position) {
         app.ports.receiveLocation.send({
           latitude: position.coords.latitude,
           longitude: position.coords.longitude
         });
       }
     );
   });
   ```

**Service Worker Flow**:
1. Check if Service Worker is supported
2. Register `service-worker.js`
3. Wait until installed
4. Load Elm application with flags
5. Setup port subscriptions
6. Show error message if not supported

---

#### `service-worker.js` (135 lines)
**Purpose**: Offline caching for PWA functionality

**Configuration**:
- **Cache version: 23** (line 15) - Must increment when deploying changes
- Cache name: `prefetch-cache-v23` (line 17)

**Cached Resources** (lines 23-27):
- `elm.js` - Compiled Elm application
- `index.html` - Application shell
- `manifest.json` - PWA manifest

**Event Handlers**:
1. **Install** (line 20): Pre-caches essential resources
   - Adds cache-busting timestamp to URLs
   - Uses no-cors mode for cross-origin resources

2. **Activate** (line 80): Cleans up old cache versions
   - Deletes caches not in CURRENT_CACHES

3. **Fetch** (line 103): Cache-first strategy
   - Returns cached response if available
   - Falls back to network if not in cache
   - Does not cache network responses (simple implementation)

**Note**: URL parameters for test mode do NOT interfere with Service Worker caching.

---

#### `manifest.json` (9 lines)
**Purpose**: PWA configuration

**Settings**:
- App name: "Waktu Sholat App"
- Start URL: index.html
- Display: standalone (full-screen, no browser UI)
- Orientation: portrait (locked)
- Theme color: #81F781 (light green)

---

### Configuration

#### `elm.json` (24 lines)
**Purpose**: Elm 0.19 project configuration and dependencies

**Type**: application

**Dependencies (direct)**:
- `elm/browser`: 1.0.2 - For Browser.element
- `elm/core`: 1.0.5 - Core Elm functions
- `elm/html`: 1.0.0 - HTML rendering
- `elm/time`: 1.0.0 - Time handling (replaces Date)

**Dependencies (indirect)**:
- `elm/json`: 1.1.3
- `elm/url`: 1.0.0
- `elm/virtual-dom`: 1.0.3

**Elm Version**: 0.19.1

**Source Directory**: `src/`

**Note**: This replaced `elm-package.json` from Elm 0.18

---

### Build and Deployment

#### `script.sh` (4 lines)
**Purpose**: Simple test/build script (currently just echoes "Success")

**Note**: Actual Elm compilation uses:
```bash
elm make src/Main.elm --output=elm.js
```

---

## Development Workflow

### Building the Application

1. **Install Elm 0.19.1**:
   ```bash
   # Download Elm binary
   curl -L -o elm.gz https://github.com/elm/compiler/releases/download/0.19.1/binary-for-linux-64-bit.gz
   gunzip elm.gz
   chmod +x elm
   sudo mv elm /usr/local/bin/elm

   # Verify installation
   elm --version  # Should show: 0.19.1
   ```

2. **Install Dependencies** (optional, downloads on first compile):
   ```bash
   # Dependencies are downloaded automatically on first compile
   # But you can pre-install with:
   elm make src/Main.elm --output=/dev/null
   ```

3. **Compile**:
   ```bash
   elm make src/Main.elm --output=elm.js
   ```

4. **Serve Locally**:
   ```bash
   # Simple HTTP server for testing
   python3 -m http.server 8000
   # or
   npx http-server -p 8000
   ```

5. **Update Service Worker Cache Version**:
   - Increment `CACHE_VERSION` in `service-worker.js:15` when deploying changes
   - This ensures users get the latest version
   - **Current version: 23**

6. **Testing**:
   - Open `http://localhost:8000`
   - For Iqomah testing: `http://localhost:8000?testIqomah=subuh&offset=1`

---

## Key Concepts and Algorithms

### Prayer Time Calculation

The application uses astronomical calculations based on the position of the sun. Here's the flow:

1. **Get Current Date and Location**
   - Date/time from system time (converted to TimeInfo)
   - Local timezone auto-detected (Time.here)
   - Location from browser Geolocation API or default coordinates

2. **Calculate Julian Date**
   - Converts Gregorian calendar (TimeInfo) to Julian date for astronomical calculations
   - Adjusts for longitude to get local Julian date

3. **Calculate Sun Position**
   - Mean anomaly and longitude
   - Ecliptic longitude
   - Declination and equation of time

4. **Calculate Each Prayer Time**
   - **Fajr**: Sun at 20° below horizon (before sunrise)
   - **Sunrise**: Sun at 0.833° below horizon (accounting for refraction)
   - **Dhuhr**: Solar noon (sun at highest point)
   - **Asr**: When shadow length = object length + 1
   - **Maghrib**: Sun at 1° below horizon (just after sunset)
   - **Isha**: Sun at 18° below horizon (after sunset)

5. **Adjust for Timezone and Longitude**
   - Convert from solar time to local time
   - Apply timezone offset (GMT+7)
   - Adjust for longitude difference from timezone meridian

6. **Format and Display**
   - Round to nearest minute
   - Format as HH:MM
   - Display in UI

### Iqomah Countdown Feature

**What is Iqomah?**: The second call to prayer, signaling that congregation prayer is about to begin (usually 5-10 minutes after Adhan).

**How it Works**:
1. Every second, check current time against all prayer times
2. If within 5 minutes after any prayer (except Terbit), show countdown
3. Calculate remaining seconds: `(5 * 60) - (current time - prayer time)`
4. Format as "X min Y sec"
5. Display in golden/yellow box below clock

**Implementation**:
- `findIqomahStatus`: Checks all prayer times, returns active Iqomah if any
- `timeInfoToSeconds`: Converts TimeInfo to seconds since midnight
- `timeStringToSeconds`: Converts "HH:MM" string to seconds
- `formatIqomahTime`: Formats seconds as "X min Y sec"
- `htmlIqomahCountdown`: Renders the countdown UI component

**Styling**:
- Background: #FFD700 (gold)
- Border: 2px solid #FFA500 (orange)
- Label color: #8B4513 (brown)
- Countdown color: #8B0000 (dark red)

### Geolocation Feature

**Implementation**: JavaScript ports (Elm 0.19 doesn't have core geolocation)

**Flow**:
1. User clicks "Cek Lokasi" button
2. Elm sends `RequestLocation` message
3. Update function calls `requestLocation ()` port
4. JavaScript receives request via `app.ports.requestLocation.subscribe`
5. JavaScript calls `navigator.geolocation.getCurrentPosition`
6. JavaScript sends coordinates back via `app.ports.receiveLocation.send`
7. Elm receives via `ReceiveLocation` message
8. Model updates with new location
9. Prayer times recalculate automatically

**Default Location**: Senayan City, Jakarta (-6.2276252, 106.7947417)

**Error Handling**: If geolocation fails, app continues with default/previous location

**Requirements**:
- HTTPS or localhost (browser security requirement)
- User permission (browser prompt)
- User interaction (button click)

### Test Mode Feature

**Purpose**: Easily test Iqomah countdown without waiting for actual prayer times

**Usage**:
```
http://localhost:8000?testIqomah=<prayer>&offset=<minutes>
```

**Examples**:
```bash
# Test Subuh Iqomah (1 minute after by default)
?testIqomah=subuh

# Test Zuhur Iqomah 3 minutes after
?testIqomah=zuhur&offset=3

# Test Magrib Iqomah at exact prayer time
?testIqomah=magrib&offset=0

# Test Isya Iqomah 4 minutes after
?testIqomah=isya&offset=4
```

**Valid Prayer Names** (case-insensitive):
- `subuh` (Fajr)
- `terbit` (Sunrise, but countdown won't show)
- `zuhur` (Dhuhr)
- `ashar` (Asr)
- `magrib` (Maghrib)
- `isya` (Isha)

**How it Works**:
1. JavaScript parses URL parameters: `URLSearchParams(window.location.search)`
2. Passes `testIqomah` and `offset` as flags to Elm
3. Elm stores in model: `testMode` and `testOffset`
4. View calculates simulated time: `prayer time + offset minutes`
5. Clock displays simulated time
6. Iqomah countdown shows based on simulated time
7. Red banner shows: "TEST MODE: SUBUH + 3 min"

**Visual Indicator**:
- Red banner (#ff6b6b background, white text)
- Shows prayer name in uppercase
- Shows offset in minutes
- Only appears when test mode is active

**Notes**:
- Clock still ticks (updates every second)
- All other features work normally
- Does NOT interfere with Service Worker
- Remove URL parameters to exit test mode

---

## Elm 0.19 Migration Notes

### What Changed from 0.18 to 0.19

**Breaking Changes**:
1. **Package System**:
   - `elm-package.json` → `elm.json`
   - Package names: `elm-lang/core` → `elm/core`
   - No more `elm-lang/geolocation` (removed from core)

2. **Application Setup**:
   - `Html.program` → `Browser.element`
   - Init function signature: `() -> (Model, Cmd Msg)` requires flags type
   - Port modules must declare: `port module Main exposing (main)`

3. **Date/Time**:
   - `Date` module removed
   - Use `Time.Posix` and `Time.Zone` instead
   - `Time.now : Task x Posix`
   - `Time.here : Task x Zone`

4. **String Conversion**:
   - `toString` → `String.fromInt`, `String.fromFloat`

5. **Result/Maybe**:
   - `Result.withDefault` works the same
   - `Maybe.withDefault` works the same

6. **Geolocation**:
   - No core package in 0.19
   - Must use JavaScript ports for geolocation

### Migration Steps Taken

1. Created `elm.json` with Elm 0.19 dependencies
2. Rewrote `Main.elm` to use `Browser.element`
3. Replaced `Date` with `TimeInfo` type and `Time.Posix`
4. Replaced `toString` with `String.fromInt`
5. Implemented geolocation via JavaScript ports
6. Updated `PrayTime.elm` to accept `TimeInfo` instead of `Date`
7. Updated `index.html` to use `Elm.Main.init` instead of `Elm.Main.embed`
8. Compiled with Elm 0.19.1 compiler

---

## Common Modifications

### Changing Default Location

**File**: `src/Main.elm:54-57`

```elm
, location =
    { latitude = -6.2276252    -- Change this
    , longitude = 106.7947417  -- Change this
    }
```

### Changing Timezone

**File**: `src/Main.elm:130`

```elm
timeZone = 7  -- Change to your GMT offset (for prayer calculation)
```

**Note**: The clock automatically uses the user's local timezone (detected via `Time.here`).

### Changing Iqomah Duration

**File**: `src/Main.elm:348`

```elm
iqomahDuration =
    5 * 60  -- Change from 5 minutes to desired duration (in seconds)
```

### Changing Prayer Time Calculation Method

**File**: `src/PrayTime.elm:42-57`

Different Islamic organizations use different angles:
- **Fajr angle** (line 42): 20° (current), could be 18°, 19.5°, etc.
- **Isha angle** (line 56): 18° (current), could be 17°, etc.
- **Asr factor** (line 51): 1 (Shafi'i), could be 2 (Hanafi)

### Adding More Cached Resources

**File**: `service-worker.js:23-27`

Add files to the `urlsToPrefetch` array and increment `CACHE_VERSION`.

### Customizing Iqomah Styling

**File**: `index.html:21-40` (mobile), `87-101` (desktop)

```css
.time__iqomah {
  background-color: #FFD700;  /* Gold - change to your color */
  border: 2px solid #FFA500;  /* Orange - change border color */
  /* ... */
}
```

---

## Troubleshooting

### Prayer Times Seem Incorrect

1. **Check timezone**: Prayer calculations use GMT+7, but clock shows local time
2. **Check location**: Use "Cek Lokasi" to get accurate coordinates
3. **Verify calculation method**: Different methods use different angles
4. **Check date/time**: System time must be accurate
5. **Check browser console**: Look for JavaScript errors

### Iqomah Countdown Not Appearing

1. **Check if within 5 minutes after prayer**: Countdown only shows during Iqomah window
2. **Use test mode**: Try `?testIqomah=subuh&offset=1` to force display
3. **Check prayer times**: Make sure prayer times are displayed correctly
4. **Exclude Terbit**: Countdown doesn't appear for sunrise (Terbit)
5. **Check time accuracy**: Clock must match actual time

### Geolocation Not Working

1. **HTTPS Required**: Geolocation API requires secure context (HTTPS or localhost)
2. **Permission Denied**: User must grant location permission
3. **Browser compatibility**: Check if browser supports geolocation
4. **Check console**: Look for errors in browser console
5. **Fallback**: App continues with default location if geolocation fails

### Test Mode Not Working

1. **URL format**: Use `?testIqomah=subuh&offset=3` (lowercase prayer name)
2. **Refresh page**: URL parameters are read on page load
3. **Check for typos**: Prayer names must match exactly (subuh, zuhur, ashar, magrib, isya)
4. **Check console**: Browser console will show if flags are received
5. **Remove parameters**: Go to `http://localhost:8000` to exit test mode

### App Not Working Offline

1. **Service Worker not registered**: Check browser compatibility
2. **Cache version**: May need to increment and reload
3. **Resources not cached**: Verify `urlsToPrefetch` array includes all needed files
4. **First load**: Must load online once before offline works
5. **Clear cache**: Try clearing browser cache and reloading

### Elm Compilation Issues

1. **Version check**: This project requires Elm 0.19.1
   ```bash
   elm --version  # Should show: 0.19.1
   ```

2. **Dependencies missing**: Dependencies download automatically on first compile
   - Wait for downloads to complete
   - Check internet connection

3. **Syntax errors**:
   - Elm 0.19 is strict about unused imports
   - Check for proper type annotations
   - Use Elm error messages (they're helpful!)

4. **Port issues**:
   - Module must be declared as `port module`
   - Port functions must have specific signatures
   - Can't test ports in `elm repl`

### Clock Shows Wrong Time

1. **Check timezone detection**: Clock uses `Time.here` to auto-detect timezone
2. **System time**: Make sure your system time is correct
3. **Browser timezone**: Make sure browser timezone matches system
4. **Test mode active**: Check if test mode is enabled (red banner)

---

## Git Information

**Current Branch**: `claude/add-iqomah-countdown-011CUMb2qmRH4eDNn3fREP7d`

**Recent Commits**:
- `d41d78e` - Add test mode for Iqomah countdown via URL parameters
- `828ab62` - Restore geolocation button using JavaScript ports
- `5bd2154` - Fix timezone to display local time instead of UTC
- `7422998` - Fix Elm 0.19 initialization in index.html
- `c5504fd` - Compile Elm code with Iqomah countdown and upgrade to Elm 0.19
- `11cb586` - Add Iqomah countdown feature for prayer times

**Branch Purpose**: Add Iqomah countdown feature and upgrade to Elm 0.19

---

## Quick Reference

### File Locations for Common Tasks

- **Change prayer calculation method**: `src/PrayTime.elm:42-57`
- **Change default location**: `src/Main.elm:54-57`
- **Change timezone for calculations**: `src/Main.elm:130`
- **Change Iqomah duration**: `src/Main.elm:348`
- **Modify UI styles**: `index.html:10-131`
- **Modify Iqomah styles**: `index.html:21-40, 87-101`
- **Update cached files**: `service-worker.js:23-27`
- **Change app name/theme**: `manifest.json`
- **Add geolocation logic**: `index.html:177-195`
- **Modify test mode logic**: `src/Main.elm:282-333`

### Important Constants

- **Cache Version**: 23 (`service-worker.js:15`)
- **Theme Color**: #81F781 (`index.html:8`, `manifest.json:7`)
- **Iqomah Color**: #FFD700 gold (`index.html:22`)
- **Responsive Breakpoint**: 1000px (`index.html:69`)
- **Clock Update Interval**: 1 second (`src/Main.elm:84`)
- **Prayer Calculation Timezone**: GMT+7 (`src/Main.elm:130`)
- **Iqomah Duration**: 5 minutes = 300 seconds (`src/Main.elm:348`)
- **Default Test Offset**: 1 minute (`index.html:164`)

### Port Names

- **outgoing**: `requestLocation : () -> Cmd msg`
- **incoming**: `receiveLocation : (LatLong -> msg) -> Sub msg`

### Test Mode URL Parameters

- **testIqomah**: Prayer name (subuh, zuhur, ashar, magrib, isya)
- **offset**: Minutes after prayer time (default: 1)

---

## External Resources

- **Elm 0.19 Documentation**: https://guide.elm-lang.org/
- **Elm Package Docs**: https://package.elm-lang.org/
- **Prayer Time Calculation**: Based on astronomical algorithms
- **Service Worker API**: https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API
- **Geolocation API**: https://developer.mozilla.org/en-US/docs/Web/API/Geolocation_API
- **PWA Best Practices**: https://web.dev/progressive-web-apps/
- **Elm Ports Guide**: https://guide.elm-lang.org/interop/ports.html
- **Time in Elm**: https://package.elm-lang.org/packages/elm/time/latest/

---

## Important Notes for Claude

### Current Architecture (Elm 0.19.1)

1. **Port Module**: Main.elm is a port module for JavaScript interop
   - Geolocation via ports (not core package)
   - Ports cannot be tested in `elm repl`
   - Port signatures must match exactly

2. **Time Handling**:
   - Use `Time.Posix` for timestamps
   - Use `Time.Zone` for timezone
   - Use `TimeInfo` custom type for prayer calculations
   - Clock auto-detects local timezone via `Time.here`

3. **Flags System**:
   - Application accepts flags on init
   - Flags are parsed from URL parameters in JavaScript
   - Type safety enforced: `Flags` type must match JavaScript object

4. **Service Worker**:
   - Simple cache-first implementation
   - Only pre-caches 3 files (elm.js, index.html, manifest.json)
   - Network responses are not cached
   - Cache must be manually versioned
   - **Always increment `CACHE_VERSION` when deploying**

5. **Test Mode**:
   - Client-side only (doesn't affect Service Worker)
   - URL parameters are read on page load
   - Simulates time by overriding clock display
   - Useful for testing Iqomah countdown
   - Shows visual indicator (red banner)

### Development Best Practices

1. **Before Committing**:
   - Compile Elm: `elm make src/Main.elm --output=elm.js`
   - Increment Service Worker cache version
   - Test locally with `python3 -m http.server 8000`
   - Test Iqomah countdown with test mode
   - Test geolocation button

2. **When Modifying Elm Code**:
   - Always recompile after changes
   - Check for type errors (Elm compiler is helpful)
   - Test in browser (not just compile)

3. **When Modifying Ports**:
   - Update both Elm side (port declaration) and JavaScript side (subscription)
   - Port types must match exactly
   - Test send/receive flow

4. **When Modifying Service Worker**:
   - Increment `CACHE_VERSION`
   - Test offline functionality
   - Clear browser cache to test fresh install

### Gotchas

1. **Elm 0.19 vs 0.18**: This is 0.19, syntax is different
2. **Ports**: Can't use in `elm repl`, must test in browser
3. **Time zones**: Prayer calc uses GMT+7, but clock auto-detects local
4. **Service Worker**: Changes won't apply until cache version increments
5. **Test mode**: Only works with URL parameters, not dynamic
6. **Geolocation**: Requires HTTPS or localhost
7. **Iqomah duration**: Hardcoded to 5 minutes
8. **Prayer names**: Must match exactly (case-insensitive) for test mode

---

*This document was created to help Claude navigate and understand the time-keeper repository efficiently. Last updated with Iqomah countdown feature, Elm 0.19 migration, geolocation ports, and test mode.*
