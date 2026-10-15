# Ubiquiti Mobile Test Assignment (transcript of assignment.pdf)

## Context

You are an iOS developer at Ubiquiti. Build a small mobile app that gives an overview of Ubiquiti products. A Figma design file (provided by email) is the UI reference.

## Requirements

- Swift
- SwiftUI
- Combine
- Loading / empty / error states polished
- Caching (in-memory or disk)

## App features

1. **Product list screen**
   - Shows a list of products.
   - Each item displays at minimum: product icon/image, model name.
2. **Filtering tabs**
   - Tabs at the top filter by category: **All, Cameras, IoT**.
   - Filtering updates the list immediately.
3. **Product details screen**
   - Tapping a list item opens a details view.
   - Shows at minimum: product name, product image, any additional attributes you choose (bonus for a sensible selection).

## Data source

Public UIDB JSON: `https://static.ui.com/fingerprint/ui/public.json`

Shape: `{ "version": string, "devices": [Device] }`, 698 devices as of 2026-10-15.

Key fields:

- `id` — primary key
- `line` — `{ id, name }`, used for filtering. The PDF says "mapping described below" but gives no mapping; see `DECISIONS.md` for the one we chose.
- `product.name` — human-readable product name
- `product.abbrev` — short name
- `shortnames` — lookup keys (optional)
- `images.default` — image identifier for image URLs
- `sku`, `deviceType`, `deviceTypes`, `icon`, `shortnames`, `sysids`, `triplets`, `videos` are present on every device
- Optional: `compliance`, `unifi`, `uisp`, `btle`, `power`, `minAdoptVersion`, `isARSupported`

Line ids observed, by count: unifi-network 232, airmax 125, unifi-protect 125, edgemax 39, unifi-access 32, airfiber 23, unifi-connect 20, amplifi 18, unifi-talk 13, mfi 12, ufiber 10, uisp 9, ltu 8, unifi-drive 8, unifi-led 5, apollo 4, wave 4, unifi-lte 3, unifi-mobility 3, sunmax 2, unknown 2, wifiman 1.

## Product image URLs

```
https://images.svc.ui.com/?u=https%3A%2F%2Fstatic.ui.com%2Ffingerprint%2Fui%2Fimages%2F${id}%2Fdefault%2F${images.default}.png&w=${size}&q=75
```

`size` is something like 128 / 256 / 640 depending on UI needs. Any reasonable image-loading approach is fine.

## Deliverables

A git repository containing:

- Full source code
- A short `README.md` with: how to run the app, assumptions/tradeoffs made, libraries used and why
