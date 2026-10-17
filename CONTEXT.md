# Ubiquiti Product Catalogue

A small iOS app that lists Ubiquiti hardware products from the public UIDB feed, filters them by category and shows one product's details.

## Language

**Product**:
One Ubiquiti hardware item as the UIDB feed describes it, identified by its UUID. The feed's JSON calls these "devices"; the app does not.
_Avoid_: Device, item, entry

**Feed**:
The whole UIDB document: a version fingerprint plus the list of products.
_Avoid_: Catalogue, database, UIDB (as a type name)

**Line**:
The product family a product belongs to, such as UniFi Protect or airMAX. Has an id and a display name. Categories are defined in terms of lines.
_Avoid_: Family, series, category

**Category**:
One of the three filter tabs: All, Cameras, IoT. A category is a rule over lines, not a field in the feed.
_Avoid_: Tab, filter, line

**Device type**:
A product's functional kind as the feed reports it (camera, switch, sensor, console…). A property of a product, never the noun for a product.
_Avoid_: Kind, type

**Placeholder product**:
One of the two feed entries under the `unknown` line ("Unknown Device", "Unknown Console"). They decode like any product; hiding them is a display rule, not a decoding rule.

**Validators**:
What the server handed back with the last feed download so the app can ask whether the feed changed: the `ETag` and `Last-Modified` values, kept verbatim. Sent back on the next request; an "unchanged" answer means the stored feed is still current. Not the fingerprint: the fingerprint is inside the feed, validators are about the download.
_Avoid_: Fingerprint, cache tag, revision

**Unchanged**:
The server's answer to a request carrying validators when the feed has not changed since. Nothing is downloaded; the stored feed stands.
_Avoid_: 304, not modified, cache hit

**Cached feed**:
The last downloaded feed bytes kept on disk together with their validators. What the app shows before the server has answered, and what it falls back to when the server cannot be reached.
_Avoid_: Store, cache (as a noun for the data)

**Refresh outcome**:
What the server said when asked for the feed: unchanged, or an updated feed that is now the cached feed. A refresh that fails has no outcome; the app keeps what it shows and calls it stale.
_Avoid_: Snapshot, result, response

**Stale**:
A feed kept on screen because the refresh behind it failed. The view model's state, not the repository's: the repository reports the failure and holds nothing. Stale is about the refresh failing, not about age: a day-old cached feed the server has confirmed is current, not stale.
_Avoid_: Outdated, offline, expired

**Update**:
A feed a refresh has just saved, handed to every screen subscribed to the repository, whoever triggered the refresh. Never the cached feed and never a failure: the first comes from `cachedFeed()`, the second goes to whoever called `refresh()`.
_Avoid_: Event, change, notification, publish (outside the in-memory fake's test hook)
