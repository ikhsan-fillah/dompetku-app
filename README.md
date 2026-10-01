# DompetKu

DompetKu is an offline-first personal finance application for one user on one device. It helps the user record income and expenses, understand spending patterns, manage a monthly budget, and review financial activity without cloud synchronization.

This README is the product brainstorming and feature specification. The development workflow, architecture, database preparation, implementation phases, and testing strategy are documented separately in [DEV_PLAN.md](DEV_PLAN.md).

## 1. Final Product Decisions

- **Users:** One user on one device.
- **Connectivity:** Local-only. No account system, cloud synchronization, or cloud backup is required for the first version.
- **Default currency:** Indonesian Rupiah (IDR).
- **Wallet model:** One wallet only. Multiple wallets are out of scope for the first version.
- **Transaction types:** Income and expense are both included in MVP 1.
- **Security:** Device biometric authentication is used instead of an application PIN.
- **Session state:** Shared Preferences stores non-sensitive session and preference flags.
- **Sensitive storage:** Secure storage is used only when a sensitive value is required.
- **Biometric lockout:** After five failed biometric attempts, the application blocks another attempt for five minutes.
- **Dashboard default range:** The first day of the current month through today.
- **Categories:** Categories can be created, renamed, archived, reordered, and customized. A category already used by a transaction cannot be deleted.
- **OCR:** The first OCR version prioritizes merchant, date, and total extraction. OCR results must always be reviewed before saving.
- **Theme:** Follow the device theme, with dark mode supported from the beginning.
- **Primary font:** Poppins.
- **Design system:** Customized Material 3.

## 2. Product Vision

Create a private, fast, and clear financial companion that helps the user:

- Record income and expenses reliably.
- Correct older transactions when a record was forgotten.
- Understand spending by category and date range.
- Compare monthly financial performance.
- Set and monitor spending budgets.
- Scan receipts to reduce manual entry.
- Keep financial records available after restarting the application.

## 3. Core User Flows

### 3.1 First Launch and Login

1. The application opens the splash screen.
2. The session state is read from local storage.
3. A new user is taken to the login page.
4. After successful login, the local session state is saved.
5. The application checks device biometric availability.
6. The user is asked to enable biometric protection after login.
7. The user enters the application after security setup is complete.

### 3.2 Returning User

1. The application opens the splash screen.
2. The stored local session state is read.
3. The application never opens the dashboard immediately when a session exists.
4. The biometric unlock state is shown.
5. The user authenticates with the device biometric prompt.
6. On success, the dashboard opens.
7. On failure, the user can retry until the lockout limit is reached.
8. After five failed attempts, biometric authentication is blocked for five minutes.

The application must never store or access raw fingerprint or face data. That data remains managed by the operating system.

### 3.3 App Lock

The application should lock again after returning from the background. The user should eventually be able to configure the auto-lock duration and manually lock the app from Profile.

### 3.4 Add a Transaction

1. The user taps the add transaction action.
2. The form defaults to today's date and the expense type.
3. The user can switch between expense and income.
4. The user enters a name, amount, date, category, payment method, and optional note.
5. The user can optionally attach a receipt image.
6. Validation runs before saving.
7. The transaction is stored locally.
8. The dashboard and transaction history refresh.

The transaction date can be changed to a previous date so forgotten transactions can be recorded.

### 3.5 Scan a Receipt

1. The user opens the receipt scanner from the transaction flow.
2. The user takes a photo or selects an existing image.
3. OCR extracts candidate fields.
4. Uncertain fields are marked for review.
5. The user edits merchant, date, total, category, and other values.
6. The transaction is created only after confirmation.

The first OCR release focuses on merchant, date, and total. Line-item extraction is a later enhancement.

## 4. Functional Scope

### 4.1 Dashboard

The default dashboard range is the first day of the current month through today. The user can choose a preset range or a custom start and end date.

Supported ranges:

- Today
- One week
- One month
- Three months
- Year to date
- One year
- All time
- Custom range

The dashboard should contain:

- Current balance.
- Total income for the selected range.
- Total expenses for the selected range.
- Remaining budget when budgets exist.
- Monthly spending efficiency progress using the actual calendar month length: 28, 29, 30, or 31 days.
- Spending trend chart.
- Four customizable category summary cards.
- Top spending category.
- Recent transactions.
- Budget warnings and useful insights.
- A prominent quick-add transaction action.

The date selector displays a start date and an end date. Tapping either date opens a calendar with quick range buttons.

Suggested order:

1. Greeting and current balance.
2. Date-range selector.
3. Income, expense, and balance summary.
4. Spending efficiency and trend.
5. Four selected category cards.
6. Recent transactions.
7. Budget warnings or insights.

### 4.2 Categories

Default expense categories:

- Food and drinks
- Transportation
- Shopping
- Bills
- Health
- Education
- Sports
- Entertainment
- Family
- Other

Default income categories:

- Salary
- Freelance
- Business
- Investment
- Gift
- Other

The user can create, rename, archive, reorder, and customize categories with an icon and color. Categories can be marked as dashboard favorites. A category already used by a transaction cannot be deleted.

### 4.3 Transactions

Each transaction can contain:

- Income or expense type.
- Name or title.
- Amount in IDR.
- Date and time.
- Category.
- Merchant or source.
- Payment method.
- Optional note.
- Optional receipt image.
- Creation and update timestamps.

Supported payment methods may include cash, e-wallet, QRIS, bank transfer, debit card, and credit card.

Transaction history should support search, date filtering, category filtering, amount filtering, type filtering, sorting, editing, deletion, and duplication.

### 4.4 Budgets

The first budget version supports monthly category budgets and an overall monthly spending limit.

Each budget shows its limit, used amount, remaining amount, usage percentage, progress state, and warnings at 75%, 90%, and 100%. Budgets can be edited or archived without deleting transaction history. Archived budgets can be reviewed and restored from the archive screen.

Implemented behavior (Stage 5A):

- The Budget tab lists budgets as progress cards with loading, empty, and error states, and pull-to-refresh.
- A budget can be overall or tied to one active expense category, with a name, an IDR limit, and a start and end date. The default period is the current calendar month.
- Usage is the sum of expense transactions inside the budget period, filtered by category when the budget has one.
- Budgets can be edited or archived from the card menu. Archiving keeps all transaction history.
- The list refreshes automatically when a budget or transaction changes.
- Still pending: a dashboard budget summary, and an archived-budgets screen.

Feature folder: `lib/features/budget/` with `bindings`, `controllers`, `data`, `models`, `repositories`, and `views`.

### 4.5 Reports

Reports may provide category breakdowns, income versus expense comparison, monthly trends, top merchants, highest spending days, average daily spending, and comparison with the previous equivalent period.

Insights should be descriptive and non-judgmental. For example: "Food spending was 18% higher than the previous month."

The report page implements: income versus expense summary, remaining budget, spending change versus the previous equivalent period, category breakdown, average daily spending, highest spending day, and top merchant.

### 4.6 Profile and Settings

The profile area may contain biometric lock preference, auto-lock duration, IDR display settings, theme preference, category management, budget management, local data deletion, privacy information, and application information.

## 5. Visual Direction

Material 3 is the base design system, customized for personal finance. Use Poppins with semi-bold headings, medium labels, and regular supporting text.

Recommended semantic palette:

- Primary deep teal: `#0F766E`
- Primary container soft mint: `#CCFBF1`
- Secondary warm amber: `#D97706`
- Secondary container light amber: `#FEF3C7`
- Income and success green: `#15803D`
- Expense and destructive rose: `#BE123C`
- Light background: `#F8FAF9`
- Surface: `#FFFFFF`
- Main text: `#1F2937`
- Muted text: `#64748B`
- Divider: `#E2E8F0`

Use teal for primary actions, green for income or positive balance, rose for expenses and destructive actions, and amber for warnings. The same semantic roles should power light and dark themes.

Keep the UI practical: use cards for repeated summaries, keep add transaction easy to reach, show exact values alongside charts, and provide loading, empty, error, and success states.

## 6. Product Success Criteria

The product direction is considered complete when the specification is clear about:

- A private local-only financial experience.
- Biometric protection before financial data is shown.
- Income and expense recording with editable historical dates.
- A dashboard with preset and custom date ranges.
- Monthly summaries that respect the actual calendar month.
- Customizable categories and a single-wallet model.
- Reviewed OCR-assisted receipt entry.
- Budgets, reports, and profile settings as part of the product direction.
- A consistent Material 3 and Poppins visual identity.

## 7. Implementation Status

Last updated: 1 October 2026. The detailed phase tracker and commit log are in [DEV_PLAN.md](DEV_PLAN.md).

| Area | Status |
|---|---|
| Local database, models, repositories | Done |
| Login, biometric unlock, app route guard | Done |
| Transactions (history and form) | Done |
| Dashboard / home | Done |
| Budgets (list, create, edit, archive, restore) | Done |
| Budget warning levels 75% / 90% / 100% | Done |
| Reports (summary, breakdown, daily statistics) | Done |
| Profile and settings | Done |
| OCR receipt scan (on-device ML Kit, review before save) | Done |

Quality gate: `flutter analyze` reports no issues and `flutter test` passes.

## 8. Release Notes

### 1.0.0

- Offline-first personal finance for one user on one device.
- Biometric protection with a five-failure lockout of five minutes, plus configurable auto-lock.
- Income and expense transactions with editable historical dates, search, filtering, duplication, and deletion.
- On-device ML Kit receipt OCR that fills candidate fields for review; photos are never stored.
- Dashboard with preset and custom date ranges, category breakdown, spending trend, budget summary, and insights.
- Budgets with 75%, 90%, and 100% warning levels, archive, and restore.
- Reports with category breakdown, previous-period comparison, daily average, highest spending day, and top merchant.
- Category management with custom icons, colors, favorites, ordering, and archive.
- Profile settings: display name, theme, auto-lock, manual lock, local export, and safe full reset.
