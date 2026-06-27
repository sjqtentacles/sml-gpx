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

  val () = section "xmlEscape"
  val () = checkString "escapes all five" ("&amp;&lt;&gt;&quot;&apos;", G.xmlEscape "&<>\"'")
  val () = checkString "passes plain text" ("hello world", G.xmlEscape "hello world")

  (* a track: one segment along the equator 0->1->2 degrees longitude, with
     elevations 10 -> 30 -> 20 (ascent of +20 then descent of -10) *)
  val () = section "track metrics"
  val trk : G.track =
    { name = SOME "Trail & <Test>"
    , segments =
        [ { points =
              [ {lat=0.0, lon=0.0, ele=SOME 10.0, time=SOME "2020-01-01T00:00:00Z"}
              , {lat=0.0, lon=1.0, ele=SOME 30.0, time=NONE}
              , {lat=0.0, lon=2.0, ele=SOME 20.0, time=NONE} ] } ] }
  (* length ~= 2 * 111 km *)
  val () = checkRealTol 5.0 "trackLengthKm ~222" (222.0, G.trackLengthKm trk)
  val () = checkRealTol 1E~9 "totalAscent = 20" (20.0, G.totalAscent trk)

  val () = section "bbox"
  val () = (case G.bbox {name=NONE, segments=[]} of
                NONE => checkBool "empty track -> NONE bbox" (true, true)
              | SOME _ => checkBool "empty track -> NONE bbox" (true, false))
  val () = (case G.bbox trk of
                NONE => checkBool "bbox present" (true, false)
              | SOME bb =>
                  let in
                    checkRealTol 1E~9 "minLat" (0.0, #minLat bb);
                    checkRealTol 1E~9 "minLon" (0.0, #minLon bb);
                    checkRealTol 1E~9 "maxLon" (2.0, #maxLon bb)
                  end)

  val () = section "serializeTrack escapes + emits ele/time"
  val xml = G.serializeTrack trk
  val () = checkBool "has <trk>" (true, String.isSubstring "<trk>" xml)
  val () = checkBool "name escaped" (true, String.isSubstring "Trail &amp; &lt;Test&gt;" xml)
  val () = checkBool "has trkpt" (true, String.isSubstring "<trkpt" xml)
  val () = checkBool "has ele" (true, String.isSubstring "<ele>" xml)
  val () = checkBool "has time" (true, String.isSubstring "<time>2020-01-01T00:00:00Z</time>" xml)
in Harness.run () end end
