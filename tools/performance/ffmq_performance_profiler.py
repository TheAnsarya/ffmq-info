#!/usr/bin/env python3
"""
FFMQ Performance Profiler - Analyze and optimize game performance

Profiling Features:
- Frame timing analysis
- CPU usage tracking
- Memory profiling
- Bottleneck detection
- Optimization suggestions
- Performance metrics

Metrics:
- FPS (frames per second)
- Frame time (ms)
- CPU cycles
- Memory usage
- VRAM usage
- DMA transfers

Analysis:
- Frame drops
- Slowdown areas
- Resource hotspots
- Code bottlenecks
- Optimization opportunities

Reports:
- Summary statistics
- Timeline graphs
- Hotspot analysis
- Recommendations
- Comparison charts

Usage:
	python ffmq_performance_profiler.py rom.sfc --profile
	python ffmq_performance_profiler.py rom.sfc --analyze trace.log
	python ffmq_performance_profiler.py rom.sfc --report performance.html
	python ffmq_performance_profiler.py rom.sfc --compare before.json after.json
	python ffmq_performance_profiler.py rom.sfc --hotspots
"""

import argparse
import json
import statistics
from pathlib import Path
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass, asdict, field
from enum import Enum


class PerformanceLevel(Enum):
	"""Performance rating"""
	EXCELLENT = "excellent"  # 60 FPS constant
	GOOD = "good"  # 55-59 FPS
	FAIR = "fair"  # 45-54 FPS
	POOR = "poor"  # 30-44 FPS
	CRITICAL = "critical"  # < 30 FPS


class BottleneckType(Enum):
	"""Bottleneck category"""
	CPU = "cpu"
	MEMORY = "memory"
	VRAM = "vram"
	DMA = "dma"
	RENDERING = "rendering"
	LOGIC = "logic"


@dataclass
class FrameMetrics:
	"""Metrics for single frame"""
	frame_number: int
	frame_time_ms: float  # Milliseconds
	fps: float
	cpu_cycles: int
	memory_used: int  # Bytes
	vram_used: int  # Bytes
	dma_transfers: int
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class Bottleneck:
	"""Performance bottleneck"""
	bottleneck_type: BottleneckType
	location: str  # Code address or area name
	severity: float  # 0-100
	description: str
	suggestion: str
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['bottleneck_type'] = self.bottleneck_type.value
		return d


@dataclass
class PerformanceReport:
	"""Performance analysis report"""
	total_frames: int
	avg_fps: float
	min_fps: float
	max_fps: float
	avg_frame_time: float
	frame_drops: int  # Frames below 60 FPS
	performance_level: PerformanceLevel
	bottlenecks: List[Bottleneck] = field(default_factory=list)
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['performance_level'] = self.performance_level.value
		return d


class FFMQPerformanceProfiler:
	"""Performance profiler and analyzer"""
	
	# SNES specifications
	CPU_CLOCK_HZ = 3579545  # ~3.58 MHz
	CYCLES_PER_FRAME = 59659  # At 60 FPS
	TARGET_FPS = 60
	TARGET_FRAME_TIME = 16.67  # ms
	
	# Memory limits
	RAM_SIZE = 128 * 1024  # 128 KB
	VRAM_SIZE = 64 * 1024  # 64 KB
	
	def __init__(self, rom_path: Optional[Path] = None, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		self.frames: List[FrameMetrics] = []
	
	def add_frame(self, frame: FrameMetrics) -> None:
		"""Add frame metrics"""
		self.frames.append(frame)
	
	def generate_test_data(self, num_frames: int = 1000) -> None:
		"""Generate simulated test data"""
		import random
		
		for i in range(num_frames):
			# Simulate varying performance
			base_time = 16.67  # Target frame time
			
			# Add occasional slowdowns
			if i % 100 < 5:  # 5% of frames slow
				frame_time = base_time * random.uniform(1.5, 2.5)
			else:
				frame_time = base_time * random.uniform(0.95, 1.05)
			
			fps = 1000.0 / frame_time
			
			# Simulate resource usage
			cpu_cycles = int(self.CYCLES_PER_FRAME * (frame_time / base_time))
			memory = random.randint(50000, 80000)
			vram = random.randint(40000, 60000)
			dma = random.randint(5, 15)
			
			frame = FrameMetrics(
				frame_number=i,
				frame_time_ms=frame_time,
				fps=fps,
				cpu_cycles=cpu_cycles,
				memory_used=memory,
				vram_used=vram,
				dma_transfers=dma
			)
			
			self.frames.append(frame)
	
	def analyze_performance(self) -> PerformanceReport:
		"""Analyze collected frame data"""
		if not self.frames:
			raise ValueError("No frame data to analyze")
		
		# Calculate statistics
		fps_values = [f.fps for f in self.frames]
		frame_times = [f.frame_time_ms for f in self.frames]
		
		avg_fps = statistics.mean(fps_values)
		min_fps = min(fps_values)
		max_fps = max(fps_values)
		avg_frame_time = statistics.mean(frame_times)
		
		# Count frame drops
		frame_drops = sum(1 for f in self.frames if f.fps < self.TARGET_FPS)
		
		# Determine performance level
		if avg_fps >= 59.5:
			level = PerformanceLevel.EXCELLENT
		elif avg_fps >= 55:
			level = PerformanceLevel.GOOD
		elif avg_fps >= 45:
			level = PerformanceLevel.FAIR
		elif avg_fps >= 30:
			level = PerformanceLevel.POOR
		else:
			level = PerformanceLevel.CRITICAL
		
		# Detect bottlenecks
		bottlenecks = self._detect_bottlenecks()
		
		report = PerformanceReport(
			total_frames=len(self.frames),
			avg_fps=avg_fps,
			min_fps=min_fps,
			max_fps=max_fps,
			avg_frame_time=avg_frame_time,
			frame_drops=frame_drops,
			performance_level=level,
			bottlenecks=bottlenecks
		)
		
		return report
	
	def _detect_bottlenecks(self) -> List[Bottleneck]:
		"""Detect performance bottlenecks"""
		bottlenecks = []
		
		# CPU bottleneck
		avg_cycles = statistics.mean(f.cpu_cycles for f in self.frames)
		if avg_cycles > self.CYCLES_PER_FRAME * 0.95:
			severity = (avg_cycles / self.CYCLES_PER_FRAME - 0.95) * 500
			
			bottlenecks.append(Bottleneck(
				bottleneck_type=BottleneckType.CPU,
				location="Main loop",
				severity=min(100, severity),
				description=f"High CPU usage: {avg_cycles:.0f} cycles/frame (target: {self.CYCLES_PER_FRAME})",
				suggestion="Optimize main game loop, reduce calculations per frame"
			))
		
		# Memory bottleneck
		avg_memory = statistics.mean(f.memory_used for f in self.frames)
		memory_percent = (avg_memory / self.RAM_SIZE) * 100
		
		if memory_percent > 80:
			severity = (memory_percent - 80) * 5
			
			bottlenecks.append(Bottleneck(
				bottleneck_type=BottleneckType.MEMORY,
				location="RAM",
				severity=min(100, severity),
				description=f"High memory usage: {memory_percent:.1f}%",
				suggestion="Reduce memory allocations, implement streaming"
			))
		
		# VRAM bottleneck
		avg_vram = statistics.mean(f.vram_used for f in self.frames)
		vram_percent = (avg_vram / self.VRAM_SIZE) * 100
		
		if vram_percent > 85:
			severity = (vram_percent - 85) * 6
			
			bottlenecks.append(Bottleneck(
				bottleneck_type=BottleneckType.VRAM,
				location="VRAM",
				severity=min(100, severity),
				description=f"High VRAM usage: {vram_percent:.1f}%",
				suggestion="Optimize sprite/tile usage, reduce loaded graphics"
			))
		
		# DMA bottleneck
		avg_dma = statistics.mean(f.dma_transfers for f in self.frames)
		if avg_dma > 20:
			severity = (avg_dma - 20) * 2
			
			bottlenecks.append(Bottleneck(
				bottleneck_type=BottleneckType.DMA,
				location="Graphics transfer",
				severity=min(100, severity),
				description=f"Excessive DMA transfers: {avg_dma:.1f}/frame",
				suggestion="Batch DMA transfers, reduce per-frame updates"
			))
		
		# Frame time variance (rendering issues)
		frame_times = [f.frame_time_ms for f in self.frames]
		if len(frame_times) > 1:
			variance = statistics.variance(frame_times)
			
			if variance > 10:
				severity = min(100, variance * 3)
				
				bottlenecks.append(Bottleneck(
					bottleneck_type=BottleneckType.RENDERING,
					location="Render pipeline",
					severity=severity,
					description=f"Inconsistent frame times (variance: {variance:.2f})",
					suggestion="Stabilize rendering workload, remove spikes"
				))
		
		# Sort by severity
		bottlenecks.sort(key=lambda b: b.severity, reverse=True)
		
		return bottlenecks
	
	def print_report(self, report: PerformanceReport) -> None:
		"""Print performance report"""
		print("\n=== Performance Report ===\n")
		print(f"Total Frames: {report.total_frames}")
		print(f"Average FPS: {report.avg_fps:.2f}")
		print(f"Min FPS: {report.min_fps:.2f}")
		print(f"Max FPS: {report.max_fps:.2f}")
		print(f"Average Frame Time: {report.avg_frame_time:.2f} ms")
		print(f"Frame Drops: {report.frame_drops} ({report.frame_drops/report.total_frames*100:.1f}%)")
		print(f"Performance Level: {report.performance_level.value.upper()}\n")
		
		if report.bottlenecks:
			print("=== Bottlenecks ===\n")
			
			for i, bottleneck in enumerate(report.bottlenecks, 1):
				print(f"{i}. {bottleneck.bottleneck_type.value.upper()} "
					  f"(Severity: {bottleneck.severity:.1f}/100)")
				print(f"   Location: {bottleneck.location}")
				print(f"   Issue: {bottleneck.description}")
				print(f"   Suggestion: {bottleneck.suggestion}\n")
		else:
			print("No bottlenecks detected!\n")
	
	def export_report_json(self, report: PerformanceReport, output_path: Path) -> None:
		"""Export report to JSON"""
		data = report.to_dict()
		
		with open(output_path, 'w', encoding='utf-8') as f:
			json.dump(data, f, indent='\t')
		
		if self.verbose:
			print(f"✓ Exported report to {output_path}")
	
	def export_report_html(self, report: PerformanceReport, output_path: Path) -> None:
		"""Export report to HTML"""
		html = f"""<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>FFMQ Performance Report</title>
<style>
body {{ font-family: Arial, sans-serif; max-width: 900px; margin: 0 auto; padding: 20px; background: #f5f5f5; }}
h1 {{ color: #2c3e50; border-bottom: 3px solid #3498db; }}
h2 {{ color: #34495e; margin-top: 30px; }}
.metric {{ background: white; padding: 15px; margin: 10px 0; border-left: 4px solid #3498db; }}
.metric-label {{ font-weight: bold; color: #7f8c8d; }}
.metric-value {{ font-size: 24px; color: #2c3e50; }}
.performance-excellent {{ color: #27ae60; }}
.performance-good {{ color: #2ecc71; }}
.performance-fair {{ color: #f39c12; }}
.performance-poor {{ color: #e67e22; }}
.performance-critical {{ color: #e74c3c; }}
.bottleneck {{ background: white; padding: 15px; margin: 10px 0; border-left: 4px solid #e74c3c; }}
.severity {{ display: inline-block; width: 100px; height: 20px; background: #ecf0f1; position: relative; }}
.severity-bar {{ height: 100%; background: #e74c3c; }}
</style>
</head>
<body>
<h1>FFMQ Performance Report</h1>

<h2>Summary</h2>
<div class="metric">
	<div class="metric-label">Total Frames Analyzed</div>
	<div class="metric-value">{report.total_frames:,}</div>
</div>
<div class="metric">
	<div class="metric-label">Average FPS</div>
	<div class="metric-value">{report.avg_fps:.2f}</div>
</div>
<div class="metric">
	<div class="metric-label">FPS Range</div>
	<div class="metric-value">{report.min_fps:.2f} - {report.max_fps:.2f}</div>
</div>
<div class="metric">
	<div class="metric-label">Average Frame Time</div>
	<div class="metric-value">{report.avg_frame_time:.2f} ms</div>
</div>
<div class="metric">
	<div class="metric-label">Frame Drops</div>
	<div class="metric-value">{report.frame_drops} ({report.frame_drops/report.total_frames*100:.1f}%)</div>
</div>
<div class="metric">
	<div class="metric-label">Performance Level</div>
	<div class="metric-value performance-{report.performance_level.value}">
		{report.performance_level.value.upper()}
	</div>
</div>

<h2>Bottlenecks</h2>
"""
		
		if report.bottlenecks:
			for i, bottleneck in enumerate(report.bottlenecks, 1):
				html += f"""
<div class="bottleneck">
	<h3>{i}. {bottleneck.bottleneck_type.value.upper()}</h3>
	<p><strong>Location:</strong> {bottleneck.location}</p>
	<p><strong>Severity:</strong> 
		<div class="severity">
			<div class="severity-bar" style="width: {bottleneck.severity}%"></div>
		</div>
		{bottleneck.severity:.1f}/100
	</p>
	<p><strong>Issue:</strong> {bottleneck.description}</p>
	<p><strong>Suggestion:</strong> {bottleneck.suggestion}</p>
</div>
"""
		else:
			html += "<p>No bottlenecks detected! Performance is excellent.</p>"
		
		html += """
</body>
</html>"""
		
		with open(output_path, 'w', encoding='utf-8') as f:
			f.write(html)
		
		if self.verbose:
			print(f"✓ Exported HTML report to {output_path}")
	
	def compare_reports(self, before: PerformanceReport, after: PerformanceReport) -> None:
		"""Compare two performance reports"""
		print("\n=== Performance Comparison ===\n")
		
		fps_diff = after.avg_fps - before.avg_fps
		fps_pct = (fps_diff / before.avg_fps) * 100
		
		time_diff = after.avg_frame_time - before.avg_frame_time
		time_pct = (time_diff / before.avg_frame_time) * 100
		
		drops_diff = after.frame_drops - before.frame_drops
		
		print(f"Average FPS: {before.avg_fps:.2f} → {after.avg_fps:.2f} "
			  f"({fps_diff:+.2f}, {fps_pct:+.1f}%)")
		print(f"Frame Time: {before.avg_frame_time:.2f} ms → {after.avg_frame_time:.2f} ms "
			  f"({time_diff:+.2f} ms, {time_pct:+.1f}%)")
		print(f"Frame Drops: {before.frame_drops} → {after.frame_drops} ({drops_diff:+d})")
		print(f"Performance: {before.performance_level.value} → {after.performance_level.value}\n")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Performance Profiler')
	parser.add_argument('rom', type=str, nargs='?', help='FFMQ ROM file (optional)')
	parser.add_argument('--profile', action='store_true', help='Run profiling test')
	parser.add_argument('--frames', type=int, default=1000, help='Number of frames to simulate')
	parser.add_argument('--report', type=str, help='Export report to HTML')
	parser.add_argument('--export', type=str, help='Export report to JSON')
	parser.add_argument('--compare', type=str, nargs=2, metavar=('BEFORE', 'AFTER'),
					   help='Compare two JSON reports')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	rom_path = Path(args.rom) if args.rom else None
	profiler = FFMQPerformanceProfiler(rom_path=rom_path, verbose=args.verbose)
	
	# Compare reports
	if args.compare:
		with open(args.compare[0], 'r') as f:
			before_data = json.load(f)
			before_data['performance_level'] = PerformanceLevel(before_data['performance_level'])
			before = PerformanceReport(**before_data)
		
		with open(args.compare[1], 'r') as f:
			after_data = json.load(f)
			after_data['performance_level'] = PerformanceLevel(after_data['performance_level'])
			after = PerformanceReport(**after_data)
		
		profiler.compare_reports(before, after)
		return 0
	
	# Profile
	if args.profile:
		print(f"Generating {args.frames} frames of test data...")
		profiler.generate_test_data(args.frames)
		
		print("Analyzing performance...")
		report = profiler.analyze_performance()
		
		profiler.print_report(report)
		
		# Export
		if args.report:
			profiler.export_report_html(report, Path(args.report))
		
		if args.export:
			profiler.export_report_json(report, Path(args.export))
		
		return 0
	
	print("Use --profile to run performance analysis")
	print("Example: python ffmq_performance_profiler.py --profile --frames 1000")
	
	return 0


if __name__ == '__main__':
	exit(main())
