# Design System Document: The Playful Polymath

## 1. Overview & Creative North Star

### Creative North Star: "The Animated Intellectual"
This design system rejects the clinical, sterile aesthetic of traditional brain-training software. Instead, it embraces the "Animated Intellectual"—a philosophy that cognitive exercise should feel like a high-stakes, rewarding adventure rather than a chore. We merge high-end editorial clarity with the tactile, dopamine-inducing physics of modern gaming.

The system is defined by its intentional use of **Character-Centric Layouts**. The 'Seirei' ghost is not a mere mascot; it is the structural anchor. By utilizing Seirei as a large-scale background element or a dynamic overlay that reacts to user progress, we break the "standard grid." We favor asymmetric composition where UI elements float and interact with the character, creating a sense of depth and life that static templates cannot replicate.

---

### 2. Colors

Our palette is anchored by a vibrant, high-energy Blue, supported by secondary "reward" tones that signify growth and achievement.

*   **Primary (#0058ba):** The core of the identity. Used for high-priority 3D buttons and active states.
*   **Secondary (#755700):** A warm gold for "Achievement" moments, trophies, and premium level-ups.
*   **Tertiary (#006940):** An energetic green for "Correct" feedback and progress bars.
*   **Neutral (Surface-Container Scale):** We use a sophisticated range of cool-tinted greys and whites (`surface-container-low` to `highest`) to manage cognitive load.

#### The "No-Line" Rule
To maintain a premium, modern feel, **1px solid borders are strictly prohibited** for sectioning content. Boundaries must be defined solely through background color shifts. For example, a `surface-container-low` activity card should sit on a `background` (#f7f5ff) surface. This creates a clean, editorial look that feels integrated rather than "boxed in."

#### Signature Textures: The Energetic Gradient
For main CTAs, do not use a flat hex. Apply a subtle linear gradient from `primary` (#0058ba) to `primary-container` (#6c9fff) at a 135-degree angle. This provides the "visual soul" necessary to make the UI feel expensive and custom.

---

### 3. Typography

We use **Plus Jakarta Sans** exclusively. Its geometric yet friendly curves perfectly bridge the gap between "clean tech" and "playful game."

*   **Display (lg/md/sm):** Reserved for "Big Win" moments and score reveals. Use `-0.02em` letter spacing for a tighter, more authoritative editorial feel.
*   **Headline (lg/md):** Used for game titles and screen headers. These should be **Bold** to provide a strong visual anchor against the character-centric backgrounds.
*   **Body (lg/md):** High legibility is key. Use `on-surface-variant` (#505a81) for body text to reduce eye strain, reserving `on-surface` (#232c51) for critical information.
*   **Labels:** All-caps labels should be used sparingly for "Level" indicators or "Category" tags to add a sense of professional categorization.

---

### 4. Elevation & Depth

We eschew traditional drop shadows for a more physical, "stacked" approach.

#### The Layering Principle
Depth is achieved by stacking surface-container tiers. 
1.  **Level 0 (Background):** `surface` (#f7f5ff) – The canvas where the 'Seirei' ghost resides.
2.  **Level 1 (Sections):** `surface-container-low` – Subtle areas for secondary content.
3.  **Level 2 (Active Cards):** `surface-container-lowest` (#ffffff) – High-contrast "sheets" for gameplay interactions.

#### Glassmorphism & Depth
For overlays and "Seirei" dialogue bubbles, use **Glassmorphism**. Apply `surface-container-lowest` at 60% opacity with a `20px` backdrop blur. This allows the vibrant character background to bleed through, ensuring the UI feels like a part of the world, not an obstruction.

#### Ambient Shadows
When a floating effect is required (e.g., a modal or popup), use an extra-diffused shadow:
`Box-shadow: 0px 10px 40px rgba(35, 44, 81, 0.08);`
The shadow is a tinted version of the `on-surface` color, mimicking natural light.

---

### 5. Components

#### 3D Game Buttons (The Signature Element)
Inspired by high-performance gaming UI, buttons must feel tactile.
*   **Primary 3D Button:** 
    *   **Base:** `primary` (#0058ba).
    *   **Bottom Shadow (The "Thick" Effect):** A 4px solid inset or offset stroke of `primary_dim` (#004da4).
    *   **Top Highlight:** A 1px internal stroke of `primary_fixed` at 30% opacity.
    *   **States:** On `hover`, the button moves 2px down. On `active`, it moves the full 4px down, "flattening" the shadow to simulate a physical press.

#### Game Progress Chips
*   Use `secondary_container` (#ffca4d) for streaks or currency. 
*   **Constraint:** No borders. Use `xl` (1.5rem) roundedness to create a friendly "pill" shape.

#### Input Fields
*   **Ghost Border:** Do not use high-contrast outlines. Use `outline-variant` at 20% opacity. 
*   **Focus State:** Shift the background to `surface-container-high` and apply a 2px `primary` bottom-border only.

#### Selection Cards
*   Instead of dividers, use **Vertical White Space** (from the Spacing Scale). To separate game categories, use a subtle shift from `surface-container-low` to `surface-container-high`.

---

### 6. Do's and Don'ts

#### Do:
*   **Do** allow the 'Seirei' character to overlap with UI containers occasionally. It creates a sense of "breaking the 4th wall."
*   **Do** use `xl` (1.5rem) or `full` roundedness for all interactive elements to maintain the "Friendly" vibe.
*   **Do** use `primary_container` (#6c9fff) for subtle background accents to tie the vibrant blue throughout the light theme.

#### Don't:
*   **Don't** use black (#000000) for text or shadows. Always use the `on-surface` or `primary_dim` tints to keep the palette energetic.
*   **Don't** use 1px solid dividers. If you feel the need for a line, increase the padding/white space instead.
*   **Don't** place the 'Seirei' character in a small, constrained box. Let the character be "large-than-life," utilizing the `display` typography to balance its visual weight.

---
*Director's Note: Remember, we are building a playground for the mind. Every tap should feel like a physical interaction, and every screen should feel like a custom-designed editorial layout where the character and the data live in perfect harmony.*