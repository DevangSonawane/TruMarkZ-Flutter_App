I'm working on a Flutter app called TruMarkZ. I need to revamp the "New Batch" flow starting from the org dashboard. Currently, tapping "New Batch" goes directly to `VerificationPlanSetupPage` (which starts with an industry selection screen). We need to INSERT a new gateway screen BEFORE that, and then build out a full product verification flow for when the user picks "Product". The human verification flow stays exactly as-is after the gateway.

---

## WHAT TO BUILD

### 1. New Gateway Screen: `BatchTypeSelectionPage`
Create file: `lib/features/orgs/verification_flow/presentation/pages/batch_type_selection_page.dart`

This is the first screen the user sees after tapping "New Batch". It presents two large cards to choose from:

**Card 1 — Human Verification**
- Icon: `Icons.person_search_rounded`
- Title: "Human Verification"
- Subtitle: "Verify identities of individuals — workers, agents, drivers, students & more"
- Tag chips below subtitle: "Blue Collar", "Gig Workers", "Insurance Agents", "Recruits"
- On tap → `context.push(AppRouter.verificationPlanSetupPath)` (existing flow, no changes)

**Card 2 — Product Verification**
- Icon: `Icons.inventory_2_rounded`
- Title: "Product Verification"
- Subtitle: "Issue digital certificates for products stored on blockchain"
- Tag chips below subtitle: "Consumer Goods", "Cosmetics", "Warranty Cards", "FMCG"
- On tap → `context.push(AppRouter.productSectorSelectorPath)` (new route)

**Design spec:**
- Match the existing app's visual style — white cards, `AppColors.brandBlue` accents, `AppColors.pageBg` background, `AppTypography` for text, same `_slideFadePage` transitions
- Each card should be large (roughly full-width, ~180px tall), with a gradient left border strip (2563EB → 1E40AF)
- Selected state: blue border `AppColors.brandBlue` width 2, with a checkmark badge top-right
- No stepper on this screen — it's just a choice screen
- AppBar: back arrow + "New Batch" title with the TruMarkZ icon asset
- Bottom CTA button (same `_GradientCtaButton` style): "Continue" — only enabled when a card is selected

---

### 2. New Screen: `ProductSectorSelectorPage`
Create file: `lib/features/orgs/verification_flow/presentation/pages/product_sector_selector_page.dart`

User selects which product sector they're creating a batch for.

**Sectors (grid of cards, 2 columns):**
Each sector card has an icon, title, short description:

1. **Consumer Goods & Warranty** — `Icons.inventory_rounded` — "Digital warranty cards with component-level blockchain certificates"
2. **Beauty & Cosmetics** — `Icons.spa_rounded` — "Product authenticity certificates with lab reports as tappable icons"
3. **Insurance** — `Icons.health_and_safety_rounded` — "Policy certificates & agent identity badges on blockchain"
4. **Transport & Logistics** — `Icons.local_shipping_rounded` — "Driver IDs with documents shareable via WhatsApp"
5. **Verified Recruitment** — `Icons.school_rounded` — "Student credential bundles with background & skill reports"
6. **Blue Collar Resources** — `Icons.engineering_rounded` — "Maids, gig workers, home service staff identity cards"

**Design spec:**
- Same `_IndustryCard` style as the existing `VerificationPlanSetupPage` industry step — square cards in a 2-col grid, circle icon container, selected state with blue border and top-right checkmark
- AppBar: back arrow + "Select Sector" title
- Stepper: show a 3-step progress bar at top (Step 1 of 3: Sector | Step 2: Product Details | Step 3: Upload)
- Bottom CTA "Continue" — enabled when sector selected
- On tap Continue → `context.push(AppRouter.productBatchSetupPath)` passing selected sector as `extra`

---

### 3. New Screen: `ProductBatchSetupPage`
Create file: `lib/features/orgs/verification_flow/presentation/pages/product_batch_setup_page.dart`

This screen collects batch metadata for the product batch. It is a single-scroll form page.

**Fields:**
- Batch Name (text field) — required
- Description (text field, optional, max 3 lines)
- Product Category — read-only display of the selected sector from previous screen (shown as a chip/pill)
- Certificate Template selector — horizontal scroll of 3 template options (described below)
- Number of Units — numeric field
- Blockchain visibility toggle — "Public Registry" vs "Private"

**Certificate Template options (horizontal scroll cards ~140x180):**
1. **Classic Card** — shows a mockup icon of a rectangular badge
2. **Circular Badge** — shows a circular radial layout icon
3. **Report Sheet** — shows a document icon

**Design spec:**
- Use `TMZInput` widget (already in `lib/core/widgets/tmz_input.dart`) for text fields
- Template cards: white cards with rounded corners, blue border when selected, template name below icon
- Stepper: step 2 of 3 highlighted
- AppBar back + "Product Details" title
- Bottom CTA "Continue" → navigates to `AppRouter.productBulkUploadPath`

---

### 4. New Screen: `ProductBulkUploadPage`
Create file: `lib/features/orgs/verification_flow/presentation/pages/product_bulk_upload_page.dart`

This mirrors the existing `BulkUploadPage` (for human verification) but is adapted for products.

**What to show:**
- Step 3 of 3 in stepper
- AppBar: "Upload Products"
- A summary card at top showing: selected Sector (chip), Batch Name, Template chosen
- Excel upload zone — same drag/drop style card as the existing `BulkUploadPage` — with label "Upload Product Data (.xlsx)"
- Download template link: "Download Excel Template" (placeholder action, `ScaffoldMessenger` snackbar for now)
- After file is picked, show a preview list card: "X rows detected" with a sample of column headers
- Bottom CTA "Create Batch" — enabled when file is picked
  - On tap → show a loading state for 1.5s (simulated) then navigate to `AppRouter.productBatchCreatedPath`

**Excel columns hint shown in the UI (info card):**
Required: `product_name`, `serial_number`, `manufacture_date`
Optional: `model_number`, `warranty_months`, `batch_code`, `color`, `description`

---

### 5. New Screen: `ProductBatchCreatedPage`
Create file: `lib/features/orgs/verification_flow/presentation/pages/product_batch_created_page.dart`

Success confirmation screen (mirrors existing `BatchCreatedSuccessPage` style).

**Contents:**
- Large animated checkmark (green circle, `Icons.check_rounded`)
- Title: "Batch Created!"
- Subtitle: "Your product verification batch has been queued. Certificates will be generated and stored on blockchain."
- Stat row: "X Products", sector name chip
- Two buttons:
  1. "View Batch" (primary gradient) → `context.go(AppRouter.appBatchesPath)`
  2. "Back to Dashboard" (outlined) → `context.go(AppRouter.dashboardPath)`

---

## ROUTING CHANGES

In `lib/core/router/app_router.dart`:

1. Add new route constants:
```dart
static const String batchTypeSelectionPath = '/batch-type-selection';
static const String productSectorSelectorPath = '/product-sector-selector';
static const String productBatchSetupPath = '/product-batch-setup';
static const String productBulkUploadPath = '/product-bulk-upload';
static const String productBatchCreatedPath = '/product-batch-created';
```

2. Register all 5 new pages as `GoRoute` entries with `_slideFadePage` transitions (same pattern as existing routes). For `productBatchSetupPath` and `productBulkUploadPath`, use `GoRouterState.extra` to pass the selected sector string between screens.

3. **Change the "New Batch" navigation in `org_dashboard_page.dart`:**
Find the `_QuickActionCard` with label `'New Batch'` (currently navigates to `AppRouter.verificationPlanSetupPath`) and change it to navigate to `AppRouter.batchTypeSelectionPath`.

---

## IMPORTANT CONSTRAINTS

- Do NOT modify any existing files except:
  - `lib/core/router/app_router.dart` (add routes + constants)
  - `lib/features/orgs/presentation/pages/org_dashboard_page.dart` (change one `onTap` line)
- All new pages must be in `lib/features/orgs/verification_flow/presentation/pages/`
- Match the existing code style exactly: use `AppColors`, `AppTypography`, `AppSpacing` constants, `TMZCard`, `TMZInput` widgets where applicable
- Use the same `_GradientCtaButton` pattern for all bottom CTAs (copy the private class or create a shared version — your call)
- No API calls in any new screen yet — all frontend only, static/mock data is fine
- Each page must handle the back button correctly (pop if can pop, else go to dashboard)
- Use `GoRouterState.extra` typed as `String?` for passing the selected sector through the product flow screens

---

## FILE REFERENCES

The existing codebase is in the `lib/` folder. Key files to reference:
- `lib/core/router/app_router.dart` — routing
- `lib/features/orgs/presentation/pages/org_dashboard_page.dart` — where "New Batch" button lives
- `lib/features/orgs/verification_flow/presentation/pages/verification_plan_setup_page.dart` — style reference for industry cards, stepper, gradient CTA button, overall page structure
- `lib/features/orgs/verification_flow/presentation/pages/bulk_upload_page.dart` — style reference for upload UX
- `lib/features/orgs/verification_flow/presentation/pages/batch_created_success_page.dart` — style reference for success screen
- `lib/core/theme/app_colors.dart`, `app_typography.dart`, `app_spacing.dart` — design tokens
- `lib/core/widgets/` — shared widget library

Start by creating the 5 new page files, then update the router, then update the dashboard's New Batch tap target.