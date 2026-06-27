signature GPX =
sig
  (* A waypoint (lat/lon plus an optional name) — the original flat model. *)
  type wpt = { lat : real, lon : real, name : string option }
  type doc = { wpts : wpt list }

  (* A track point: position plus optional elevation (metres) and ISO-8601 time. *)
  type pt = { lat : real, lon : real, ele : real option, time : string option }

  (* A track segment is an ordered list of points; a track is a named list of
     segments. *)
  type seg = { points : pt list }
  type track = { name : string option, segments : seg list }

  (* A bounding box over a set of coordinates. *)
  type bbox = { minLat : real, minLon : real, maxLat : real, maxLon : real }

  (* --- waypoint API (unchanged) --- *)
  val parse : string -> doc
  val serialize : doc -> string
  val haversineKm : wpt * wpt -> real

  (* --- track API --- *)

  (* XML-escape a string for safe inclusion in an attribute or element body
     (& < > " '). *)
  val xmlEscape : string -> string

  (* Total great-circle length of a track in km (sum over consecutive points of
     every segment; segments are not joined to each other). *)
  val trackLengthKm : track -> real

  (* Bounding box of all points in a track, or NONE if the track has no points. *)
  val bbox : track -> bbox option

  (* Total positive elevation gain over a track in metres (sum of upward
     elevation changes between consecutive points that both carry elevation). *)
  val totalAscent : track -> real

  (* Serialize a track to a `<trk>` element (with `<trkseg>`/`<trkpt>` children),
     XML-escaping the name and emitting optional `<ele>`/`<time>` children. *)
  val serializeTrack : track -> string
end
