
; TEXT: Location names
; 
; TODO: maybe convert to a macro of some kind instead of * for $03?

pushpc
pushtable
table "simple.tbl",rtl

org pctosnes($063ed0)
LocationNames:

	db "World***********"
	db "Focus Tower*****"
	db "Hill of Destiny*"
	db "Level Forest****"
	db "Foresta*********"
	db "Kaeli's House***"
	db "Sand Temple*****"
	db "Bone Dungeon****"
	db "Libra Temple****"
	db "Aquaria*********"
	db "Phoebe's House**"
	db "Wintry Cave*****"
	db "Life Temple*****"
	db "Falls Basin*****"
	db "Ice Pyramid*****"
	db "Spencer's Place*"
	db "Wintry Temple***"
	db "Fireburg********"
	db "Reuben's House**"
	db "Mine************"
	db "Sealed Temple***"
	db "Volcano*********"
	db "Lava Dome*******"
	db "Rope Bridge*****"
	db "Alive Forest****"
	db "Giant Tree******"
	db "Kaidge Temple***"
	db "Windhole Temple*"
	db "Mount Gale******"
	db "Windia**********"
	db "Otto's House****"
	db "Pazuzu's Tower**"
	db "Light Temple****"
	db "Ship Dock*******"
	db "Deck************"
	db "Mac's Ship******"
	db "Doom Castle*****"

pulltable
pullpc
