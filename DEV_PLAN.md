# DompetKu Development Plan

This document contains the development workflow for DompetKu. The product decisions and feature brainstorming are documented in [README.md](README.md).

The implementation order is intentional: stabilize the project, prepare the core logic and database, implement services and controllers, test the behavior, and only then build the UI.

## Implementation Status

Last updated: 29 September 2026.

Current quality gate: `flutter analyze` reports no issues and `flutter test` passes.

| Phase | Scope | Status |
|---|---|---|
| 0 | Baseline and cleanup | Done |
| 1 | Core contracts and utilities | Done |
| 2 | Database and migrations | Done |
| 3 | Models and domain logic | Done |
| 4 | Platform services | Done |
| 5 | Authentication and security logic | Implemented (auth controller, route guard, biometric pages); to be confirmed against exit criteria |
| 6 | Controllers and state flow | In progress: transaction, budget, and shell controllers exist; report and profile controllers to be confirmed |
| 7 | Minimal UI shell | Implemented (splash, login, biometric pages, main shell); to be confirmed |
| 8 | Transaction feature UI | Implemented (history and form sheet); to be confirmed |
| 9 | Dashboard UI | Implemented (home page); to be verified against calculation tests |
| 10 | Budgets, reports, and profile UI | In progress: budgets done (Stage 5A); threshold warnings, reports, and profile settings pending |
| 11 | OCR | Not started |
| 12 | Quality and release preparation | Not started |

Statuses marked "to be confirmed" were inferred from the code present in the repository and must be checked against each phase's exit criteria before being marked Done.

### Stage 5A: Budgets (completed)

| Step | Content | Commit |
|---|---|---|
| 5A-1 | Budget model, repository contract, and local data source | Present before 5A-2 |
| 5A-2 | `BudgetController`: progress from expense transactions, archive, silent refresh, with tests | f76282a |
| 5A-3 | `BudgetFormController`: create and edit, validation, active expense categories | 77a1983 |
| 5A-4a | `BudgetBinding` with lazy, fenix registration | 6ae6d44 |
| 5A-4b | `BudgetPage`: progress cards, loading, empty, and error states | 15d1128 |
| 5A-4c | `BudgetFormPage`: create and edit form | 65c3614 |
| 5A-4d | `/budget-form` route, binding on the home route, Edit and Archive menu | 765791a |
| 5A-4e | Lint fixes (`initialValue`, `(_, _)`) | 3975ca9 |
| 5A-5 | Budget tab in the main shell now shows `BudgetPage` | 9a8c2b8 |
| 5A-6 | `BudgetFormController` tests | d00a735 |

Implemented budget rules:

- A budget is either overall (no category) or tied to one active expense category.
- Usage is the sum of expense transactions inside the budget's inclusive date range.
- Archiving a budget never deletes transaction history.
- Changing a budget or a transaction triggers a refresh through `DataRefreshService`.

### Next Steps

1. Align budget warnings with the 75%, 90%, and 100% thresholds from the README, using `BudgetStatus` levels instead of the fixed 80% used by the first budget card.
2. Show a budget summary and warnings on the dashboard.
3. Add an archived-budgets screen with restore.
4. Build report filters and visualizations (Phase 10).
5. Complete profile and settings (theme, biometric preference, auto-lock, safe data deletion).
6. Implement OCR with mandatory review (Phase 11).
7. Run the full quality checklist and prepare release notes (Phase 12).

## 1. Development Rules

- Keep financial data local to the device.
- Keep SQLite access out of pages and widgets.
- Keep financial calculations in pure, testable services.
- Keep platform capabilities behind injectable services.
- Keep controllers responsible for state and user intent.
- Use typed models instead of passing raw maps through the application.
- Validate each phase before starting the next one.
- Do not build UI for a feature until its data and logic path is testable.

## 2. Recommended Architecture

```text
Presentation
  Pages, widgets, and controllers

Domain
  Entities, value objects, repository contracts, and use cases

Data
  Models, SQLite data sources, repository implementations, and mappers

Core
  Database, platform services, constants, errors, validation, formatting, and theme
```

Dependency direction:

```text
Page / Widget
    -> Controller
    -> Use Case or Repository Contract
    -> Repository Implementation
    -> Local Data Source
    -> SQLite or Platform API
```

Pages and widgets must not contain direct SQLite queries or complex financial calculations.

## 3. Target Project Structure

```text
lib/
  app/
    bindings/
    routes/
  core/
    constant/
    database/
      app_database.dart
      database_constants.dart
      migrations.dart
      tables/
    errors/
    services/
      biometric_service.dart
      shared_prefs_service.dart
      secure_storage_service.dart
      app_lock_service.dart
      image_storage_service.dart
      ocr_service.dart
    theme/
    utils/
      date_range.dart
      formatter.dart
      validator.dart
    widgets/
  features/
    auth/
      controllers/
      pages/
    category/
      controllers/
      data/
      models/
      repositories/
    transaction/
      controllers/
      data/
      models/
      repositories/
    budget/
      bindings/
      controllers/
      data/
      models/
      repositories/
      views/
    dashboard/
      controllers/
      models/
      services/
    report/
      controllers/
      models/
      services/
    profile/
      controllers/
      pages/
```

## 4. Phase 0: Baseline and Cleanup

1. Confirm the Flutter and Dart versions.
2. Run `flutter pub get`.
3. Run `flutter analyze` and `flutter test` to capture the current baseline.
4. Fix current compilation errors.
5. Remove duplicate imports.
6. Remove obsolete PIN references from the active flow.
7. Correct dependency registration order in the initial binding.
8. Replace the default counter test with a minimal application smoke test.
9. Run `flutter analyze` and `flutter test` again.

**Exit criteria:** The project compiles, tests start successfully, and the initial route can open.

## 5. Phase 1: Core Contracts and Utilities

Prepare logic that does not depend on widgets or a real device.

### Constants

Create constants for:

- Default currency: `IDR`.
- Database name and version.
- Route names.
- Maximum biometric failures: `5`.
- Biometric lockout duration: `5 minutes`.
- Default dashboard start: first day of the current month.

### Enums and Value Objects

Create:

- `TransactionType`: income or expense.
- `PaymentMethod`: cash, e-wallet, QRIS, bank transfer, debit card, credit card, or other.
- `DateRangePreset`: today, week, month, three months, YTD, year, all time, custom.
- `DateRange`: validated start and end dates.
- `BiometricStatus`: unavailable, required, authenticating, authenticated, failed, locked out.
- Application failure types for validation, storage, biometric, OCR, and database errors.

### Utilities

Implement and test:

- IDR amount parsing and formatting.
- Required-field validation.
- Positive amount validation.
- Inclusive date-range validation.
- Preset date-range calculation.
- Calendar month length calculation.
- Five-failure lockout calculation.

**Exit criteria:** These utilities are unit-testable without Flutter UI.

## 6. Phase 2: Database and Migrations

SQLite is the source of truth for categories, transactions, and budgets. Shared Preferences is not suitable for financial records.

### Database Rules

- Use a versioned SQLite database.
- Implement migrations from the first schema version.
- Store IDR amounts as integers.
- Store timestamps consistently, preferably UTC internally.
- Use foreign keys and indexes.
- Archive categories and budgets instead of destructive deletion.
- Store receipt paths separately from transaction data.
- Seed default categories only when the database is created for the first time.

### Initial Tables

#### `categories`

- `id` INTEGER primary key.
- `name` TEXT not null.
- `type` TEXT not null: `income` or `expense`.
- `icon_key` TEXT not null.
- `color_value` INTEGER not null.
- `is_default` INTEGER not null.
- `is_favorite` INTEGER not null.
- `sort_order` INTEGER not null.
- `is_archived` INTEGER not null.
- `created_at` TEXT not null.
- `updated_at` TEXT not null.

#### `transactions`

- `id` INTEGER primary key.
- `type` TEXT not null.
- `title` TEXT not null.
- `amount` INTEGER not null.
- `currency` TEXT not null, initially `IDR`.
- `transaction_date` TEXT not null.
- `category_id` INTEGER not null.
- `merchant_or_source` TEXT.
- `payment_method` TEXT.
- `note` TEXT.
- `receipt_path` TEXT.
- `created_at` TEXT not null.
- `updated_at` TEXT not null.
- Foreign key to `categories(id)`.

Indexes: `transaction_date`, `category_id`, `type`, and `created_at`.

#### `budgets`

- `id` INTEGER primary key.
- `name` TEXT not null.
- `amount_limit` INTEGER not null.
- `category_id` INTEGER nullable for an overall budget.
- `start_date` TEXT not null.
- `end_date` TEXT not null.
- `is_archived` INTEGER not null.
- `created_at` TEXT not null.
- `updated_at` TEXT not null.

### Database Components

Implement before UI:

- `AppDatabase`: opens the database and coordinates migrations.
- `DatabaseConstants`: database and column constants.
- `Migrations`: creates tables, indexes, seed data, and future upgrades.
- `CategoryLocalDataSource`: category CRUD and ordering.
- `TransactionLocalDataSource`: transaction CRUD and filtered queries.
- `BudgetLocalDataSource`: budget CRUD and budget queries.
- Row mappers: convert database maps into typed models and back.

### Database Tests

Test database creation, seed data, CRUD, category archive behavior, foreign keys, date filters, category filters, and migration behavior.

**Exit criteria:** Data survives application restart and database behavior is covered by tests.

## 7. Phase 3: Models and Domain Logic

Create typed models before building pages.

### Models

- `CategoryModel`.
- `TransactionModel`.
- `BudgetModel`.
- `DashboardSummaryModel`.
- `CategorySummaryModel`.
- `SpendingTrendPoint`.
- `OcrDraftModel`.
- `AppSessionModel`.

Models should be immutable where practical and should explicitly convert to and from database maps.

### Repository Contracts

Define contracts before implementations:

- `SessionRepository`.
- `CategoryRepository`.
- `TransactionRepository`.
- `BudgetRepository`.
- `DashboardRepository` or dashboard query service.

Repositories return typed results and domain-friendly failures, not raw database maps or platform exceptions.

### Financial Services

Create pure services for:

- Total income in a date range.
- Total expenses in a date range.
- Balance calculation.
- Category totals.
- Spending trend buckets.
- Budget used and remaining amounts.
- Monthly efficiency based on the actual month length.
- Previous equivalent period comparison.

All calculations use the selected inclusive date range consistently. Dashboard, reports, and budgets must share these calculations instead of reimplementing them.

**Exit criteria:** Correct typed financial results can be produced without UI.

## 8. Phase 4: Platform Services

Prepare platform integrations behind injectable abstractions:

- `BiometricService`: checks availability and performs device authentication.
- `SessionService`: reads and writes local login state with Shared Preferences.
- `SecureStorageService`: stores only values that genuinely require secure storage.
- `AppLockService`: tracks app lifecycle and lock timing.
- `ImageStorageService`: stores and removes receipt images.
- `OcrService`: converts receipt images into editable OCR drafts.

Each service must be mockable for tests.

**Exit criteria:** Platform-dependent behavior has testable interfaces and does not leak into domain logic.

## 9. Phase 5: Authentication and Security Logic

1. Implement session persistence.
2. Implement biometric availability checks.
3. Implement biometric setup after successful first login.
4. Implement biometric unlock for returning users.
5. Implement the five-failure counter.
6. Implement the five-minute lockout.
7. Persist only the lockout state and timestamps that are necessary.
8. Implement app lifecycle locking.
9. Replace splash fixed delays with awaited session initialization.
10. Implement clear unavailable, denied, failed, and locked-out states.
11. Add service and controller tests with mocked biometric results.

The application must not show financial data before successful unlock.

**Exit criteria:** A returning user cannot reach financial data without authentication.

## 10. Phase 6: Controllers and State Flow

Prepare controllers around user intent:

- `SplashController`: resolves initial session state.
- `AuthController`: login, biometric setup, unlock, failure count, and lockout.
- `DashboardController`: date range, summary, trends, category cards, and refresh.
- `CategoryController`: load, create, edit, archive, reorder, and favorite categories.
- `TransactionController`: form state, validation, save, edit, delete, duplicate, and filters.
- `BudgetController`: load, create, edit, archive, and progress.
- `ReportController`: report range and report calculations.
- `ProfileController`: theme, biometric preference, auto-lock, and data settings.

Controllers must expose explicit loading, success, empty, and error states. Dependencies must be registered before controllers are constructed. Avoid calling `Get.find` from field initializers before bindings are ready.

Test controller states for loading, success, empty data, validation errors, repository failures, and refresh after mutations.

**Exit criteria:** Every important user action has a tested service, repository, and controller path.

## 11. Phase 7: Minimal UI Shell

Only after the previous logic layers are ready:

1. Configure Poppins.
2. Create customized Material 3 light and dark color schemes.
3. Build route and navigation structure.
4. Build reusable buttons, fields, amount input, loading state, empty state, error state, and confirmation dialog.
5. Build splash, login, biometric setup, and biometric unlock pages.
6. Remove old PIN pages from the active navigation.
7. Add widget tests for authentication gates and error states.

**Exit criteria:** Authentication UI works against tested services and controllers.

## 12. Phase 8: Transaction Feature UI

1. Build the transaction form.
2. Default the date to today.
3. Support income and expense.
4. Support previous dates.
5. Add category and payment method selection.
6. Add validation and save feedback.
7. Build transaction history.
8. Add search, filters, sorting, edit, delete, and duplicate actions.
9. Add widget tests for the primary transaction flow.

**Exit criteria:** The user can create and manage real local transactions.

## 13. Phase 9: Dashboard UI

1. Build the default current-month range.
2. Build preset and custom date-range selection.
3. Build balance and income/expense summary cards.
4. Build monthly efficiency progress.
5. Build trend visualization with exact values.
6. Build four customizable category cards.
7. Build recent transactions and quick add.
8. Add loading, empty, and error states.
9. Verify displayed values against calculation tests.

**Exit criteria:** Dashboard values match repository and domain calculations for every supported range.

## 14. Phase 10: Budgets, Reports, and Profile UI

Progress: item 1 is done (Stage 5A). The warning thresholds in item 2 are pending: the first budget card uses a fixed 80% warning and must move to the 75%, 90%, and 100% levels.

1. Build budget creation and progress UI.
2. Add 75%, 90%, and 100% threshold warnings.
3. Build report filters and visualizations.
4. Build profile and settings.
5. Add theme and biometric preference controls.
6. Add safe local data deletion confirmation.

**Exit criteria:** Secondary features use shared repositories and calculations without duplicating business rules.

## 15. Phase 11: OCR

1. Evaluate an OCR solution for accuracy, platform support, privacy, and offline behavior.
2. Implement image capture and selection.
3. Implement image storage and cleanup.
4. Parse merchant, date, and total into `OcrDraftModel`.
5. Mark uncertain fields.
6. Build the review and edit screen.
7. Save a transaction only after confirmation.
8. Test missing fields, invalid totals, different date formats, blurry images, and user edits.

The initial OCR implementation should prefer a privacy-preserving and offline-capable solution when accuracy is acceptable. If offline accuracy is insufficient, the limitation must be documented before any remote processing is introduced.

**Exit criteria:** OCR never silently saves an unreviewed transaction.

## 16. Phase 12: Quality and Release Preparation

1. Run unit, widget, database, and integration tests.
2. Test on Android devices with and without biometric hardware.
3. Test biometric failure and five-minute lockout behavior.
4. Test dark mode, small screens, long amounts, empty data, and database failures.
5. Check data persistence after force close and restart.
6. Add local export before releasing destructive data-management features.
7. Review permissions and privacy behavior.
8. Update README and release notes.

## 17. Testing Checklist

### Unit Tests

- Date-range presets and custom ranges.
- Calendar month length and monthly efficiency.
- IDR amount validation and formatting.
- Balance and summary calculations.
- Budget progress and thresholds.
- Biometric lockout rules.
- OCR field parsing.

### Database Tests

- Schema creation.
- Default category seeding.
- Transaction CRUD.
- Category archive behavior.
- Foreign key behavior.
- Date and category filters.
- Database migrations.

### Controller Tests

- Initial session resolution.
- Authentication success and failure.
- Loading, empty, success, and error states.
- Transaction validation and save flow.
- Dashboard refresh after a transaction changes.
- Budget progress, archive, and form validation (covered in Stage 5A).

### Widget and Integration Tests

- First-login flow.
- Returning-user biometric gate.
- Transaction creation.
- Custom date-range selection.
- Dashboard summary rendering.
- Dark mode rendering.

## 18. Final Definition of Done

The first usable application is complete when:

- The project compiles and passes analysis.
- A new user can log in and configure biometric protection.
- A returning user must pass biometric authentication before seeing financial data.
- Five failed biometric attempts trigger a five-minute lockout.
- A user can add, edit, delete, duplicate, and review income or expense transactions.
- Transaction dates default to today but can be changed to an earlier date.
- Default categories are seeded once and remain manageable.
- Categories used by transactions cannot be deleted.
- The dashboard defaults to the first day of the current month through today.
- Preset and custom date ranges calculate correct totals.
- Monthly efficiency follows the actual number of days in each calendar month.
- Data remains available after application restart.
- Dark mode follows the selected device or app theme.
- OCR results are reviewed before a transaction is created.
- Loading, empty, validation, biometric failure, lockout, and database error states are handled.
- Core domain, database, controller, and user flows are covered by automated tests.
