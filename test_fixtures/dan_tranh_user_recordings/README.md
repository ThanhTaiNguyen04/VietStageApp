# Bản thu người dùng

Nguồn: `E:/amThanhDanTranh`, ngày 04/10/2026. Chuyển 15 file M4A sang WAV mono PCM 16-bit, 44.1 kHz bằng FFmpeg; giữ nguyên số dây trong tên gốc. Thiếu dây 7 và 10. Không thay đổi các bản gốc.

Chạy kiểm tra offline:

```powershell
godot --headless --path . --log-file ./recording-audit.log --script res://scratchpad/audit_user_strings.gd
```

Bảng đo và giới hạn kiểm tra: `docs/dan-tranh-recording-audit.md`. Các file này không được dùng để thay tần số chuẩn hoặc tự chấm mọi bản thu là đúng.
