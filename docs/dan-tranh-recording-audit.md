# Đối chiếu bản thu đàn tranh ngày 04/10/2026

Nguồn: `E:/amThanhDanTranh`, 15 file M4A, chuyển mono PCM 44.1 kHz bằng FFmpeg. Thiếu dây 7 và 10.

Đo bằng YIN C++, lấy trung vị ba cửa sổ 4096 mẫu sau đỉnh tiếng gảy. Đây là kiểm tra file thu, chưa phải kiểm thử microphone trực tiếp. Chấm theo cao độ chuẩn, sai số cho phép ±65 cents. Không tự thay tần số chuẩn bằng bản thu lệch âm.

| Dây | Chuẩn (Hz) | Đo (Hz) | Lệch (cents) | Khuyến nghị |
|---|---:|---:|---:|---|
| 1 | 196.00 | 203.21 | +62.6 | Trong ngưỡng |
| 2 | 220.00 | 211.94 | -64.7 | Trong ngưỡng |
| 3 | 261.63 | 258.78 | -19.0 | Trong ngưỡng |
| 4 | 293.66 | 291.03 | -15.6 | Trong ngưỡng |
| 5 | 329.63 | 314.71 | -80.2 | Cần chỉnh tăng |
| 6 | 392.00 | 386.18 | -25.9 | Trong ngưỡng |
| 8 | 523.25 | 521.45 | -6.0 | Trong ngưỡng |
| 9 | 587.33 | 573.24 | -42.0 | Trong ngưỡng |
| 11 | 783.99 | 732.04 | -118.7 | Cần chỉnh tăng |
| 12 | 880.00 | 832.18 | -96.7 | Cần chỉnh tăng |
| 13 | 1046.50 | 964.44 | -141.4 | Cần chỉnh tăng |
| 14 | 1174.66 | 1060.53 | -176.9 | Cần chỉnh tăng |
| 15 | 1318.51 | 1106.93 | -302.8 | Cần chỉnh tăng |
| 16 | 1567.98 | 1311.65 | -309.0 | Cần chỉnh tăng |
| 17 | 1760.00 | 1707.32 | -52.6 | Trong ngưỡng |

Ở cửa sổ gần đỉnh được đo riêng, dây 11, 13 và 15 bị bộ lọc từ chối vì cao độ không gần tần số dây chuẩn. Khi xử lý toàn bộ bản thu, những cửa sổ khác có thể được nhận diện thành nốt khác; không nới ngưỡng để chấm nhầm dây. Chỉ những dây trong ±65 cents mới đủ điều kiện cao độ.

## Lỗi lesson và xác minh

- `LessonDanTranh._process_practice()` từng đọc `analyzer._pitch_history`, thuộc tính không tồn tại. Test runtime tái hiện lỗi ngay sau khi cao độ được xác nhận, trước khi nốt được đánh dấu `hit`. Đã bỏ phân tích contour sai khỏi luồng gảy nốt đơn; các bài Nhấn/Rung có lịch sử và bộ chấm riêng.
- Dừng lời AI trực tiếp bằng `AudioStreamPlayer.stop()` không phát `tts_finished`, khiến khóa micro không được mở. Lesson dùng `AIAudioManager.stop_speech()` để kết thúc hàng đợi, vô hiệu callback cũ và phát tín hiệu kết thúc; giữ cooldown 0,4 giây.
- Fallback GDScript trước đây chấp nhận mọi âm vượt ngưỡng với confidence 90%. Nay chạy cùng các tiêu chí tiếng gảy/độ suy giảm/âm sắc như nhánh native và yêu cầu đủ cửa sổ phân tích. Ngưỡng late decay tăng từ 0,05 lên 0,25 dB để loại mẫu phụ âm rồi nguyên âm; 15 bản thu được đối chiếu trên cả hai nhánh.
- Loại chấp nhận tự động dây cao hơn một quãng tám cho Sol1/La1. UI phân biệt “Đúng cao độ · đang xác nhận nốt” với “CHÍNH XÁC” khi đã hoàn tất nốt.

Godot 4.7.2, kiểm tra đã chạy:

```powershell
godot --headless --path . --log-file ./lesson-audit.log res://scratchpad/audit_lesson_runtime.tscn --quit-after 300
godot --headless --path . --log-file ./filter-audit.log --script res://test_dan_tranh_instrument_filter.gd --quit-after 300
godot --headless --path . --log-file ./tts-audit.log --script res://scratchpad/audit_tts_stop_lock.gd --quit-after 300
godot --headless --path . --log-file ./recording-audit.log --script res://scratchpad/audit_user_strings.gd --quit-after 300
```

Kết quả: PASS cho runtime lesson với 17 cao độ mô phỏng, từ chối sai quãng tám, khóa/mở micro sau cooldown, xác nhận nốt và di chuyển nốt kế tiếp; PASS cho bộ lọc mẫu tiếng gảy/giọng nói/gõ/nhiễu mô phỏng; PASS dừng và kết thúc TTS; PASS đối chiếu native/fallback trên 15 bản thu và không loại các bản thu trong ngưỡng ±65 cents. Test lesson còn cảnh báo 4 ObjectDB instances lúc thoát.

Bộ `test_dan_tranh_pluck_flow.gd` khi chạy dưới scene có autoload còn 8 lỗi về onset/Á/Vê. Đã đối chiếu bằng nguồn HEAD trong bản sao riêng: cùng 8 lỗi đã tồn tại trước sửa, cộng thêm hai lỗi nhận nhầm hum/click đã hết ở bản sửa. Không tuyên bố toàn bộ kỹ thuật đã qua kiểm thử. Chạy trực tiếp một số test SceneTree bằng `--script` không khởi tạo autoload `BackendReport` đúng thời điểm; runner scene dùng project autoload để kiểm tra lesson.

Godot import tài nguyên đã hoàn tất; editor có cảnh báo UID trùng scene, cổng EditorFileServer 6010 và lỗi ghi editor settings ngoài workspace. Chưa xuất bản build cho điện thoại; chưa xác minh microphone/loa thực tế hoặc hiệu năng fallback trên iOS/Xogot. Bộ bản thu này thiếu dây 7, 10 và không gồm bản thu đối chứng giọng nói/tạp âm thật.

## Kiểm tra bổ sung toàn bộ bản thu qua lesson

```powershell
godot --headless --path . --log-file ./recording-lesson-flow.log res://scratchpad/audit_recording_lesson_flow.tscn --quit-after 1200
```

Runner thay nguồn microphone bằng PCM của từng bản thu, đưa các khung 735 mẫu qua `AudioCaptureAnalyzer._process()` thực tế, sau đó gọi `LessonDanTranh._process_practice()`. Không tự đặt cao độ hay đánh dấu `hit` trong test. Đã chạy dưới Godot, mix rate 44.1 kHz, kết quả PASS trên cả 15 file:

- Dây 1, 2, 3, 4, 6, 8, 9, 17: được lesson tự đánh dấu `hit=true` theo cao độ chuẩn.
- Dây 5, 11, 12, 13, 14, 15, 16: không hoàn tất nốt mục tiêu vì lệch cao độ. Ví dụ dây 13 có thể nhận thành Si3, dây 14 thành Đô4, dây 16 thành Mi4; tên file không được dùng để ép nốt nhận diện.

Đây là kiểm thử offline luồng phân tích và chấm nốt đơn trên bản thu thật. Không kiểm tra quyền microphone, phần cứng, bus lọc âm, phản hồi loa hoặc tính thời gian thực trên điện thoại. Runner còn cảnh báo 4 ObjectDB instances khi thoát. Kiểm tra nốt kế tiếp di chuyển sau xác nhận nằm trong `audit_lesson_runtime.tscn`.

## Nới nhẹ cho các bài nhập môn Level 1–2

Theo yêu cầu thực hành dễ hơn, ngưỡng qua nốt đơn ở Level 1–2 tăng từ ±65 lên ±80 cents. Cao độ chuẩn không đổi. Level 3 trở lên giữ ±65 cents; vẫn không chấp nhận dây khác hoặc sai quãng tám. Thời gian báo sai ở Level 1–2 tăng từ 0,02 lên 0,18 giây để bỏ qua sai số thoáng qua.

Sau khi hoàn tất một lần gảy, lesson ghi lại generation của attack đó. Tiếng ngân của cùng attack không được dùng để báo sai nốt tiếp theo hoặc hoàn tất thêm một nốt; một attack mới vẫn được chấm bình thường.

Đã chạy `audit_lesson_runtime.tscn`: PASS cho sai số 75 cents ở nhập môn, từ chối 90 cents/sai dây/sai quãng tám, giữ ngưỡng Level 3, bỏ qua tiếng ngân Sol1 khi chuyển La1, chấm lần gảy La1 mới, chưa báo sai ở 32 ms nhưng phản hồi âm sai kéo dài quá 180 ms. Test còn cảnh báo 8 ObjectDB instances khi thoát.

Đã chạy thêm:

```powershell
godot --headless --path . --log-file ./beginner-recordings.log res://scratchpad/audit_recording_lesson_flow.tscn --quit-after 1200 -- --beginner
```

PASS cho toàn bộ 6 bản thu dây đầu qua luồng phân tích/chấm thực tế ở chế độ nhập môn, gồm dây 5 được chấp nhận ở phần đầu tiếng gảy trong ±80 cents. Trung vị bản thu dây 5 vẫn lệch khoảng -80 cents: nên chỉnh âm cho ổn định. Không dùng kết quả này để khẳng định microphone thực tế trên điện thoại hoặc toàn bộ kỹ thuật đã được xác minh. Test bản thu còn cảnh báo 6 ObjectDB instances khi thoát.

## Nốt cuối bài gảy ngón 2

Đổi trường độ Mi2 cuối Bài 4.1 (`dan_tranh_level_1_bai_8_practice`) từ 2 phách sang 1 phách trong dữ liệu bundled, để khung luyện tập sinh nốt đen (`quarter`). Bài này dùng nội dung bundled vì remote content đang tắt.

Sửa việc chốt `pitch_estimation_done` trước khi cập nhật độ ổn định của cao độ mới. Trước đây khung trước ổn định có thể khiến khung mới bị chốt dù cao độ mới vừa bị loại, giữ `current_pitch=0` đến hết lần gảy. Nay chỉ chốt sau khi cao độ mới ổn định và cổng tiếng đàn đã mở.

Đã chạy `audit_lesson_runtime.tscn`: PASS kiểm tra chuyển từ cao độ cũ sang Mi2, khung chưa ổn định không bị chốt và khung kế tiếp nhận lại Mi2. Đã chạy `audit_recording_lesson_flow.tscn -- --finger2-final`: PASS kiểm tra trường độ Mi2 cuối do `_start_practice()` tạo là `quarter`, mô phỏng bốn nốt trước đã hoàn tất, giữ generation attack trước, đưa toàn bộ bản thu dây 5 qua `_process()` và nốt cuối được lesson tự đánh dấu hoàn tất. Chưa kiểm tra microphone trực tiếp trên điện thoại.

Kiểm tra bổ sung: lesson có thể giữ trường độ cũ từ `PracticeRoom.current_song_durations`, hoặc dùng 17 nốt mặc định khi mở trực tiếp. Đã đồng bộ riêng bài `dan_tranh_level_1_bai_8_practice` với 5 nốt, trường độ và ngón gảy bundled khi mở lesson và bắt đầu thực hành (remote content tắt). Test cố tình gán lại trường độ cuối 2 phách trước `_start_practice()` và xác nhận nó được sửa thành nốt đen thực tế.

Đã chạy nốt cuối với `--finger2-final --fallback`: PASS cả hình dạng/trường độ cuối và bản thu Mi2 ở nhánh GDScript. Chạy thêm `--finger2-final --fallback --slow-frames`, khung 2205 mẫu tương đương 20 FPS tại 44.1 kHz: PASS Mi2 hoàn tất. Đây là mô phỏng kích thước khung, không phải đo hiệu năng hay microphone trên thiết bị Xogot. Các lần chạy còn cảnh báo ObjectDB khi thoát (2 hoặc 4 instances).

## Mi2 nhận được âm nhưng báo sai: kiểm tra khung xử lý lớn

Người dùng xác nhận có nhận âm nhưng app báo sai nốt. Kiểm thử bổ sung dùng các khung 2205 mẫu (50 ms ở 44.1 kHz, thay vì 735 mẫu/16.7 ms), cho cả C++ và fallback GDScript. Đây là mô phỏng kích thước khung capture, không phải chạy trên thiết bị Xogot thực tế.

Trước sửa, cả hai nhánh FAIL trên bản thu dây 5: khi cổng tiếng đàn mở, cao độ đã giảm còn khoảng 313.6–313.7 Hz, lệch khoảng -86 cents so với Mi2=329.63 Hz. Ngưỡng nhập môn ±80 cents từ chối nốt dù có cao độ tin cậy. Nhánh native ghi `passed=false`, fallback cũng `passed=false`.

Nới riêng Mi2 ở Level 1–2 thành ±90 cents để có biên nhỏ cho phần suy giảm sau tiếng gảy. Các nốt nhập môn khác vẫn ±80 cents, Level 3 trở lên vẫn ±65 cents. Không thay tần số chuẩn hoặc chấp nhận sai quãng tám.

Sau sửa, hai lệnh sau đều PASS: Mi2 cuối được lesson tự đánh dấu hoàn tất bằng toàn bộ bản thu dây 5 khi bốn nốt trước đã hoàn tất.

```powershell
godot --headless --path . --log-file ./mi2-slow-native.log res://scratchpad/audit_recording_lesson_flow.tscn --quit-after 1200 -- --finger2-final --slow-frames
godot --headless --path . --log-file ./mi2-slow-fallback.log res://scratchpad/audit_recording_lesson_flow.tscn --quit-after 1200 -- --finger2-final --slow-frames --fallback
```

`audit_lesson_runtime.tscn` cũng PASS: chấp nhận Mi2 ở 313.6 Hz cho nhập môn, từ chối Rê2=293.66 Hz, Fa2=349.23 Hz, Mi3=659.25 Hz, và giữ ngưỡng nghiêm hơn ở Level 3. Native replay còn cảnh báo 4 ObjectDB instances khi thoát. Chưa xác minh trên microphone của thiết bị người dùng; không khẳng định đây là nguyên nhân duy nhất của báo sai trên thiết bị đó.
