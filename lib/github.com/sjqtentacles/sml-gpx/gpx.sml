structure Gpx :> GPX =
struct
  type wpt = { lat : real, lon : real, name : string option }
  type doc = { wpts : wpt list }
  type pt = { lat : real, lon : real, ele : real option, time : string option }
  type seg = { points : pt list }
  type track = { name : string option, segments : seg list }
  type bbox = { minLat : real, minLon : real, maxLat : real, maxLon : real }

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
  fun haversineRaw (lat1,lon1,lat2,lon2) =
    let val dLat = (lat2 - lat1) * Math.pi / 180.0
        val dLon = (lon2 - lon1) * Math.pi / 180.0
        val rlat1 = lat1 * Math.pi / 180.0
        val rlat2 = lat2 * Math.pi / 180.0
        val h = Math.sin (dLat/2.0) * Math.sin (dLat/2.0)
              + (Math.cos rlat1) * (Math.cos rlat2) * Math.sin (dLon/2.0) * Math.sin (dLon/2.0)
    in 2.0 * earthR * Math.atan2 (Math.sqrt h, Math.sqrt (1.0-h)) end
  fun haversineKm (a : wpt, b : wpt) =
    haversineRaw (#lat a, #lon a, #lat b, #lon b)

  (* --- XML escaping --- *)
  fun xmlEscape s =
    let
      fun esc c =
        case c of
            #"&" => "&amp;"
          | #"<" => "&lt;"
          | #">" => "&gt;"
          | #"\"" => "&quot;"
          | #"'" => "&apos;"
          | _ => String.str c
    in String.concat (List.map esc (String.explode s)) end

  (* --- track metrics --- *)
  fun allPoints ({segments, ...} : track) =
    List.concat (List.map #points segments)

  (* pairwise fold over a list, applying f to each adjacent pair *)
  fun foldPairs f init [] = init
    | foldPairs f init [_] = init
    | foldPairs f init (a :: (rest as b :: _)) =
        foldPairs f (f (a, b, init)) rest

  fun trackLengthKm (t : track) =
    let
      fun segLen ({points} : seg) =
        foldPairs (fn (a : pt, b : pt, acc) =>
                     acc + haversineRaw (#lat a, #lon a, #lat b, #lon b))
                  0.0 points
    in List.foldl (fn (s, acc) => acc + segLen s) 0.0 (#segments t) end

  fun bbox (t : track) =
    case allPoints t of
        [] => NONE
      | (p0 :: rest) =>
          let
            val init = { minLat = #lat p0, minLon = #lon p0
                       , maxLat = #lat p0, maxLon = #lon p0 }
            fun upd ({minLat,minLon,maxLat,maxLon}, p : pt) =
              { minLat = Real.min (minLat, #lat p)
              , minLon = Real.min (minLon, #lon p)
              , maxLat = Real.max (maxLat, #lat p)
              , maxLon = Real.max (maxLon, #lon p) }
          in SOME (List.foldl (fn (p, acc) => upd (acc, p)) init rest) end

  fun totalAscent (t : track) =
    let
      fun segAscent ({points} : seg) =
        foldPairs (fn (a : pt, b : pt, acc) =>
                     case (#ele a, #ele b) of
                         (SOME ea, SOME eb) =>
                           if eb > ea then acc + (eb - ea) else acc
                       | _ => acc)
                  0.0 points
    in List.foldl (fn (s, acc) => acc + segAscent s) 0.0 (#segments t) end

  fun serializeTrack (t : track) =
    let
      fun attr (k, v) = " " ^ k ^ "=" ^ String.str q ^ v ^ String.str q
      fun optEl (tag, NONE) = ""
        | optEl (tag, SOME v) = "<" ^ tag ^ ">" ^ xmlEscape v ^ "</" ^ tag ^ ">"
      fun optReal (tag, NONE) = ""
        | optReal (tag, SOME (v : real)) = "<" ^ tag ^ ">" ^ Real.toString v ^ "</" ^ tag ^ ">"
      fun ptEl (p : pt) =
        "<trkpt" ^ attr ("lat", Real.toString (#lat p))
        ^ attr ("lon", Real.toString (#lon p)) ^ ">"
        ^ optReal ("ele", #ele p) ^ optEl ("time", #time p)
        ^ "</trkpt>"
      fun segEl ({points} : seg) =
        "<trkseg>" ^ String.concat (List.map ptEl points) ^ "</trkseg>"
      val nameEl = case #name t of NONE => ""
                   | SOME nm => "<name>" ^ xmlEscape nm ^ "</name>"
    in
      "<trk>" ^ nameEl ^ String.concat (List.map segEl (#segments t)) ^ "</trk>"
    end
end

