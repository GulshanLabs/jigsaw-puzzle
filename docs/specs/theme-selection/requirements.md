# Requirements Document

## Introduction

This document specifies the requirements for adding a Theme Selection feature to the Jigsaw Puzzle Game app. The feature allows users to choose from a set of predefined color themes (including Light, Dark, and custom palettes) via the existing settings bottom sheet. The selected theme applies globally to all screens, auto-adjusts button colors for contrast, and persists across app restarts using the existing SharedPreferences infrastructure.

## Glossary

- **Theme_Selector**: The UI component within the settings bottom sheet that displays available themes and allows the user to select one.
- **Theme_Cubit**: The BLoC-pattern Cubit responsible for managing the current theme state, loading the persisted theme on startup, and emitting theme changes to the widget tree.
- **Preferences_Repository**: The existing persistence layer (`PreferencesRepository`) backed by SharedPreferences, extended to store and retrieve the selected theme identifier.
- **App_Theme**: A data model representing a single color theme, containing an identifier, display name, background color, and derived surface/button colors.
- **Theme_Registry**: The predefined, ordered collection of all available App_Theme instances.
- **Active_Theme**: The App_Theme currently applied to the application.
- **Contrast_Calculator**: The logic that derives foreground and button colors from a given background color to meet readable contrast.

## Requirements

### Requirement 1: Predefined Theme Catalog

**User Story:** As a player, I want a set of predefined color themes to choose from, so that I can personalize the look of the app.

#### Acceptance Criteria

1. THE Theme_Registry SHALL contain exactly five App_Theme instances in the following order: Light, Dark, Ocean, Sunset, Forest.
2. THE App_Theme for "Light" SHALL use a light background color and dark foreground colors.
3. THE App_Theme for "Dark" SHALL use a dark background color and light foreground colors.
4. THE App_Theme for "Ocean" SHALL use a blue-toned background color palette.
5. THE App_Theme for "Sunset" SHALL use a warm orange/red-toned background color palette.
6. THE App_Theme for "Forest" SHALL use a green-toned background color palette.
7. WHEN no theme preference has been previously saved, THE Theme_Cubit SHALL default to the "Light" theme.

### Requirement 2: Theme Selection UI

**User Story:** As a player, I want to select a theme from the settings bottom sheet, so that I can change the app appearance without leaving my current screen.

#### Acceptance Criteria

1. WHEN the settings bottom sheet is opened, THE Theme_Selector SHALL display all five themes from the Theme_Registry as selectable options.
2. THE Theme_Selector SHALL display each theme option with the theme display name and a color preview swatch showing the theme background color.
3. WHILE a theme is the Active_Theme, THE Theme_Selector SHALL visually indicate the active theme with a distinct selected state (e.g., a check mark or highlighted border).
4. WHEN the user taps a theme option in the Theme_Selector, THE Theme_Cubit SHALL emit the selected App_Theme as the new Active_Theme.
5. THE Theme_Selector SHALL be rendered below the existing Sound Effects toggle within the settings bottom sheet.

### Requirement 3: Global Theme Application

**User Story:** As a player, I want the selected theme to change the look of every screen, so that the app feels consistent.

#### Acceptance Criteria

1. WHEN the Active_Theme changes, THE App SHALL update the background color of PhotoSourceScreen, GridConfigScreen, BoardScreen, and CompletionScreen to match the Active_Theme background color.
2. WHEN the Active_Theme changes, THE App SHALL update the AppBar background color on all screens to match the Active_Theme color scheme.
3. WHEN the Active_Theme changes, THE App SHALL update text colors on all screens to maintain readability against the Active_Theme background color.
4. THE App SHALL apply the Active_Theme by rebuilding the MaterialApp-level ThemeData so that all Material widgets inherit the theme automatically.

### Requirement 4: Button Contrast Auto-Adjustment

**User Story:** As a player, I want buttons to remain readable regardless of the selected theme, so that I can always interact with the app comfortably.

#### Acceptance Criteria

1. WHEN the Active_Theme changes, THE Contrast_Calculator SHALL derive ElevatedButton foreground and background colors that provide readable contrast against the Active_Theme background color.
2. WHEN the Active_Theme changes, THE Contrast_Calculator SHALL derive OutlinedButton foreground and border colors that provide readable contrast against the Active_Theme background color.
3. WHEN the Active_Theme changes, THE Contrast_Calculator SHALL derive IconButton icon colors that provide readable contrast against the AppBar color.
4. FOR ALL five themes in the Theme_Registry, THE Contrast_Calculator SHALL produce button colors where the foreground-to-background luminance contrast ratio is at least 4.5:1 per WCAG AA guidelines.

### Requirement 5: Theme Persistence

**User Story:** As a player, I want my theme choice to be remembered after I close and reopen the app, so that I do not have to reselect it every time.

#### Acceptance Criteria

1. WHEN the user selects a theme, THE Preferences_Repository SHALL persist the selected App_Theme identifier to SharedPreferences.
2. WHEN the app starts, THE Theme_Cubit SHALL load the persisted theme identifier from the Preferences_Repository and emit the corresponding App_Theme as the Active_Theme.
3. IF the persisted theme identifier does not match any theme in the Theme_Registry, THEN THE Theme_Cubit SHALL fall back to the "Light" theme and persist the corrected identifier.
4. IF no theme identifier is found in SharedPreferences, THEN THE Theme_Cubit SHALL use the "Light" theme as the default Active_Theme.

### Requirement 6: Theme Data Model Serialization

**User Story:** As a developer, I want theme identifiers to serialize and deserialize reliably, so that persistence is robust.

#### Acceptance Criteria

1. THE App_Theme model SHALL include a unique string identifier for each theme (e.g., "light", "dark", "ocean", "sunset", "forest").
2. WHEN a theme identifier string is provided, THE Theme_Registry SHALL return the matching App_Theme instance.
3. FOR ALL App_Theme instances in the Theme_Registry, serializing the identifier and then looking it up SHALL return an equivalent App_Theme (round-trip property).
