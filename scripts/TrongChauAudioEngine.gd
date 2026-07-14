class_name TrongChauAudioEngine
extends Node

var _player_center: AudioStreamPlayer
var _player_edge: AudioStreamPlayer
var _player_hard: AudioStreamPlayer
var _player_soft: AudioStreamPlayer
var _player_rim: AudioStreamPlayer
var _player_roll: AudioStreamPlayer

var _players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	_player_center = _create_player("res://assets/audio/trong_chau/center_hit.mp3")
	_player_edge = _create_player("res://assets/audio/trong_chau/edge_hit.mp3")
	_player_hard = _create_player("res://assets/audio/trong_chau/hard_hit.mp3")
	_player_soft = _create_player("res://assets/audio/trong_chau/soft_hit.mp3")
	_player_rim = _create_player("res://assets/audio/trong_chau/rim_hit.mp3")
	_player_roll = _create_player("res://assets/audio/trong_chau/drum_roll.mp3")

func _create_player(path: String) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	var stream = load(path)
	if stream:
		player.stream = stream
	add_child(player)
	_players.append(player)
	return player

func play_center() -> void:
	_player_center.play()

func play_edge() -> void:
	_player_edge.play()

func play_rim() -> void:
	_player_rim.play()

func play_roll() -> void:
	_player_roll.play()

func play_soft() -> void:
	_player_soft.play()

func play_hard() -> void:
	_player_hard.play()

func stop_all() -> void:
	for player in _players:
		if player.playing:
			player.stop()
