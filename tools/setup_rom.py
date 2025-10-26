#!/usr/bin/env python3
"""
Final Fantasy Mystic Quest - ROM Configuration Script
Verifies and prepares the base ROM for development
"""

import os
import sys
import hashlib
import shutil
from typing import Dict, Optional

class FFMQROMConfig:
    """Configure ROM for FFMQ development"""
    
    def __init__(self, rom_dir: str = "roms"):
        self.rom_dir = rom_dir
        self.target_rom = "Final Fantasy - Mystic Quest (U) (V1.1).sfc"
        
        # Known ROM versions with checksums
        self.known_roms = {
            "Final Fantasy - Mystic Quest (U) (V1.1)": {
                "filename": "Final Fantasy - Mystic Quest (U) (V1.1).sfc",
                "size": 524288,  # 512KB
                "crc32": "2c52c792",
                "md5": "f7faeae5a847c098d677070920769ca2",
                "sha1": "6be74b73b736bc6027c0e92619874da0c498bed0",
                "notes": "Primary development target",
                "header": True,
            },
            "Final Fantasy - Mystic Quest (U) (V1.0)": {
                "filename": "Final Fantasy - Mystic Quest (U) (V1.0) [!].sfc",
                "size": 524288,
                "crc32": "6b19a2c6", 
                "md5": "da08f0559fade06f37d5fdf1b6a6d92e",
                "sha1": "787c535aaca7b57f6b85fc02ceef106f7fe5ea59",
                "notes": "Original US release",
                "header": True,
            },
            "Final Fantasy USA - Mystic Quest (J)": {
                "filename": "Final Fantasy USA - Mystic Quest (J) [!].sfc",
                "size": 524288,
                "crc32": "1da17f0c",
                "md5": "5164060bd3350d7a6325ec8ae80bba54", 
                "sha1": "ffc05a65ef43fa5c56c9930af1af527509c1ae05",
                "notes": "Japanese version",
                "header": True,
            },
            "Mystic Quest Legend (E)": {
                "filename": "Mystic Quest Legend (E) [!].sfc",
                "size": 524288,
                "crc32": "45a7328f",
                "md5": "92461cd3f1a72b8beb32ebab98057b76",
                "sha1": "3d3ec05a11d808600752c89895f04d5213e532b6", 
                "notes": "European version",
                "header": True,
            }
        }
    
    def calculate_checksums(self, filepath: str) -> Dict[str, str]:
        """Calculate MD5, SHA1, and CRC32 checksums for a file"""
        md5_hash = hashlib.md5()
        sha1_hash = hashlib.sha1()
        
        try:
            with open(filepath, 'rb') as f:
                # Read in chunks to handle large files
                while chunk := f.read(8192):
                    md5_hash.update(chunk)
                    sha1_hash.update(chunk)
            
            # For CRC32, we need to read the file again (simpler approach)
            import zlib
            with open(filepath, 'rb') as f:
                crc32 = zlib.crc32(f.read()) & 0xffffffff
            
            return {
                'md5': md5_hash.hexdigest(),
                'sha1': sha1_hash.hexdigest(),
                'crc32': f"{crc32:08x}",
                'size': os.path.getsize(filepath)
            }
        except Exception as e:
            print(f"Error calculating checksums: {e}")
            return {}
    
    def identify_rom(self, filepath: str) -> Optional[str]:
        """Identify which ROM version this is"""
        checksums = self.calculate_checksums(filepath)
        
        for rom_name, rom_info in self.known_roms.items():
            if (checksums.get('md5', '').lower() == rom_info['md5'].lower() or
                checksums.get('sha1', '').lower() == rom_info['sha1'].lower() or
                checksums.get('crc32', '').lower() == rom_info['crc32'].lower()):
                return rom_name
        
        return None
    
    def check_rom_directory(self) -> bool:
        """Check if ROM directory exists and contains ROMs"""
        if not os.path.exists(self.rom_dir):
            print(f"ROM directory not found: {self.rom_dir}")
            return False
        
        print(f"Checking ROM directory: {self.rom_dir}")
        
        # List all .sfc files
        sfc_files = [f for f in os.listdir(self.rom_dir) if f.lower().endswith('.sfc')]
        
        if not sfc_files:
            print("No .sfc ROM files found in directory")
            return False
        
        print(f"Found {len(sfc_files)} ROM files:")
        
        # Analyze each ROM file
        for sfc_file in sfc_files:
            filepath = os.path.join(self.rom_dir, sfc_file)
            print(f"\n  {sfc_file}:")
            
            # Get file size
            size = os.path.getsize(filepath)
            print(f"    Size: {size} bytes ({size / 1024:.1f} KB)")
            
            # Try to identify the ROM
            rom_id = self.identify_rom(filepath)
            if rom_id:
                print(f"    Identified as: {rom_id}")
                print(f"    Notes: {self.known_roms[rom_id]['notes']}")
            else:
                print("    Unknown ROM (calculating checksums...)")
                checksums = self.calculate_checksums(filepath)
                print(f"    MD5: {checksums.get('md5', 'error')}")
                print(f"    SHA1: {checksums.get('sha1', 'error')}")
                print(f"    CRC32: {checksums.get('crc32', 'error')}")
        
        return True
    
    def verify_target_rom(self) -> bool:
        """Verify the target ROM exists and is correct"""
        target_path = os.path.join(self.rom_dir, self.target_rom)
        
        if not os.path.exists(target_path):
            print(f"Target ROM not found: {target_path}")
            print("\nLooking for alternative ROMs...")
            
            # Try to find any FFMQ ROM
            for rom_name, rom_info in self.known_roms.items():
                alt_path = os.path.join(self.rom_dir, rom_info['filename'])
                if os.path.exists(alt_path):
                    print(f"Found alternative ROM: {rom_info['filename']}")
                    print(f"Consider copying/renaming to: {self.target_rom}")
                    return False
            
            print("No FFMQ ROMs found. Please add ROM files to the roms/ directory.")
            return False
        
        # Verify the ROM
        rom_id = self.identify_rom(target_path)
        if rom_id:
            print(f"Target ROM verified: {rom_id}")
            return True
        else:
            print(f"Target ROM found but not recognized: {target_path}")
            return False
    
    def check_rom_header(self, filepath: str) -> bool:
        """Check if ROM has a copier header"""
        size = os.path.getsize(filepath)
        
        # Check if size suggests a header (512 bytes extra)
        if size % 1024 == 512:
            print(f"  ROM appears to have a 512-byte header")
            return True
        elif size % 1024 == 0:
            print(f"  ROM appears to be headerless")
            return False
        else:
            print(f"  ROM size unusual: {size} bytes")
            return False
    
    def create_development_copy(self) -> bool:
        """Create a clean copy of the ROM for development"""
        target_path = os.path.join(self.rom_dir, self.target_rom)
        
        if not os.path.exists(target_path):
            print("Target ROM not found for development copy")
            return False
        
        # Create a clean copy in the build directory
        os.makedirs("build", exist_ok=True)
        dev_copy_path = os.path.join("build", "base_rom.sfc")
        
        try:
            shutil.copy2(target_path, dev_copy_path)
            print(f"Created development copy: {dev_copy_path}")
            
            # Verify the copy
            if self.identify_rom(dev_copy_path):
                print("Development copy verified successfully")
                return True
            else:
                print("Warning: Development copy verification failed")
                return False
        except Exception as e:
            print(f"Error creating development copy: {e}")
            return False
    
    def create_rom_info_file(self) -> bool:
        """Create a ROM information file for reference"""
        info_path = "build/rom_info.txt"
        os.makedirs("build", exist_ok=True)
        
        try:
            with open(info_path, 'w') as f:
                f.write("Final Fantasy Mystic Quest - ROM Information\n")
                f.write("===========================================\n\n")
                
                # Write info about target ROM
                target_path = os.path.join(self.rom_dir, self.target_rom)
                if os.path.exists(target_path):
                    rom_id = self.identify_rom(target_path)
                    checksums = self.calculate_checksums(target_path)
                    
                    f.write(f"Development ROM: {self.target_rom}\n")
                    f.write(f"Identified as: {rom_id or 'Unknown'}\n")
                    f.write(f"Size: {checksums.get('size', 0)} bytes\n")
                    f.write(f"MD5: {checksums.get('md5', 'unknown')}\n")
                    f.write(f"SHA1: {checksums.get('sha1', 'unknown')}\n")
                    f.write(f"CRC32: {checksums.get('crc32', 'unknown')}\n\n")
                    
                    if self.check_rom_header(target_path):
                        f.write("Header: Present (512 bytes)\n")
                    else:
                        f.write("Header: Not present\n")
                
                f.write("\nKnown ROM Versions:\n")
                f.write("==================\n\n")
                
                for rom_name, rom_info in self.known_roms.items():
                    f.write(f"{rom_name}:\n")
                    f.write(f"  Filename: {rom_info['filename']}\n")
                    f.write(f"  Size: {rom_info['size']} bytes\n")
                    f.write(f"  MD5: {rom_info['md5']}\n")
                    f.write(f"  SHA1: {rom_info['sha1']}\n")
                    f.write(f"  CRC32: {rom_info['crc32']}\n")
                    f.write(f"  Notes: {rom_info['notes']}\n\n")
            
            print(f"ROM information saved: {info_path}")
            return True
        except Exception as e:
            print(f"Error creating ROM info file: {e}")
            return False
    
    def setup_rom_environment(self) -> bool:
        """Setup the complete ROM environment"""
        print("Setting up Final Fantasy Mystic Quest ROM environment...")
        print("=" * 60)
        
        # Check ROM directory
        if not self.check_rom_directory():
            return False
        
        print("\n" + "=" * 60)
        
        # Verify target ROM
        if not self.verify_target_rom():
            return False
        
        print("\n" + "=" * 60)
        
        # Create development copy
        if not self.create_development_copy():
            print("Warning: Could not create development copy")
        
        # Create ROM info file
        self.create_rom_info_file()
        
        print("\nROM environment setup complete!")
        print("\nNext steps:")
        print("1. Run 'make extract-assets' to extract game assets")
        print("2. Run 'make rom' to build the ROM")
        print("3. Run 'make test' to test in emulator")
        
        return True

def main():
    if len(sys.argv) > 1:
        rom_dir = sys.argv[1]
    else:
        rom_dir = "roms"
    
    config = FFMQROMConfig(rom_dir)
    success = config.setup_rom_environment()
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()