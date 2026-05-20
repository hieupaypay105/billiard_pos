# Project-Dependent Filter Flow (Generic)

## Objective
Describe the parent-child dependent filter flow (parent -> child). This document is intended to be reusable across screens with similar dependent filters.

## Scope
- Applicable to any screen with dependent filters
- Reference example: `KhachHangFilterScreen` (project -> area/type)

## Key Concepts
- Parent filter: `parent_id` (e.g. `project_id`)
- Child filters: `child` (e.g. `area`, `type`)
- Rule: When the parent changes, child filters must be reset and their options reloaded.

## High-Level Flow
1. User changes `parent_id`.
2. UI updates `selectedParentId` immediately to control enable/disable of child fields.
3. Provider receives the new parent and reloads dependent options.
4. UI resets child filter values to avoid stale/invalid selections.
5. UI shows a loading placeholder while fetching new options.

## Layer Details

### 1) UI (Screen)
- When `parent_id` changes:
  - Take the last parent value (if multi-select) or the single value (if single-select).
  - If value exists:
    - `setState(selectedParentId = v)`
    - `provider.setSelectedParent(v)`
  - If cleared:
    - `setState(selectedParentId = null)`
  - Reset child fields:
    - `fields['childA'].didChange([])`
    - `fields['childB'].didChange([])`

- Enable/disable child fields based on `selectedParentId`:
  - Child fields are enabled only when `selectedParentId != null`.

- While provider is loading options:
  - Show a loading placeholder instead of dropdowns.

### 2) Provider
- `setSelectedParent(parentId)`:
  - If parent is unchanged: return.
  - Update `_selectedParentId`.
  - Clear `_childOptions`.
  - `notifyListeners()` to update UI immediately.
  - Call `loadChildOptions()`.

- `loadChildOptions()`:
  - Set `_isLoadingChildOptions = true`.
  - Fetch child options in parallel for `parentId`.
  - Update `_childOptions` when done.
  - Turn off loading and `notifyListeners()`.

## Why Child Filters Must Be Reset
- Child data depends on the parent.
- When parent changes, previous child selections may become invalid.
- Resetting ensures filter consistency and avoids incorrect results.

## Reusable Pattern for Other Screens

### UI Pattern
- Maintain local `selectedParentId` state.
- On parent change:
  - Update local state.
  - Call provider to set parent.
  - Reset child fields in the form.
- Disable child fields until parent is selected.

### Provider Pattern
- Store `selectedParentId`.
- Clear child options when parent changes.
- Fetch child options by parent id.
- Notify UI at both stages:
  - Start loading.
  - Finish loading.

## Technical Notes
- If UI allows multi-select but logic is single-select, standardize the behavior:
  - Either enforce single selection.
  - Or handle a list of parent ids instead of `values.last`.

