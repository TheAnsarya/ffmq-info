;==============================================================================
; ACCESSORY_NAMES - Text Data
;==============================================================================

org $04FD00

; 0000: #
accessory_names_0000:
  db $FE,$00

; 0001: ######[CLEAR][WAIT]
accessory_names_0001:
  db $FE,$FE,$FE,$FE,$FE,$FE,$03,$02,$00

; 0002: ##[CLEAR]
accessory_names_0002:
  db $FE,$FE,$03,$00

; 0007: #
accessory_names_0007:
  db $FE,$00

; 0008: #####
accessory_names_0008:
  db $FE,$FE,$FE,$FE,$FE,$00

; 0012: #####
accessory_names_0012:
  db $FE,$FE,$FE,$FE,$FE,$00

; 0014: ######
accessory_names_0014:
  db $FE,$FE,$FE,$FE,$FE,$FE,$00

; 0015: #######
accessory_names_0015:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0017: ###
accessory_names_0017:
  db $FE,$FE,$FE,$00

; 0021: #######
accessory_names_0021:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0023: #####
accessory_names_0023:
  db $FE,$FE,$FE,$FE,$FE,$00

; 0030: ##
accessory_names_0030:
  db $FE,$FE,$00

; 0032: ######
accessory_names_0032:
  db $FE,$FE,$FE,$FE,$FE,$FE,$00

; 0036: ###[WAIT]##
accessory_names_0036:
  db $FE,$FE,$FE,$02,$FE,$FE,$00

; 0039: #########
accessory_names_0039:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0040: __###n#n#n#
accessory_names_0040:
  db $06,$06,$FE,$FE,$FE,$C1,$FE,$C1,$FE,$C1,$FE,$00

; 0041: ##
accessory_names_0041:
  db $FE,$FE,$00

; 0043: ###n####
accessory_names_0043:
  db $FE,$FE,$FE,$C1,$FE,$FE,$FE,$FE,$00

; 0044: ###
accessory_names_0044:
  db $FE,$FE,$FE,$00

; 0046: 
#
accessory_names_0046:
  db $01,$FE,$00

; 0049: ##[NAME]#[WAIT]#[NAME]##
accessory_names_0049:
  db $FE,$FE,$04,$FE,$02,$FE,$04,$FE,$FE,$00

; 0051: [NAME]#[NAME]###
accessory_names_0051:
  db $04,$FE,$04,$FE,$FE,$FE,$00

; 0054: ####
accessory_names_0054:
  db $FE,$FE,$FE,$FE,$00

; 0056: ##
accessory_names_0056:
  db $FE,$FE,$00

