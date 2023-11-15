require "./scripts/bf3.rb"
require 'colorize'


range = 4

puts

search_query = ARGV[0]
results = []
BF3::EVENT_MESSAGES.each do |evid, msgs|
  msgs.each do |msg|
    if msg["name"].downcase.include?(search_query.downcase)
      results << ({
        evid: evid,
        msg: msg,
        start_index: msg["name"].downcase.index(search_query.downcase),
        end_index: msg["name"].downcase.index(search_query.downcase) + search_query.length - 1,
      })
    end
  end
end

results_by_evid = results.group_by { |res| res[:evid] }

results_by_evid.each do |evid, results|
  ev = BF3::EVENT_LIST.find { |ev| ev["mstxt"] == evid || ev["name"] == evid }

  puts "Event: #{evid}".colorize(:red)

  unless ev.nil?
    if evid.start_with?("ev4")
      evmap = "ma40a"

      kizuna_event = BF3::GMK_KIZUNA_EVENTS[evmap][1].find { |kev| kev["EventName"] == evid || kev["ChangeEvent"] == evid }
      gmk = BF3::GMK_LOCATIONS[1].find { |gmk| gmk["GimmickID"] == kizuna_event["ID"] } unless kizuna_event.nil?
      puts "Affinity Scene #{gmk["SequentialID"]}".colorize(:red) unless gmk.nil?
      puts

      BF3::print_location_header gmk, evmap
    else
      BF3::print_scene_event_theater_header ev
      puts
      
      evmap = ev["playMap"].split("_").last.downcase unless ev["playMap"].empty?
      evloc = ev.then { |ev| { "X" => ev["playMapX"], "Y" => ev["playMapY"], "Z" => ev["playMapZ"] } }

      if evloc["X"] == 0.0 && evloc["Y"] == 0.0 && evloc["Z"] == 0.0
        mev = BF3::MAP_EVENTS[evmap][1].find { |mev| mev["EventID"] == evid } unless evmap.nil? || BF3::MAP_EVENTS[evmap].nil?
        gmk2 = BF3::GMK_LOCATIONS[1].find { |gmk| gmk["GimmickID"] == mev["ID"] } unless mev.nil?
        evloc = gmk2 unless gmk2.nil?
      end

      if evloc["X"] == 0.0 && evloc["Y"] == 0.0 && evloc["Z"] == 0.0
        # as a last resort, we'll try to recursively go backwards through LinkID until we find a non zero pos
        root_ev = ev
        loop do
          next_ev = BF3::EVENT_LIST.find { |ev| ev["linkID"] == root_ev["$id"] }
          break if next_ev.nil?

          next_evmap = next_ev["playMap"].split("_").last.downcase unless next_ev["playMap"].empty?
          break if next_evmap != evmap

          if next_ev["playMapX"] == 0.0 && next_ev["playMapY"] == 0.0 && next_ev["playMapZ"] == 0.0
            mev = BF3::MAP_EVENTS[evmap][1].find { |mev| mev["EventID"] == next_ev["mstxt"] || mev["EventID"] == next_ev["name"] } unless evmap.nil? || BF3::MAP_EVENTS[evmap].nil?
            gmk2 = BF3::GMK_LOCATIONS[1].find { |gmk| gmk["GimmickID"] == mev["ID"] } unless mev.nil?
            evloc = gmk2 unless gmk2.nil?
            break
          else
            evloc = next_ev.then { |ev| { "X" => ev["playMapX"], "Y" => ev["playMapY"], "Z" => ev["playMapZ"] } }
            break
          end
          root_ev = next_ev
        end
      end

      BF3::print_location_header evloc, evmap unless evmap.nil?
    end
  end

  has_printed = false
  broke = false

  matches = results.map { |res| res[:msg]["$id"] }.uniq.sort

  ev_msgs = BF3::EVENT_MESSAGES[evid]

  start_id = [matches[0] - range, 0].max
  end_id = [matches[-1] + range, ev_msgs[-1]["$id"]].min

  truncate_start = start_id > 0
  truncate_end = end_id < ev_msgs[-1]["$id"]

  puts

  if truncate_start
      puts "...\n".colorize(:black) if truncate_start
  else
      puts "******\n".colorize(:black)
  end
 
  no_talkers = ev_msgs.select { |ev_msg| !ev_msg.has_key?("talker") || ev_msg["talker"].empty? }.size == ev_msgs.size

  ev_msgs.each do |ev_msg|
    next if ev_msg["$id"] < start_id
    break if ev_msg["$id"] > end_id

    next if ev_msg["name"].empty?

    puts "[#{BF3::get_talker_name(ev_msg["talker"])}]".colorize(:magenta) unless no_talkers
    if ev_msg.has_key?("talkattr")
      case ev_msg["talkattr"]
      when 33024
        # normal style
      when 33025
        puts "*shouting*".colorize(:black)
      when 33026
        puts "*in thought*".colorize(:black)
      when 33027
        puts "*on call*".colorize(:black)
      else
        puts "[unknown talkattr: #{ev_msg["talkattr"]}]".colorize(:black)
      end
    end

    if matches.include?(ev_msg["$id"])
      result = results.find { |res| res[:msg]["$id"] == ev_msg["$id"] }
      # print the whole line in green and bold the search query
      # remember that the search query is case insensitive
      # we have to preserve the casing of the original text too
      puts ev_msg["name"][0...result[:start_index]].colorize(:green) + ev_msg["name"][result[:start_index]..result[:end_index]].colorize(:white).bold + ev_msg["name"][result[:end_index]+1..-1].colorize(:green) 
      puts
    elsif ev_msg["name"].start_with?("[ML")
      puts "%s\n" % [ev_msg["name"].colorize(:black)]
      puts
    else
      puts "%s\n" % [ev_msg["name"].colorize(:blue)]
      puts
    end
  end

  if truncate_end
    puts "...\n".colorize(:black)
  else
    puts "******\n".colorize(:black) unless broke
  end
end

