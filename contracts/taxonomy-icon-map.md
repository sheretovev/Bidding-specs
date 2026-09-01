# Taxonomy Icon Map

The shared vocabulary of `taxonomy.icon` name strings, and each platform's mapping to its
own icon set. **This starter list was assembled from the categories mentioned while writing
this spec and common auction verticals — it has not been reconciled against whatever
operators actually type into the taxonomy admin tool.** Treat the names here as a proposal to
validate against real taxonomy data, not a closed, authoritative enum; both platforms' code
must fall back to the default glyph for any name not listed here; that fallback is what
makes an unreconciled or newly-added name safe rather than broken (SPEC-CAT-002).

Name matching is case-insensitive; both platforms should normalize (`lowercased()`/
`toLowerCase()`) before lookup.

| Icon name | Web (`react-icons/fa`) | iOS (SF Symbol) |
|---|---|---|
| `vehicle` | `FaCar` | `car.fill` |
| `truck` | `FaTruck` | `truck.box.fill` |
| `tractor` | `FaTractor` | `car.side.fill` *(no direct tractor symbol; see note)* |
| `helicopter` | `FaHelicopter` | `airplane` *(no dedicated helicopter symbol; see note)* |
| `aircraft` | `FaPlane` | `airplane` |
| `boat` | `FaShip` | `sailboat.fill` |
| `heavy-equipment` | `FaTruckMonster` | `wrench.and.screwdriver.fill` |
| `real-estate` | `FaBuilding` | `building.2.fill` |
| `land` | `FaMapMarkedAlt` | `map.fill` |
| `machinery` | `FaCogs` | `gearshape.2.fill` |
| `electronics` | `FaMicrochip` | `cpu.fill` |
| `furniture` | `FaCouch` | `sofa.fill` |
| `jewelry` | `FaGem` | `sparkles` |
| `art` | `FaPalette` | `paintpalette.fill` |
| `agriculture` | `FaTractor` | `leaf.fill` |
| **default / fallback** | `FaThLarge` | `square.grid.2x2.fill` |

**Note on `tractor`/`helicopter` on iOS:** SF Symbols has no dedicated glyph for either as of
this writing; the substitutes above are placeholders picked for silhouette association, not
a perfect match. Flag this explicitly to whoever owns the iOS icon set rather than silently
shipping a mismatch — a custom symbol image (bundled asset) may be worth adding for these
two specifically, given they were the user's own example categories.

## Maintenance

- When a new `icon` name shows up in taxonomy data that isn't in this table, both platforms
  already render the default glyph for it (SPEC-CAT-002) — there is no urgency to update
  code before adding the row here.
- Add rows here first, in the same PR/commit for both platforms' lookup tables, so the two
  never drift — this file is the shared source, not a description of two independently
  maintained tables.
