using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace pull_assets_from_rom {
	class Program {
		// Make sure rom is unheadered
		static string romfilename = @"c:\working\Final Fantasy - Mystic Quest (U) (V1.0) [!].smc";
		static string outputfolder = @"c:\working\ffmq-assets\";

		private static byte[] _rom = null;
		public static byte[] ROM {
			get {
				if (_rom == null) {
					_rom = new byte[0x80000];
					using (var romstream = File.OpenRead(romfilename)) {
						romstream.Read(_rom, 0, 0x80000);
					}
				}

				return _rom;
			}
		}

		static List<Asset> Definition = new List<Asset>() {
			new Asset(@"data\graphics\048000-tiles.bin", 0x020000, 0x1800),
			new Asset(@"data\graphics\tiles.bin", 0x028C80, 0x6600),
			new Asset(@"data\graphics\038030-title-screen-maybe.bin", 0x038030, 0x1000),
			new Asset(@"data\graphics\data07b013.bin", 0x03B013, 0x2BE9),

			
			new Asset(@"data\graphics\title-screen-crystals-01.bin", 0x026220, 0x60),	// $04e220-$04e27f, in file $026220-$02627f
			new Asset(@"data\graphics\title-screen-crystals-02.bin", 0x026490, 0x90),	// $04e490-$‭04e51f, in file $026490-$0‭2651f
			new Asset(@"data\graphics\title-screen-crystals-03.bin", 0x027cc0, 0x1e0),	// $04fcc0-$0‭4fe9f‬, in file $027cc0-$0‭27e9f
			
			new Asset(@"data\graphics\title-screen-words.bin", 0x062a4c, 0xca0)			// $0caa4c-$0‭cb6ec, in file $062a4c-$0636ec

	};


		static void Main(string[] args) {
			PullAssets();
		}
		static void PullAssets() {
			foreach (var def in Definition) {
				var section = new MemoryStream(ROM, def.Address, def.Size);

				string path = Path.Combine(outputfolder, def.Path);
				string dir = Path.GetDirectoryName(path);
				Directory.CreateDirectory(dir);

				using (var file = File.OpenWrite(path)) {
					section.CopyTo(file);
				}
			}
		}

		class Asset {
			public string Path { get; set; }
			public int Address { get; set; }
			public int Size { get; set; }

			public Asset() { }

			public Asset(string path, int address, int size) {
				Path = path;
				Address = address;
				Size = size;
			}
		}
	}
}
