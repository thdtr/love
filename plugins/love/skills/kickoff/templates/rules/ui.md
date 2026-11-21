---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.vue"
  - "**/*.svelte"
  - "**/*.css"
---

# UI

- `docs/DESIGN.md` wins every visual decision. Use its tokens and the components in `<src/components/ui>`, and look for an existing one before creating a color, spacing, font or component.
- Without `docs/DESIGN.md`, copy the pattern of nearby components and ask when in doubt.
- Components with remote data handle loading, empty and error.
- Interactive elements work with the keyboard, show focus and have a label.
- Check visible changes in the running app with `/verify`, not just in the code. If the spec has a reference image, compare against it.
