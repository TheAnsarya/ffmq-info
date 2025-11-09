#!/usr/bin/env python3
"""
SNES Memory Map Analyzer

Comprehensive tool for analyzing and visualizing SNES ROM memory layout.
Features include:
- ROM mapping detection (LoROM, HiROM, ExHiROM, SA-1)
- Bank analysis and visualization
- Header parsing (internal/external)
- Region detection (code vs data)
- Pattern analysis (repeated data, compression candidates)
- Entropy calculation
- String extraction (ASCII, Japanese)
- Graphical memory map visualization

Memory Mappings:
- LoROM: 32KB banks, $8000-$FFFF → ROM
- HiROM: 64KB banks, $0000-$FFFF → ROM
- ExHiROM: Extended HiROM (>4MB)
- SA-1: Special chip with BW-RAM
"""

from dataclasses import dataclass
from enum import Enum
from typing import Dict, List, Optional, Set, Tuple
import struct
import pygame


class ROMType(Enum):
    """ROM mapping types"""
    LOROM = "LoROM"
    HIROM = "HiROM"
    EXHIROM = "ExHiROM"
    SA1 = "SA-1"
    UNKNOWN = "Unknown"


class RegionType(Enum):
    """Memory region types"""
    CODE = "code"
    DATA = "data"
    TEXT = "text"
    GRAPHICS = "graphics"
    MUSIC = "music"
    EMPTY = "empty"
    HEADER = "header"
    VECTOR = "vector"


@dataclass
class ROMHeader:
    """SNES ROM header information"""
    title: str
    rom_type: int
    rom_size: int
    sram_size: int
    country_code: int
    developer_id: int
    version: int
    checksum: int
    checksum_complement: int
    
    # Derived info
    mapping_mode: ROMType
    has_sram: bool
    size_kb: int
    
    def is_valid(self) -> bool:
        """Check if header appears valid"""
        # Checksum complement should XOR to 0xFFFF
        if (self.checksum ^ self.checksum_complement) != 0xFFFF:
            return False
        
        # ROM size should be reasonable
        if self.rom_size > 13:  # Max 64Mbit
            return False
        
        # Country code should be valid
        if self.country_code > 15:
            return False
        
        return True


@dataclass
class MemoryRegion:
    """A region of memory"""
    start: int  # PC offset
    end: int
    region_type: RegionType
    entropy: float  # 0-8 bits
    unique_bytes: int
    description: str = ""
    
    def size(self) -> int:
        return self.end - self.start
    
    def get_color(self) -> Tuple[int, int, int]:
        """Get color for visualization"""
        colors = {
            RegionType.CODE: (100, 200, 100),      # Green
            RegionType.DATA: (100, 150, 255),      # Blue
            RegionType.TEXT: (255, 200, 100),      # Orange
            RegionType.GRAPHICS: (200, 100, 200),  # Purple
            RegionType.MUSIC: (255, 150, 150),     # Pink
            RegionType.EMPTY: (80, 80, 80),        # Dark gray
            RegionType.HEADER: (255, 255, 100),    # Yellow
            RegionType.VECTOR: (255, 100, 100),    # Red
        }
        return colors.get(self.region_type, (128, 128, 128))


@dataclass
class BankInfo:
    """Information about a ROM bank"""
    bank_number: int
    pc_offset: int
    size: int
    entropy: float
    unique_bytes: int
    regions: List[MemoryRegion]
    
    def is_empty(self) -> bool:
        """Check if bank is mostly empty"""
        return self.unique_bytes < 16


class MemoryMapAnalyzer:
    """Main memory map analyzer"""
    
    def __init__(self, rom_data: bytes):
        self.rom_data = rom_data
        self.rom_type = ROMType.UNKNOWN
        self.header: Optional[ROMHeader] = None
        self.banks: List[BankInfo] = []
        self.regions: List[MemoryRegion] = []
        
        # Analyze ROM
        self._detect_mapping()
        self._parse_header()
        self._analyze_banks()
        self._detect_regions()
    
    def _detect_mapping(self):
        """Detect ROM mapping type"""
        size = len(self.rom_data)
        
        # Try to find valid header
        # LoROM header at $7FB0 (PC: $7FB0 or $FFB0)
        # HiROM header at $FFB0 (PC: $FFB0)
        
        lorom_score = 0
        hirom_score = 0
        
        # Check LoROM header location
        if size > 0x8000:
            header_offset = 0x7FB0 if size <= 0x8000 else 0xFFB0
            if header_offset + 0x30 <= size:
                header = self._try_parse_header(header_offset)
                if header and header.is_valid():
                    lorom_score = 10
                    if (header.rom_type & 0x01) == 0:  # LoROM bit
                        lorom_score += 5
        
        # Check HiROM header location
        if size > 0xFFB0:
            header = self._try_parse_header(0xFFB0)
            if header and header.is_valid():
                hirom_score = 10
                if (header.rom_type & 0x01) == 1:  # HiROM bit
                    hirom_score += 5
        
        # Determine mapping
        if lorom_score > hirom_score:
            self.rom_type = ROMType.LOROM
        elif hirom_score > 0:
            self.rom_type = ROMType.HIROM
        else:
            self.rom_type = ROMType.UNKNOWN
    
    def _try_parse_header(self, offset: int) -> Optional[ROMHeader]:
        """Try to parse header at given offset"""
        try:
            if offset + 0x30 > len(self.rom_data):
                return None
            
            data = self.rom_data[offset:offset + 0x30]
            
            # Parse header fields
            title = data[0:21].decode('ascii', errors='ignore').strip('\x00')
            rom_type = data[0x15]
            rom_size = data[0x17]
            sram_size = data[0x18]
            country = data[0x19]
            developer = data[0x1A]
            version = data[0x1B]
            checksum_comp = struct.unpack('<H', data[0x1C:0x1E])[0]
            checksum = struct.unpack('<H', data[0x1E:0x20])[0]
            
            # Determine mapping mode
            mapping = ROMType.UNKNOWN
            map_mode = rom_type & 0x0F
            if map_mode == 0:
                mapping = ROMType.LOROM
            elif map_mode == 1:
                mapping = ROMType.HIROM
            elif map_mode == 5:
                mapping = ROMType.EXHIROM
            elif map_mode == 3:
                mapping = ROMType.SA1
            
            # Calculate ROM size
            size_kb = 1 << rom_size if rom_size < 14 else 0
            
            return ROMHeader(
                title=title,
                rom_type=rom_type,
                rom_size=rom_size,
                sram_size=sram_size,
                country_code=country,
                developer_id=developer,
                version=version,
                checksum=checksum,
                checksum_complement=checksum_comp,
                mapping_mode=mapping,
                has_sram=sram_size > 0,
                size_kb=size_kb
            )
        except Exception:
            return None
    
    def _parse_header(self):
        """Parse ROM header"""
        if self.rom_type == ROMType.LOROM:
            offset = 0xFFB0 if len(self.rom_data) > 0x8000 else 0x7FB0
        elif self.rom_type == ROMType.HIROM:
            offset = 0xFFB0
        else:
            offset = 0xFFB0
        
        self.header = self._try_parse_header(offset)
    
    def _calculate_entropy(self, data: bytes) -> float:
        """Calculate Shannon entropy of data (0-8 bits)"""
        if len(data) == 0:
            return 0.0
        
        # Count byte frequencies
        freq = [0] * 256
        for byte in data:
            freq[byte] += 1
        
        # Calculate entropy
        entropy = 0.0
        total = len(data)
        for count in freq:
            if count > 0:
                p = count / total
                entropy -= p * (p.bit_length() - 1)  # Approximate log2
        
        return entropy
    
    def _analyze_banks(self):
        """Analyze ROM banks"""
        if self.rom_type == ROMType.LOROM:
            bank_size = 0x8000  # 32KB
        elif self.rom_type in (ROMType.HIROM, ROMType.EXHIROM):
            bank_size = 0x10000  # 64KB
        else:
            bank_size = 0x8000
        
        num_banks = (len(self.rom_data) + bank_size - 1) // bank_size
        
        for i in range(num_banks):
            offset = i * bank_size
            end = min(offset + bank_size, len(self.rom_data))
            bank_data = self.rom_data[offset:end]
            
            # Calculate entropy
            entropy = self._calculate_entropy(bank_data)
            
            # Count unique bytes
            unique = len(set(bank_data))
            
            self.banks.append(BankInfo(
                bank_number=i,
                pc_offset=offset,
                size=len(bank_data),
                entropy=entropy,
                unique_bytes=unique,
                regions=[]
            ))
    
    def _detect_regions(self):
        """Detect different memory regions"""
        # Split into chunks for analysis
        chunk_size = 0x1000  # 4KB chunks
        
        for i in range(0, len(self.rom_data), chunk_size):
            end = min(i + chunk_size, len(self.rom_data))
            chunk = self.rom_data[i:end]
            
            # Calculate metrics
            entropy = self._calculate_entropy(chunk)
            unique = len(set(chunk))
            
            # Classify region based on entropy and patterns
            region_type = self._classify_chunk(chunk, entropy, unique)
            
            self.regions.append(MemoryRegion(
                start=i,
                end=end,
                region_type=region_type,
                entropy=entropy,
                unique_bytes=unique
            ))
    
    def _classify_chunk(self, data: bytes, entropy: float, unique: int) -> RegionType:
        """Classify a chunk of data"""
        size = len(data)
        
        # Check for empty/unused
        if unique < 4:
            return RegionType.EMPTY
        
        # Check for text (high ratio of printable ASCII)
        printable = sum(1 for b in data if 0x20 <= b < 0x7F)
        if printable > size * 0.7:
            return RegionType.TEXT
        
        # Check for graphics (moderate entropy, many unique bytes)
        if 3.0 < entropy < 6.0 and unique > 100:
            # Look for tile patterns (repeating 8-byte or 16-byte chunks)
            if self._has_tile_pattern(data):
                return RegionType.GRAPHICS
        
        # Check for code (high entropy, varied bytes)
        if entropy > 5.0 and unique > 200:
            return RegionType.CODE
        
        # Check for music data (look for APU patterns)
        if self._has_music_pattern(data):
            return RegionType.MUSIC
        
        # Default to data
        return RegionType.DATA
    
    def _has_tile_pattern(self, data: bytes) -> bool:
        """Check for graphics tile patterns"""
        # Look for repeating 8-byte patterns (2bpp tiles)
        if len(data) < 16:
            return False
        
        patterns_8 = {}
        for i in range(0, len(data) - 7, 8):
            pattern = data[i:i + 8]
            patterns_8[pattern] = patterns_8.get(pattern, 0) + 1
        
        # If many patterns repeat, likely tiles
        repeating = sum(1 for count in patterns_8.values() if count > 1)
        return repeating > len(patterns_8) * 0.3
    
    def _has_music_pattern(self, data: bytes) -> bool:
        """Check for music/sound data patterns"""
        if len(data) < 32:
            return False
        
        # Look for BRR header patterns (common in SNES music)
        # BRR blocks start with header byte
        brr_headers = 0
        for i in range(0, len(data) - 9, 9):
            header = data[i]
            # Check for valid BRR header bits
            if (header & 0x0C) == 0 or (header & 0xF0) in [0x00, 0x10, 0x20, 0x30]:
                brr_headers += 1
        
        return brr_headers > (len(data) // 9) * 0.5
    
    def find_strings(self, min_length: int = 4) -> List[Tuple[int, str]]:
        """Find ASCII strings in ROM"""
        strings = []
        current_string = []
        start_offset = 0
        
        for i, byte in enumerate(self.rom_data):
            if 0x20 <= byte < 0x7F:  # Printable ASCII
                if not current_string:
                    start_offset = i
                current_string.append(chr(byte))
            else:
                if len(current_string) >= min_length:
                    strings.append((start_offset, ''.join(current_string)))
                current_string = []
        
        return strings
    
    def find_repeated_data(self, min_size: int = 16, min_repeats: int = 3) -> List[Tuple[bytes, List[int]]]:
        """Find repeated data patterns"""
        patterns: Dict[bytes, List[int]] = {}
        
        for i in range(0, len(self.rom_data) - min_size):
            pattern = self.rom_data[i:i + min_size]
            if pattern not in patterns:
                patterns[pattern] = []
            patterns[pattern].append(i)
        
        # Filter to patterns that repeat enough
        repeated = [(pattern, offsets) for pattern, offsets in patterns.items() 
                    if len(offsets) >= min_repeats]
        
        # Sort by total size (pattern size * repeats)
        repeated.sort(key=lambda x: len(x[0]) * len(x[1]), reverse=True)
        
        return repeated
    
    def get_compression_candidates(self) -> List[MemoryRegion]:
        """Find regions that would benefit from compression"""
        candidates = []
        
        for region in self.regions:
            # Low entropy and moderate unique bytes = good compression candidate
            if region.entropy < 4.0 and 16 < region.unique_bytes < 200:
                if region.region_type not in (RegionType.EMPTY, RegionType.CODE):
                    candidates.append(region)
        
        return candidates
    
    def export_report(self, filename: str):
        """Export analysis report"""
        with open(filename, 'w') as f:
            f.write("SNES ROM Memory Map Analysis Report\n")
            f.write("=" * 70 + "\n\n")
            
            # ROM info
            f.write(f"ROM Size: {len(self.rom_data):,} bytes ({len(self.rom_data) // 1024}KB)\n")
            f.write(f"Mapping Mode: {self.rom_type.value}\n")
            f.write(f"Number of Banks: {len(self.banks)}\n\n")
            
            # Header info
            if self.header:
                f.write("ROM Header Information:\n")
                f.write(f"  Title: {self.header.title}\n")
                f.write(f"  Mapping: {self.header.mapping_mode.value}\n")
                f.write(f"  ROM Size: {self.header.size_kb}KB\n")
                f.write(f"  SRAM: {'Yes' if self.header.has_sram else 'No'}\n")
                f.write(f"  Country: {self.header.country_code}\n")
                f.write(f"  Version: {self.header.version}\n")
                f.write(f"  Checksum: ${self.header.checksum:04X}\n")
                f.write(f"  Checksum Valid: {self.header.is_valid()}\n\n")
            
            # Bank summary
            f.write("Bank Summary:\n")
            f.write("-" * 70 + "\n")
            f.write(f"{'Bank':<6} {'Offset':<10} {'Size':<8} {'Entropy':<8} {'Unique':<8} {'Status'}\n")
            f.write("-" * 70 + "\n")
            
            for bank in self.banks:
                status = "Empty" if bank.is_empty() else "Used"
                f.write(f"{bank.bank_number:<6} ${bank.pc_offset:06X}   {bank.size:<8} "
                       f"{bank.entropy:>6.2f}   {bank.unique_bytes:<8} {status}\n")
            
            f.write("\n")
            
            # Region summary
            region_counts = {}
            for region in self.regions:
                region_counts[region.region_type] = region_counts.get(region.region_type, 0) + 1
            
            f.write("Region Type Summary:\n")
            f.write("-" * 40 + "\n")
            for region_type, count in sorted(region_counts.items(), key=lambda x: x[1], reverse=True):
                total_size = sum(r.size() for r in self.regions if r.region_type == region_type)
                f.write(f"{region_type.value:<12}: {count:>4} regions, {total_size:>8,} bytes\n")
            
            f.write("\n")
            
            # Strings found
            strings = self.find_strings()
            if strings:
                f.write(f"Text Strings Found: {len(strings)}\n")
                f.write("-" * 70 + "\n")
                for offset, string in strings[:20]:  # Show first 20
                    f.write(f"${offset:06X}: {string[:50]}\n")
                if len(strings) > 20:
                    f.write(f"  ... and {len(strings) - 20} more\n")
                f.write("\n")
            
            # Compression candidates
            candidates = self.get_compression_candidates()
            if candidates:
                f.write(f"Compression Candidates: {len(candidates)}\n")
                total_size = sum(c.size() for c in candidates)
                f.write(f"Total Size: {total_size:,} bytes\n")
                f.write("-" * 70 + "\n")
                for region in candidates[:10]:
                    f.write(f"${region.start:06X}-${region.end:06X} "
                           f"({region.size():>6,} bytes, entropy {region.entropy:.2f})\n")
                f.write("\n")


class MemoryMapVisualizer:
    """Interactive memory map visualizer"""
    
    def __init__(self, analyzer: MemoryMapAnalyzer, width: int = 1200, height: int = 800):
        self.analyzer = analyzer
        self.width = width
        self.height = height
        self.running = True
        
        pygame.init()
        self.screen = pygame.display.set_mode((width, height))
        pygame.display.set_caption("SNES Memory Map Visualizer")
        self.clock = pygame.time.Clock()
        
        self.font = pygame.font.Font(None, 20)
        self.small_font = pygame.font.Font(None, 16)
        
        # View state
        self.view_offset = 0
        self.bytes_per_row = 256
        self.zoom = 1.0
        self.selected_region: Optional[MemoryRegion] = None
    
    def run(self):
        """Main visualization loop"""
        while self.running:
            self._handle_events()
            self._render()
            self.clock.tick(60)
        
        pygame.quit()
    
    def _handle_events(self):
        """Handle user input"""
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self.running = False
            
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    self.running = False
                elif event.key == pygame.K_UP:
                    self.view_offset = max(0, self.view_offset - self.bytes_per_row * 16)
                elif event.key == pygame.K_DOWN:
                    self.view_offset = min(len(self.analyzer.rom_data), 
                                          self.view_offset + self.bytes_per_row * 16)
                elif event.key == pygame.K_PAGEUP:
                    self.view_offset = max(0, self.view_offset - self.bytes_per_row * 64)
                elif event.key == pygame.K_PAGEDOWN:
                    self.view_offset = min(len(self.analyzer.rom_data), 
                                          self.view_offset + self.bytes_per_row * 64)
                elif event.key == pygame.K_HOME:
                    self.view_offset = 0
                elif event.key == pygame.K_END:
                    self.view_offset = max(0, len(self.analyzer.rom_data) - self.bytes_per_row * 32)
            
            elif event.type == pygame.MOUSEBUTTONDOWN:
                if event.button == 1:  # Left click
                    self._handle_click(event.pos)
                elif event.button == 4:  # Scroll up
                    self.view_offset = max(0, self.view_offset - self.bytes_per_row * 4)
                elif event.button == 5:  # Scroll down
                    self.view_offset = min(len(self.analyzer.rom_data), 
                                          self.view_offset + self.bytes_per_row * 4)
    
    def _handle_click(self, pos: Tuple[int, int]):
        """Handle mouse click"""
        x, y = pos
        
        # Check if clicking in map area
        if 200 < x < self.width - 300 and 100 < y < self.height - 50:
            # Calculate byte offset
            map_width = self.width - 500
            pixel_x = x - 200
            pixel_y = y - 100
            
            byte_offset = self.view_offset + (pixel_y * self.bytes_per_row)
            
            # Find region at this offset
            for region in self.analyzer.regions:
                if region.start <= byte_offset < region.end:
                    self.selected_region = region
                    break
    
    def _render(self):
        """Render visualization"""
        self.screen.fill((20, 20, 30))
        
        # Draw title
        title = self.font.render("SNES ROM Memory Map", True, (255, 255, 255))
        self.screen.blit(title, (20, 20))
        
        # Draw ROM info
        if self.analyzer.header:
            info = self.small_font.render(f"{self.analyzer.header.title} - "
                                         f"{len(self.analyzer.rom_data) // 1024}KB - "
                                         f"{self.analyzer.rom_type.value}", True, (200, 200, 200))
            self.screen.blit(info, (20, 50))
        
        # Draw memory map
        self._draw_memory_map()
        
        # Draw legend
        self._draw_legend()
        
        # Draw selected region info
        if self.selected_region:
            self._draw_region_info()
        
        pygame.display.flip()
    
    def _draw_memory_map(self):
        """Draw the memory map visualization"""
        map_x = 200
        map_y = 100
        map_width = self.width - 500
        map_height = self.height - 150
        
        # Background
        pygame.draw.rect(self.screen, (30, 30, 40), (map_x, map_y, map_width, map_height))
        
        # Calculate bytes visible
        pixels_per_byte = map_width / self.bytes_per_row
        visible_rows = int(map_height / pixels_per_byte)
        end_offset = min(self.view_offset + visible_rows * self.bytes_per_row, 
                        len(self.analyzer.rom_data))
        
        # Draw regions
        for region in self.analyzer.regions:
            if region.end < self.view_offset or region.start > end_offset:
                continue
            
            # Calculate position
            start = max(region.start, self.view_offset)
            end = min(region.end, end_offset)
            
            for offset in range(start, end):
                relative_offset = offset - self.view_offset
                row = relative_offset // self.bytes_per_row
                col = relative_offset % self.bytes_per_row
                
                x = map_x + col * pixels_per_byte
                y = map_y + row * pixels_per_byte
                
                color = region.get_color()
                pygame.draw.rect(self.screen, color, (x, y, pixels_per_byte + 1, pixels_per_byte + 1))
        
        # Draw selection
        if self.selected_region:
            start = max(self.selected_region.start, self.view_offset)
            end = min(self.selected_region.end, end_offset)
            
            if start < end:
                # Draw outline
                for offset in [start, end - 1]:
                    relative_offset = offset - self.view_offset
                    row = relative_offset // self.bytes_per_row
                    col = relative_offset % self.bytes_per_row
                    
                    x = map_x + col * pixels_per_byte
                    y = map_y + row * pixels_per_byte
                    
                    pygame.draw.rect(self.screen, (255, 255, 0), 
                                   (x - 1, y - 1, pixels_per_byte + 2, pixels_per_byte + 2), 2)
        
        # Draw border
        pygame.draw.rect(self.screen, (100, 100, 120), (map_x, map_y, map_width, map_height), 2)
        
        # Draw offset labels
        offset_text = self.small_font.render(f"Offset: ${self.view_offset:06X}", True, (200, 200, 200))
        self.screen.blit(offset_text, (map_x, map_y - 25))
    
    def _draw_legend(self):
        """Draw color legend"""
        legend_x = self.width - 280
        legend_y = 100
        
        title = self.font.render("Legend", True, (255, 255, 255))
        self.screen.blit(title, (legend_x, legend_y))
        
        y = legend_y + 30
        for region_type in RegionType:
            color = MemoryRegion(0, 0, region_type, 0, 0).get_color()
            
            # Color box
            pygame.draw.rect(self.screen, color, (legend_x, y, 20, 20))
            pygame.draw.rect(self.screen, (100, 100, 120), (legend_x, y, 20, 20), 1)
            
            # Label
            label = self.small_font.render(region_type.value, True, (200, 200, 200))
            self.screen.blit(label, (legend_x + 30, y + 2))
            
            y += 25
    
    def _draw_region_info(self):
        """Draw selected region information"""
        info_x = 20
        info_y = self.height - 120
        
        # Background
        pygame.draw.rect(self.screen, (40, 40, 50), (info_x, info_y, 700, 100))
        pygame.draw.rect(self.screen, (100, 100, 120), (info_x, info_y, 700, 100), 2)
        
        # Title
        title = self.font.render("Selected Region", True, (255, 255, 255))
        self.screen.blit(title, (info_x + 10, info_y + 10))
        
        # Info
        region = self.selected_region
        info_lines = [
            f"Type: {region.region_type.value}",
            f"Offset: ${region.start:06X} - ${region.end:06X} ({region.size():,} bytes)",
            f"Entropy: {region.entropy:.2f} bits",
            f"Unique bytes: {region.unique_bytes}",
        ]
        
        y = info_y + 35
        for line in info_lines:
            text = self.small_font.render(line, True, (200, 200, 200))
            self.screen.blit(text, (info_x + 10, y))
            y += 20


def main():
    """Test memory map analyzer"""
    # Create a test ROM
    import random
    
    test_rom = bytearray(0x40000)  # 256KB test ROM
    
    # Add header at LoROM location
    header_offset = 0xFFB0
    test_rom[header_offset:header_offset + 21] = b'TEST ROM FFMQ HACK\x00\x00\x00'
    test_rom[header_offset + 0x15] = 0x20  # LoROM
    test_rom[header_offset + 0x17] = 9     # 512KB
    test_rom[header_offset + 0x18] = 3     # 8KB SRAM
    test_rom[header_offset + 0x19] = 1     # USA
    test_rom[header_offset + 0x1A] = 0x33  # Developer
    test_rom[header_offset + 0x1B] = 1     # Version 1
    
    # Calculate checksum
    checksum = sum(test_rom) & 0xFFFF
    complement = checksum ^ 0xFFFF
    test_rom[header_offset + 0x1C:header_offset + 0x1E] = struct.pack('<H', complement)
    test_rom[header_offset + 0x1E:header_offset + 0x20] = struct.pack('<H', checksum)
    
    # Add some code
    for i in range(0x8000, 0x9000):
        test_rom[i] = random.randint(0x00, 0xFF)
    
    # Add some graphics (tile-like patterns)
    for i in range(0x10000, 0x18000):
        test_rom[i] = (i % 256)
    
    # Add some text
    text = b"FINAL FANTASY MYSTIC QUEST - A SQUARE GAME FOR THE SUPER NINTENDO"
    test_rom[0x20000:0x20000 + len(text)] = text
    
    # Analyze
    analyzer = MemoryMapAnalyzer(bytes(test_rom))
    
    # Print analysis
    print("Memory Map Analysis")
    print("=" * 60)
    print(f"ROM Type: {analyzer.rom_type.value}")
    print(f"ROM Size: {len(test_rom):,} bytes")
    print(f"Banks: {len(analyzer.banks)}")
    print(f"Regions: {len(analyzer.regions)}")
    
    if analyzer.header:
        print(f"\nHeader: {analyzer.header.title}")
        print(f"Valid: {analyzer.header.is_valid()}")
    
    # Export report
    analyzer.export_report("memory_map_report.txt")
    print("\nReport exported to memory_map_report.txt")
    
    # Launch visualizer
    print("\nLaunching visualizer...")
    visualizer = MemoryMapVisualizer(analyzer)
    visualizer.run()


if __name__ == "__main__":
    main()
