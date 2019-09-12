# Johnny's Left 4 Dead 2 Mods

## Berserker

One player may become a berserker by typing !berserker in the chat.

The berserker has more rage the lower their health is.

Rage makes the berserker:
* Move faster
* Swing their weapon faster
* Do more damage
* Take less damage

The berserker can also double-jump.

The berserker is not allowed to use primary weapons.

## Medic 

One player may become the medic by typing !medic in the chat

The medic can heal other survivors by standing near to them, and constantly
regenerates health.

The medic periodically receives pain pills, adrenaline and first-aid kits.

The medic is not allowed to use primary weapons.

### CVars

* **medic_distance** Medic heal distance
* **medic_speed** Medic heal speed
* **medic_temp_healing** Amount of temporary healing to get for every 1 point of real health received
* **medic_boost_distance** How close to the medic players need to be to receive boost healing
* **medic_guardian_angel** Can the medic still heal people while dead (by spectating them)?

# Build/Install

## With CMake
```shell
cd /path/to/your/left4dead2/addons/sourcemod/scripting
git clone https://github.com/Johnny-Bags/l4d2-mods.git
cd l4d2-mods
mkdir _bld; cd _bld
cmake ..
cmake --build . --target install
```
If you clone the repo to a different directory then you'll need to specify the
plugins directory like this:
```shell
cmake .. -DCMAKE_INSTALL_PREFIX=/path/to/your/left4dead2/addons/sourcemod/plugins
```

## Manually
```shell
git clone https://github.com/Johnny-Bags/l4d2-mods.git
cd l4d2-mods
/path/to/your/spcomp ./berserker/berserker.sp -o berserker
/path/to/your/spcomp ./medic/medic.sp -o medic
cp berserker.smx /path/to/your/left4dead2/addons/sourcemod/plugins
cp medic.smx /path/to/your/left4dead2/addons/sourcemod/plugins
```
