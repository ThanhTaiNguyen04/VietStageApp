# Bộ mẫu thu thật cho bộ lọc đàn tranh

Thư mục này dành cho bản thu thật, không dùng âm tổng hợp và không dùng
Kayageum/Guzheng thay cho đàn tranh Việt Nam.

## Chuẩn file

- WAV PCM 16-bit, mono, 44.1 kHz.
- Mỗi file dài 1–3 giây, không normalize riêng từng file.
- Giữ tiếng nền và khoảng cách micro giống lúc sử dụng ứng dụng.
- Với ba file đàn tranh, đặt lần gảy đầu tiên trong 100 ms đầu và thu ít nhất
  ba lần gảy rõ ở vùng dây thấp, giữa và cao.
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
- Tiếng gảy đàn tranh thật ở vùng thấp, giữa và cao.

Nên thu mỗi nhóm bằng ít nhất hai người, hai khoảng cách micro và hai mức âm
lượng. Khi đã thay đủ file đúng tên trong `manifest.json`, đổi `ready` thành
`true` rồi chạy:

```text
godot --headless --path . --script res://test_dan_tranh_real_audio.gd
```

Test cố ý dừng với mã lỗi nếu `ready` còn là `false`, thiếu category hoặc thiếu
file. Điều này ngăn bộ test báo xanh khi thực tế chỉ mới chạy âm tổng hợp.
