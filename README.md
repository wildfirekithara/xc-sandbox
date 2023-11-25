# XC Sandbox

Unsorted unorganized dumping ground of random notes, scripts, and experiments for Xenoblade Chronicles reverse engineering

It's a big mess! Don't expect anything too much of use, but I'll update this page occassionally if I come up with anything I think is useful.

Things of note:

[wwnames-aab_events.txt](./wwnames-aab_events.txt)
- event names for hashing. intended for use with https://github.com/bnnm/wwiser

[aab_parse.rb](./rb-sandbox/aab_parse.rb)
- dumps SND timeline from .aab files, with WWise event name and timeline position in frames (30fps)
- can dump the timeline to a MIDI file as well

Example:

https://github.com/wildfirekithara/xc-sandbox/assets/130002142/a86b299a-159f-4348-be3b-329add198a6e

Put together using:

```
ruby aab_parse.rb -i ch41141000_wp44_talent00.aab -m midi
SND count: 11
SND 0 -- 0x664B7417 -- S_talent_00_wp44 -- Time 2.0 -- S_talent_00_w -- Event: btl_pc14_fire01
SND 1 -- 0xCAA714F5 -- S_talent_00_wp44 -- Time 24.0 -- S_talent_00_w -- Event: elem_fire_spin01
SND 2 -- 0xF789BE4E -- S_talent_00_wp44 -- Time 34.0 -- S_talent_00_w -- Event: elem_fire_spin01
SND 3 -- 0xF789BE4E -- S_talent_00_wp44 -- Time 44.0 -- S_talent_00_w -- Event: elem_fire_spin01
SND 4 -- 0xF789BE4E -- S_talent_00_wp44 -- Time 54.0 -- S_talent_00_w -- Event: elem_fire_spin01
SND 5 -- 0x79F1A4AC -- S_talent_00_wp44 -- Time 70.0 -- S_talent_00_w -- Event: elem_fire004
SND 6 -- 0x498FA7F5 -- S_talent_00_wp44 -- Time 148.0 -- S_talent_00_w -- Event: btl_sp_m00
SND 7 -- 0xB7583197 -- S_talent_00_wp44 -- Time 150.0 -- S_talent_00_w -- Event: elem_fire001
SND 8 -- 0x26CBE59A -- S_talent_00_wp44 -- Time 84.0 -- S_talent_00_w -- Event: btl_pc14_inst04
SND 9 -- 0xF789BE4E -- S_talent_00_wp44 -- Time 150.0 -- S_talent_00_w -- Event: elem_fire001
SND 10 -- 0xF789BE4E -- S_talent_00_wp44 -- Time 150.0 -- S_talent_00_w -- Event: elem_fire001
btl_pc14_fire01
btl_pc14_inst04
btl_sp_m00
elem_fire001
elem_fire004
elem_fire_spin01
```


If you're looking to play around with things I recommend checking these resources:
- https://xenobladedata.github.io/ - generally useful hub
- https://github.com/ScanMountGoat/xc3_lib - file formats, model viewing/extraction tools
- https://github.com/PredatorCZ/XenoLib - file formats
- https://github.com/BlockBuilder57/xenomods - set of general mods, such as freecam
- https://github.com/RoccoDev/xc3-file-loader - easy file replacement
- https://github.com/RoccoDev/bdat-rs - bdat manipulation
- https://github.com/bnnm/wwiser - WWise simulator

