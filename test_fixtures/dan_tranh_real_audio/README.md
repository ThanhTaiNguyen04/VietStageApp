# Bộ mẫu thu thật cho bộ lọc đàn tranh

Thư mục này dành cho bản thu thật, không dùng âm tổng hợp và không dùng
Kayageum/Guzheng thay cho đàn tranh Việt Nam.

## Chuẩn file

- WAV PCM 16-bit, mono, 44.1 kHz.
- Mỗi file dài 1–3 giây, không normalize riêng từng file.
- Giữ tiếng nền và khoảng cách micro giống lúc sử dụng ứng dụng.
- Với 17 file `string_*.wav`, mỗi file chỉ gảy dây được ghi trong tên file.
  Đặt một lần gảy rõ trong 100 ms đầu, để tiếng ngân tự nhiên và không đọc tên
  nốt trong lúc thu. Không đổi cao độ hoặc normalize riêng từng file.
- Bốn file `technique_*.wav` lần lượt thu Á, Nhấn, Rung và Vê bằng đàn tranh
  thật. Mỗi file phải bắt đầu bằng một tiếng gảy rõ trong 100 ms đầu để bộ lọc
  kiểm tra được transient của dây đàn.
- `speaker_playback.wav` phải được thu lại bằng micro khi âm thanh đang phát từ
  loa điện thoại/laptop; không đưa file loa gốc trực tiếp vào bộ test.

## Nội dung bắt buộc

- Nói bình thường.
- Hát đúng một nốt đàn tranh mục tiêu.
- Ngân dài.
- Luyến từ nốt thấp lên nốt cao.
- Hát có vocal vibrato.
- Gõ lên bàn/vỏ đàn, vỗ tay, nhiễu phòng.
- Âm thanh được micro thu lại từ loa.
- Tiếng gảy riêng từng dây đàn tranh từ dây 1 đến dây 17.
- Bản thu thật của Á, Nhấn, Rung và Vê.

Nên thu nhóm giọng nói/tạp âm bằng ít nhất hai người, hai khoảng cách micro và
hai mức âm lượng. Khi đã thêm đủ file đúng tên trong `manifest.json`, nghe lại
để xác nhận không vỡ tiếng, rồi đổi `ready` thành `true` và chạy:

```text
godot --headless --path . --script res://test_dan_tranh_real_audio.gd
```

Test cố ý dừng với mã lỗi nếu `ready` còn là `false`, thiếu category hoặc thiếu
file. Điều này ngăn bộ test báo xanh khi thực tế chỉ mới chạy âm tổng hợp.
