# Kế hoạch hoàn thiện giao diện luồng Mini Game 1

## 1. Mục tiêu và nguồn yêu cầu

Hoàn thiện luồng **Mini Game 1 – Thử thách nhịp điệu** trong ứng dụng Godot, từ màn chọn hoạt động đến kết quả cuối, bảo đảm:

- Bám giao diện tham chiếu trong ảnh phiếu đăng ký: thẻ Mini Game 1 màu xanh lá, nhãn “MINI-GAME 1”, biểu tượng nốt nhạc, tiêu đề “Thử thách nhịp điệu”, nút “Bắt đầu”, nền nhạc cụ và nút quay lại.
- Đúng yêu cầu chức năng trong `README.md` và `apiList_doc.md`: trò chơi khớp nhịp điệu, lấy thử thách từ backend, nộp kết quả qua API minigame, hiển thị điểm/sao dựa trên độ chính xác.
- Hoạt động trên desktop và mobile, có trạng thái loading, lỗi, offline và đang đồng bộ rõ ràng.

Phạm vi mặc định của Mini Game 1 là thao tác **tap/click theo nhịp**. Phân tích onset từ microphone và BEAT_MAP thuộc nhóm AI/practice; chỉ đưa vào Mini Game 1 nếu sản phẩm xác nhận đây là đầu vào bắt buộc thay cho tap/click.

## 2. Hiện trạng đã rà soát

Luồng hiện tại đã có:

- Điều hướng từ `LearningActivitiesScreen` sang `RhythmChallengeScreen`.
- Intro, đếm ngược, beat lane, nút tap, PERFECT/GOOD/MISS, nhiều vòng và màn kết quả.
- Đọc challenge `RHYTHM_MATCH` từ backend và gửi attempt theo ID.
- Dữ liệu mẫu trong `data/learning_activity_samples.json`.

Các khoảng trống cần xử lý trước khi coi là hoàn thành:

| Mức | Khoảng trống | Ảnh hưởng |
| --- | --- | --- |
| P0 | `score` vừa cộng theo từng tap vừa cộng `round_score`, đồng thời bị reset ở đầu mỗi vòng | Điểm cuối có thể cộng trùng và không tích lũy đúng qua nhiều vòng |
| P0 | Offline luôn hiển thị 0 sao vì sao cuối chỉ lấy từ phản hồi API | Trái yêu cầu 1–3 sao theo độ chính xác |
| P0 | Trạng thái `be` được đặt khi đăng nhập, không dựa trên kết quả submit | Có thể báo “đã đồng bộ” dù request thất bại |
| P0 | Khi context chứa nhiều lesson, loader dừng sau lesson BE đầu tiên dù không có `RHYTHM_MATCH` | Có thể rơi vào dữ liệu giả dù backend có thử thách hợp lệ ở lesson sau |
| P1 | “Nghe mẫu” chỉ in danh sách timestamp, chưa phát metronome/reference audio | Không tạo được mẫu nhịp để người chơi bắt chước |
| P1 | Tap sớm ngoài cửa sổ có thể đánh dấu MISS cho beat gần nhất chưa xử lý | Phán định thiếu công bằng và làm mất beat tương lai |
| P1 | Chưa có loading/empty/error/retry/submitting rõ ràng | Luồng async dễ trông như bị treo hoặc báo sai |
| P1 | Parser chỉ lấy vòng đầu trong `contentJson.rounds`; chưa dùng title, difficulty, tempo | Không thể hiện đúng dữ liệu challenge đầy đủ |
| P2 | Kích thước cố định 280–300 px và breakpoint chỉ tính lúc `_ready` | Có nguy cơ tràn/cắt trên mobile nhỏ hoặc khi đổi kích thước cửa sổ |
| P2 | Chưa có test tự động riêng cho Mini Game 1 | Dễ tái phát lỗi chấm điểm, parser và chuyển trạng thái |

Lưu ý hợp đồng API: backend source hiện tại nhận `score`, `clientAttemptId`, `startedAt`, `completedAt` và tự tính sao. File OpenAPI trong workspace đang cũ hơn source ở phần này, nên lấy backend source và endpoint chạy thực tế làm chuẩn khi tích hợp.

## 3. Luồng UI đích

```text
Màn hoạt động
  → Loading challenge
  → Intro / hướng dẫn + Nghe mẫu
  → Countdown 3–2–1
  → Playing
      HUD vòng + điểm + accuracy
      beat lane + playhead
      nút tap toàn chiều rộng an toàn
      feedback PERFECT / GOOD / MISS
  → Kết quả vòng
      → vòng tiếp theo, hoặc
  → Submitting
  → Kết quả cuối
      điểm / max score / accuracy / sao / điểm thưởng / trạng thái sync
      Chơi lại | Về hoạt động
```

Các nhánh bắt buộc:

- Không có mạng hoặc chưa đăng nhập: dùng đúng dữ liệu mẫu của nhạc cụ, chấm sao cục bộ, ghi rõ “Chế độ offline”; không tuyên bố đã lưu backend.
- API tải lỗi: hiển thị lỗi ngắn gọn với “Thử lại” và “Chơi offline”.
- API nộp lỗi: vẫn giữ kết quả vừa chơi, hiển thị “Chưa đồng bộ” và nút “Thử đồng bộ lại”; không mất attempt hiện tại.
- Không có challenge `RHYTHM_MATCH`: hiển thị empty state thay vì âm thầm thay bằng challenge không liên quan.

## 4. Kế hoạch triển khai

### Giai đoạn A — Chuẩn hóa dữ liệu và state machine (P0)

1. Tạo model challenge nội bộ thống nhất: `id`, `lesson_id`, `title`, `difficulty`, `tempo_bpm`, `beats`, `max_score`, `reference_asset` và `order_index`.
2. Tách parser để hỗ trợ cả `beats` trực tiếp và toàn bộ `rounds`; lọc timestamp không hợp lệ, sắp xếp tăng dần, loại trùng và từ chối challenge rỗng.
3. Với một active lesson: tải đúng lesson đó. Với danh sách nhiều lesson: duyệt hết, gom/deduplicate `RHYTHM_MATCH`, sắp theo lesson/order; không `break` trước khi tìm thấy dữ liệu hợp lệ.
4. Dùng `learning_activity_samples.json` làm fallback thật, không hard-code một mẫu khác trong screen.
5. Định nghĩa state rõ ràng: `LOADING`, `INTRO`, `PREVIEW`, `COUNTDOWN`, `PLAYING`, `ROUND_RESULT`, `SUBMITTING`, `FINAL_RESULT`, `ERROR`.

### Giai đoạn B — Sửa gameplay và chấm điểm (P0)

1. Chỉ giữ một công thức điểm: tổng accuracy points của từng beat → scale theo `maxScore`; tách `round_score` và `total_score` để không cộng trùng/reset sai.
2. Phán định theo cửa sổ thời gian cấu hình được, ví dụ PERFECT ±80 ms, GOOD ±240 ms; tap ngoài cửa sổ không tiêu thụ beat tương lai.
3. Tự MISS beat khi cửa sổ đã qua; khóa double tap trên beat đã xử lý.
4. Tính accuracy, hits và sao cục bộ từ cùng một nguồn dữ liệu; backend response là nguồn chuẩn cho sao/điểm thưởng khi submit thành công.
5. Hủy timer/audio an toàn khi retry, back hoặc scene bị đóng để tránh callback muộn.

### Giai đoạn C — Hoàn thiện từng màn hình (P1)

1. **Màn chọn hoạt động:** giữ bố cục và nhận diện theo ảnh; kiểm tra hover/pressed/focus, vùng bấm tối thiểu 48 px và trạng thái card Mini Game 1.
2. **Loading/error:** spinner hoặc skeleton nhẹ; nội dung lỗi có retry/offline/back.
3. **Intro:** title challenge, vòng hiện tại/tổng vòng, difficulty/tempo nếu có, hướng dẫn ngắn, “Nghe mẫu” và “Bắt đầu”.
4. **Nghe mẫu:** phát metronome theo beat; nếu backend có reference asset thì ưu tiên asset, có loading/stop/replay và không cho chồng nhiều playback.
5. **Countdown:** overlay lớn, không cho tap trước “BẮT ĐẦU”, có âm cue nếu âm thanh đang bật.
6. **Playing:** HUD gọn; beat lane co giãn; playhead dễ nhìn; nút tap xanh lá lớn; animation/haptic/audio feedback nhẹ cho PERFECT/GOOD/MISS.
7. **Kết quả vòng:** score vòng, accuracy, hit/miss, nút vòng tiếp theo.
8. **Kết quả cuối:** tổng điểm đúng, sao, points backend, sync status trung thực, chơi lại, retry sync và quay về màn hoạt động.

### Giai đoạn D — Tích hợp backend và offline (P0/P1)

1. Xác minh endpoint `GET /api/lessons/{id}/minigames` trả `RHYTHM_MATCH` và parse đúng `contentJson` thực tế.
2. Xác minh `POST /api/minigames/{id}/attempts` với payload theo backend source hiện tại; giữ `clientAttemptId` ổn định khi retry để chống submit trùng.
3. Chỉ đặt trạng thái “Đã đồng bộ” sau response thành công; lưu reason/message khi lỗi.
4. Không cộng thưởng giả ở client. Khi offline chỉ hiển thị điểm/sao preview, phân biệt rõ với reward đã ghi backend.
5. Sau submit thành công, refresh progress và dùng `starsEarned`, `pointsEarned`, tổng sao/điểm từ response/cache backend.

### Giai đoạn E — Responsive, accessibility và polish (P2)

1. Kiểm tra tối thiểu 1920×1080, 1366×768, 390×844 và 360×800; không tràn ngang, không che safe area.
2. Thay width cố định bằng min/max theo viewport; mobile xếp action dọc nếu không đủ ngang.
3. Hỗ trợ touch, click và phím Space/Enter cho tap; focus visible và label không phụ thuộc màu duy nhất.
4. Tôn trọng giảm chuyển động nếu dự án có setting tương ứng; âm lượng cue theo setting âm thanh chung.
5. Giữ font, màu navy/xanh lá/vàng, nền nhạc cụ và card kính đồng nhất với ảnh tham chiếu.

## 5. Test và cổng nghiệm thu

### Test tự động

- Parser: `beats`, `rounds`, JSON string, field camelCase/snake_case, dữ liệu rỗng/sai, thứ tự và duplicate.
- Judgement: biên PERFECT/GOOD/MISS, tap sớm/muộn, double tap và tự MISS.
- Scoring: một vòng/nhiều vòng, maxScore khác nhau, offline stars và không cộng trùng.
- State transition: loading → intro → countdown → playing → result; retry/back trong mọi state.
- Sync: success, 401, timeout, 5xx và retry cùng `clientAttemptId`.

### Runtime Godot bắt buộc

- Chạy import/parser check toàn project.
- Chạy scene thật từ màn hoạt động, bấm Mini Game 1 và hoàn tất ít nhất một lượt.
- Chụp/đối chiếu màn activity, intro, playing và result ở desktop + mobile.
- Kiểm tra một lượt có đăng nhập với backend thật và một lượt offline.
- Xác minh attempt xuất hiện qua GET attempts hoặc dữ liệu backend tương ứng; đối chiếu score/stars/points với UI.

### Definition of Done

- Tất cả trạng thái và nhánh lỗi ở mục 3 chạy được, không có màn trắng hoặc nút chết.
- Giao diện launcher bám ảnh tham chiếu và màn chơi cùng design system.
- Điểm, accuracy, hits, sao và points nhất quán qua một/nhiều vòng.
- Online submit đúng challenge ID và báo sync trung thực; offline không giả đồng bộ.
- Không có parser error/runtime error trong log Godot.
- Test tự động liên quan vượt qua và có bằng chứng runtime cho desktop/mobile/backend.

## 6. Thứ tự thực hiện đề xuất

1. A + B trước để khóa dữ liệu, state và công thức điểm.
2. D ngay sau đó để UI kết quả dựa trên contract thật.
3. C hoàn thiện toàn bộ màn hình theo state đã ổn định.
4. E và test ma trận kích thước.
5. Chạy toàn bộ cổng nghiệm thu; chỉ báo “hoàn thành” khi có bằng chứng runtime và API thực tế.
