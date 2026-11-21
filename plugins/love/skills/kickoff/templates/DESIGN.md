# Design

Visual stack is <Tailwind CSS, a component library, an icon set>.

## Principles

1. <Principle, such as one primary action per screen.>
2. <Principle.>
3. <Principle.>

## Tokens

Defined in `<src/styles/tokens.css>`. Use them by role, never by raw value.

| Kind | Tokens |
|---|---|
| Color | <accent, fg, fg-muted, bg, surface, border, danger, success> |
| Type | <family and scale; numbers use tabular-nums> |
| Spacing | <scale> |
| Radius | <sm, md, lg> |
| Motion | <duration>, respecting `prefers-reduced-motion` |

## Components

Base components live in `<src/components/ui>`. Create a new one only when nothing there fits, and put it there.

## Patterns

- Screens with remote data have loading, empty (with an action) and error (with retry) states.
- Forms validate on submit and on the server, show the error next to the field and move focus to the first error.
- Destructive actions ask for confirmation or offer undo.

## Don't

- <A concrete pattern to avoid, such as a modal inside a modal.>
