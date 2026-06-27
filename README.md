# sml-gpx

[![CI](https://github.com/sjqtentacles/sml-gpx/actions/workflows/ci.yml/badge.svg)](https://github.com/sjqtentacles/sml-gpx/actions/workflows/ci.yml)

Lightweight GPX reading/writing and great-circle geometry for Standard ML.
Extracts `<wpt lat=… lon=…>` entries from a GPX document, computes haversine
distances, and offers a richer **track** model (segments of points with optional
elevation/time) with length, bounding-box, ascent, and XML-escaping helpers.

## API

```sml
type wpt = { lat : real, lon : real, name : string option }
type doc = { wpts : wpt list }
type pt  = { lat : real, lon : real, ele : real option, time : string option }
type seg = { points : pt list }
type track = { name : string option, segments : seg list }
type bbox  = { minLat : real, minLon : real, maxLat : real, maxLon : real }

(* waypoints *)
Gpx.parse gpxString          (* -> { wpts = [...] } *)
Gpx.serialize doc            (* -> "<wpt lat=...>...</wpt>\n..." *)
Gpx.haversineKm (a, b)       (* great-circle distance in km *)

(* tracks *)
Gpx.xmlEscape s              (* escape & < > " ' *)
Gpx.trackLengthKm track      (* summed segment length in km *)
Gpx.bbox track               (* SOME {minLat,...} or NONE if no points *)
Gpx.totalAscent track        (* total positive elevation gain in metres *)
Gpx.serializeTrack track     (* -> "<trk>...<trkseg><trkpt .../></trkseg></trk>" *)
```

```sml
val trk = { name = SOME "Hike", segments =
              [ { points = [ {lat=0.0,lon=0.0,ele=SOME 10.0,time=NONE}
                           , {lat=0.0,lon=1.0,ele=SOME 30.0,time=NONE} ] } ] }
Gpx.trackLengthKm trk        (* ~111.0 *)
Gpx.totalAscent trk          (* 20.0 *)
```

## Scope and limitations

- **Parsing is line-oriented** for waypoints — a pragmatic reader, **not** a
  general XML parser. It expects each `<wpt>` on its own line and reads the
  `lat`/`lon` attributes; the track types are construct/serialize-only (there is
  no `<trk>` *parser* yet, only `serializeTrack`).
- `name` is always `NONE` on `parse` (the waypoint element body is not read).
- `serialize` emits a flat list of `<wpt>` elements, not a full GPX document
  with the `<gpx>` envelope; `serializeTrack` emits a single `<trk>` element.
- Distance uses a spherical earth (radius 6371 km); no ellipsoidal correction.
- `totalAscent` only counts segments between points that both carry elevation.

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
  gpx.sml      waypoint parse/serialize, haversine, track metrics + XML escape
  gpx.mlb
test/
  test.sml     parse, round-trip, haversine, xmlEscape, track length/bbox/ascent
```

## License

MIT. See [LICENSE](LICENSE).
