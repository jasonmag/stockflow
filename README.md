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
- `DATABASE_URL`
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

Healthcheck endpoint: `GET /up`

## Notes

- Delivered records cannot be voided/deleted (MVP safety choice).
- Financial delete actions are owner-restricted.
