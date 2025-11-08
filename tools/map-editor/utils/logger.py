#!/usr/bin/env python3
"""
Logging utilities for FFMQ Map Editor
"""

import logging
import sys
from pathlib import Path
from datetime import datetime

def setup_logger(name: str, log_file: str = None, level=logging.INFO) -> logging.Logger:
	"""Set up a logger with console and file handlers"""
	
	logger = logging.getLogger(name)
	logger.setLevel(level)
	
	# Remove existing handlers
	logger.handlers = []
	
	# Create formatter
	formatter = logging.Formatter(
		'%(asctime)s - %(name)s - %(levelname)s - %(message)s',
		datefmt='%Y-%m-%d %H:%M:%S'
	)
	
	# Console handler
	console_handler = logging.StreamHandler(sys.stdout)
	console_handler.setLevel(level)
	console_handler.setFormatter(formatter)
	logger.addHandler(console_handler)
	
	# File handler (if log_file specified)
	if log_file:
		log_path = Path(log_file)
		log_path.parent.mkdir(parents=True, exist_ok=True)
		
		file_handler = logging.FileHandler(log_path)
		file_handler.setLevel(level)
		file_handler.setFormatter(formatter)
		logger.addHandler(file_handler)
	else:
		# Default log file in logs directory
		log_dir = Path(__file__).parent.parent / 'logs'
		log_dir.mkdir(exist_ok=True)
		
		timestamp = datetime.now().strftime('%Y%m%d')
		log_file = log_dir / f'map_editor_{timestamp}.log'
		
		file_handler = logging.FileHandler(log_file)
		file_handler.setLevel(level)
		file_handler.setFormatter(formatter)
		logger.addHandler(file_handler)
	
	return logger
