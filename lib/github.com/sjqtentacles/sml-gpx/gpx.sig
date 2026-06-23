signature GPX =
sig
  type wpt = { lat : real, lon : real, name : string option }
  type doc = { wpts : wpt list }
  val parse : string -> doc
  val serialize : doc -> string
  val haversineKm : wpt * wpt -> real
end
