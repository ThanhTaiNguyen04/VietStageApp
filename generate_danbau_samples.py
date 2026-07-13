import wave
import struct
import math
import random

# Tần số của 6 nốt (từ cao xuống thấp)
notes = [
    ("dan_bau_do6.wav", 1046.50), # Đố
    ("dan_bau_sol5.wav", 783.99), # Sol
    ("dan_bau_mi5.wav", 659.25),  # Mi
    ("dan_bau_do5.wav", 523.25),  # Đô
    ("dan_bau_sol4.wav", 392.00), # Sol
    ("dan_bau_do4.wav", 261.63)   # Đồ
]

sample_rate = 44100
duration = 3.5 # Độ dài mỗi file (giây)

for filename, freq in notes:
    print(f"Generating {filename} ({freq} Hz)...")
    
    # Số lượng sample
    num_samples = int(sample_rate * duration)
    
    # Karplus-Strong Algorithm parameters
    delay_len = int(sample_rate / freq)
    buffer = [random.uniform(-1.0, 1.0) for _ in range(delay_len)]
    
    # Áp dụng Low-pass filter ngay từ đầu để bớt tiếng chói của noise
    for i in range(1, delay_len):
        buffer[i] = 0.5 * (buffer[i] + buffer[i-1])
    
    audio_data = []
    pos = 0
    
    # Độ ngân dài hơn cho tần số thấp, ngắn hơn cho tần số cao
    decay = 1.0 - (1.0 / (delay_len * (15.0 + freq * 0.01)))
    decay = min(max(decay, 0.999), 0.9999)

    for i in range(num_samples):
        # Karplus-Strong averaging filter
        next_pos = (pos + 1) % delay_len
        out = decay * 0.5 * (buffer[pos] + buffer[next_pos])
        
        # Lưu lại vào buffer
        buffer[pos] = out
        
        # Thêm Harmonic Overtone để tạo tiếng "bồi âm" (trong trẻo hơn)
        t = i / sample_rate
        # Envelope cho tiếng gảy (nhỏ dần)
        env = math.exp(-t * 2.5) 
        harmonic_blend = out + (math.sin(2 * math.pi * freq * 2 * t) * 0.1 * env)
        
        # Convert to 16-bit integer
        val = int(max(min(harmonic_blend, 1.0), -1.0) * 32767.0)
        audio_data.append(val)
        
        pos = next_pos

    # Lưu thành file wav
    filepath = f"assets/audio/{filename}"
    with wave.open(filepath, 'w') as wav_file:
        wav_file.setnchannels(1) # Mono
        wav_file.setsampwidth(2) # 2 bytes = 16 bit
        wav_file.setframerate(sample_rate)
        
        # Pack data to binary
        binary_data = struct.pack('<' + 'h' * num_samples, *audio_data)
        wav_file.writeframes(binary_data)
        
print("Hoàn tất tạo 6 file .wav multi-sample!")
