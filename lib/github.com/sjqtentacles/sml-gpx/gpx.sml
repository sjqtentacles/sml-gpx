structure Gpx :> GPX =
struct
  type wpt = { lat : real, lon : real, name : string option }
  type doc = { wpts : wpt list }
  val q = Char.chr 34
  fun splitLines s = String.tokens (fn c => c = #"\n") s
  fun getAttr line key =
    let val needle = key ^ "=" ^ String.str q
        fun search i =
          if i >= String.size line then NONE
          else if String.isPrefix needle (String.extract (line, i, NONE)) then
            let val start = i + String.size needle
                fun endQ j = if j >= String.size line then j
                             else if String.sub (line, j) = q then j else endQ (j+1)
                val stop = endQ start
            in SOME (String.substring (line, start, stop - start))
            end
            else search (i+1)
    in search 0 end
  fun parseReal line key =
    case getAttr line key of SOME s => (case Real.fromString s of SOME x => x | NONE => 0.0) | NONE => 0.0
  fun parseWpt line = { lat = parseReal line "lat", lon = parseReal line "lon", name = NONE }
  fun parse s = { wpts = List.map parseWpt (List.filter (String.isPrefix "<wpt") (splitLines s)) }
  fun wptLine (w as {lat, lon, name=_}) =
    "<wpt lat=" ^ String.str q ^ Real.toString lat ^ String.str q
    ^ " lon=" ^ String.str q ^ Real.toString lon ^ String.str q ^ "></wpt>"
  fun serialize (d as {wpts}) = String.concatWith "\n" (List.map wptLine wpts)
  val earthR = 6371.0
  fun haversineKm (a,b) =
    let val {lat=lat1,lon=lon1,name=_} = a val {lat=lat2,lon=lon2,name=_} = b
        val dLat = (lat2 - lat1) * Math.pi / 180.0
        val dLon = (lon2 - lon1) * Math.pi / 180.0
        val rlat1 = lat1 * Math.pi / 180.0
        val rlat2 = lat2 * Math.pi / 180.0
        val h = Math.sin (dLat/2.0) * Math.sin (dLat/2.0)
              + (Math.cos rlat1) * (Math.cos rlat2) * Math.sin (dLon/2.0) * Math.sin (dLon/2.0)
    in 2.0 * earthR * Math.atan2 (Math.sqrt h, Math.sqrt (1.0-h)) end
end
