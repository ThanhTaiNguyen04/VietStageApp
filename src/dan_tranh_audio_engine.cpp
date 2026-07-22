#include "dan_tranh_audio_engine.h"

#include <godot_cpp/classes/audio_stream.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/callable.hpp>

using namespace godot;

void DanTranhAudioEngine::_bind_methods() {
	ClassDB::bind_method(D_METHOD("configure_samples", "streams"), &DanTranhAudioEngine::configure_samples);
	ClassDB::bind_method(D_METHOD("play_sample", "string_index", "volume_db", "pitch_scale"), &DanTranhAudioEngine::play_sample, DEFVAL(-12.0f), DEFVAL(1.0f));
	ClassDB::bind_method(D_METHOD("stop_all"), &DanTranhAudioEngine::stop_all);
	ClassDB::bind_method(D_METHOD("is_playing"), &DanTranhAudioEngine::is_playing);
	ClassDB::bind_method(D_METHOD("get_sample_count"), &DanTranhAudioEngine::get_sample_count);
	ClassDB::bind_method(D_METHOD("_on_sample_finished", "string_index"), &DanTranhAudioEngine::_on_sample_finished);

	ADD_SIGNAL(MethodInfo("sample_started", PropertyInfo(Variant::INT, "string_index")));
	ADD_SIGNAL(MethodInfo("sample_finished", PropertyInfo(Variant::INT, "string_index")));
}

void DanTranhAudioEngine::configure_samples(const Array &streams) {
	stop_all();
	for (AudioStreamPlayer *player : players) {
		if (player != nullptr) {
			player->queue_free();
		}
	}
	players.clear();
	players.resize(streams.size());

	for (int i = 0; i < streams.size(); i++) {
		AudioStreamPlayer *player = memnew(AudioStreamPlayer);
		Ref<AudioStream> stream = streams[i];
		player->set_stream(stream);
		player->set_bus("Master");
		add_child(player);
		player->connect("finished", Callable(this, "_on_sample_finished").bind(i));
		players.write[i] = player;
	}
}

bool DanTranhAudioEngine::play_sample(int string_index, float volume_db, float pitch_scale) {
	if (string_index < 0 || string_index >= players.size()) {
		return false;
	}
	AudioStreamPlayer *player = players[string_index];
	if (player == nullptr || player->get_stream().is_null()) {
		return false;
	}
	player->stop();
	player->set_volume_db(volume_db);
	player->set_pitch_scale(pitch_scale);
	player->play();
	emit_signal("sample_started", string_index);
	return true;
}

void DanTranhAudioEngine::stop_all() {
	for (AudioStreamPlayer *player : players) {
		if (player != nullptr) {
			player->stop();
		}
	}
}

bool DanTranhAudioEngine::is_playing() const {
	for (AudioStreamPlayer *player : players) {
		if (player != nullptr && player->is_playing()) {
			return true;
		}
	}
	return false;
}

int DanTranhAudioEngine::get_sample_count() const {
	return players.size();
}

void DanTranhAudioEngine::_on_sample_finished(int string_index) {
	emit_signal("sample_finished", string_index);
}
