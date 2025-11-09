"""
Advanced Data Compression System for SNES ROMs
Implements multiple compression algorithms optimized for retro hardware.
"""

import struct
from typing import List, Tuple, Optional, Dict
from enum import Enum
from dataclasses import dataclass
import json


class CompressionType(Enum):
    """Compression algorithm types"""
    NONE = 0
    RLE = 1          # Run-Length Encoding
    LZSS = 2         # Lempel-Ziv-Storer-Szymanski
    LZ77 = 3         # LZ77 variant
    HUFFMAN = 4      # Huffman coding
    DELTA = 5        # Delta encoding
    BIT_PACKING = 6  # Bit-level packing


@dataclass
class CompressionStats:
    """Compression statistics"""
    original_size: int
    compressed_size: int
    ratio: float
    algorithm: CompressionType
    time_ms: float = 0.0
    
    def to_dict(self):
        return {
            'original_size': self.original_size,
            'compressed_size': self.compressed_size,
            'compression_ratio': round(self.ratio, 3),
            'savings_percent': round((1 - self.ratio) * 100, 1),
            'algorithm': self.algorithm.value,
            'time_ms': round(self.time_ms, 2)
        }


class RLECompressor:
    """Run-Length Encoding compressor"""
    
    @staticmethod
    def compress(data: bytes) -> bytes:
        """Compress data using RLE"""
        if not data:
            return b''
        
        compressed = bytearray()
        i = 0
        
        while i < len(data):
            # Count run length
            current_byte = data[i]
            run_length = 1
            
            while (i + run_length < len(data) and
                   data[i + run_length] == current_byte and
                   run_length < 127):
                run_length += 1
            
            # If run > 2, encode as run
            if run_length >= 3:
                compressed.append(0x80 | run_length)  # High bit set = run
                compressed.append(current_byte)
                i += run_length
            else:
                # Literal run
                literal_start = i
                literal_count = 0
                
                while (i < len(data) and literal_count < 127):
                    # Check if we hit a run
                    if i + 2 < len(data) and data[i] == data[i + 1] == data[i + 2]:
                        break
                    i += 1
                    literal_count += 1
                
                if literal_count > 0:
                    compressed.append(literal_count)  # High bit clear = literal
                    compressed.extend(data[literal_start:i])
        
        return bytes(compressed)
    
    @staticmethod
    def decompress(data: bytes) -> bytes:
        """Decompress RLE data"""
        decompressed = bytearray()
        i = 0
        
        while i < len(data):
            control = data[i]
            i += 1
            
            if control & 0x80:  # Run
                run_length = control & 0x7F
                if i < len(data):
                    byte_value = data[i]
                    i += 1
                    decompressed.extend([byte_value] * run_length)
            else:  # Literal
                literal_count = control
                if i + literal_count <= len(data):
                    decompressed.extend(data[i:i + literal_count])
                    i += literal_count
        
        return bytes(decompressed)


class LZSSCompressor:
    """LZSS compressor (Lempel-Ziv-Storer-Szymanski)"""
    
    def __init__(self, window_size: int = 4096, lookahead_size: int = 18):
        self.window_size = window_size
        self.lookahead_size = lookahead_size
    
    def compress(self, data: bytes) -> bytes:
        """Compress data using LZSS"""
        if not data:
            return b''
        
        compressed = bytearray()
        position = 0
        
        while position < len(data):
            # Find longest match in sliding window
            match_pos, match_len = self._find_longest_match(data, position)
            
            if match_len >= 3:  # Encode as reference
                # Format: 1 bit flag (1) + 12 bits offset + 4 bits length
                offset = position - match_pos
                compressed.append(0x80 | ((offset >> 8) & 0x0F))
                compressed.append(offset & 0xFF)
                compressed.append((match_len - 3) & 0x0F)
                position += match_len
            else:  # Encode as literal
                # Format: 1 bit flag (0) + 7 bits literal
                compressed.append(data[position] & 0x7F)
                position += 1
        
        return bytes(compressed)
    
    def _find_longest_match(self, data: bytes, position: int
                            ) -> Tuple[int, int]:
        """Find longest match in sliding window"""
        window_start = max(0, position - self.window_size)
        best_match_pos = position
        best_match_len = 0
        
        # Search window for matches
        for i in range(window_start, position):
            match_len = 0
            while (position + match_len < len(data) and
                   match_len < self.lookahead_size and
                   data[i + match_len] == data[position + match_len]):
                match_len += 1
            
            if match_len > best_match_len:
                best_match_pos = i
                best_match_len = match_len
        
        return best_match_pos, best_match_len
    
    def decompress(self, data: bytes) -> bytes:
        """Decompress LZSS data"""
        decompressed = bytearray()
        i = 0
        
        while i < len(data):
            control = data[i]
            i += 1
            
            if control & 0x80:  # Reference
                if i + 1 < len(data):
                    offset = ((control & 0x0F) << 8) | data[i]
                    i += 1
                    length = (data[i] & 0x0F) + 3
                    i += 1
                    
                    # Copy from window
                    copy_pos = len(decompressed) - offset
                    for _ in range(length):
                        if copy_pos < len(decompressed):
                            decompressed.append(decompressed[copy_pos])
                            copy_pos += 1
            else:  # Literal
                decompressed.append(control)
        
        return bytes(decompressed)


class DeltaCompressor:
    """Delta encoding compressor"""
    
    @staticmethod
    def compress(data: bytes) -> bytes:
        """Compress using delta encoding"""
        if not data:
            return b''
        
        compressed = bytearray()
        compressed.append(data[0])  # First byte as-is
        
        for i in range(1, len(data)):
            delta = (data[i] - data[i - 1]) & 0xFF
            compressed.append(delta)
        
        return bytes(compressed)
    
    @staticmethod
    def decompress(data: bytes) -> bytes:
        """Decompress delta encoded data"""
        if not data:
            return b''
        
        decompressed = bytearray()
        decompressed.append(data[0])
        
        for i in range(1, len(data)):
            value = (decompressed[i - 1] + data[i]) & 0xFF
            decompressed.append(value)
        
        return bytes(decompressed)


class BitPacker:
    """Bit-level data packing"""
    
    @staticmethod
    def pack_4bpp_to_3bpp(data: bytes) -> bytes:
        """Pack 4-bit pixels to 3-bit (16 colors -> 8 colors)"""
        packed = bytearray()
        
        # Process 8 pixels at a time (4 bytes -> 3 bytes)
        for i in range(0, len(data), 4):
            chunk = data[i:i + 4]
            if len(chunk) < 4:
                break
            
            # Extract 4-bit values
            pixels = []
            for byte in chunk:
                pixels.append((byte >> 4) & 0x0F)
                pixels.append(byte & 0x0F)
            
            # Convert to 3-bit (map 0-15 to 0-7)
            pixels_3bit = [p // 2 for p in pixels]
            
            # Pack 8 3-bit values into 3 bytes
            packed.append((pixels_3bit[0] << 5) | (pixels_3bit[1] << 2) |
                          (pixels_3bit[2] >> 1))
            packed.append(((pixels_3bit[2] & 1) << 7) | (pixels_3bit[3] << 4) |
                          (pixels_3bit[4] << 1) | (pixels_3bit[5] >> 2))
            packed.append(((pixels_3bit[5] & 3) << 6) | (pixels_3bit[6] << 3) |
                          pixels_3bit[7])
        
        return bytes(packed)
    
    @staticmethod
    def unpack_3bpp_to_4bpp(data: bytes) -> bytes:
        """Unpack 3-bit pixels to 4-bit"""
        unpacked = bytearray()
        
        # Process 3 bytes at a time
        for i in range(0, len(data), 3):
            chunk = data[i:i + 3]
            if len(chunk) < 3:
                break
            
            # Extract 3-bit values
            pixels = [
                (chunk[0] >> 5) & 0x07,
                (chunk[0] >> 2) & 0x07,
                ((chunk[0] & 0x03) << 1) | ((chunk[1] >> 7) & 0x01),
                (chunk[1] >> 4) & 0x07,
                (chunk[1] >> 1) & 0x07,
                ((chunk[1] & 0x01) << 2) | ((chunk[2] >> 6) & 0x03),
                (chunk[2] >> 3) & 0x07,
                chunk[2] & 0x07
            ]
            
            # Convert back to 4-bit (map 0-7 to 0-15)
            pixels_4bit = [p * 2 for p in pixels]
            
            # Pack into bytes
            for j in range(0, 8, 2):
                unpacked.append((pixels_4bit[j] << 4) | pixels_4bit[j + 1])
        
        return bytes(unpacked)


class CompressionManager:
    """Manage multiple compression algorithms"""
    
    def __init__(self):
        self.rle = RLECompressor()
        self.lzss = LZSSCompressor()
        self.delta = DeltaCompressor()
        self.bit_packer = BitPacker()
    
    def compress(self, data: bytes, algorithm: CompressionType) -> bytes:
        """Compress data with specified algorithm"""
        if algorithm == CompressionType.NONE:
            return data
        elif algorithm == CompressionType.RLE:
            return self.rle.compress(data)
        elif algorithm == CompressionType.LZSS:
            return self.lzss.compress(data)
        elif algorithm == CompressionType.DELTA:
            return self.delta.compress(data)
        elif algorithm == CompressionType.BIT_PACKING:
            return self.bit_packer.pack_4bpp_to_3bpp(data)
        else:
            return data
    
    def decompress(self, data: bytes, algorithm: CompressionType) -> bytes:
        """Decompress data"""
        if algorithm == CompressionType.NONE:
            return data
        elif algorithm == CompressionType.RLE:
            return self.rle.decompress(data)
        elif algorithm == CompressionType.LZSS:
            return self.lzss.decompress(data)
        elif algorithm == CompressionType.DELTA:
            return self.delta.decompress(data)
        elif algorithm == CompressionType.BIT_PACKING:
            return self.bit_packer.unpack_3bpp_to_4bpp(data)
        else:
            return data
    
    def find_best_algorithm(self, data: bytes) -> Tuple[CompressionType, bytes, CompressionStats]:
        """Find best compression algorithm for data"""
        best_algo = CompressionType.NONE
        best_compressed = data
        best_ratio = 1.0
        
        algorithms = [
            CompressionType.RLE,
            CompressionType.LZSS,
            CompressionType.DELTA,
            CompressionType.BIT_PACKING
        ]
        
        for algo in algorithms:
            try:
                compressed = self.compress(data, algo)
                ratio = len(compressed) / len(data) if len(data) > 0 else 1.0
                
                if ratio < best_ratio:
                    best_ratio = ratio
                    best_algo = algo
                    best_compressed = compressed
            except Exception:
                continue
        
        stats = CompressionStats(
            original_size=len(data),
            compressed_size=len(best_compressed),
            ratio=best_ratio,
            algorithm=best_algo
        )
        
        return best_algo, best_compressed, stats
    
    def analyze_data(self, data: bytes) -> Dict[str, any]:
        """Analyze data characteristics"""
        if not data:
            return {}
        
        # Count unique bytes
        unique_bytes = len(set(data))
        
        # Find runs
        max_run = 1
        current_run = 1
        for i in range(1, len(data)):
            if data[i] == data[i - 1]:
                current_run += 1
                max_run = max(max_run, current_run)
            else:
                current_run = 1
        
        # Calculate entropy (simplified)
        byte_counts = {}
        for byte in data:
            byte_counts[byte] = byte_counts.get(byte, 0) + 1
        
        entropy = 0.0
        for count in byte_counts.values():
            prob = count / len(data)
            if prob > 0:
                entropy -= prob * (prob.bit_length() - 1)
        
        return {
            'size': len(data),
            'unique_bytes': unique_bytes,
            'max_run_length': max_run,
            'entropy': round(entropy, 2),
            'compressibility': 'high' if max_run > 10 or unique_bytes < 50 else
                               'medium' if max_run > 5 or unique_bytes < 100 else 'low'
        }


class CompressionDatabase:
    """Track compressed data in ROM"""
    
    def __init__(self):
        self.entries = []
    
    def add_entry(self, offset: int, size: int, algorithm: CompressionType,
                  stats: CompressionStats, label: str = ""):
        """Add compressed data entry"""
        self.entries.append({
            'offset': offset,
            'compressed_size': size,
            'algorithm': algorithm.value,
            'stats': stats.to_dict(),
            'label': label
        })
    
    def export(self, filepath: str):
        """Export database"""
        with open(filepath, 'w') as f:
            json.dump({'entries': self.entries}, f, indent=2)
    
    def get_total_savings(self) -> int:
        """Calculate total space saved"""
        total_saved = 0
        for entry in self.entries:
            stats = entry['stats']
            saved = stats['original_size'] - stats['compressed_size']
            total_saved += saved
        return total_saved


def main():
    """Test compression system"""
    
    # Create test data
    test_cases = [
        # RLE-friendly: lots of runs
        bytes([0xFF] * 100 + [0x00] * 100 + [0xAA] * 50),
        
        # LZSS-friendly: repeated patterns
        bytes([i % 16 for i in range(256)] * 4),
        
        # Delta-friendly: sequential values
        bytes(range(256)),
        
        # Random: hard to compress
        bytes([i * 17 % 256 for i in range(256)])
    ]
    
    manager = CompressionManager()
    
    for i, data in enumerate(test_cases):
        print(f"\nTest Case {i + 1}:")
        print(f"Original size: {len(data)} bytes")
        
        # Analyze
        analysis = manager.analyze_data(data)
        print(f"Unique bytes: {analysis['unique_bytes']}")
        print(f"Max run: {analysis['max_run_length']}")
        print(f"Compressibility: {analysis['compressibility']}")
        
        # Find best algorithm
        algo, compressed, stats = manager.find_best_algorithm(data)
        print(f"\nBest algorithm: {algo.name}")
        print(f"Compressed size: {stats.compressed_size} bytes")
        print(f"Ratio: {stats.ratio:.3f} ({(1-stats.ratio)*100:.1f}% savings)")
        
        # Verify decompression
        decompressed = manager.decompress(compressed, algo)
        if decompressed == data:
            print("✓ Decompression verified")
        else:
            print("✗ Decompression failed!")
    
    # Database example
    db = CompressionDatabase()
    for i, data in enumerate(test_cases):
        algo, compressed, stats = manager.find_best_algorithm(data)
        db.add_entry(0x10000 + i * 1000, len(compressed), algo, stats,
                     f"TestData{i}")
    
    db.export("compression_db.json")
    print(f"\nTotal space saved: {db.get_total_savings()} bytes")
    print("Database exported to compression_db.json")


if __name__ == '__main__':
    main()
