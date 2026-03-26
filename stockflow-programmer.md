Stockflow Current-State Guide
=============================

This document describes the current implementation state of the Stockflow Rails app in this repository. It is not a future-state product spec. Where the app differs from the earlier roadmap, this file reflects the code that exists now.

Stack
-----
- Ruby on Rails 8
- Ruby 3.4
- Hotwire: Turbo + Stimulus
- TailwindCSS
- ActiveStorage
- ActiveJob
- SQLite in local development
- Kamal deploy files present in `config/deploy.yml` and `config/deploy.dev.yml`

App Purpose
-----------
Stockflow is a browser-first operations app for small supplier businesses. The implemented scope centers on:
- multi-business authentication and membership
- inventory tracking through stock movements, purchases, and deliveries
- payables, receivables, collections, and expenses
- delivery PDF generation and emailing

High-Level Architecture
-----------------------
- Business scoping is enforced through `Current.business` and controller scoping.
- Most domain models include `business_id`.
- Cross-tenant association validation is implemented through `BusinessScopeValidation`.
- System admins operate through the admin namespace and must impersonate a store user to access normal store workflows.

Implemented Routes
------------------
Key route groups currently available:
- public pages: `/`, `/about`
- auth: `/login`, `/admin/login`, `/registration`, `/passwords`
- admin: `/admin`, `/admin/users`, `/admin/businesses`, `/admin/memberships`, `/admin/impersonation`
- store settings: `/business/edit`, `/business/members`
- domain CRUD: categories, customers, suppliers, products, locations, expenses, payables, payments, purchases, receivables, collections, deliveries, notifications
- stock ledger: `/stock_movements`
- dashboard: `/dashboard`
- delivery PDF preview:
  - `/deliveries/preview_pdf`
  - `/deliveries/:id/preview_pdf`
- healthcheck: `/up`

Authentication And Multi-Business Behavior
------------------------------------------
Implemented models:
- `User`
- `Business`
- `Membership`
- `Session`

Implemented behavior:
- users authenticate with `has_secure_password`
- public registration creates users pending approval
- admin users can approve pending users
- users can belong to multiple businesses through memberships
- current business is stored in session and surfaced through `Current.business`
- system admins are blocked from normal business pages unless impersonating
- owners have broader access than staff

Authorization currently enforced in controllers:
- owners can manage broader business data
- staff are limited to a narrower set of operational pages
- system admins use the admin namespace and impersonation flow

Important controller-level guard:
- `ApplicationController#ensure_staff_can_manage_operations!`
- allowed for staff: dashboard, deliveries, stock movements, notifications, user guide, business switch, session/sign out

Admin Namespace
---------------
Implemented admin features:
- admin dashboard
- user list and detail views
- approve pending users
- edit users
- manage memberships across businesses
- create and inspect businesses
- impersonation create/destroy

Current Domain Models
---------------------
Implemented business-scoped domain models:
- Category
- Expense
- Payable
- Payment
- Product
- Location
- StockMovement
- PurchaseFundingSource
- Supplier
- Purchase
- PurchaseItem
- Customer
- Receivable
- Collection
- Delivery
- DeliveryItem
- DeliveryEmailLog
- Notification

Expenses
--------
Current implementation differs from the original enum-heavy roadmap.

Implemented behavior:
- expenses belong to a business and category
- receipt attachment is required unless the expense was auto-generated from a purchase
- expense currency is forced from the current business currency
- `funding_source` is a text label selected from business-configured purchase funding sources
- `payment_method` is a string enum: `cash` or `credit`
- payment method is auto-derived from the selected funding source type

Payables integration:
- if expense category is `Payables`, the form can select one or more payables to settle
- saving the expense creates `Payment` rows against those payables
- the amount and payee are synchronized from the selected payables

Credit-expense integration:
- credit expenses auto-create a payable of type `credit_card`

Payables, Payments, Receivables, Collections
--------------------------------------------
Implemented:
- payables CRUD
- mark payable paid
- payments index
- receivables CRUD
- mark receivable collected
- collections index

Notification support:
- `DailyRemindersJob` creates notifications for due-soon and overdue payables/receivables
- notifications belong to a business and user
- notifications support unread/read status

Products And Catalog Data
-------------------------
Implemented product fields include:
- name
- sku
- unit
- inventory_type
- brand
- barcode
- description
- base_cost_cents
- reorder_level
- active

Implemented behavior:
- SKU exists and is validated
- inventory type is free-text and supports existing options
- unit is free-text
- barcode scan UI is present in the product form
- reorder level is used by dashboard low-stock logic

Locations
---------
Implemented as business-scoped storage endpoints with `location_type`.

Purchases
---------
Implemented workflow:
- purchases have supplier, purchased_on, receiving_location, funding_source, notes, status
- purchase items store quantity and unit cost
- create and update support draft and received status
- receiving a purchase creates stock-in movements
- receiving a purchase also syncs an expense
- a purchase becomes effectively locked once received

Current funding source behavior:
- purchase funding source is a business-configured text label
- funding source types are managed by `PurchaseFundingSource`
- source types are currently `cash` or `credit`

Purchase action timestamp behavior:
- `received_at` is stored when inventory is first received
- stock movement `occurred_on` for received purchases uses `received_at.to_date`
- purchase document date remains `purchased_on`

Purchases UI currently includes:
- list
- new/edit form
- show page
- receive action from show page

Deliveries
----------
Implemented workflow:
- deliveries have customer, delivered_on, delivery_number, status, from_location, notes, show_prices
- delivery items store quantity and optional unit price
- show page exposes PDF and email actions
- delivered records are no longer editable

Inventory deduction behavior:
- when a delivery is marked delivered, stock validator checks available stock
- stock-out movements are created for each item
- delivery status becomes `delivered`
- repeated mark-delivered calls do not deduct inventory twice

Delivery action timestamp behavior:
- `marked_delivered_at` is stored when inventory is first deducted
- stock movement `occurred_on` for delivered deliveries uses `marked_delivered_at.to_date`
- delivery document date remains `delivered_on`

Delivery PDF
------------
Implemented with `Prawn` in `Deliveries::ReportPdfGenerator`.

Current preview/render behavior:
- unsaved draft preview route: `/deliveries/preview_pdf`
- saved delivery preview route: `/deliveries/:id/preview_pdf`
- preview renders inline in a new tab
- saved delivery show page also supports attached PDF generation and download

Current PDF layout behavior:
- half-inch margins on all sides
- title and delivery number
- `Delivery to <customer>`
- optional address
- items table
- notes
- signature lines
- page numbers

Current items table behavior:
- if `show_prices` is false:
  - columns are `#`, `Product`, `Quantity`
- if `show_prices` is true:
  - columns are `#`, `Product`, `Quantity`, `Unit Price`, `Sub-total`
- total is rendered below the table, outside the table
- `Total` aligns with the `Unit Price` column
- total amount aligns with the `Sub-total` column
- total amount has a double underline

Delivery form UX currently implemented:
- readonly delivery number preview before save
- nested delivery items
- unit price `Enter` / forward `Tab` on the last row adds another item row
- focus moves to the new row’s product field
- product lookup excludes products already selected in other visible rows

Delivery email workflow:
- `Generate PDF` attaches/replaces `delivery.report_pdf`
- `Email PDF` validates recipients, ensures a PDF exists, creates a queued email log, and enqueues `DeliveryReportEmailJob`
- mail is sent by `DeliveryReportMailer`

Stock Movements And Inventory
-----------------------------
Implemented movement types:
- `in`
- `out`
- `transfer`
- `adjustment`

Validation rules implemented:
- `in`: requires `to_location`, disallows `from_location`
- `out`: requires `from_location`, disallows `to_location`
- `transfer`: requires both
- `adjustment`: requires at least one location

Inventory services:
- `Inventory::OnHandCalculator`
- `Inventory::StockValidator`

Current inventory views:
- stock movement index
- current counts grouped by location
- movement ledger table with date, type, product, quantity, from, to

Current stock movement ledger labels:
- plain inbound rows: `To` is the destination location
- purchases: `From = supplier`, `To = receiving location`
- deliveries: `From = from_location`, `To = customer`

Current count behavior:
- stock in adds quantity to `to_location`
- stock out deducts quantity from `from_location`
- transfer subtracts from `from_location` and adds to `to_location`
- adjustment adds to the chosen location according to stored quantity sign/value

Dashboard
---------
Implemented dashboard sections:
- upcoming payables
- overdue payables
- upcoming receivables
- overdue receivables
- low-stock products based on reorder level
- month-to-date expenses
- month-to-date cash expenses
- month-to-date collections
- month-to-date payments
- net cashflow
- today’s delivered deliveries

Business Settings
-----------------
Current business-level settings include:
- business name
- currency
- reminder lead days
- purchase funding sources
- business member management for owners

Purchase funding sources:
- are their own model: `PurchaseFundingSource`
- are auto-created with defaults after business creation
- currently infer source type from label

Notifications And Background Jobs
---------------------------------
Implemented jobs:
- `DailyRemindersJob`
- `DeliveryReportEmailJob`

Implemented background usage:
- reminder notifications for due-soon and overdue receivables/payables
- asynchronous delivery report email sending

Views And UX
------------
Current UI style is a shared Tailwind component approach, including:
- page headers
- cards
- table wrappers
- badges/status pills
- button variants
- field labels and field inputs
- empty states

Current notable UX patterns:
- public home and about pages
- admin login separate from normal login
- business-scoped navigation in application layout
- delivery nested item UX with Stimulus
- purchase nested item UX
- barcode scanner UI in product form

Known Current-State Differences From The Older Roadmap
------------------------------------------------------
- no implemented multi-theme system is documented in the current codebase snapshot
- expenses and purchases use business-configured funding-source text labels instead of the original personal/business enum approach
- expense payment methods are `cash` / `credit`, not the earlier `cash` / `bank` / `card` matrix
- stock movement entry is a single CRUD flow, not separate dedicated pages for each movement type
- delivery PDF preview exists and is more advanced than the original draft spec
- inventory ledger display includes contextual supplier/customer labels
- purchases and deliveries now track explicit inventory-action timestamps (`received_at`, `marked_delivered_at`)

Testing State
-------------
Request-test coverage is present in `test/requests/mvp_flows_test.rb` and related files.

Currently covered flows include:
- expense creation
- payable payment flow
- purchase receive flow
- delivery creation and mark-delivered flow
- delivery PDF generation
- delivery PDF preview for unsaved and saved deliveries
- delivery email queueing
- cross-tenant validation checks
- staff and system-admin access restrictions
- inventory count updates
- stock movement ledger labeling for purchases and deliveries
- action timestamp behavior for receive and mark delivered

Operational Notes
-----------------
- the default parallel test runner in this environment has a `minitest` compatibility issue
- request test runs are reliable with:
  - `PARALLEL_WORKERS=1 bin/rails test test/requests/mvp_flows_test.rb`

Migration State
---------------
Recent schema changes relevant to current workflows:
- custom purchase funding sources
- expense purchase linkage
- payables linkage to expenses
- business currency
- `deliveries.marked_delivered_at`
- `purchases.received_at`

If You Update This File
-----------------------
Treat this file as a current-state architecture guide:
- prefer describing implemented behavior over desired behavior
- call out gaps explicitly instead of mixing them into the main flow as if already complete
- update routes, domain behavior, and timestamp/inventory semantics when the code changes
