#ifndef DAN_TRANH_AUDIO_ENGINE_H
#define DAN_TRANH_AUDIO_ENGINE_H

#include <godot_cpp/classes/audio_stream_player.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/templates/vector.hpp>
#include <godot_cpp/variant/array.hpp>

using namespace godot;

class DanTranhAudioEngine : public Node {
	GDCLASS(DanTranhAudioEngine, Node);

protected:
	static void _bind_methods();

private:
	Vector<AudioStreamPlayer *> players;
	void _on_sample_finished(int string_index);

public:
	DanTranhAudioEngine() = default;
	~DanTranhAudioEngine() override = default;

	void configure_samples(const Array &streams);
	bool play_sample(int string_index, float volume_db = -12.0f, float pitch_scale = 1.0f);
	void stop_all();
	bool is_playing() const;
	int get_sample_count() const;
};

#endif
