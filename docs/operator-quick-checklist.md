# Operator Quick Checklist

Use this as the day-to-day run sheet for inventory operations.

## Pre-Shift Setup

1. Confirm correct business is selected.
2. Confirm master records exist and are up to date:
   - Products
   - Suppliers
   - Customers (supermarkets)
   - Locations (`Main Storage`, `Dispatch Area`)
3. Check `Stock Movements` for unresolved or unclear entries from prior day.

## A. Purchase and Receive

1. Create purchase (`Purchases` -> `New Purchase`).
2. Enter supplier, date, receiving location, funding source.
3. Add all line items with quantity and unit cost.
4. Save as draft.
5. When goods physically arrive and are checked, open purchase and click `Receive`.

Done criteria:

- Purchase status is `received`.
- Stock-in entries exist in `Stock Movements`.

## B. Pick/Collect for Delivery

1. Decide pick method:
   - Direct from `Main Storage`, or
   - Stage via `Dispatch Area` (recommended).
2. If staging, create `Stock Movement` with type `transfer`:
   - `from_location = Main Storage`
   - `to_location = Dispatch Area`
3. Put delivery reference in notes.

Done criteria:

- Required quantities are available in chosen delivery source location.

## C. Create and Complete Delivery

1. Create delivery (`Deliveries` -> `New Delivery`).
2. Set supermarket customer, date, and `From Location`.
3. Add delivery line items and quantities.
4. Save as draft.
5. Optional: generate/email PDF.
6. After physical dispatch is confirmed, click `Mark Delivered`.

Done criteria:

- Delivery status is `delivered`.
- Stock-out movements are created.

## D. Returned Items (Partial/Full Undelivered)

1. Create `Stock Movement` with type `adjustment`.
2. Enter positive quantity for returned stock.
3. Set `to_location` to receiving location (usually `Main Storage`).
4. Add notes with:
   - Delivery number
   - Reason
   - Quantity accepted back

Done criteria:

- Returned quantity is added back to inventory.

## E. Spoilage

1. Create `Stock Movement` with type `adjustment`.
2. Enter negative quantity for spoiled units.
3. Set `from_location` where spoilage occurred.
4. Add notes with reason and batch/date if known.

Done criteria:

- Spoiled quantity is removed from inventory with traceable reason.

## F. Own Consumption

1. Create `Stock Movement` with type `adjustment`.
2. Enter negative quantity for internal usage.
3. Set `from_location`.
4. Add notes with usage reason (for example `OWN_USE: office pantry`).

Done criteria:

- Internal usage is deducted and traceable in ledger.

## End-of-Day Reconciliation

1. All physically received purchases are marked `received`.
2. All completed dispatches are marked `delivered`.
3. All returns are posted as positive adjustments.
4. All spoilage and own-use are posted as negative adjustments.
5. Notes are complete for every manual adjustment.
6. Spot-check top SKUs in `Stock Movements` for abnormal variance.

## Notes Standard (Use Prefixes)

- `PURCHASE:`
- `DELIVERY:`
- `RETURN:`
- `SPOILAGE:`
- `OWN_USE:`
