
!ram_0800 = $0800

!ram_19bd = $19bd		; $19bd-$19be => 2 bytes, botttom 4 bits of $19bd are a dma transfer size variable
!ram_19bf = $19bf		; $19bf

!tilemap_vram_control = $19fa							; $19fa => 1 byte, VMAIN flags ---- known values $80, $81
!tilemap_vram_destination_addresses = $19fb				; $19fb-$1a02 => 8 bytes, 2-byte pairs, 4 of them, each is destination address in VRAM
!tilemap_wram_source_addresses = $1a03					; $1a03-$1a0a => 8 bytes, 2-byte pairs, 4 of them, each is source address offset
!tilemap_dma_transfer_sizes = $1a0b						; $1a0b-$1a12 => 8 bytes, 2-byte pairs, 4 of them, each is DMA transfer size in bytes

!tilemap_vram_control_2 = $1a13							; $1a13 => 1 byte, VMAIN flags ---- known values $80, $81
!tilemap_vram_destination_addresses_2 = $1a14			; $1a14-$1a1b => 8 bytes, 2-byte pairs, 4 of them, each is destination address in VRAM
!tilemap_wram_source_addresses_2 = $1a1c				; $1a1c-$1a23 => 8 bytes, 2-byte pairs, 4 of them, each is source address offset
!tilemap_dma_transfer_sizes_2 = $1a24					; $1a24-$1a2b => 8 bytes, 2-byte pairs, 4 of them, each is DMA transfer size in bytes

!ram_1a3d = $1a3d

!ram_1031 = $1031
!ram_1031_long = $001031


!MENU_COLOR = $0e9c
!MENU_COLOR_LOW = $0e9c
!MENU_COLOR_HIGH = $0e9d


