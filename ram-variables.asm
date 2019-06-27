

!general_address = $0017


!loop_counter_62 = $62
!loop_counter_64 = $64
!temp_64 = $64

!flags_d8 = $00d8

!color_data_source_offset = $00f4
!color_data_source_offset_2 = $00f7

!ram_0111 = $0111

!tilemap_wram_source_start = $0800
!tilemap_wram_source_start_2 = $0900
!ram_0900 = $0900

!ram_1031 = $1031
!ram_1031_long = $001031



!ram_1924 = $1924
!ram_1925 = $1925


!ram_195f = $195f

!ram_19a5 = $19a5



!ram_19b4 = $19b4		; if bit 3 = 1 then !ram_1a33 => $80 else $00

!ram_19bd = $19bd		; $19bd => botttom 4 bits inversed are a dma transfer size variable
!ram_19bf = $19bf		; $19bf

; $19fa => 1 byte, VMAIN flags ---- known values $80, $81
!tilemap_vram_control = $19fa
; $19fb-$1a02 => 8 bytes, 2-byte pairs, 4 of them, each is destination address in VRAM
!tilemap_vram_destination_addresses = $19fb
; $1a03-$1a0a => 8 bytes, 2-byte pairs, 4 of them, each is source address offset
!tilemap_wram_source_addresses = $1a03
; $1a0b-$1a12 => 8 bytes, 2-byte pairs, 4 of them, each is DMA transfer size in bytes
!tilemap_dma_transfer_sizes = $1a0b

; $1a13 => 1 byte, VMAIN flags ---- known values $80, $81
!tilemap_vram_control_2 = $1a13
; $1a14-$1a1b => 8 bytes, 2-byte pairs, 4 of them, each is destination address in VRAM
!tilemap_vram_destination_addresses_2 = $1a14
; $1a1c-$1a23 => 8 bytes, 2-byte pairs, 4 of them, each is source address offset
!tilemap_wram_source_addresses_2 = $1a1c
; $1a24-$1a2b => 8 bytes, 2-byte pairs, 4 of them, each is DMA transfer size in bytes
!tilemap_dma_transfer_sizes_2 = $1a24


!ram_1a2d = $1a2d

!ram_1a31 = $1a31
!ram_1a32 = $1a32
!ram_1a33 = $1a33
!ram_1a34 = $1a34

!ram_1a3d = $1a3d

!ram_1a46 = $1a46

!ram_1a4c = $1a4c



!menu_color = $0e9c
!menu_color_high = $0e9d


