# DESIGN.md: Swara

A design system for a children's speech-practice app. The child should feel **calm, unhurried, and never judged** on how they speak. This document is the single source of truth for colors, typography, shape, motion, and component patterns across the app.

---

## 1. Principles

1. **No pressure.** No countdown timers, no fluency scores, no "wrong" answers, no red marks. Time is never used against the child.
2. **Celebrate effort and courage, not fluency.** Rewards go to practicing and brave moments, never to "smooth" speech.
3. **One thing at a time.** One main action per screen. Big targets, few choices, and plenty of space.
4. **Soft and slow.** Rounded shapes, gentle colors, and slow motion. Nothing flashes, shakes, or buzzes.
5. **Words are warm and short.** Use plain sentences a six-year-old can read. The app speaks like a kind friend.
6. **Two audiences, clearly separated.** The child area is playful. The Grown-ups corner and authentication screens are calmer and more neutral, so adults and children never confuse the two.

---

## 2. Color tokens

The app uses a **dark-blue variant of the Calm Cub palette**. The `_primary` blue replaces Calm Cub's teal everywhere; all other tokens retain their Calm Cub semantics.

### 2.1 Ink and text

| Token       | Hex       | Role                                          |
| ----------- | --------- | --------------------------------------------- |
| `_ink`      | `#1E3A44` | Primary text, icons, error text               |
| `_inkMuted` | `#3F5F6A` | Secondary text, input labels, supporting copy |

### 2.2 Brand

| Token          | Hex       | Role                                                                                                 |
| -------------- | --------- | ---------------------------------------------------------------------------------------------------- |
| `_primary`     | `#1D4A87` | Primary buttons, focused borders, floating labels, badge fill, active states                         |
| `_primaryTint` | `#D9E6F7` | Soft blue tint for card borders, enabled input borders, icon-circle backgrounds, and tinted callouts |

### 2.3 Accents

| Token        | Hex       | Role                                                    |
| ------------ | --------- | ------------------------------------------------------- |
| `_sun`       | `#FFC94A` | Highlight bar under headings, scene sun, reward accents |
| `_sunTint`   | `#FFF3CF` | Soft yellow circles and celebratory icon backgrounds    |
| `_lilacTint` | `#DCD3F8` | Soft lilac circles and scene far hill                   |
| `_coral`     | `#FF8A6B` | Warm accents, including balloon and cheeks              |
| `_coralDeep` | `#E4553A` | Record button and "stuck" mood. Never means "error"     |
| `_coralTint` | `#FFD3C6` | Record-button halo                                      |

### 2.4 Screen grounds

Each screen uses one ground tint. Cards placed on top are always white.

| Token            | Hex       | Screen                                      |
| ---------------- | --------- | ------------------------------------------- |
| `_groundHome`    | `#E6F4F1` | Home — mint mist                            |
| `_groundBreathe` | `#DCEEFA` | Balloon breaths — sky                       |
| `_groundRead`    | `#FFF6E0` | Slow talk — warm paper                      |
| `_groundFeel`    | `#EEE9FB` | How I feel — lilac                          |
| `_groundGarden`  | `#E4F3DC` | My calm garden — meadow                     |
| `_groundAdult`   | `#F2F6F5` | Grown-ups corner and authentication screens |

### 2.5 Mood faces

Always pair each mood color with a text label. Never communicate meaning through color alone.

| Token         | Hex       |
| ------------- | --------- |
| `_moodEasy`   | `#BDE7C8` |
| `_moodBumpy`  | `#FFE49A` |
| `_moodStuck`  | `#FFD3C6` |
| `_moodUnsure` | `#DCD3F8` |

### 2.6 Data bars — Grown-ups corner only

Use darker colors so data visualizations remain readable on white.

| Token        | Hex       |
| ------------ | --------- |
| `_dataEasy`  | `#5FB77A` |
| `_dataBumpy` | `#F2B93B` |
| `_dataStuck` | `#E4553A` |

### Color rules

- Backgrounds are tinted; cards are white.
- `_primary` is the only primary action color.
- `_coralDeep` is reserved for recording and the "stuck" mood.
- Never use red to indicate failure or negative feedback.
- Colors that must be distinguished must also differ by shape, label, or icon.

---

## 3. Typography

| Role                   | Font    | Weight | Size / line height             |
| ---------------------- | ------- | ------ | ------------------------------ |
| Screen title           | Fredoka | 600    | 24px                           |
| Hero heading           | Fredoka | 600    | 32px / 1.2, clamped to 24–34px |
| Reading text (stories) | Fredoka | 500    | 30px / 1.7                     |
| Card title and button  | Fredoka | 600    | 19–22px                        |
| Body                   | Nunito  | 700    | 17–18px / 1.3                  |
| Supporting text        | Nunito  | 700    | 16px                           |
| Caption and tab label  | Nunito  | 700    | 14px minimum                   |

Google Fonts stylesheet for web-based previews:

```html
<link
  href="https://fonts.googleapis.com/css2?family=Fredoka:wght@500;600&family=Nunito:wght@600;700;800&display=swap"
  rel="stylesheet"
/>
```

### Typography rules

- Use sentence case everywhere.
- No all-caps text, italics, or underlined links inside child screens.
- Reading text uses generous line spacing of 1.7 and short lines of approximately 25 characters on a phone.
- Body text must use a weight of at least 600 and a size of at least 16px. The only exception is tab labels, which may use 14px.
- Font sizes scale using a clamped factor derived from `MediaQuery.textScaler`. See Section 9.

---

## 4. Shape, spacing, and size

### Spacing scale

Use the following spacing values:

`4, 8, 10, 12, 16, 20, 24, 28, 36`

Screen side padding:

- 24px on desktop-class widths.
- 16px on narrow phones below 360dp.

### Corner radii

- Buttons: full pills, with radius equal to half the button height.
- Authentication and home cards: 32px.
- Child task cards: 24–28px.
- Inputs: 22px.
- Small tiles: 20–22px.
- Bottom navigation top corners: 28px.
- Avoid sharp corners throughout the app.

### Touch targets

- Minimum interactive target: 48px.
- Primary buttons: 56–64px tall.
- Record button: 88px diameter.
- Maintain at least 10px between adjacent interactive targets.

### Phone frame

- Reference size: 390 × 844.
- Use single-column layouts on phones.
- Where appropriate, use a spacer to move the main action toward the bottom, within easy thumb reach.

### Elevation

Use almost no elevation. Separate elements through color, particularly white cards on tinted backgrounds.

The only shadow-like effects are:

- A solid 2px `_primaryTint` border around authentication cards.
- A soft colored glow behind child task cards, using approximately 18–22% accent opacity.
- A `_coralTint` halo behind the record button.

---

## 5. Components

### Top bar

- Back button: 48px white circle with a chevron on the left.
- Centered Fredoka title.
- Empty 48px spacer on the right to keep the title centered.
- No fake status bar.
- Title scales from 22px to 18px on narrow screens.

### Authentication card — Login, Register, Splash

The signature surface of the Grown-ups corner.

- White fill with a 32px radius.
- 2px `_primaryTint` border.
- Top padding offset by an additional 40px to accommodate an overlapping badge.
- Badge: 76 × 76px circular `_primary` fill with a 6px `_groundAdult` ring.
- Login badge: `waving_hand_outlined`.
- Register badge: `people_outline_rounded`.
- Splash badge: the `ස` glyph.
- Centered Fredoka heading followed by a 48 × 6px `_sun` accent bar with a 3px radius.
- Inputs: 22px radius, `_groundAdult` fill, and 1.5px `_primaryTint` border when enabled.
- Focused input border: 3px `_primary`.
- Error input border: 2px `_ink`.
- Prefix icons sit inside 36px `_primaryTint` circles with `_primary` glyphs.
- Primary action: full-width pill, 64px tall or 56px on short screens.
- Footer link: centered `Wrap` containing "New to Swara?" or "Already have an account?" with a `_primary` text button.
- Center the card inside a `SingleChildScrollView` and `ConstrainedBox`.
- Maximum card width: 460px, increasing to 520px in landscape.

### Primary button

- Full pill shape.
- 64px tall, reduced to 56px on short screens.
- `_primary` fill.
- White Fredoka text at 22px.
- Pressed state darkens `_primary` by 8%.
- Use one primary button per screen.

### Secondary button

- 52–56px tall.
- Full pill shape.
- Either transparent with a 3px `_primary` border and `_primary` text, or white with `_ink` text.
- Used for actions such as "Add a brave moment", "Practice reminders", and "All done".

### Text button

- 52px tall.
- `_ink` text with no fill.
- Used for actions such as "Skip for today".
- Skipping is always allowed and never framed as failure.

### Adventure card — Child Home

The child-facing card shares the authentication card's visual DNA but uses accent tints.

- White fill.
- 24px radius.
- 2px `_primaryTint` border.
- Soft accent-colored glow behind the card, using 18% opacity, 14px blur, and 6px vertical offset.
- Illustration band with a 16:10 aspect ratio.
- Illustration background uses the accent color at 14% opacity.
- Optional `Image.asset`; fall back to an icon if the image is unavailable.
- Icon badge: 34px circle with an accent fill and subtle black shadow, positioned at the top-left.
- Text block:
  - Fredoka Sinhala title at 16px.
  - Nunito 800 English subtitle in the accent color at 13px.
  - Nunito 700 caption at 12px.
- Press animation: `Transform.scale` from 1.0 to 0.96 over 120ms using `easeOut`.

### Task card — Home list

- White card with a 24px radius.
- Minimum height: 84px.
- Left side: 56px circle with a soft tint and 30px line icon.
- Middle: Fredoka title and one-line description.
- Right: 32px status circle.
- Completed: `_primary` circle with a check.
- Next: `_primary` circle with a chevron.
- Later: pale circle with a chevron.
- The next-up card has a 4px `_primary` ring.

### Progress card — Child Home

- White card with a 32px radius.
- 2px `_primaryTint` border.
- 52px `_sunTint` circle containing a `_sun` trophy icon.
- Fredoka heading and Nunito supporting line.
- `_primary` chevron on the right.

### Mood tile — Feelings

- Two-column grid of white cards.
- Each card is 158px tall.
- Large 72px face, Fredoka label, and one short descriptor.
- Selected tile gets a 5px `_primary` ring.
- Use radio semantics: `role="radiogroup"` and `role="radio"` with `aria-checked`.

### Segmented control — Pace

- White pill-shaped track with 6px padding.
- Three options, each 52px tall.
- Selected option uses `_primary` fill and white text.

### Record button

- 88px circle.
- `_coralDeep` fill.
- White microphone icon.
- 8px `_coralTint` halo.
- Centered below a "Tap to read aloud" caption.

### Reading highlight

- The current phrase is displayed on a rounded `_sun`-yellow highlight.
- Read phrases remain in full `_ink`.
- Upcoming phrases use `_inkFaint` (`#6C858D`), only at reading sizes of 30px or above.
- A row of 14px dots shows phrase progress.
- Never display words per minute.

### Speech bubble and tip strip

- Mascot on the left and bubble on the right.
- Bubble uses `_sunTint` or `_groundBreathe`.
- Radius: 20–22px.
- Include one short, kind sentence.

### Footer tip — Child Home

- `_primaryTint` background at 60% opacity.
- 22px radius.
- 1.5px `_primaryTint` border.
- 18px emoji and Nunito 700 caption in `_inkMuted`.

### Progress dots and day row

- Completed: filled `_primary` or `_sun`.
- Current day: white fill with `_primary` ring.
- Upcoming: pale fill.
- Day letters appear below each dot.
- Always provide an `aria-label` describing the whole row.

### Bottom navigation

- White bar with 28px top corners.
- Four tabs: Home, Practice, Garden, and Grown-ups.
- Each tab is 72px wide and at least 52px tall.
- Each tab contains a 24px line icon and 14px label.
- Active tab sits inside a `_primaryTint` pill.

### Data bars — Grown-ups corner only

- Pill-shaped bars, 18px tall.
- Pale track.
- Label on the left and count on the right.

---

## 6. Iconography and illustration

### Line icons

- 24px grid.
- 2px stroke.
- Round caps and joins.
- `_ink` color.
- Hand-drawn feel.
- No filled glyphs except stars and the microphone capsule.
- Never use emoji in production child screens. The footer tip emoji is a temporary exception.

### Mascot — Cub the bear

- Round honey-brown head: `#D9A066`.
- Cream muzzle: `#F6E3C8`.
- Two round ears with cream inner sections.
- Small dark eyes with a white sparkle.
- Rosy cheeks using `_coral` at 55% opacity.
- Gentle smile.
- Cub always looks calm and happy, never surprised or worried.
- Use at 120px for the hero and 44px for tip strips.

### Illustration style

- Flat shapes.
- No outlines or gradients.
- Soft tinted fills.
- Scenes such as the balloon and garden hill are simple and symmetrical.

### Mood faces

Each face uses a circle, two dot eyes, and a one-stroke mouth.

- Easy: smile.
- Bumpy: wavy line.
- Stuck: flat line with slanted brows.
- Not sure: small ring.

### The Calm Scene — Authentication and splash background

A shared `_CalmScenePainter` paints the same flat scene behind every Grown-ups corner screen.

1. `_groundAdult` base rectangle.
2. Three concentric circles at the top-right:
   - `_groundSky`, radius `0.55w`.
   - `_primaryTint` at 85% opacity, radius `0.36w`.
   - White at 55% opacity, radius `0.18w`.
3. `_sunTint` circle at the top-left, radius `0.22w`.
4. `_lilacTint` circle at mid-right, 70% opacity, radius `0.15w`.
5. Small `_sun` circle, radius `0.045w`, with three white accent dots.
6. Three hills, painted back-to-front:
   - Far hill: `_lilacTint` at 55% opacity.
   - Middle hill: `_primaryTint`.
   - Front hill: `_groundGarden`.

Wrap the painter in `ExcludeSemantics` because it is decorative.

---

## 7. Motion

- Use slow, eased motion, generally 400–800ms with `easeInOut`.
- Breathing animations use a 4-second inhale and 4-second exhale cycle. Allow the pace to be slowed further.
- Entrance stagger:
  - The `_Reveal` widget fades and rises items in order.
  - Duration: `500 + order * 140` milliseconds.
  - Curve: `easeInOut`.
  - Vertical translation: 14px to 0.
  - Used on authentication cards and child home sections.
- Rewards, such as a flower growing, use gentle scale-and-fade animations, never confetti bursts.
- Press feedback scales task cards to 0.96 over 120ms with `easeOut`.
- No shaking, flashing, bouncing alerts, or sudden sounds.
- Respect reduced-motion preferences by replacing animations with fades or static states.
- Every `_Reveal` and card animation checks `MediaQuery.disableAnimationsOf(context)`.
- Avoid loading spinners that make waiting feel stressful. Use a calm Cub image with a short sentence instead.
- The splash screen may use a small inline spinner with "Getting things ready…" because it is a router gate rather than a general waiting state.

---

## 8. Voice and copy

- Speak like a friendly guide.
- Use short sentences, present tense, and plain words.
- Say **"bumpy"** and **"stuck"**, not "error" or "failed".
- Say **"all done"**, not "finished".
- Reassure without praising fluency.

### Good examples

- "Take your time today. There is no rush!"
- "Any answer is okay. Cub is listening."
- "Bumpy days happen to lots of kids. You are still a great talker."

### Avoid

- "Great job speaking clearly!"
- "Try again."
- "Wrong."
- Streak-loss warnings.
- Comparisons with other children.

### Grown-ups corner

- Use calm, factual, second-person copy.
- Include a short note explaining that Swara supports work with a speech-language pathologist and does not replace professional support.

### Bilingual pattern

Child-facing and authentication copy pairs Sinhala and English with a middle-dot separator (`·`).

Examples:

- `Email · විද්‍යුත් තැපෑල`
- `Create account · ගිණුමක් සාදන්න`

Keep the bilingual pattern consistent throughout the app.

---

## 9. Accessibility

### Contrast

- Text contrast must be at least 4.5:1.
- Large text of 24px or above may use a minimum contrast ratio of 3:1.
- `_inkFaint` (`#6C858D`) is used only for reading text at 30px or above.

### Touch targets and semantics

- Every tappable element must be a real button.
- Icon-only buttons must have an `aria-label` or a Flutter tooltip.
- Decorative painters and badges must be wrapped in `ExcludeSemantics`.
- Never show a state through color alone. Add a ring, check, label, or shape change.

### Dynamic Type

- Support system text scaling up to 130%.
- Every screen reads:

```dart
MediaQuery.textScaler.scale(1).clamp(1.0, 1.3)
```

- Multiply font sizes by the clamped scale factor.
- Layouts must wrap content instead of clipping it.

### Responsive signals

- `isNarrow`: width below 360dp. Use tighter horizontal padding and a smaller AppBar title.
- `isShort`: height below 640dp. Use tighter vertical gaps and 56px buttons.
- `isLandscape`: width greater than height. Increase card maximum width to 520px and use a three-column child home grid.
- `scale`: `(width / 390).clamp(0.85, 1.15) * textScale`, with the resulting value clamped to 0.85–1.25.

### Recording and exercise controls

- Audio playback and recording always require an explicit tap.
- Show a clear stop control.
- Never record automatically.
- Offer a "Slower" pace.
- Keep the Pause button visible during every exercise.

---

## 10. Screen patterns

| Screen           | Ground                    | Hero element                                                  | Single main action          |
| ---------------- | ------------------------- | ------------------------------------------------------------- | --------------------------- |
| Splash           | `_groundAdult` with scene | Badge with `ස` glyph and "Getting things ready…"              | Automatic — router gate     |
| Login            | `_groundAdult` with scene | Authentication card with waving-hand badge                    | Sign in                     |
| Register         | `_groundAdult` with scene | Authentication card with people badge                         | Create account              |
| Home (child)     | `_groundHome`             | Greeting card, adventure grid, and progress card              | Open the next-up task       |
| Balloon breaths  | `_groundBreathe`          | Large `_coral` balloon, "Breathe in" label, and count circles | Pause / All done            |
| Slow talk        | `_groundRead`             | Story card with `_sun` highlight on the current phrase        | Record                      |
| How I feel       | `_groundFeel`             | Four mood tiles                                               | Tell Cub                    |
| My calm garden   | `_groundGarden`           | Hill with one flower per practice                             | Add a brave moment          |
| Grown-ups corner | `_groundAdult`            | Week summary and tips                                         | Share with speech therapist |

### When adding a new screen

1. Pick a ground tint.
2. Add a top bar, except on authentication screens where it is omitted.
3. Put one hero element in the upper half.
4. Place the single main action near the bottom.
5. Keep bottom navigation on tab screens only, never inside exercises.

---

## 11. Do and don't

| Do                                       | Don't                                              |
| ---------------------------------------- | -------------------------------------------------- |
| Use one clear action per screen          | Stack several competing buttons                    |
| Reward practice and brave moments        | Reward "smooth" speech or show fluency scores      |
| Keep Skip and Pause always available     | Trap the child in a flow                           |
| Use soft, tinted grounds and white cards | Use pure white backgrounds or dark mode by default |
| Pair every color meaning with a label    | Rely on red/green to signal good or bad            |
| Keep copy short and kind                 | Use clinical terms on child screens                |
| Use slow, eased motion                   | Use timers, countdowns, or flashing effects        |
| Pair Sinhala and English with `·`        | Mix languages inconsistently                       |

---

## 12. Quick start for any new UI

1. Copy the relevant tokens below into the screen file, or import them from a shared `app_tokens.dart`.
2. Choose a ground tint for the new screen and set the body font to Nunito 700.
3. Build with 24px side padding, white cards with 24–32px radii, and pill buttons at least 56px tall.
4. Wrap major sections in `_Reveal(order: n, reduceMotion: …)` for the staggered entrance.
5. Add the mascot only where guidance or encouragement is needed, with at most one mascot per screen.
6. Write copy using Section 8, then check contrast and touch targets using Section 9.

### Token block — Dart

```dart
// Swara — dark-blue Calm Cub variant

const _groundHome    = Color(0xFFE6F4F1);
const _groundBreathe = Color(0xFFDCEEFA);
const _groundRead    = Color(0xFFFFF6E0);
const _groundFeel    = Color(0xFFEEE9FB);
const _groundGarden  = Color(0xFFE4F3DC);
const _groundAdult   = Color(0xFFF2F6F5);

const _primary       = Color(0xFF1D4A87);
const _primaryTint   = Color(0xFFD9E6F7);

const _sun           = Color(0xFFFFC94A);
const _sunTint       = Color(0xFFFFF3CF);
const _lilacTint     = Color(0xFFDCD3F8);
const _coral         = Color(0xFFFF8A6B);
const _coralDeep     = Color(0xFFE4553A);
const _coralTint     = Color(0xFFFFD3C6);

const _ink           = Color(0xFF1E3A44);
const _inkMuted      = Color(0xFF3F5F6A);
const _inkFaint      = Color(0xFF6C858D); // 30px+ only

const _fredoka       = 'Fredoka';
const _nunito        = 'Nunito';
```

### Token block — CSS

```css
:root {
  --ground-home: #e6f4f1;
  --ground-breathe: #dceefa;
  --ground-read: #fff6e0;
  --ground-feel: #eee9fb;
  --ground-garden: #e4f3dc;
  --ground-adult: #f2f6f5;

  --primary: #1d4a87;
  --primary-tint: #d9e6f7;

  --sun: #ffc94a;
  --sun-tint: #fff3cf;
  --lilac-tint: #dcd3f8;
  --coral: #ff8a6b;
  --coral-deep: #e4553a;
  --coral-tint: #ffd3c6;

  --ink: #1e3a44;
  --ink-muted: #3f5f6a;
  --ink-faint: #6c858d;
}
```

---

## 13. Migration notes from Calm Cub

| Calm Cub                    | Swara                                                     | Where it changed                                            |
| --------------------------- | --------------------------------------------------------- | ----------------------------------------------------------- |
| `--teal: #1B7F7F`           | `_primary: #1D4A87`                                       | Replaced teal everywhere                                    |
| `--teal-tint: #D6EDE8`      | `_primaryTint: #D9E6F7`                                   | Card borders, active navigation pill, icon circles          |
| `--ground-home: #E6F4F1`    | Unchanged                                                 | Home background                                             |
| `--ground-adult: #F2F6F5`   | Unchanged                                                 | Authentication screens                                      |
| Cub at 120px hero           | Cub at 120px hero; authentication badge becomes icon-only | Authentication screens use a neutral greeting glyph         |
| Flat `AppColors.background` | `_CalmScenePainter` scene                                 | Shared scene on Grown-ups corner and authentication screens |

Screens that still reference `AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadii`, or `AppMotion` from `core/theme/app_theme.dart` should be migrated to the tokens in Section 12 as they are updated.

---

**Source of truth:** This document describes Swara's dark-blue Calm Cub design variant, including the documented splash, login, register, and child home patterns. When implementing new screens, follow these tokens and patterns to maintain a consistent experience across the app.
