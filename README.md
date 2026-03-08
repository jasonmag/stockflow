# Stockflow

Stockflow is a Rails 8 app for small supplier operations: inventory ledger, expenses, payables, receivables, purchases, deliveries, and delivery report PDFs with email delivery.

## Stack

- Ruby 3.4.x
- Rails 8.x
- Hotwire (Turbo + Stimulus)
- Tailwind CSS
- SQLite (development/test)
- PostgreSQL (production)
- ActiveStorage (local in dev/test, S3-compatible in production)
- Solid Queue / Solid Cache / Solid Cable
- Kamal deployment

## Implemented MVP Scope

- Authentication (Rails 8 auth generator)
- Multi-business scoping via `Membership` and session-based current business switcher
- Expenses with receipt attachments + MTD insight cards
- Payables + mark paid (creates `Payment`)
- Purchases + receive workflow (creates stock-in `StockMovement`)
- Inventory ledger with validations and on-hand calculation services
- Receivables + mark collected (creates `Collection`)
- Deliveries + delivery number generation + mark delivered workflow (creates stock-out movements)
- Delivery report PDF generation using Prawn and ActiveStorage attachment
- Delivery report email queueing with `DeliveryEmailLog` + `DeliveryReportEmailJob`
- Dashboard and notifications (with daily reminder job)
- Seeds and integration tests for required MVP flows

## Local Setup

1. Install Ruby 3.4.x and Bundler.
2. Install gems:

```bash
bundle install
```

3. Prepare DB:

```bash
bin/rails db:prepare
```

4. Seed demo data:

```bash
bin/rails db:seed
```

5. Run app:

```bash
bin/dev
```

## GitHub Repository Setup

If you already created the GitHub repo, run:

```bash
git remote add origin git@github.com:jasonmag/stockflow.git
git branch -M main
git push -u origin main
```

Demo owner login:

- Email: `owner@stockflow.local`
- Password: `password123`

## Tests

Run MVP integration tests:

```bash
bin/rails test test/requests/mvp_flows_test.rb
```

## Delivery Report (PDF + Email)

From a delivery record you can:

- Generate/Regenerate PDF
- Download PDF attachment
- Queue email with comma/semicolon separated recipients

Background email jobs are processed by Solid Queue.

## Environment Variables (Production)

- `RAILS_MASTER_KEY`
- `SECRET_KEY_BASE`
- `APP_HOST`
- `SMTP_USERNAME`
- `SMTP_PASSWORD`
- `SMTP_ADDRESS`
- `SMTP_PORT`
- `S3_ACCESS_KEY_ID`
- `S3_SECRET_ACCESS_KEY`
- `S3_BUCKET`
- `S3_ENDPOINT`
- `S3_REGION`

## ActiveStorage Services

- Development/test: local disk
- Production: `s3_compatible` service in `config/storage.yml`

## Production Database

- Production deploys use SQLite files under `storage/`:
  - `storage/production.sqlite3`
  - `storage/production_cache.sqlite3`
  - `storage/production_queue.sqlite3`
  - `storage/production_cable.sqlite3`
- Ensure the Kamal storage volume is persistent and backed up.

## Kamal Deployment

1. Update `config/deploy.yml` with real servers, registry, and host.
2. Set secrets in `.kamal/secrets`.
3. Build and deploy:

```bash
bin/kamal setup
bin/kamal deploy
```

4. Run migrations on deploy target when needed:

```bash
bin/kamal app exec "bin/rails db:prepare"
```

## Kamal Dev (Local Host)

Use the isolated dev config in `config/deploy.dev.yml` via `bin/kamal-dev`.

1. Update local secrets in `.kamal/secrets.dev` (at minimum `SECRET_KEY_BASE`).
2. Make sure Docker is running and localhost SSH access works for Kamal.
3. Run setup/deploy:

```bash
bin/kamal-dev setup
bin/kamal-dev deploy
```

4. Open the app at `http://localhost:3000`.
5. Run migrations when needed:

```bash
bin/kamal-dev app exec "bin/rails db:prepare"
```

Healthcheck endpoint: `GET /up`

## Notes

- Delivered records cannot be voided/deleted (MVP safety choice).
- Financial delete actions are owner-restricted.

## Operations Documentation

- End-to-end inventory operations SOP: `docs/inventory-operations-workflow.md`
- Operator one-page checklist: `docs/operator-quick-checklist.md`
