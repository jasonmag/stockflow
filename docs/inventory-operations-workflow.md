# Inventory Operations Workflow

This document defines the full operating flow in Stockflow for:

1. Purchasing items
2. Receiving items into storage
3. Picking inventory for supermarket delivery
4. Completing delivery
5. Recording returned items (partial or full undelivered)
6. Recording spoilage
7. Recording own-consumption usage

## Scope

This SOP is for day-to-day inventory operations using these Stockflow modules:

- `Purchases`
- `Deliveries`
- `Stock Movements`
- `Locations`, `Products`, `Suppliers`, `Customers`

## Required Setup

Before processing transactions, make sure these records already exist:

- Supplier records (`Suppliers`)
- Product catalog (`Products`)
- Storage and dispatch locations (`Locations`)
- Supermarket customer records (`Customers`)

Recommended location setup:

- `Main Storage` (location type: `storage` or `warehouse`)
- `Dispatch Area` (location type: `storage` or `other`)

## Inventory Ledger Rules

Stockflow on-hand is calculated from `StockMovement` records:

- `in`: adds stock to `to_location`
- `out`: removes stock from `from_location`
- `transfer`: removes from `from_location`, adds to `to_location`
- `adjustment`: applies `quantity` to one location (`to_location` or `from_location`)

Practical adjustment usage:

- Positive adjustment (`+`) to add stock back
- Negative adjustment (`-`) to reduce stock for loss/usage corrections

## End-to-End Process

### 1. Purchase Items

1. Open `Purchases` -> `New Purchase`.
2. Set:
   - `Supplier`
   - `Purchased On`
   - `Receiving Location` (usually `Main Storage`)
   - `Funding Source`
3. Add purchase line items:
   - `Product`
   - `Quantity`
   - `Unit Cost`
4. Save the purchase in `draft`.

Control checks:

- Confirm SKU, quantity, and cost against supplier invoice before saving.
- Keep external invoice reference in purchase `Notes`.

### 2. Receive to Storage

1. Open the purchase record.
2. Verify all inbound quantities.
3. Click `Receive` once goods are physically accepted.

System result:

- Creates stock-in `StockMovement` entries for each purchase item.
- Movement type: `in`
- Destination: `Receiving Location`
- Purchase status becomes `received`.

Control checks:

- Perform receiving only once per purchase to avoid duplicate stock-in.
- If received quantity differs from PO, correct purchase lines before pressing `Receive`.

### 3. Collect Inventory for Supermarket Delivery

Use one of these methods:

1. Direct dispatch from storage:
   - Create delivery with `From Location = Main Storage`.
2. Stage to dispatch area first (recommended for physical picking control):
   - Create `Stock Movement` with `transfer` from `Main Storage` to `Dispatch Area`.
   - Then create delivery with `From Location = Dispatch Area`.

When staging transfers:

1. Open `Stock Movements` -> `New Stock Movement`.
2. Set `movement_type = transfer`.
3. Fill `product`, `quantity`, `from_location`, `to_location`, `occurred_on`.
4. Add notes like `Pick for DR draft to <supermarket name>`.
5. Save.

### 4. Deliver to Supermarket

1. Open `Deliveries` -> `New Delivery`.
2. Set:
   - `Customer` (target supermarket)
   - `Delivered On`
   - `From Location` (storage or dispatch area)
   - Optional `Notes`
3. Add delivery items (`product`, `quantity`, optional `unit_price`).
4. Save delivery in `draft`.
5. Optional: `Generate PDF` and `Email PDF`.
6. After truck handoff is confirmed, click `Mark Delivered`.

System result:

- Validates available stock in `From Location`.
- Creates stock-out `StockMovement` entries for each delivery item.
- Delivery status becomes `delivered`.

Control checks:

- Do not mark delivered until physical dispatch/receipt event is confirmed.
- If stock is insufficient, fix source location or quantities before retrying.

### 5. Record Returns (Partial or Full Undelivered)

When a supermarket returns some/all items after a delivery has been marked delivered:

1. Open `Stock Movements` -> `New Stock Movement`.
2. Set `movement_type = adjustment`.
3. Set positive `quantity` for returned units.
4. Set `to_location` to the receiving storage location (for example `Main Storage`).
5. Set `occurred_on` to the actual return date.
6. In `notes`, include:
   - Delivery number (for traceability)
   - Return reason
   - Quantity accepted back
   Example: `Return from DR-2026-000123, not accepted by supermarket`
7. Save.

Recommended operational step:

- Update delivery `Notes` with return summary to keep the commercial and inventory record connected.

### 6. Record Spoilage

For damaged/expired stock that must be removed:

1. Open `Stock Movements` -> `New Stock Movement`.
2. Set `movement_type = adjustment`.
3. Set negative `quantity` (example: `-3.00`).
4. Set `from_location` to the location where spoilage occurred.
5. Set `occurred_on`.
6. Add notes with reason, batch/date, and approver if applicable.
   Example: `Spoilage - broken seal, batch B2402`.
7. Save.

### 7. Record Own Consumption

For owner/staff internal usage (not customer delivery):

1. Open `Stock Movements` -> `New Stock Movement`.
2. Set `movement_type = adjustment`.
3. Set negative `quantity` (example: `-1.00`).
4. Set `from_location` where stock was taken.
5. Set `occurred_on`.
6. Add notes like:
   `Own consumption - office pantry`.
7. Save.

## Daily Reconciliation Checklist

1. Purchases:
   - All physically received purchases are marked `received`.
2. Deliveries:
   - All completed deliveries are marked `delivered`.
3. Returns:
   - Every undelivered returned item has a positive adjustment.
4. Spoilage and own consumption:
   - Every loss/usage event has a negative adjustment with notes.
5. Ledger audit:
   - Review `Stock Movements` for missing location, unclear notes, or unusual quantities.

## Note Templates

Use consistent note prefixes for easy filtering:

- `PURCHASE:` supplier invoice or PO reference
- `DELIVERY:` dispatch remarks or receiving remarks
- `RETURN:` delivery number + reason
- `SPOILAGE:` root cause + batch
- `OWN_USE:` department/person + purpose

## Example Transaction Chain

1. Purchase 20 units of Product A -> receive to `Main Storage` (`+20`).
2. Transfer 12 units to `Dispatch Area` (`-12 Main Storage`, `+12 Dispatch Area`).
3. Deliver 12 units to supermarket from `Dispatch Area` (`-12 Dispatch Area`).
4. Supermarket returns 2 undelivered units -> adjustment `+2` to `Main Storage`.
5. 1 unit spoiled in storage -> adjustment `-1` from `Main Storage`.
6. 1 unit used internally -> adjustment `-1` from `Main Storage`.

Net position from this chain can be traced entirely in `Stock Movements`.
