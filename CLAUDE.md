# CLAUDE.md - Repository Navigation Guide

## Project Overview

**time-keeper** is a Progressive Web App (PWA) that displays Islamic prayer times (Waktu Sholat) based on the user's geographic location. The application is built with Elm and features offline capabilities through Service Workers.

### Key Features
- Real-time clock display
- Automatic prayer time calculation based on astronomical algorithms
- Geolocation support for accurate prayer times
- Offline-first PWA with Service Worker caching
- Responsive design for mobile and desktop
- Default location: Senayan City, Jakarta (lat: -6.2276252, lng: 106.7947417)

### Tech Stack
- **Language**: Elm 0.18
- **Dependencies**: elm-lang/core, elm-lang/html, elm-lang/geolocation
- **PWA**: Service Worker with cache-first strategy
- **Styling**: Inline CSS with responsive breakpoints

---

## Repository Structure

```
/home/user/time-keeper/
├── src/
│   ├── Main.elm              # Main application logic and UI
│   └── PrayTime.elm          # Prayer time calculation algorithms
├── index.html                # Application entry point
├── elm.js                    # Compiled Elm application (generated)
├── manifest.json             # PWA manifest configuration
├── service-worker.js         # Service Worker for offline functionality
├── serviceworker-cache-polyfill.js  # Service Worker polyfill
├── script.sh                 # Simple build/test script
├── elm-package.json          # Elm package dependencies
└── README.md                 # Project documentation (minimal)
```

---

## Core Files and Their Purposes

### Application Logic

#### `src/Main.elm` (162 lines)
**Purpose**: Main application entry point and UI rendering

**Key Components**:
- **Model** (lines 22-31):
  - `time: Time` - Current timestamp
  - `location: LatLong` - User's coordinates (default: Senayan City)

- **Messages** (lines 46-50):
  - `Tick Time` - Updates every second
  - `LookupLocation` - Triggered by "Cek Lokasi" button
  - `Success Location` - Geolocation success
  - `Failure Geolocation.Error` - Geolocation failure

- **Update Function** (lines 53-70): Handles state updates

- **View Function** (lines 78-112):
  - Displays current time as HH:MM:SS
  - Shows 6 prayer times (Subuh, Terbit, Zuhur, Ashar, Magrib, Isya)
  - Renders "Cek Lokasi" button for geolocation

- **Key Functions**:
  - `formattedDate` (line 115): Formats time to HH:MM:SS
  - `toHtmlClock` (line 130): Renders clock display
  - `htmlTimeStructure` (line 136): Renders each prayer time card
  - `processLocation` (line 148): Handles geolocation result

**Hard-coded Values**:
- Time zone: GMT+7 (line 94)
- Elevation: 0 meters (line 91)

---

#### `src/PrayTime.elm` (377 lines)
**Purpose**: Astronomical calculations for Islamic prayer times

**Key Components**:

1. **Data Types**:
   - `PrayTimes` (lines 17-24): Raw prayer times as Float (hours)
   - `FormattedPrayTimes` (lines 60-67): Formatted prayer times as String (HH:MM)
   - `SunPosition` (lines 303-304): Declination and equation of time

2. **Main Calculation Pipeline** (used in Main.elm:97-101):
   ```elm
   calculatePrayTimes -> adjustTimes -> formatTimes -> toTimeList
   ```

3. **Core Functions**:
   - `calculatePrayTimes` (line 27): Master function that calculates all prayer times
     - Parameters: latitude, longitude, elevation, timeZone, date
     - Uses sun angle calculations for each prayer

   - `sunAngleTime` (line 160): Calculates prayer time for given sun angle
     - Used for Fajr (20°), Sunrise (0.833°), Maghrib (1°), Isha (18°)

   - `calcAsrTime` (line 139): Special calculation for Asr prayer
     - Uses shadow length factor (default: 1)

   - `midDayTime` (line 204): Calculates Dhuhr (midday) time

   - `adjustTimes` (line 103): Adjusts times for timezone and longitude
     - Adds 2-minute correction for most prayers
     - Adds -2 minute correction for sunrise

4. **Astronomical Utilities**:
   - `toJulianDate` (line 270): Converts Gregorian date to Julian date
   - `sunPosition` (line 307): Calculates sun's declination and equation of time
   - `riseSetAngle` (line 216): Calculates angle adjustment for elevation
   - `fixAngle` (line 369): Normalizes angles to 0-360°
   - `fixHour` (line 374): Normalizes hours to 0-24

5. **Prayer Time Labels** (lines 6-14):
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
- Asr: Shadow length = object length + 1

---

### Frontend and PWA

#### `index.html` (144 lines)
**Purpose**: Application shell and Service Worker registration

**Structure**:
- **Head** (lines 5-97):
  - Meta tags for viewport and theme color (#81F781 - light green)
  - Inline CSS with responsive breakpoints at 1000px
  - PWA manifest link

- **Styles**:
  - Mobile-first design (default width: 300px)
  - Desktop layout at 1000px+ (90% width, larger fonts)
  - Grid layout for prayer times on desktop (33% width per prayer)

- **Body** (lines 99-141):
  - `#main` div for Elm app mounting
  - `#status` div for Service Worker status messages
  - Elm initialization: `Elm.Main.embed(node)` (line 123)
  - Service Worker registration with fallback (lines 126-139)

**Service Worker Flow**:
1. Check if Service Worker is supported
2. Register `service-worker.js`
3. Wait until installed
4. Load Elm application
5. Show error message if not supported

---

#### `service-worker.js` (135 lines)
**Purpose**: Offline caching for PWA functionality

**Configuration**:
- Cache version: 18 (line 15)
- Cache name: `prefetch-cache-v18` (line 17)

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

#### `elm-package.json` (17 lines)
**Purpose**: Elm project configuration and dependencies

**Dependencies**:
- `elm-lang/core`: 5.0.0 - 6.0.0
- `elm-lang/html`: 2.0.0 - 3.0.0
- `elm-lang/geolocation`: 1.0.0 - 2.0.0

**Elm Version**: 0.18.0 (legacy version)

**Source Directory**: `src/`

---

### Build and Deployment

#### `script.sh` (4 lines)
**Purpose**: Simple test/build script (currently just echoes "Success")

**Note**: This appears to be a placeholder. Actual Elm compilation would use:
```bash
elm-make src/Main.elm --output=elm.js
```

---

## Development Workflow

### Building the Application

1. **Install Elm 0.18**:
   ```bash
   npm install -g elm@0.18
   ```

2. **Install Dependencies**:
   ```bash
   elm-package install
   ```

3. **Compile**:
   ```bash
   elm-make src/Main.elm --output=elm.js
   ```

4. **Serve Locally**:
   ```bash
   # Simple HTTP server for testing
   python -m http.server 8000
   # or
   npx serve .
   ```

5. **Update Service Worker Cache Version**:
   - Increment `CACHE_VERSION` in `service-worker.js:15` when deploying changes
   - This ensures users get the latest version

---

## Key Concepts and Algorithms

### Prayer Time Calculation

The application uses astronomical calculations based on the position of the sun. Here's the flow:

1. **Get Current Date and Location**
   - Date from system time
   - Location from browser Geolocation API or default coordinates

2. **Calculate Julian Date**
   - Converts Gregorian calendar to Julian date for astronomical calculations
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

### Geolocation Feature

- **Default Location**: Senayan City, Jakarta (-6.2276252, 106.7947417)
- **User Action**: Click "Cek Lokasi" button
- **Browser Prompt**: Asks for location permission
- **On Success**: Updates prayer times for user's location
- **On Failure**: Continues using default or previous location

---

## Common Modifications

### Changing Default Location

**File**: `src/Main.elm:41-42`

```elm
, location = { latitude = -6.2276252    -- Change this
             , longitude = 106.7947417 } -- Change this
```

### Changing Timezone

**File**: `src/Main.elm:94`

```elm
timeZone = toFloat 7  -- Change to your GMT offset
```

### Changing Prayer Time Calculation Method

**File**: `src/PrayTime.elm:34-49`

Different Islamic organizations use different angles:
- **Fajr angle** (line 34): 20° (current), could be 18°, 19.5°, etc.
- **Isha angle** (line 48): 18° (current), could be 17°, etc.
- **Asr factor** (line 43): 1 (Shafi'i), could be 2 (Hanafi)

### Adding More Cached Resources

**File**: `service-worker.js:23-27`

Add files to the `urlsToPrefetch` array and increment `CACHE_VERSION`.

---

## Troubleshooting

### Prayer Times Seem Incorrect

1. **Check timezone** (`src/Main.elm:94`): Should match your GMT offset
2. **Check location**: Use "Cek Lokasi" to get accurate coordinates
3. **Verify calculation method**: Different methods use different angles
4. **Check date/time**: System time must be accurate

### Geolocation Not Working

1. **HTTPS Required**: Geolocation API requires secure context (HTTPS or localhost)
2. **Permission Denied**: User must grant location permission
3. **Fallback**: App continues with default location if geolocation fails

### App Not Working Offline

1. **Service Worker not registered**: Check browser compatibility
2. **Cache version**: May need to increment and reload
3. **Resources not cached**: Verify `urlsToPrefetch` array includes all needed files

### Elm Compilation Issues

- **Version mismatch**: This project requires Elm 0.18 (legacy version)
- **Modern Elm (0.19+)**: Would require significant code changes
  - `Html.program` → `Browser.element`
  - `toString` → `String.fromInt`
  - Module declarations changed
  - `Date` module completely redesigned

---

## Git Information

**Current Branch**: `claude/create-claude-readme-011CUMacse7bMcnYBt57ghe4`

**Recent Commits**:
- `94d4f8e` - Create script.sh
- `f18d10a` - default location to Senayan City
- `62b6413` - Fix button styling safari
- `e73f69d` - Still load application when service worker not supported
- `e5c2725` - Fix manifest.json

---

## Future Enhancement Ideas

1. **User Preferences**:
   - Save preferred location
   - Choose calculation method
   - Select timezone manually
   - Dark mode support

2. **Features**:
   - Notifications before prayer times
   - Qibla direction indicator
   - Prayer time history
   - Multiple location bookmarks
   - Hijri calendar integration

3. **Technical Improvements**:
   - Upgrade to Elm 0.19.1
   - Add TypeScript types for ports
   - Improve Service Worker caching strategy
   - Add unit tests for prayer calculations
   - Reduce bundle size
   - Add build scripts

4. **UI/UX**:
   - Show time until next prayer
   - Highlight current/next prayer
   - Add prayer name translations
   - Improve mobile gestures
   - Add loading states

---

## Important Notes for Claude

1. **Elm 0.18 Syntax**: This is a legacy version. Be careful with syntax that changed in 0.19+
   - Use `Html.program` not `Browser.element`
   - Use `toString` not `String.fromInt`
   - Date module is different

2. **No Build System**: Currently no package.json or automated build
   - Would need to compile Elm manually
   - Service Worker cache version must be manually incremented

3. **Hardcoded Values**: Several values are hardcoded that might need to be configurable:
   - Timezone (GMT+7)
   - Default location (Senayan City)
   - Prayer calculation angles
   - Elevation (0 meters)

4. **Service Worker**: Simple cache-first implementation
   - Only pre-caches 3 files
   - Network responses are not cached
   - Cache must be manually versioned

5. **Geolocation**: Requires user interaction and permission
   - Won't work on first load without user action
   - Requires HTTPS in production

---

## Quick Reference

### File Locations for Common Tasks

- **Change prayer calculation method**: `src/PrayTime.elm:34-49`
- **Change default location**: `src/Main.elm:41-42`
- **Change timezone**: `src/Main.elm:94`
- **Modify UI styles**: `index.html:10-94`
- **Update cached files**: `service-worker.js:23-27`
- **Change app name/theme**: `manifest.json`
- **Add new Elm dependencies**: `elm-package.json:10-13`

### Important Constants

- **Cache Version**: 18 (`service-worker.js:15`)
- **Theme Color**: #81F781 (`index.html:8`, `manifest.json:7`)
- **Responsive Breakpoint**: 1000px (`index.html:51`)
- **Clock Update Interval**: 1 second (`src/Main.elm:75`)
- **Timezone**: GMT+7 (`src/Main.elm:94`)

---

## External Resources

- **Elm 0.18 Documentation**: https://elm-lang.org/docs (archived)
- **Prayer Time Calculation**: Based on astronomical algorithms
- **Service Worker API**: https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API
- **Geolocation API**: https://developer.mozilla.org/en-US/docs/Web/API/Geolocation_API
- **PWA Best Practices**: https://web.dev/progressive-web-apps/

---

*This document was created to help Claude navigate and understand the time-keeper repository efficiently.*
