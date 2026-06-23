structure Tests = struct open Harness structure G = Gpx
fun run () = let
  val s = "<wpt lat=\"0\" lon=\"0\"></wpt>\n<wpt lat=\"0\" lon=\"1\"></wpt>"
  val d = G.parse s
  val () = section "GPX round-trip"
  val () = checkInt "2 wpts" (2, List.length (#wpts d))
  val s2 = G.serialize d
  val d2 = G.parse s2
  val () = checkInt "round-trip count" (2, List.length (#wpts d2))
  val dist = G.haversineKm ({lat=0.0,lon=0.0,name=NONE}, {lat=0.0,lon=1.0,name=NONE})
  val () = checkRealTol 10.0 "haversine ~111km" (111.0, dist)
in Harness.run () end end
