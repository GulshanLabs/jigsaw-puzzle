# Requirements Document

## Introduction

This document defines the requirements for changing the jigsaw puzzle game's image processing behaviour so that the full source image is used for the puzzle, rather than centre-cropping to a square. Currently, the Image_Processor crops the Source_Image to the largest centred square before slicing, which discards portions of non-square images. The new behaviour preserves the entire Source_Image, producing rectangular Pieces whose aspect ratio matches the Source_Image's aspect ratio divided by the grid dimensions. The Board, grid preview overlay, and all related components must be updated to handle non-square Pieces and non-square board layouts.

## Glossary

- **App**: The jigsaw puzzle mobile game application.
- **Source_Image**: The original photo selected or captured by the user, used as the basis for the puzzle.
- **Grid**: The N×N arrangement of equal rectangular cells that the Source_Image is divided into.
- **Piece**: A single rectangular tile that represents one cell of the Grid, containing a cropped portion of the Source_Image.
- **Board**: The interactive game screen displaying all Pieces in their current shuffled or rearranged positions.
- **Image_Processor**: The system component responsible for scaling and splitting the Source_Image into Pieces.
- **Piece_Width**: The pixel width of each Piece, equal to the Source_Image width divided by N.
- **Piece_Height**: The pixel height of each Piece, equal to the Source_Image height divided by N.
- **Aspect_Ratio**: The ratio of width to height of the Source_Image or a Piece.
- **Grid_Preview**: The overlay drawn on the Source_Image preview during grid size configuration, showing how the image will be divided.

---

## Requirements

### Requirement 1: Full Image Utilisation

**User Story:** As a player, I want the puzzle to use my entire photo without cropping so that no part of the image is lost when creating the puzzle.

#### Acceptance Criteria

1. WHEN the Image_Processor receives the Source_Image and grid dimensions N, THE Image_Processor SHALL use the full width and full height of the Source_Image without cropping any region.
2. THE Image_Processor SHALL NOT apply any centre-crop, aspect-ratio crop, or other spatial reduction to the Source_Image before slicing.
3. WHEN the Source_Image is square, THE Image_Processor SHALL produce square Pieces identical in behaviour to the previous implementation.

---

### Requirement 2: Rectangular Piece Generation

**User Story:** As a player, I want the puzzle pieces to match the shape of my photo divided by the grid so that the pieces accurately represent the full image.

#### Acceptance Criteria

1. THE Image_Processor SHALL divide the Source_Image into exactly N×N Pieces, where each Piece has a width equal to the Source_Image width integer-divided by N and a height equal to the Source_Image height integer-divided by N.
2. THE Image_Processor SHALL produce Pieces that all have identical pixel dimensions (Piece_Width × Piece_Height).
3. THE Image_Processor SHALL assign each Piece a unique identifier corresponding to its correct Grid position (row, column).
4. WHEN the Source_Image has a non-square Aspect_Ratio, THE Image_Processor SHALL produce rectangular Pieces whose Aspect_Ratio matches the Source_Image Aspect_Ratio.

---

### Requirement 3: Board Layout for Rectangular Pieces

**User Story:** As a player, I want the puzzle board to display rectangular pieces correctly so that the puzzle looks right and I can solve it comfortably.

#### Acceptance Criteria

1. THE Board SHALL render the N×N Grid using the Aspect_Ratio of the Source_Image, so that the overall board shape matches the Source_Image proportions.
2. THE Board SHALL scale the Grid to fit within the available screen space while preserving the Source_Image Aspect_Ratio.
3. WHEN Pieces are rectangular, THE Board SHALL size each cell to the Piece_Width-to-Piece_Height ratio, ensuring Pieces are displayed without distortion.
4. THE Board SHALL remain responsive to user input at all times during an active puzzle session, regardless of Piece shape.

---

### Requirement 4: Grid Preview Overlay for Full Image

**User Story:** As a player, I want the grid preview on the configuration screen to show how my full image will be divided so that I can see the actual piece shapes before starting.

#### Acceptance Criteria

1. WHEN the user selects a grid size on the configuration screen, THE Grid_Preview SHALL overlay grid lines on the full Source_Image preview, dividing it into N×N cells that match the Source_Image Aspect_Ratio.
2. THE Grid_Preview SHALL NOT assume square cells; THE Grid_Preview SHALL draw horizontal and vertical lines at intervals proportional to the Source_Image dimensions divided by N.
3. WHEN the Source_Image is non-square, THE Grid_Preview SHALL show rectangular cells that accurately represent the shape of the resulting Pieces.

---

### Requirement 5: Swap Animation for Rectangular Pieces

**User Story:** As a player, I want piece swap animations to work correctly with rectangular pieces so that the game feels smooth regardless of piece shape.

#### Acceptance Criteria

1. WHEN a Swap is performed on the Board with rectangular Pieces, THE App SHALL animate the two Pieces moving to their new positions with a transition duration of no more than 300 milliseconds.
2. THE App SHALL animate Pieces using their actual rectangular dimensions, ensuring Pieces do not overlap or distort during the animation.

---

### Requirement 6: Piece Data Round-Trip Integrity

**User Story:** As a developer, I want to verify that slicing the full image into pieces and reassembling them reconstructs the original image so that no pixel data is lost.

#### Acceptance Criteria

1. FOR ALL valid Source_Images and grid sizes N in {2, 3, 4, 5, 6}, reassembling all N×N Pieces produced by the Image_Processor in their correct Grid positions SHALL reconstruct an image pixel-equivalent to the Source_Image (up to integer-division rounding of edge pixels).
2. THE Image_Processor SHALL preserve the pixel content of each region of the Source_Image in the corresponding Piece without colour alteration or spatial transformation beyond the grid slice.

---

### Requirement 7: Error Handling for Image Processing

**User Story:** As a player, I want the app to handle image processing errors gracefully so that I am not left on a broken screen.

#### Acceptance Criteria

1. IF the Image_Processor encounters an error reading or processing the Source_Image, THEN THE App SHALL display an error message and return the user to the photo source selection screen.
2. IF the Source_Image dimensions are smaller than N pixels in either width or height, THEN THE Image_Processor SHALL throw an error indicating the image is too small for the selected grid size.

