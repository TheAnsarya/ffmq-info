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

		static List<Asset> Definition = new List<Asset>() {
			new Asset(@"data\graphics\048000-tiles.bin", 0x020000, 0x1800),
			new Asset(@"data\graphics\tiles.bin", 0x028C80, 0x6600),
			new Asset(@"data\graphics\038030-title-screen-maybe.bin", 0x038030, 0x1000),
			new Asset(@"data\graphics\data07b013.bin", 0x03B013, 0x2BE9)
		};


		static void Main(string[] args) {
			PullAssets();
		}
		static void PullAssets() {
			var rom = new byte[0x80000];
			using (var romstream = File.OpenRead(romfilename)) {
				romstream.Read(rom, 0, 0x80000);
			}

			foreach (var def in Definition) {
				var section = new MemoryStream(rom, def.Address, def.Size);

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
