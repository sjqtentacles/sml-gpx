# sml-gpx

[![CI](https://github.com/sjqtentacles/sml-gpx/actions/workflows/ci.yml/badge.svg)](https://github.com/sjqtentacles/sml-gpx/actions/workflows/ci.yml)

Lightweight GPX **waypoint** reading/writing and great-circle distance for
Standard ML. Extracts `<wpt lat=… lon=…>` entries from a GPX document and
computes distances with the haversine formula.

## API

```sml
type wpt = { lat : real, lon : real, name : string option }
type doc = { wpts : wpt list }

Gpx.parse gpxString          (* -> { wpts = [...] } *)
Gpx.serialize doc            (* -> "<wpt lat=...>...</wpt>\n..." *)
Gpx.haversineKm (a, b)       (* great-circle distance in km *)
```

```sml
val d = Gpx.parse "<wpt lat=\"51.5\" lon=\"-0.1\"></wpt>"
Gpx.haversineKm (hd (#wpts d), hd (#wpts d))   (* 0.0 *)
```

## Scope and limitations

- **Waypoints only**, and parsed line-by-line by attribute extraction — this is
  a pragmatic reader, **not** a general XML parser. It expects each `<wpt>` on
  its own line and reads the `lat`/`lon` attributes; tracks (`<trk>`), routes
  (`<rte>`), elevation, time, and nested metadata are ignored.
- `name` is always `NONE` on parse (the element body is not read).
- `serialize` emits a flat list of `<wpt>` elements, not a full GPX document
  with the XML/`<gpx>` envelope.
- Distance uses a spherical earth (radius 6371 km); no ellipsoidal correction.

## Installing with smlpkg

```sh
smlpkg add github.com/sjqtentacles/sml-gpx
smlpkg sync
```

Reference from your `.mlb`:

```
lib/github.com/sjqtentacles/sml-gpx/gpx.mlb
```

## Building and testing

```sh
make test        # MLton
make test-poly   # Poly/ML
make all-tests   # both
make clean
```

## Project layout

```
sml.pkg
Makefile
lib/github.com/sjqtentacles/sml-gpx/
  gpx.sig
  gpx.sml      waypoint parse/serialize + haversine
  gpx.mlb
test/
  test.sml     parse, round-trip, haversine distances
```

## License

MIT. See [LICENSE](LICENSE).
