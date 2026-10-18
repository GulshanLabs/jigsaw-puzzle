# Requirements Document

## Introduction

This document defines the requirements for a mobile jigsaw puzzle game app. The app allows users to create personalized puzzles from photos taken with their device camera or selected from their photo gallery. After choosing a photo, the user selects how many equal square pieces to divide the image into. The pieces are shuffled and displayed on a board, where the user rearranges them using a swap mechanic — tapping a piece and then tapping a destination swaps the two pieces — until the original image is reconstructed.

## Glossary

- **App**: The jigsaw puzzle mobile game application.
- **Camera**: The device's built-in camera hardware and associated OS-level capture interface.
- **Gallery**: The device's native photo library or media storage.
- **Source_Image**: The original photo selected or captured by the user, used as the basis for the puzzle.
- **Grid**: The N×N arrangement of equal square cells that the Source_Image is divided into.
- **Piece**: A single square tile that represents one cell of the Grid, containing a cropped portion of the Source_Image.
- **Board**: The interactive game screen displaying all Pieces in their current shuffled or rearranged positions.
- **Puzzle_State**: The current arrangement of all Pieces on the Board at any given moment.
- **Solved_State**: The Puzzle_State in which every Piece occupies its correct Grid position, reconstructing the Source_Image.
- **Swap**: The mechanic by which two Pieces exchange their Board positions.
- **Selection**: The act of tapping a Piece to mark it as the active piece awaiting a swap target.
- **Move_Count**: The running total of Swaps performed by the user during a puzzle session.
- **Timer**: The elapsed-time counter that tracks how long the user has been solving the current puzzle.
- **Permission_Manager**: The system component responsible for requesting and evaluating OS-level permissions.
- **Image_Processor**: The system component responsible for cropping, scaling, and splitting the Source_Image into Pieces.
- **Shuffle_Engine**: The system component responsible for randomising the initial Puzzle_State.
- **Win_Detector**: The system component responsible for evaluating whether the current Puzzle_State equals the Solved_State.

---

## Requirements

### Requirement 1: Camera Access Permission

**User Story:** As a player, I want the app to request camera access so that I can take a photo directly within the app to use as my puzzle image.

#### Acceptance Criteria

1. WHEN the user chooses to take a photo, THE Permission_Manager SHALL request camera permission from the operating system before activating the camera.
2. WHEN the operating system grants camera permission, THE App SHALL open the device camera interface for the user to capture a photo.
3. IF the user denies camera permission, THEN THE App SHALL display an explanatory message stating that camera access is required to take a photo, and SHALL present an option to open the device settings.
4. IF the user has previously denied camera permission permanently, THEN THE Permission_Manager SHALL direct the user to the device settings screen to manually enable camera access.

---

### Requirement 2: Photo Gallery Access

**User Story:** As a player, I want to upload a picture from my gallery so that I can use an existing photo as my puzzle image.

#### Acceptance Criteria

1. WHEN the user chooses to select a photo from the gallery, THE Permission_Manager SHALL request photo library read permission from the operating system.
2. WHEN the operating system grants photo library permission, THE App SHALL open the device's native photo picker interface.
3. WHEN the user selects a photo from the picker, THE App SHALL use that photo as the Source_Image.
4. IF the user denies photo library permission, THEN THE App SHALL display an explanatory message stating that gallery access is required to select a photo, and SHALL present an option to open the device settings.
5. IF the user cancels the photo picker without selecting a photo, THEN THE App SHALL return the user to the photo source selection screen without altering any existing state.

---

### Requirement 3: Photo Source Selection

**User Story:** As a player, I want to choose between taking a new photo or picking one from my gallery so that I have flexibility in how I create my puzzle.

#### Acceptance Criteria

1. THE App SHALL present the user with two clearly labelled options on the home screen: "Take a Photo" and "Choose from Gallery".
2. WHEN the user selects "Take a Photo", THE App SHALL initiate the camera permission and capture flow defined in Requirement 1.
3. WHEN the user selects "Choose from Gallery", THE App SHALL initiate the gallery permission and selection flow defined in Requirement 2.
4. WHEN a Source_Image has been successfully obtained by either method, THE App SHALL proceed to the puzzle configuration screen.

---

### Requirement 4: Puzzle Grid Size Selection

**User Story:** As a player, I want to choose how many pieces to divide my photo into so that I can control the difficulty of the puzzle.

#### Acceptance Criteria

1. WHEN the user arrives at the puzzle configuration screen, THE App SHALL display a preview of the Source_Image alongside a grid size selector.
2. THE App SHALL offer grid size options of 2×2 (4 pieces), 3×3 (9 pieces), 4×4 (16 pieces), 5×5 (25 pieces), and 6×6 (36 pieces).
3. WHEN the user selects a grid size, THE App SHALL update the Source_Image preview to overlay the corresponding Grid lines, showing how the image will be divided.
4. WHEN the user confirms the grid size selection, THE App SHALL pass the Source_Image and the selected grid dimensions to the Image_Processor.
5. THE App SHALL require the user to confirm a grid size selection before proceeding; THE App SHALL NOT advance to the Board without an explicit confirmation.

---

### Requirement 5: Image Processing and Piece Generation

**User Story:** As a player, I want my photo to be divided into equal square pieces so that the puzzle tiles are uniform and the image can be reconstructed correctly.

#### Acceptance Criteria

1. WHEN the Image_Processor receives the Source_Image and grid dimensions N, THE Image_Processor SHALL crop the Source_Image to a square aspect ratio before splitting, preserving the largest centred square region.
2. THE Image_Processor SHALL divide the cropped Source_Image into exactly N×N equal square Pieces, where each Piece has identical pixel dimensions.
3. THE Image_Processor SHALL assign each Piece a unique identifier corresponding to its correct Grid position (row, column).
4. WHEN image processing is complete, THE Image_Processor SHALL pass all N×N Pieces to the Shuffle_Engine.
5. IF the Image_Processor encounters an error reading or processing the Source_Image, THEN THE App SHALL display an error message and return the user to the photo source selection screen.

---

### Requirement 6: Puzzle Shuffling

**User Story:** As a player, I want the puzzle pieces to be shuffled into a random order so that the game presents a genuine challenge.

#### Acceptance Criteria

1. WHEN the Shuffle_Engine receives the set of Pieces, THE Shuffle_Engine SHALL randomise the positions of all Pieces to produce an initial Puzzle_State.
2. THE Shuffle_Engine SHALL ensure the initial Puzzle_State is not equal to the Solved_State; THE Shuffle_Engine SHALL re-shuffle if the first randomisation produces a solved arrangement.
3. WHEN shuffling is complete, THE App SHALL display the Board with all Pieces in their shuffled positions.

---

### Requirement 7: Board Display

**User Story:** As a player, I want to see all puzzle pieces displayed on a board so that I can view the current state of the puzzle and plan my moves.

#### Acceptance Criteria

1. THE Board SHALL display all N×N Pieces in a Grid layout that fills the available screen width, with each Piece scaled proportionally to fit.
2. THE Board SHALL render each Piece with its correct cropped image content visible at all times.
3. WHILE a puzzle session is active, THE Board SHALL display the current Move_Count and the current Timer value in a persistent header or overlay area.
4. THE Board SHALL remain responsive to user input at all times during an active puzzle session.

---

### Requirement 8: Piece Selection

**User Story:** As a player, I want to tap a puzzle piece to select it so that I can indicate which piece I want to move.

#### Acceptance Criteria

1. WHEN the user taps a Piece on the Board, THE App SHALL mark that Piece as the active Selection and apply a visible highlight or border to distinguish it from unselected Pieces.
2. WHEN a Piece is already selected and the user taps the same Piece again, THE App SHALL deselect it and remove the highlight, returning to a no-selection state.
3. WHILE a Piece is selected, THE Board SHALL remain fully interactive so the user can tap any other Piece to trigger a Swap.

---

### Requirement 9: Piece Swapping

**User Story:** As a player, I want to swap two pieces by selecting one and then tapping another so that I can rearrange the puzzle without needing empty spaces.

#### Acceptance Criteria

1. WHEN a Piece is selected and the user taps a different Piece on the Board, THE App SHALL swap the Board positions of the selected Piece and the tapped Piece.
2. WHEN a Swap is performed, THE App SHALL increment the Move_Count by 1.
3. WHEN a Swap is performed, THE App SHALL animate the two Pieces moving to their new positions with a transition duration of no more than 300 milliseconds.
4. WHEN a Swap is complete, THE App SHALL deselect all Pieces and pass the updated Puzzle_State to the Win_Detector.
5. THE App SHALL allow any Piece to be swapped with any other Piece regardless of their positions on the Board.

---

### Requirement 10: Win Detection

**User Story:** As a player, I want the app to detect when I have solved the puzzle so that I receive feedback on my completion.

#### Acceptance Criteria

1. WHEN the Win_Detector receives an updated Puzzle_State, THE Win_Detector SHALL compare each Piece's current Board position against its correct Grid position.
2. WHEN all Pieces occupy their correct Grid positions, THE Win_Detector SHALL signal a puzzle completion event to the App.
3. WHEN a puzzle completion event is received, THE App SHALL stop the Timer.
4. WHEN a puzzle completion event is received, THE App SHALL display a completion screen showing the reconstructed Source_Image, the final Move_Count, and the final elapsed time.

---

### Requirement 11: Completion Screen and Replay Options

**User Story:** As a player, I want to see my results and choose what to do next after solving a puzzle so that I can replay or start a new puzzle.

#### Acceptance Criteria

1. THE completion screen SHALL display the fully reconstructed Source_Image, the total Move_Count, and the total elapsed time.
2. THE completion screen SHALL present the user with two options: "Play Again" and "New Puzzle".
3. WHEN the user selects "Play Again", THE App SHALL re-shuffle the same Source_Image with the same grid size and start a new session, resetting the Move_Count and Timer to zero.
4. WHEN the user selects "New Puzzle", THE App SHALL return the user to the photo source selection screen and discard the current Source_Image and Puzzle_State.

---

### Requirement 12: Timer

**User Story:** As a player, I want a timer to track how long I take to solve the puzzle so that I can measure and improve my performance.

#### Acceptance Criteria

1. WHEN the Board is first displayed at the start of a puzzle session, THE Timer SHALL begin counting elapsed time in whole seconds.
2. WHILE a puzzle session is active, THE Timer SHALL increment by 1 every second and display the current elapsed time on the Board.
3. WHEN a puzzle completion event is received, THE Timer SHALL stop and retain its final value for display on the completion screen.
4. WHEN a new puzzle session begins, THE Timer SHALL reset to zero before starting.

---

### Requirement 13: Move Counter

**User Story:** As a player, I want to see how many moves I have made so that I can track my efficiency while solving the puzzle.

#### Acceptance Criteria

1. WHEN a puzzle session begins, THE App SHALL initialise the Move_Count to zero.
2. WHEN a Swap is performed, THE App SHALL increment the Move_Count by 1 and update the displayed value on the Board immediately.
3. WHEN a new puzzle session begins, THE App SHALL reset the Move_Count to zero.

---

### Requirement 14: Accessibility

**User Story:** As a player with accessibility needs, I want the app to support standard mobile accessibility features so that I can use the app comfortably.

#### Acceptance Criteria

1. THE App SHALL apply accessibility labels to all interactive elements, including the "Take a Photo" button, "Choose from Gallery" button, each Piece on the Board, and all completion screen actions.
2. THE App SHALL support the operating system's dynamic text size settings, scaling all non-image text elements accordingly.
3. WHEN a Piece is selected, THE App SHALL announce the selection state change via the platform's accessibility service (e.g., VoiceOver on iOS, TalkBack on Android).
4. THE App SHALL maintain a minimum touch target size of 44×44 points for all interactive controls outside the Board Grid.
