You are building a production-ready Ruby on Rails app using the LATEST stable Rails 8.x and modern Ruby (use latest stable Ruby 3.4.x unless specified otherwise). The app must be deployable with Kamal (Docker-based deploy), and run well as a browser-first web app (mobile/tablet compatible).

Tech stack:
- Ruby on Rails 8.x (latest stable)
- Ruby 3.4.x (latest stable)
- Hotwire: Turbo + Stimulus
- TailwindCSS
- Postgres in production, SQLite in development
- ActiveStorage (local in dev; S3-compatible in production)
- Background jobs: Solid Queue (Rails-native) for reminders and email delivery
- Kamal for deployment (with container registry)

App goal:
Inventory + cashflow + receivables/payables system for a small supplier business (supermarket + vending).
MVP must include generating a Delivery Report PDF (printable) and emailing it to recipients.

========================================================
1) AUTH + BUSINESS SCOPING (Multi-business)
========================================================
- Implement authentication (prefer Rails 8 built-in auth generator if available; otherwise Devise).
- Models:
  - User
  - Business
  - Membership (user_id, business_id, role enum {owner, staff})
- Current business:
  - Store current_business_id in session.
  - Business switcher UI in navbar.
- All domain records must include business_id and be scoped by current_business in controllers and queries.
- Hardening requirement (implemented):
  - Add cross-tenant association validation so related records must match the same business.
  - Example checks: Purchase->Supplier/Location, Delivery->Customer/Location/Items, StockMovement->Product/Locations/Reference.
  - Reject mismatched IDs with model validation errors (prevents crafted cross-tenant POST/PATCH payloads).

========================================================
2) EXPENSES + FUNDING SOURCE (Personal vs Business)
========================================================
- Expense fields:
  business_id, occurred_on (date), payee (string), category_id,
  amount_cents (int), currency (string),
  funding_source enum {personal, business},
  payment_method enum {cash, bank, card},
  notes (text)
- Attach receipt via ActiveStorage (one attachment minimum).
- UI:
  - index with filters (date range, category, funding_source, payee search)
  - new/edit/show
- Insight cards:
  - personal out-of-pocket MTD
  - business-paid MTD
  - total expenses MTD

========================================================
3) PAYABLES + PAYMENTS + REMINDERS
========================================================
- Payable fields:
  business_id,
  payable_type enum {supplier, credit_card, loan, rent, utilities, other},
  payee (string),
  amount_cents, currency,
  due_on (date),
  status enum {unpaid, paid, overdue},
  notes (text),
  recurring_rule (string nullable; MVP can be one-off only)
- Payment model:
  business_id,
  payable_id nullable,
  expense_id nullable,
  paid_on (date),
  amount_cents,
  method enum {cash, bank, card},
  notes (text)
- UI:
  - Upcoming (next 30 days) list, Overdue list, All payables list
  - Mark paid action (Turbo frame updates status and lists)
  - Payments history on payable show page

========================================================
4) PRODUCTS + LOCATIONS + STOCK MOVEMENTS (Inventory Ledger)
========================================================
- Product:
  business_id, name, sku nullable, unit enum/string (pc/box/case),
  reorder_level integer nullable, active boolean default true
- Location:
  business_id, name,
  location_type enum {home, storage, warehouse, vending, customer, other}
- StockMovement:
  business_id,
  movement_type enum {in, out, transfer, adjustment},
  product_id,
  quantity (decimal),
  unit_cost_cents integer nullable (required for movement_type=in),
  from_location_id nullable,
  to_location_id nullable,
  occurred_on (date),
  reference_type/reference_id nullable (polymorphic link),
  notes (text)
- Validation rules:
  - in: requires to_location, from_location must be null
  - out: requires from_location, to_location must be null
  - transfer: requires both
  - adjustment: requires a location and quantity can be positive/negative (choose one approach and enforce it consistently)
- Implement service objects:
  - Inventory::OnHandCalculator (on-hand per product per location + totals)
  - Inventory::StockValidator (checks sufficient stock before stock-out / delivery)
- UI:
  - Products CRUD
  - Locations CRUD
  - Stock Movements: separate “Stock In / Stock Out / Transfer / Adjustment” flows
  - Inventory view:
    - by product totals
    - drilldown by location
    - low-stock badge where on-hand <= reorder_level

========================================================
5) PURCHASES + COST TRACKING
========================================================
- Supplier:
  business_id, name, optional contact fields
- Purchase:
  business_id, supplier_id, purchased_on (date),
  receiving_location_id,
  funding_source enum {personal, business},
  notes (text),
  status enum {draft, received} (MVP)
- PurchaseItem:
  purchase_id, product_id, quantity (decimal), unit_cost_cents (int)
- Receive workflow:
  - On receive, create StockMovement records type=in per item into receiving_location_id with unit_cost_cents
  - Mark purchase status = received
- Costing:
  - Weighted average cost helper based on stock-in movements (per product)

========================================================
6) RECEIVABLES + COLLECTIONS (Cash In) + REMINDERS
========================================================
- Customer:
  business_id, name, optional address/contact fields
- Receivable:
  business_id, customer_id, reference string,
  delivered_on date nullable,
  due_on date,
  amount_cents, currency,
  status enum {pending, collected, late},
  notes (text)
- Collection:
  business_id, receivable_id nullable,
  collected_on date,
  amount_cents,
  method enum {cash, bank},
  notes (text)
- UI:
  - Receivables list: due soon (next 30 days), overdue, all
  - Mark collected action: creates Collection + updates receivable status via Turbo
  - Collections history page (optional MVP)

========================================================
6.5) DELIVERIES + DELIVERY REPORT (PDF + EMAIL) [MVP REQUIRED]
========================================================
Implement a Delivery workflow for supermarkets/customers that generates a printable PDF and can email it.

A) Models
- Delivery:
  business_id,
  customer_id,
  delivered_on (date),
  delivery_number (string unique per business, e.g. DR-YYYY-000001),
  status enum {draft, delivered, void},
  from_location_id (required to mark delivered),
  notes (text)
- DeliveryItem:
  delivery_id,
  product_id,
  quantity (decimal),
  unit_price_cents (int nullable)   -- optional: keep but allow hiding prices in PDF
- DeliveryEmailLog:
  delivery_id,
  sent_by_user_id,
  recipients (text),
  subject (string),
  message (text),
  sent_at datetime,
  status enum {queued, sent, failed},
  error_message (text nullable)

B) Delivery UI / Screens
- Deliveries index:
  filters by customer/date/status; quick actions:
   View, Edit, Generate PDF, Download PDF, Email PDF, Mark Delivered
- Delivery form:
  customer, delivered_on, from_location, notes
  nested items (DeliveryItem): product select + quantity (+ optional unit_price)
- Delivery show:
  display items, totals, status, stock-out link records, PDF status, email history
  buttons:
    - Generate/Regenerate PDF (Turbo)
    - Download PDF (ActiveStorage)
    - Email PDF (form: recipients + subject + message)
    - Mark as Delivered

C) PDF generation
- Use Prawn gem to generate a Delivery Report PDF (avoid headless browser dependency).
- PDF content must include:
  - Business name (and optional contact info if available)
  - Title: "Delivery Report"
  - delivery_number, delivered_on
  - customer name (and optional address)
  - items table: product name, unit, quantity
  - (optional) show unit_price and totals if unit_price present AND a toggle says show_prices
  - notes
  - signature lines: Delivered by / Received by / Date
  - page numbers
- Storage:
  - Attach PDF to the Delivery via ActiveStorage (e.g., delivery.report_pdf attachment).
  - Regeneration should replace existing attachment.

D) Emailing the report
- Implement DeliveryReportMailer:
  - send_report(delivery_id, recipients, subject, message)
  - attach the Delivery PDF
- Provide a DeliveryReportEmailJob (ActiveJob) to send in background (Solid Queue).
- Email form:
  - recipients input accepts comma/semicolon-separated emails
  - validate format; if invalid, show errors
- On submit:
  - create DeliveryEmailLog status=queued
  - enqueue job
- In job:
  - send email
  - update log status=sent with sent_at
  - on exception update status=failed with error_message

E) Inventory integration (critical)
- When Delivery is marked delivered:
  - validate from_location present
  - validate sufficient stock for each item (block and show errors if insufficient)
  - create StockMovement records of type=out per item:
    business_id, product_id, quantity,
    from_location_id, occurred_on=delivered_on,
    reference_type="Delivery", reference_id=delivery.id,
    notes="Delivery <delivery_number> to <customer>"
  - update delivery status to delivered
- If delivery is voided:
  - MVP: disallow voiding once delivered OR require a reversal workflow (choose one and document).
  - Prefer MVP: disallow voiding if delivered.

========================================================
7) DASHBOARD (End-of-day Insights)
========================================================
Dashboard should show:
- Upcoming payables (next 7 / 30 days)
- Overdue payables
- Upcoming receivables (collections due next 7 / 30)
- Overdue receivables
- Low stock alerts
- Month-to-date:
  - expenses total
  - personal out-of-pocket total
  - collections total
  - net cashflow = collections - expenses - payments
- Today:
  - deliveries made today + link to delivery reports

========================================================
8) REMINDERS + NOTIFICATIONS (MVP)
========================================================
- Notification:
  business_id, user_id,
  notifiable_type/id,
  message, due_on,
  status enum {unread, read}
- Business settings:
  reminder_lead_days integer default 7
- Daily job:
  - generates notifications for payables due in lead days, and overdue payables
  - generates notifications for receivables due in lead days, and overdue receivables
- Notifications inbox UI:
  - list unread/read
  - mark read (Turbo)

========================================================
9) UI/UX REQUIREMENTS
========================================================
- TailwindCSS must be used as the primary UI layer with a clean, user-friendly, mobile-first design.
- Theme requirement (mandatory):
  - Implement at least 3 visual themes (e.g., Ocean, Forest, Classic) using CSS variables + Tailwind component classes.
  - Include a visible theme switcher in the app shell (navbar/header).
  - Persist user theme choice in browser localStorage and apply it on first paint to avoid flash/mismatch.
  - Theme must affect key UI surfaces (background, cards, buttons, badges, links, nav, tables), not only one accent color.
- Build a reusable UI pattern set (partials/components) for:
  - App shell: top nav, business switcher, page header, breadcrumb
  - Data displays: cards, responsive tables, definition lists, KPI widgets
  - Actions: buttons (primary/secondary/ghost/danger), dropdowns, pagination
  - Feedback: badges, alerts, toasts/flash messages, form errors, empty states, skeleton loaders
  - Forms: labeled inputs, selects, date pickers, textareas, input groups, validation hints
- Design tokens (Tailwind theme):
  - Define consistent color palette, spacing scale, radius, shadows, and typography in Tailwind config.
  - Ensure high contrast text and status colors (success/warning/danger/info).
  - Keep visual hierarchy clear using size/weight/spacing, not color alone.
- User-friendly layout requirements:
  - Mobile-first screens that scale cleanly to tablet/desktop.
  - Sticky table headers for long lists; horizontal scroll wrappers on small screens.
  - Primary actions visible above the fold; destructive actions visually distinct.
  - Empty states should include helpful copy and a clear next action.
- Accessibility requirements:
  - Keyboard navigable interactive elements with visible focus states.
  - Minimum touch target size for buttons/controls.
  - Proper labels, aria attributes where needed, and semantic HTML structure.
  - Do not rely only on color to convey status.
- Turbo/Stimulus UX:
  - Inline status updates for payable paid / receivable collected / delivery delivered.
  - Use Turbo Frames for partial page refreshes in lists and detail side panels.
  - Optional modal forms for quick actions; ensure Esc/close behavior and focus management.
- Domain-specific UI guidance:
  - Dashboard: KPI cards first, then alerts (overdue/low stock), then activity lists.
  - Financial pages: default sort by most urgent due date; highlight overdue rows.
  - Inventory pages: low-stock badges and quick filters (location/product/status).
  - Deliveries: one-click actions for Generate PDF, Download PDF, Email PDF, Mark Delivered.
- Currency helpers:
  - Store cents; display formatted currency (2 decimals) consistently across all components.

CRUD UI implementation baseline (must be maintained):
- All CRUD resources must use Tailwind component classes for consistent UX:
  - Page headers: `page-title` + subtitle + primary action button.
  - Forms: wrap in `card`, use `field-label` and `field-input`, show validation errors in `flash flash-alert`.
  - Actions: use `btn` variants (`btn-primary`, `btn-secondary`, `btn-ghost`, `btn-danger`) for links and form submits.
  - Lists: use `table-wrap` + `table-base` for data tables with action column on the right.
  - Show/detail views: render key fields in card-based definition lists (`dl`) and display statuses using `status_badge`.
  - Empty states: use `empty-state` copy with a clear next action.
- Apply the same design contract across all domain CRUD pages:
  - Products, Customers, Suppliers, Locations
  - Expenses, Payables, Receivables
  - Purchases, Deliveries, Stock Movements
  - Supporting views: Categories, Payments, Collections, Notifications

Starter Tailwind component checklist (implementation order):
1. Foundation
   - Configure Tailwind theme tokens (colors, spacing, radius, shadows, typography).
   - Create base layout shell: navbar, business switcher, container, page header.
   - Add theme variables and at least 3 theme palettes; wire a persistent theme switcher.
2. Core controls
   - Build button variants (primary/secondary/ghost/danger) and link styles.
   - Build form primitives: input, select, textarea, checkbox, date input, field error text.
3. Feedback and states
   - Implement flash/alert components (success/warning/error/info).
   - Implement badges and status pills for payable/receivable/delivery/inventory states.
   - Implement empty-state and loading/skeleton components.
4. Data presentation
   - Build responsive table wrapper with sticky header and row status styling.
   - Build card and KPI widgets for dashboard summaries.
5. Interaction patterns
   - Add Turbo Frame-ready partials for lists and detail panels.
   - Add modal/slide-over pattern with proper focus handling and keyboard close behavior.
6. Domain assembly
   - Apply components to Dashboard first, then Deliveries, then Payables/Receivables, then Inventory.
   - Validate consistency of spacing, type scale, button placement, and status color usage.
7. Quality checks
   - Run mobile viewport checks for key pages (dashboard, index lists, form pages, delivery show).
   - Run keyboard-only pass and focus visibility checks.
   - Verify color contrast and that status is understandable without color alone.

========================================================
10) AUTHORIZATION RULES
========================================================
- Owner: full CRUD
- Staff:
  - can create/edit deliveries and stock movements
  - can view dashboard
  - cannot delete financial records (expenses/payables/collections)
  - cannot change business settings
Use a simple policy layer (Pundit) or controller checks.

Implemented controller-check baseline:
- `ApplicationController` enforces a global staff operation guard.
- Allowed for staff: dashboard, deliveries, stock movements, notifications, user guide, sign out, business switch.
- Owner/system-admin required for restricted domains.

System admin (platform-level) implemented:
- `users.system_admin` boolean flag.
- Admin namespace:
  - `/admin` dashboard
  - `/admin/users` (view users, toggle system admin, manage memberships)
  - `/admin/businesses` (view tenants and members)
- System admins can manage users/business memberships across all tenants.

========================================================
11) DEPLOYMENT REQUIREMENTS (KAMAL + DOCKER)
========================================================
- Provide:
  - Dockerfile for Rails 8 production (multi-stage, bootsnap precompile, assets precompile)
  - .dockerignore
  - Kamal config (deploy.yml):
    - registry settings (Docker Hub or GHCR)
    - env + secrets:
      RAILS_MASTER_KEY
      SECRET_KEY_BASE
      DATABASE_URL or POSTGRES settings
      ACTIVE_STORAGE service env vars (S3 compatible)
      SMTP settings for Action Mailer in production
    - accessories:
      - Postgres as accessory container by default
      - (optional) Redis only if needed; prefer Solid Queue without extra deps
- Production readiness:
  - /up healthcheck route for Kamal
  - migrations run on deploy (document the commands)
- README includes:
  - local dev setup
  - how to set secrets
  - how to deploy with Kamal
  - how to configure SMTP and S3 storage

========================================================
12) SEEDS + TESTS
========================================================
- Seeds:
  - owner user
  - business
  - sample customers (supermarket)
  - sample products + locations
- Tests (request/system):
  - create expense
  - mark payable paid
  - receive purchase -> creates stock-in movements
  - create delivery -> mark delivered -> creates stock-out movements
  - generate delivery PDF -> attachment exists
  - email delivery PDF -> enqueues job + creates DeliveryEmailLog
  - cross-tenant validation checks for purchases/deliveries/stock movements
  - staff authorization guard check
  - system admin namespace access checks

Deliver the full codebase with clean structure, clear README, and production-ready defaults.

========================================================
13) GIT WORKFLOW REQUIREMENT
========================================================
- Always create a git commit whenever any file changes are made.
- Do not leave modified or staged files uncommitted at the end of a task.
