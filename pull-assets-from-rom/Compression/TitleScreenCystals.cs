using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace pull_assets_from_rom.Compression {
	class TitleScreenCystals {

		// todo: make a dynamic loaded version
		private static byte[][] ControlCodes = new byte[][] {
			new byte[]  {0x00,0x01,0x82,0x00,0x01,0x82,0x00,0x01,0x82,0x00,0x01,0x82,0x02,0x03,0x82,0x02,0x03,0x82,0x02,0x03,0x82,0x02,0x03,0x82,0x04,0x05,0x82,0x04,0x05,0x82,0x04,0x05,0x82,0x04,0x05,0x82,0x06,0x07,0x82,0x06,0x07,0x82,0x06,0x07,0x82,0x06,0x07,0x82,0x00,0x01,0x82,0x00,0x01,0x86,0x08,0x81,0x09,0x81,0x02,0x03,0x82,0x02,0x03,0x8A,0x04,0x05,0x82,0x04,0x05,0x8A,0x06,0x07,0x82,0x06,0x07,0xFF },
			new byte[]  {0x08,0x81,0x09,0xFF },
			new byte[]  {0x00,0x83,0x00,0x83,0x00,0x83,0x00,0x83,0x02,0x83,0x02,0x83,0x02,0x83,0x02,0x83,0x04,0x83,0x04,0x83,0x04,0x83,0x04,0x83,0x06,0x83,0x06,0x83,0x06,0x83,0x06,0x83,0x00,0x83,0x00,0x86,0x08,0x81,0x09,0x82,0x02,0x83,0x02,0x8B,0x04,0x83,0x04,0x8B,0x06,0x83,0x06,0xFF },
			new byte[]  {0x0A,0x0B,0x83,0x0F,0x82,0x13,0x14,0x86,0x0C,0x0D,0x82,0x10,0x11,0x82,0x15,0x16,0x87,0x0E,0x83,0x12,0x83,0x17,0x92,0x18,0x19,0x82,0x1D,0x8B,0x1A,0x1B,0x8F,0x1C,0xFF},
			new byte[]  {0x0C,0x83,0x10,0x83,0x15,0x87,0x0A,0x0B,0x83,0x0F,0x82,0x13,0x14,0xA2,0x1A,0x8F,0x18,0x19,0x82,0x1D,0xFF},
			new byte[]  {0x0C,0x83,0x10,0x83,0x15,0x87,0x0A,0x87,0x13,0xA3,0x1A,0x8F,0x18,0x83,0x1D,0xFF},
			new byte[]  {0x0A,0x87,0x13,0x87,0x0C,0x83,0x10,0x83,0x15,0xA3,0x18,0x83,0x1D,0x8B,0x1A,0xFF}
		};


		// CopyAndDecompressCrystals

		/*
			jsr CopyTitleScreenCrystalsCompressed
			jsr ExpandSecondHalfWithZeros
			jsr DecompressCrystals
		*/

		public static byte[] Decompress(byte[] input) {
			byte[] data = ExpandSecondHalfWithZeros(input);
			byte[] output = new byte[0x2000];

			/*
			 
			 
	jsr .Section91af
	jsr .Section9197
	jsr ReverseWordArrays
	jsr .Section91b7
	jsr .Section919f
	jsr ReverseBitsAndShiftLeftSection
	jsr .Section91bf
	jsr ReverseWordArrays
	jsr .Section91c7
	jsr .Section91a7
	jsr ReverseWordArrays

	ldy #$24c0
	ldx #$9400			; DataDecompressCrystalsControl06
	bra .MainLoop

	.Section9197
	ldy #$2080
	ldx #$93ca			; DataDecompressCrystalsControl04
	bra .MainLoop

	.Section919f
	ldy #$2480
	ldx #$93eb			; DataDecompressCrystalsControl05
	bra .MainLoop

	.Section91a7
	ldy #$20c0
	ldx #$9410			; DataDecompressCrystalsControl07
	bra .MainLoop

	.Section91af
	ldy #$2000
	ldx #$9346			; DataDecompressCrystalsControl01
	bra .MainLoop

	.Section91b7
	ldy #$2b80
	ldx #$9392			; DataDecompressCrystalsControl02
	bra .MainLoop

	.Section91bf
	ldy #$2ba0
	ldx #$9392			; DataDecompressCrystalsControl02
	bra .MainLoop

	.Section91c7
	ldy #$2040
	ldx #$9396			; DataDecompressCrystalsControl03

	.MainLoop {
		phk
		plb					; databank => program bank, $0c
		lda $0000,x
		and #$00ff			; A => control code ($0000[X].low)
		cmp #$0080
		bcs .SkipAhead			; if high bit set then .SkipAhead else .Decompress

		.Decompress {
			asl a
			asl a
			asl a
			asl a
			asl a				; A => A * $20
			phx					; save control code offset
			tax					; X => A

			jsr DecompressCrystalsChunk

			plx					; restore control code offset
			inx					; increment control code offset
			bra .MainLoop
		}

		.SkipAhead {
			cmp #$00ff
			beq .Exit			; exit when control code = $FF

			and #$007f			; clear high bit
			; skip A * $20 bytes of destination
			asl a
			asl a
			asl a
			asl a
			asl a				; A => A * $20
			sta !temp_64
			tya
			adc !temp_64
			tay					; Y => Y + A

			inx					; increment control code offset
			bra .MainLoop
		}
	}

	.Exit
	rts					; exit routine

			 
			 
			 */



			return output;
		}

		private static byte[] ExpandSecondHalfWithZeros(byte[] input) {
			if (input.Length % 0x18 != 0) {
				throw new ArgumentException("input needs to be in full $18 byte chunks");
			}

			byte[] output = new byte[input.Length * 4 / 3];

			int y = 0;
			for (int i = 0; i < input.Length; i++) {
				output[y] = input[i];
				y++;

				// skip a byte in destination
				if ((i % 0x18) >= 0x10) {
					y++;
				}
			}

			return output;
		}


		private static void DecompressChunk(byte[] source, byte[] dest, ref int x, ref int y) {
			for (int i = 8; i > 0; i--) {
				byte tmp = (byte)((source[x] | source[x + 1] | source[x + 0x10]) ^ 0xFF);

				dest[y] = (byte)((tmp & dest[y]) | source[x]);
				dest[y + 1] = (byte)((tmp & dest[y + 1]) | source[x + 1]);
				dest[y + 0x10] = (byte)((tmp & dest[y + 0x10]) | source[x + 0x10]);

				x += 2;
				y += 2;
			}

			y += 0x10;
		}


		private static void ReverseWordArrays(byte[] data) {
			int x = 0;

			for (int i = 0; i < 0x1e; i++) {
				ReverseWordArray(data, ref x);
				ReverseWordArray(data, ref x);
			}
		}

		private static void ReverseWordArray(byte[] data, ref int x) {
			byte[] tmp = new byte[0x10];

			for (int i = 0; i < 8; i++) {
				tmp[i * 2] = data[x + ((7 - i) * 2)];
				tmp[(i * 2) + 1] = data[x + ((7 - i) * 2) + 1];
			}

			for (int i = 0; i < 0x10; i++) {
				data[x + i] = tmp[i];
			}

			x += 0x10;
		}

		// for $3c0 bytes
		// reverse and shift first $10 bytes
		// then reverse and shift $8 more times skipping every other byte
		private static void ReverseBitsAndShiftLeftSection(byte[] data) {
			int x = 0;

			for (int i = 0; i < 0x1e; i++) {
				for (int j = 0; j < 0x10; j++) {
					ReverseBitsAndShiftLeft(data, ref x);
				}

				for (int j = 0; j < 9; j++) {
					ReverseBitsAndShiftLeft(data, ref x);
					x++;
				}
			}
		}

		// Reverse bits in byte and shift left
		// turns 12345678 into 76543210
		private static void ReverseBitsAndShiftLeft(byte[] data, ref int x) {
			byte tmp = ReverseBits(data[x]);
			tmp = (byte)((tmp << 1) & 0xff);
			data[x] = tmp;
			x++;
		}

		// Reverse the bits of a byte
		// Seems overly complicated but it works and is fast
		// https://stackoverflow.com/a/3590938/3325644
		private static byte ReverseBits(byte b) {
			return (byte)(((b * 0x80200802ul) & 0x0884422110ul) * 0x0101010101ul >> 32);
		}
	}
}
