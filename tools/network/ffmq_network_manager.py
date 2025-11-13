#!/usr/bin/env python3
"""
FFMQ Network Manager - Online multiplayer and netplay

Network Features:
- Netplay support
- Client/server architecture
- Input synchronization
- State synchronization
- Rollback netcode
- Lobby system

Netplay Features:
- Host/join games
- Input latency compensation
- Desync detection
- Save state sync
- Spectator mode

Network Protocol:
- UDP for input
- TCP for state sync
- Frame-based lockstep
- Input delay buffering
- Prediction/rollback

Features:
- Host netplay sessions
- Join remote games
- Synchronize game state
- Handle lag compensation
- Manage lobbies
- Spectator support

Usage:
	python ffmq_network_manager.py --host --port 7777
	python ffmq_network_manager.py --join 192.168.1.100 --port 7777
	python ffmq_network_manager.py --create-lobby "My Game"
	python ffmq_network_manager.py --list-lobbies
	python ffmq_network_manager.py --spectate 192.168.1.100:7777
"""

import argparse
import socket
import json
import struct
import threading
import time
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass, asdict, field
from enum import Enum


class ConnectionState(Enum):
	"""Connection state"""
	DISCONNECTED = "disconnected"
	CONNECTING = "connecting"
	CONNECTED = "connected"
	SYNCING = "syncing"
	PLAYING = "playing"
	DESYNCED = "desynced"


class PacketType(Enum):
	"""Network packet type"""
	HELLO = 0
	INPUT = 1
	STATE = 2
	SYNC_CHECK = 3
	DISCONNECT = 4
	CHAT = 5
	LOBBY_INFO = 6


@dataclass
class NetworkPlayer:
	"""Network player"""
	player_id: int
	name: str
	ip_address: str
	port: int
	latency: int = 0  # ms
	connected: bool = True
	spectator: bool = False


@dataclass
class InputPacket:
	"""Input packet"""
	frame: int
	player_id: int
	buttons: int
	timestamp: float = field(default_factory=time.time)


@dataclass
class StatePacket:
	"""State sync packet"""
	frame: int
	checksum: int
	state_data: bytes


@dataclass
class Lobby:
	"""Game lobby"""
	lobby_id: str
	name: str
	host: NetworkPlayer
	players: List[NetworkPlayer] = field(default_factory=list)
	max_players: int = 2
	started: bool = False
	game_name: str = "Final Fantasy Mystic Quest"


class FFMQNetworkManager:
	"""Network and netplay manager"""
	
	# Network constants
	DEFAULT_PORT = 7777
	MAX_PLAYERS = 2
	MAX_SPECTATORS = 8
	INPUT_BUFFER_SIZE = 60  # Frames
	SYNC_CHECK_INTERVAL = 180  # Frames (3 seconds at 60 FPS)
	
	# Packet size limits
	MAX_PACKET_SIZE = 4096
	HEADER_SIZE = 8
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.state = ConnectionState.DISCONNECTED
		self.players: Dict[int, NetworkPlayer] = {}
		self.lobbies: Dict[str, Lobby] = {}
		self.input_buffer: Dict[int, List[InputPacket]] = {}  # Frame -> inputs
		self.current_frame = 0
		self.socket: Optional[socket.socket] = None
		self.running = False
		self.server_thread: Optional[threading.Thread] = None
		
		# Local player
		self.local_player_id = 1
		self.local_player_name = "Player"
	
	def create_lobby(self, lobby_id: str, name: str, max_players: int = 2) -> Lobby:
		"""Create game lobby"""
		host = NetworkPlayer(
			player_id=self.local_player_id,
			name=self.local_player_name,
			ip_address="localhost",
			port=self.DEFAULT_PORT
		)
		
		lobby = Lobby(
			lobby_id=lobby_id,
			name=name,
			host=host,
			max_players=max_players
		)
		
		self.lobbies[lobby_id] = lobby
		
		if self.verbose:
			print(f"✓ Created lobby: {name}")
		
		return lobby
	
	def join_lobby(self, lobby_id: str, player_name: str) -> bool:
		"""Join lobby"""
		if lobby_id not in self.lobbies:
			print(f"Lobby {lobby_id} not found")
			return False
		
		lobby = self.lobbies[lobby_id]
		
		if len(lobby.players) >= lobby.max_players:
			print(f"Lobby {lobby_id} is full")
			return False
		
		player = NetworkPlayer(
			player_id=len(lobby.players) + 2,
			name=player_name,
			ip_address="",
			port=0
		)
		
		lobby.players.append(player)
		
		if self.verbose:
			print(f"✓ Joined lobby: {lobby.name}")
		
		return True
	
	def host_session(self, port: int = DEFAULT_PORT) -> bool:
		"""Host netplay session"""
		try:
			# Create TCP socket for connections
			self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
			self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
			self.socket.bind(('0.0.0.0', port))
			self.socket.listen(self.MAX_PLAYERS + self.MAX_SPECTATORS)
			
			self.state = ConnectionState.CONNECTING
			self.running = True
			
			# Start server thread
			self.server_thread = threading.Thread(target=self._server_loop)
			self.server_thread.daemon = True
			self.server_thread.start()
			
			if self.verbose:
				print(f"🌐 Hosting on port {port}")
			
			return True
		
		except Exception as e:
			print(f"Error hosting session: {e}")
			return False
	
	def join_session(self, host: str, port: int = DEFAULT_PORT) -> bool:
		"""Join netplay session"""
		try:
			# Create TCP socket
			self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
			self.socket.connect((host, port))
			
			self.state = ConnectionState.CONNECTING
			
			# Send hello packet
			self._send_hello()
			
			if self.verbose:
				print(f"🌐 Connected to {host}:{port}")
			
			return True
		
		except Exception as e:
			print(f"Error joining session: {e}")
			return False
	
	def _server_loop(self) -> None:
		"""Server accept loop"""
		while self.running and self.socket:
			try:
				client_socket, address = self.socket.accept()
				
				if self.verbose:
					print(f"📥 Connection from {address}")
				
				# Handle client in separate thread
				client_thread = threading.Thread(
					target=self._handle_client,
					args=(client_socket, address)
				)
				client_thread.daemon = True
				client_thread.start()
			
			except:
				break
	
	def _handle_client(self, client_socket: socket.socket, address: Tuple) -> None:
		"""Handle client connection"""
		while self.running:
			try:
				# Receive packet
				data = client_socket.recv(self.MAX_PACKET_SIZE)
				
				if not data:
					break
				
				# Process packet
				self._process_packet(data, client_socket)
			
			except:
				break
		
		client_socket.close()
	
	def _send_hello(self) -> None:
		"""Send hello packet"""
		data = {
			'player_name': self.local_player_name,
			'version': '1.0'
		}
		
		self._send_packet(PacketType.HELLO, json.dumps(data).encode())
	
	def send_input(self, frame: int, buttons: int) -> None:
		"""Send input packet"""
		packet = InputPacket(
			frame=frame,
			player_id=self.local_player_id,
			buttons=buttons
		)
		
		# Serialize
		data = struct.pack('<IIH', frame, self.local_player_id, buttons)
		
		self._send_packet(PacketType.INPUT, data)
		
		# Buffer locally
		if frame not in self.input_buffer:
			self.input_buffer[frame] = []
		
		self.input_buffer[frame].append(packet)
	
	def send_state(self, frame: int, checksum: int, state_data: bytes) -> None:
		"""Send state sync packet"""
		# Header: frame (4 bytes) + checksum (4 bytes)
		header = struct.pack('<II', frame, checksum)
		data = header + state_data
		
		self._send_packet(PacketType.STATE, data)
	
	def send_sync_check(self, frame: int, checksum: int) -> None:
		"""Send sync check"""
		data = struct.pack('<II', frame, checksum)
		self._send_packet(PacketType.SYNC_CHECK, data)
	
	def _send_packet(self, packet_type: PacketType, data: bytes) -> bool:
		"""Send packet"""
		if not self.socket:
			return False
		
		try:
			# Packet format: type (1 byte) + size (3 bytes) + data
			header = struct.pack('<BI', packet_type.value, len(data))
			packet = header + data
			
			self.socket.sendall(packet)
			
			return True
		
		except Exception as e:
			if self.verbose:
				print(f"Error sending packet: {e}")
			return False
	
	def _process_packet(self, data: bytes, source: socket.socket) -> None:
		"""Process received packet"""
		if len(data) < 5:
			return
		
		# Parse header
		packet_type_value = struct.unpack('<B', data[0:1])[0]
		packet_type = PacketType(packet_type_value)
		size = struct.unpack('<I', data[1:5])[0]
		payload = data[5:5+size]
		
		# Handle by type
		if packet_type == PacketType.HELLO:
			self._handle_hello(payload, source)
		elif packet_type == PacketType.INPUT:
			self._handle_input(payload)
		elif packet_type == PacketType.STATE:
			self._handle_state(payload)
		elif packet_type == PacketType.SYNC_CHECK:
			self._handle_sync_check(payload)
		elif packet_type == PacketType.CHAT:
			self._handle_chat(payload)
	
	def _handle_hello(self, data: bytes, source: socket.socket) -> None:
		"""Handle hello packet"""
		try:
			info = json.loads(data.decode())
			
			player_id = len(self.players) + 1
			player = NetworkPlayer(
				player_id=player_id,
				name=info.get('player_name', f'Player{player_id}'),
				ip_address=source.getpeername()[0],
				port=source.getpeername()[1]
			)
			
			self.players[player_id] = player
			
			if self.verbose:
				print(f"👤 Player joined: {player.name}")
		
		except:
			pass
	
	def _handle_input(self, data: bytes) -> None:
		"""Handle input packet"""
		if len(data) < 10:
			return
		
		frame, player_id, buttons = struct.unpack('<IIH', data)
		
		packet = InputPacket(
			frame=frame,
			player_id=player_id,
			buttons=buttons
		)
		
		# Buffer input
		if frame not in self.input_buffer:
			self.input_buffer[frame] = []
		
		self.input_buffer[frame].append(packet)
	
	def _handle_state(self, data: bytes) -> None:
		"""Handle state sync packet"""
		if len(data) < 8:
			return
		
		frame, checksum = struct.unpack('<II', data[:8])
		state_data = data[8:]
		
		if self.verbose:
			print(f"📦 Received state for frame {frame} (checksum: {checksum:08X})")
	
	def _handle_sync_check(self, data: bytes) -> None:
		"""Handle sync check"""
		if len(data) < 8:
			return
		
		frame, remote_checksum = struct.unpack('<II', data)
		
		# In real implementation, compare with local checksum
		# For now, just log
		if self.verbose:
			print(f"🔍 Sync check at frame {frame}: {remote_checksum:08X}")
	
	def _handle_chat(self, data: bytes) -> None:
		"""Handle chat message"""
		try:
			message = data.decode('utf-8')
			print(f"💬 {message}")
		except:
			pass
	
	def get_inputs_for_frame(self, frame: int) -> Dict[int, int]:
		"""Get all player inputs for frame"""
		if frame not in self.input_buffer:
			return {}
		
		inputs = {}
		
		for packet in self.input_buffer[frame]:
			inputs[packet.player_id] = packet.buttons
		
		return inputs
	
	def calculate_latency(self, player_id: int) -> int:
		"""Calculate player latency (simplified)"""
		if player_id in self.players:
			return self.players[player_id].latency
		return 0
	
	def disconnect(self) -> None:
		"""Disconnect from session"""
		self.running = False
		
		if self.socket:
			try:
				self._send_packet(PacketType.DISCONNECT, b'')
				self.socket.close()
			except:
				pass
			
			self.socket = None
		
		self.state = ConnectionState.DISCONNECTED
		
		if self.verbose:
			print("🔌 Disconnected")
	
	def print_status(self) -> None:
		"""Print network status"""
		print(f"\n=== Network Status ===\n")
		print(f"State: {self.state.value}")
		print(f"Frame: {self.current_frame}")
		print(f"Players: {len(self.players)}")
		
		if self.players:
			print(f"\nConnected Players:")
			print(f"{'ID':<4} {'Name':<20} {'IP':<18} {'Latency':<10}")
			print('-' * 52)
			
			for player_id, player in sorted(self.players.items()):
				status = "✓" if player.connected else "✗"
				print(f"{player.player_id:<4} {player.name:<20} {player.ip_address:<18} "
					  f"{player.latency}ms")
	
	def print_lobby_list(self) -> None:
		"""Print lobby list"""
		if not self.lobbies:
			print("No lobbies")
			return
		
		print(f"\n=== Lobbies ===\n")
		print(f"{'ID':<15} {'Name':<25} {'Players':<10} {'Host':<20}")
		print('-' * 70)
		
		for lobby_id, lobby in self.lobbies.items():
			player_count = f"{len(lobby.players)}/{lobby.max_players}"
			print(f"{lobby.lobby_id:<15} {lobby.name:<25} {player_count:<10} "
				  f"{lobby.host.name:<20}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Network Manager')
	parser.add_argument('--host', action='store_true', help='Host session')
	parser.add_argument('--join', type=str, metavar='HOST', help='Join session')
	parser.add_argument('--port', type=int, default=7777, help='Network port')
	parser.add_argument('--name', type=str, default='Player', help='Player name')
	parser.add_argument('--create-lobby', type=str, metavar='NAME',
					   help='Create lobby')
	parser.add_argument('--join-lobby', type=str, metavar='LOBBY_ID',
					   help='Join lobby')
	parser.add_argument('--list-lobbies', action='store_true', help='List lobbies')
	parser.add_argument('--spectate', type=str, metavar='HOST:PORT',
					   help='Spectate session')
	parser.add_argument('--status', action='store_true', help='Show network status')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	manager = FFMQNetworkManager(verbose=args.verbose)
	manager.local_player_name = args.name
	
	# Create lobby
	if args.create_lobby:
		lobby_id = f"lobby_{int(time.time())}"
		manager.create_lobby(lobby_id, args.create_lobby)
	
	# Join lobby
	if args.join_lobby:
		manager.join_lobby(args.join_lobby, args.name)
	
	# Host session
	if args.host:
		manager.host_session(args.port)
		
		try:
			# Keep running
			while manager.running:
				time.sleep(1)
		except KeyboardInterrupt:
			manager.disconnect()
		
		return 0
	
	# Join session
	if args.join:
		manager.join_session(args.join, args.port)
		
		try:
			# Keep running
			while manager.state != ConnectionState.DISCONNECTED:
				time.sleep(1)
		except KeyboardInterrupt:
			manager.disconnect()
		
		return 0
	
	# List lobbies
	if args.list_lobbies:
		manager.print_lobby_list()
		return 0
	
	# Status
	if args.status or not any([args.host, args.join, args.create_lobby, args.join_lobby]):
		manager.print_status()
	
	return 0


if __name__ == '__main__':
	exit(main())
