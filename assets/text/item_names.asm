;==============================================================================
; ITEM_NAMES - Text Data
;==============================================================================

org $04F000

; 0000: [WAIT][WAIT][WAIT]

##[NAME][ITEM]###
item_names_0000:
  db $02,$02,$02,$01,$01,$FE,$FE,$04,$05,$FE,$FE,$FE,$00

; 0001: #[CLEAR][CLEAR][CLEAR]
#_##
item_names_0001:
  db $FE,$03,$03,$03,$01,$FE,$06,$FE,$FE,$00

; 0002: #####Vl####F
item_names_0002:
  db $FE,$FE,$FE,$FE,$FE,$AF,$BF,$FE,$FE,$FE,$FE,$9F,$00

; 0003: F
item_names_0003:
  db $9F,$00

; 0005: #
item_names_0005:
  db $FE,$00

; 0006: #########'Wl
item_names_0006:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$D1,$B0,$BF,$00

; 0007: e######F##t
item_names_0007:
  db $B8,$FE,$FE,$FE,$FE,$FE,$FE,$9F,$FE,$FE,$C7,$00

; 0008: _#########
item_names_0008:
  db $06,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0009: ########y##
item_names_0009:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$CC,$FE,$FE,$00

; 0010: &#Vi8#######
item_names_0010:
  db $DB,$FE,$AF,$BC,$98,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0011: ########G
item_names_0011:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$A0,$00

; 0012: G##99#######
item_names_0012:
  db $A0,$FE,$FE,$99,$99,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0013: ###m9######
item_names_0013:
  db $FE,$FE,$FE,$C0,$99,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0014: ######S#####
item_names_0014:
  db $FE,$FE,$FE,$FE,$FE,$FE,$AC,$FE,$FE,$FE,$FE,$FE,$00

; 0015: #r#######FD#
item_names_0015:
  db $FE,$C5,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$9F,$9D,$FE,$00

; 0016: ####5#######
item_names_0016:
  db $FE,$FE,$FE,$FE,$95,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0017: ###########
item_names_0017:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0018: ###UP#######
item_names_0018:
  db $FE,$FE,$FE,$AE,$A9,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0019: ###t#F##k
item_names_0019:
  db $FE,$FE,$FE,$C7,$FE,$9F,$FE,$FE,$BE,$00

; 0020: l###########
item_names_0020:
  db $BF,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0021: #J#####t####
item_names_0021:
  db $FE,$A3,$FE,$FE,$FE,$FE,$FE,$C7,$FE,$FE,$FE,$FE,$00

; 0022: #########Zd#
item_names_0022:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$B3,$B7,$FE,$00

; 0023: ##########
item_names_0023:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0024: #d##k##e
item_names_0024:
  db $FE,$B7,$FE,$FE,$BE,$FE,$FE,$B8,$00

; 0025: ##[NAME]###
item_names_0025:
  db $FE,$FE,$04,$FE,$FE,$FE,$00

; 0026: #T######
item_names_0026:
  db $FE,$AD,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0027: ######
item_names_0027:
  db $FE,$FE,$FE,$FE,$FE,$FE,$00

; 0028: #kl#####x###
item_names_0028:
  db $FE,$BE,$BF,$FE,$FE,$FE,$FE,$FE,$CB,$FE,$FE,$FE,$00

; 0029: ###qCi######
item_names_0029:
  db $FE,$FE,$FE,$C4,$9C,$BC,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0030: ########
item_names_0030:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0031: #########bh#
item_names_0031:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$B5,$BB,$FE,$00

; 0032: ###l#i#####e
item_names_0032:
  db $FE,$FE,$FE,$BF,$FE,$BC,$FE,$FE,$FE,$FE,$FE,$B8,$00

; 0033: lm####d#T##
item_names_0033:
  db $BF,$C0,$FE,$FE,$FE,$FE,$B7,$FE,$AD,$FE,$FE,$00

; 0034: #_##########
item_names_0034:
  db $FE,$06,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0035: [CLEAR]#########
item_names_0035:
  db $03,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0036: ##########
item_names_0036:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0037: #Vl##&##l###
item_names_0037:
  db $FE,$AF,$BF,$FE,$FE,$DB,$FE,$FE,$BF,$FE,$FE,$FE,$00

; 0038: ########T###
item_names_0038:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$AD,$FE,$FE,$FE,$00

; 0039: ######d##
item_names_0039:
  db $FE,$FE,$FE,$FE,$FE,$FE,$B7,$FE,$FE,$00

; 0040: ##########C#
item_names_0040:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$9C,$FE,$00

; 0041: C
item_names_0041:
  db $9C,$00

; 0042: [CLEAR][CLEAR][WAIT]


item_names_0042:
  db $03,$03,$02,$01,$01,$00

; 0043: P
item_names_0043:
  db $A9,$00

; 0044: ####E#######
item_names_0044:
  db $FE,$FE,$FE,$FE,$9E,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0045: #
item_names_0045:
  db $FE,$00

; 0046: 7#####[WAIT]####P
item_names_0046:
  db $97,$FE,$FE,$FE,$FE,$FE,$02,$FE,$FE,$FE,$FE,$A9,$00

; 0047: V#8#######
item_names_0047:
  db $AF,$FE,$98,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0048: #knp##E###e
item_names_0048:
  db $FE,$BE,$C1,$C3,$FE,$FE,$9E,$FE,$FE,$FE,$B8,$00

; 0049: O###t####0
item_names_0049:
  db $A8,$FE,$FE,$FE,$C7,$FE,$FE,$FE,$FE,$90,$00

; 0050: ############
item_names_0050:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0051: ##########C#
item_names_0051:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$9C,$FE,$00

; 0052: A#Z#Ytg#A#9#
item_names_0052:
  db $9A,$FE,$B3,$FE,$B2,$C7,$BA,$FE,$9A,$FE,$99,$FE,$00

; 0053: 9FFlllFFF##y
item_names_0053:
  db $99,$9F,$9F,$BF,$BF,$BF,$9F,$9F,$9F,$FE,$FE,$CC,$00

; 0054: #U##-#w##7#3
item_names_0054:
  db $FE,$AE,$FE,$FE,$DA,$FE,$CA,$FE,$FE,$97,$FE,$93,$00

; 0055: ##########k#
item_names_0055:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$BE,$FE,$00

; 0056: #######[NAME][NAME][ITEM][ITEM]#
item_names_0056:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$04,$04,$05,$05,$FE,$00

; 0057: #'#####_#aih
item_names_0057:
  db $FE,$D1,$FE,$FE,$FE,$FE,$FE,$06,$FE,$B4,$BC,$BB,$00

; 0058: h###[NAME]F####n#
item_names_0058:
  db $BB,$FE,$FE,$FE,$04,$9F,$FE,$FE,$FE,$FE,$C1,$FE,$00

; 0059: mpt#########
item_names_0059:
  db $C0,$C3,$C7,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0060: #u#AA###oii#
item_names_0060:
  db $FE,$C8,$FE,$9A,$9A,$FE,$FE,$FE,$C2,$BC,$BC,$FE,$00

; 0061: ########h
item_names_0061:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$BB,$00

; 0062: t##[NAME]####k
##
item_names_0062:
  db $C7,$FE,$FE,$04,$FE,$FE,$FE,$FE,$BE,$01,$FE,$FE,$00

; 0063: ##
[CLEAR]q##
item_names_0063:
  db $FE,$FE,$01,$03,$C4,$FE,$FE,$00

; 0064: ####i######
item_names_0064:
  db $FE,$FE,$FE,$FE,$BC,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0065: #
item_names_0065:
  db $FE,$00

; 0066: ############
item_names_0066:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0067: #F#######B##
item_names_0067:
  db $FE,$9F,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$9B,$FE,$FE,$00

; 0068: #xbxbD&x#v#
item_names_0068:
  db $FE,$CB,$B5,$CB,$B5,$9D,$DB,$CB,$FE,$C9,$FE,$00

; 0069: u###########
item_names_0069:
  db $C8,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0070: ############
item_names_0070:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0071: ############
item_names_0071:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0072: #####s#####
item_names_0072:
  db $FE,$FE,$FE,$FE,$FE,$C6,$FE,$FE,$FE,$FE,$FE,$00

; 0073: ####[CLEAR]#####
item_names_0073:
  db $FE,$FE,$FE,$FE,$03,$FE,$FE,$FE,$FE,$FE,$00

; 0074: #########p#
item_names_0074:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$C3,$FE,$00

; 0075: #####m
item_names_0075:
  db $FE,$FE,$FE,$FE,$FE,$C0,$00

; 0076: ###u#
item_names_0076:
  db $FE,$FE,$FE,$C8,$FE,$00

; 0077: ####m
item_names_0077:
  db $FE,$FE,$FE,$FE,$C0,$00

; 0078: #####pin#m##
item_names_0078:
  db $FE,$FE,$FE,$FE,$FE,$C3,$BC,$C1,$FE,$C0,$FE,$FE,$00

; 0079: #######mm#
item_names_0079:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$C0,$C0,$FE,$00

; 0080: G##W#0#0####
item_names_0080:
  db $A0,$FE,$FE,$B0,$FE,$90,$FE,$90,$FE,$FE,$FE,$FE,$00

; 0081: #m##########
item_names_0081:
  db $FE,$C0,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0082: ######[ITEM][CLEAR][CLEAR]


item_names_0082:
  db $FE,$FE,$FE,$FE,$FE,$FE,$05,$03,$03,$01,$01,$00

; 0084: ############
item_names_0084:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0085: ############
item_names_0085:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0086: ####lI#lF##
item_names_0086:
  db $FE,$FE,$FE,$FE,$BF,$A2,$FE,$BF,$9F,$FE,$FE,$00

; 0087: ######k###
item_names_0087:
  db $FE,$FE,$FE,$FE,$FE,$FE,$BE,$FE,$FE,$FE,$00

; 0088: #########[CLEAR]
item_names_0088:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$03,$00

; 0089: [CLEAR]#######[CLEAR]##
item_names_0089:
  db $03,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$03,$FE,$FE,$00

; 0090: ###ddp#
item_names_0090:
  db $FE,$FE,$FE,$B7,$B7,$C3,$FE,$00

; 0091: #
item_names_0091:
  db $FE,$00

; 0092: ####U###G##
item_names_0092:
  db $FE,$FE,$FE,$FE,$AE,$FE,$FE,$FE,$A0,$FE,$FE,$00

; 0093: ##[CLEAR]###m####
item_names_0093:
  db $FE,$FE,$03,$FE,$FE,$FE,$C0,$FE,$FE,$FE,$FE,$00

; 0094: ##########Z#
item_names_0094:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$B3,$FE,$00

; 0095: #########[NAME]#s
item_names_0095:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$04,$FE,$C6,$00

; 0096: #[CLEAR]##########
item_names_0096:
  db $FE,$03,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0097: ##_[CLEAR]

_#####
item_names_0097:
  db $FE,$FE,$06,$03,$01,$01,$06,$FE,$FE,$FE,$FE,$FE,$00

; 0098: #########
item_names_0098:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0100: #nn[CLEAR][CLEAR]#######
item_names_0100:
  db $FE,$C1,$C1,$03,$03,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0101: ###n[CLEAR][ITEM]######
item_names_0101:
  db $FE,$FE,$FE,$C1,$03,$05,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0102: ####_####y#[NAME]
item_names_0102:
  db $FE,$FE,$FE,$FE,$06,$FE,$FE,$FE,$FE,$CC,$FE,$04,$00

; 0103: #########
item_names_0103:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0104: #VIso_[NAME]#[NAME]###
item_names_0104:
  db $FE,$AF,$A2,$C6,$C2,$06,$04,$FE,$04,$FE,$FE,$FE,$00

; 0105: ########
item_names_0105:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0106: ########
item_names_0106:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0107: ##m####
item_names_0107:
  db $FE,$FE,$C0,$FE,$FE,$FE,$FE,$00

; 0108: #p######
item_names_0108:
  db $FE,$C3,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0109: #########
item_names_0109:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0110: #W#GGmm
item_names_0110:
  db $FE,$B0,$FE,$A0,$A0,$C0,$C0,$00

; 0114: pYzH#H####
item_names_0114:
  db $C3,$B2,$CD,$A1,$FE,$A1,$FE,$FE,$FE,$FE,$00

; 0115: ###
item_names_0115:
  db $FE,$FE,$FE,$00

; 0116: #####WW##
item_names_0116:
  db $FE,$FE,$FE,$FE,$FE,$B0,$B0,$FE,$FE,$00

; 0117: ##

item_names_0117:
  db $FE,$FE,$01,$00

; 0118: O#######m#m#
item_names_0118:
  db $A8,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$C0,$FE,$C0,$FE,$00

; 0119: ########
item_names_0119:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0120: #########l#l
item_names_0120:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$BF,$FE,$BF,$00

; 0121: #[ITEM]
item_names_0121:
  db $FE,$05,$00

; 0122: [NAME][NAME][NAME]_##l
item_names_0122:
  db $04,$04,$04,$06,$FE,$FE,$BF,$00

; 0123: #
item_names_0123:
  db $FE,$00

; 0124: #####m#m#m#m
item_names_0124:
  db $FE,$FE,$FE,$FE,$FE,$C0,$FE,$C0,$FE,$C0,$FE,$C0,$00

; 0125: #
item_names_0125:
  db $FE,$00

; 0126: #####[CLEAR][CLEAR]



[CLEAR]
item_names_0126:
  db $FE,$FE,$FE,$FE,$FE,$03,$03,$01,$01,$01,$01,$03,$00

; 0127: [WAIT]0###[WAIT]

[CLEAR]###
item_names_0127:
  db $02,$90,$FE,$FE,$FE,$02,$01,$01,$03,$FE,$FE,$FE,$00

; 0128: i####[NAME]K#####
item_names_0128:
  db $BC,$FE,$FE,$FE,$FE,$04,$A4,$FE,$FE,$FE,$FE,$FE,$00

; 0129: ###8####k
item_names_0129:
  db $FE,$FE,$FE,$98,$FE,$FE,$FE,$FE,$BE,$00

; 0130: ######[CLEAR][CLEAR]
item_names_0130:
  db $FE,$FE,$FE,$FE,$FE,$FE,$03,$03,$00

; 0132: ##m###'#####
item_names_0132:
  db $FE,$FE,$C0,$FE,$FE,$FE,$D1,$FE,$FE,$FE,$FE,$FE,$00

; 0133: #####l#l
item_names_0133:
  db $FE,$FE,$FE,$FE,$FE,$BF,$FE,$BF,$00

; 0134: #l####n####
item_names_0134:
  db $FE,$BF,$FE,$FE,$FE,$FE,$C1,$FE,$FE,$FE,$FE,$00

; 0135: ###Cu###
item_names_0135:
  db $FE,$FE,$FE,$9C,$C8,$FE,$FE,$FE,$00

; 0136: ########0###
item_names_0136:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$90,$FE,$FE,$FE,$00

; 0137: #########
item_names_0137:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0139: [CLEAR]
item_names_0139:
  db $03,$00

; 0140: ###########
item_names_0140:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0141: #######C##
item_names_0141:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$9C,$FE,$FE,$00

; 0142: ##########
item_names_0142:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0143: ######
item_names_0143:
  db $FE,$FE,$FE,$FE,$FE,$FE,$00

; 0146: ########

item_names_0146:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$01,$00

; 0147: 
_####
fl#
item_names_0147:
  db $01,$06,$FE,$FE,$FE,$FE,$01,$B9,$BF,$FE,$00

; 0148: ######
item_names_0148:
  db $FE,$FE,$FE,$FE,$FE,$FE,$00

; 0149: ##m######
item_names_0149:
  db $FE,$FE,$C0,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0150: #GG####
item_names_0150:
  db $FE,$A0,$A0,$FE,$FE,$FE,$FE,$00

; 0151: ####m#
item_names_0151:
  db $FE,$FE,$FE,$FE,$C0,$FE,$00

; 0152: 7#####[WAIT]#####
item_names_0152:
  db $97,$FE,$FE,$FE,$FE,$FE,$02,$FE,$FE,$FE,$FE,$FE,$00

; 0153: ##8#######
item_names_0153:
  db $FE,$FE,$98,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0154: #W#u###E###e
item_names_0154:
  db $FE,$B0,$FE,$C8,$FE,$FE,$FE,$9E,$FE,$FE,$FE,$B8,$00

; 0155: O##0u###
item_names_0155:
  db $A8,$FE,$FE,$90,$C8,$FE,$FE,$FE,$00

; 0157: #
item_names_0157:
  db $FE,$00

; 0158: #######[NAME][NAME][ITEM][ITEM]#
item_names_0158:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$04,$04,$05,$05,$FE,$00

; 0159: #######_#w#d
item_names_0159:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$06,$FE,$CA,$FE,$B7,$00

; 0160: j#g#####n#
item_names_0160:
  db $BD,$FE,$BA,$FE,$FE,$FE,$FE,$FE,$C1,$FE,$00

; 0161: m#ps########
item_names_0161:
  db $C0,$FE,$C3,$C6,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0162: ############
item_names_0162:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0163: ############
item_names_0163:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0164: ##########7#
item_names_0164:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$97,$FE,$00

; 0165: ##########
item_names_0165:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0166: ####li##e###
item_names_0166:
  db $FE,$FE,$FE,$FE,$BF,$BC,$FE,$FE,$B8,$FE,$FE,$FE,$00

; 0167: ######d###
item_names_0167:
  db $FE,$FE,$FE,$FE,$FE,$FE,$B7,$FE,$FE,$FE,$00

; 0168: #nt########[CLEAR]
item_names_0168:
  db $FE,$C1,$C7,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$03,$00

; 0169: [CLEAR][WAIT]######[CLEAR]###
item_names_0169:
  db $03,$02,$FE,$FE,$FE,$FE,$FE,$FE,$03,$FE,$FE,$FE,$00

; 0170: S######
item_names_0170:
  db $AC,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0171: ######
item_names_0171:
  db $FE,$FE,$FE,$FE,$FE,$FE,$00

; 0173: #
item_names_0173:
  db $FE,$00

; 0174: [CLEAR][CLEAR][WAIT]


item_names_0174:
  db $03,$03,$02,$01,$01,$00

; 0175: #
item_names_0175:
  db $FE,$00

; 0177: #
item_names_0177:
  db $FE,$00

; 0178: ############
item_names_0178:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0179: ########m##
item_names_0179:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$C0,$FE,$FE,$00

; 0180: #########4##
item_names_0180:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$94,$FE,$FE,$00

; 0181: #m########j#
item_names_0181:
  db $FE,$C0,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$BD,$FE,$00

; 0182: #######[NAME][NAME][ITEM][ITEM]#
item_names_0182:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$04,$04,$05,$05,$FE,$00

; 0183: #######_#q#R
item_names_0183:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$06,$FE,$C4,$FE,$AB,$00

; 0184: h#a#######
item_names_0184:
  db $BB,$FE,$B4,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0185: ##ty####x#h
item_names_0185:
  db $FE,$FE,$C7,$CC,$FE,$FE,$FE,$FE,$CB,$FE,$BB,$00

; 0186: t#b####9U###
item_names_0186:
  db $C7,$FE,$B5,$FE,$FE,$FE,$FE,$99,$AE,$FE,$FE,$FE,$00

; 0187: #t[CLEAR]_q##
item_names_0187:
  db $FE,$C7,$03,$06,$C4,$FE,$FE,$00

; 0188: ####Q#######
item_names_0188:
  db $FE,$FE,$FE,$FE,$AA,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0189: #
item_names_0189:
  db $FE,$00

; 0191: m
item_names_0191:
  db $C0,$00

; 0192: #wkwk#C#u#u#
item_names_0192:
  db $FE,$CA,$BE,$CA,$BE,$FE,$9C,$FE,$C8,$FE,$C8,$FE,$00

; 0193: u###########
item_names_0193:
  db $C8,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0194: ############
item_names_0194:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0195: ############
item_names_0195:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0196: ###s#####m
item_names_0196:
  db $FE,$FE,$FE,$C6,$FE,$FE,$FE,$FE,$FE,$C0,$00

; 0197: #####[CLEAR]######
item_names_0197:
  db $FE,$FE,$FE,$FE,$FE,$03,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0198: ############
item_names_0198:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0199: F#########
item_names_0199:
  db $9F,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0200: ###u#
M##k#
item_names_0200:
  db $FE,$FE,$FE,$C8,$FE,$01,$A6,$FE,$FE,$BE,$FE,$00

; 0201: ####m
item_names_0201:
  db $FE,$FE,$FE,$FE,$C0,$00

; 0202: ####x#r#u##
item_names_0202:
  db $FE,$FE,$FE,$FE,$CB,$FE,$C5,$FE,$C8,$FE,$FE,$00

; 0203: #
item_names_0203:
  db $FE,$00

; 0204: 0##O###u###[NAME]
item_names_0204:
  db $90,$FE,$FE,$A8,$FE,$FE,$FE,$C8,$FE,$FE,$FE,$04,$00

; 0205: ##########u#
item_names_0205:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$C8,$FE,$00

; 0206: ############
item_names_0206:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0207: ############
item_names_0207:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0208: #####E#8##
item_names_0208:
  db $FE,$FE,$FE,$FE,$FE,$9E,$FE,$98,$FE,$FE,$00

; 0209: ######
item_names_0209:
  db $FE,$FE,$FE,$FE,$FE,$FE,$00

; 0210: ###ll#####
item_names_0210:
  db $FE,$FE,$FE,$BF,$BF,$FE,$FE,$FE,$FE,$FE,$00

; 0211: #########Wde
item_names_0211:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$B0,$B7,$B8,$00

; 0212: ###ll##p#
item_names_0212:
  db $FE,$FE,$FE,$BF,$BF,$FE,$FE,$C3,$FE,$00

; 0213: ###W###
item_names_0213:
  db $FE,$FE,$FE,$B0,$FE,$FE,$FE,$00

; 0214: #####U###G##
item_names_0214:
  db $FE,$FE,$FE,$FE,$FE,$AE,$FE,$FE,$FE,$A0,$FE,$FE,$00

; 0215: ##[CLEAR]###m#####
item_names_0215:
  db $FE,$FE,$03,$FE,$FE,$FE,$C0,$FE,$FE,$FE,$FE,$FE,$00

; 0216: #77####p#il#
item_names_0216:
  db $FE,$97,$97,$FE,$FE,$FE,$FE,$C3,$FE,$BC,$BF,$FE,$00

; 0217: #######m
item_names_0217:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$C0,$00

; 0218: #######Yw###
item_names_0218:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$B2,$CA,$FE,$FE,$FE,$00

; 0219: #[NAME]_[CLEAR]

_#####
item_names_0219:
  db $FE,$04,$06,$03,$01,$01,$06,$FE,$FE,$FE,$FE,$FE,$00

; 0220: #########
item_names_0220:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0222: #ts#########
item_names_0222:
  db $FE,$C7,$C6,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0223: ###t#######m
item_names_0223:
  db $FE,$FE,$FE,$C7,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$C0,$00

; 0224: ##[CLEAR]####-#y##
item_names_0224:
  db $FE,$FE,$03,$FE,$FE,$FE,$FE,$DA,$FE,$CC,$FE,$FE,$00

; 0225: ######
#
item_names_0225:
  db $FE,$FE,$FE,$FE,$FE,$FE,$01,$FE,$00

; 0226: ####
item_names_0226:
  db $FE,$FE,$FE,$FE,$00

; 0227: #
item_names_0227:
  db $FE,$00

; 0228: ###WWmm
item_names_0228:
  db $FE,$FE,$FE,$B0,$B0,$C0,$C0,$00

; 0230: ####WW##
item_names_0230:
  db $FE,$FE,$FE,$FE,$B0,$B0,$FE,$FE,$00

; 0231: ##

item_names_0231:
  db $FE,$FE,$01,$00

; 0232: S#s#####
item_names_0232:
  db $AC,$FE,$C6,$FE,$FE,$FE,$FE,$FE,$00

; 0233: #########
item_names_0233:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0234: #########l#l
item_names_0234:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$BF,$FE,$BF,$00

; 0235: ####
item_names_0235:
  db $FE,$FE,$FE,$FE,$00

; 0236: #####Xlbh-##
item_names_0236:
  db $FE,$FE,$FE,$FE,$FE,$B1,$BF,$B5,$BB,$DA,$FE,$FE,$00

; 0237: ###mm####m
item_names_0237:
  db $FE,$FE,$FE,$C0,$C0,$FE,$FE,$FE,$FE,$C0,$00

; 0238: #mm####mmmmG
item_names_0238:
  db $FE,$C0,$C0,$FE,$FE,$FE,$FE,$C0,$C0,$C0,$C0,$A0,$00

; 0239: G#mm#m###j#C
item_names_0239:
  db $A0,$FE,$C0,$C0,$FE,$C0,$FE,$FE,$FE,$BD,$FE,$9C,$00

; 0240: ############
item_names_0240:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0241: ###########T
item_names_0241:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$AD,$00

; 0242: #T#########
item_names_0242:
  db $FE,$AD,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00

; 0243: #####
item_names_0243:
  db $FE,$FE,$FE,$FE,$FE,$00

; 0244: ###########G
item_names_0244:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$A0,$00

; 0245: #########df#
item_names_0245:
  db $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$B7,$B9,$FE,$00

; 0246: ######
item_names_0246:
  db $FE,$FE,$FE,$FE,$FE,$FE,$00

; 0247: ##m###
item_names_0247:
  db $FE,$FE,$C0,$FE,$FE,$FE,$00

