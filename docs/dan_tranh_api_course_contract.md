# Contract giáo trình Đàn Tranh với VietStage API

## Trạng thái tích hợp

`DanTranhApiCourseContract.REMOTE_CONTENT_ENABLED` đang là `false`. Giáo trình
Đàn Tranh vẫn đọc dữ liệu cứng hiện tại. Contract này chỉ chuẩn bị cấu trúc cho
giai đoạn tích hợp web sau khi các bài học và nhận diện âm thanh đã ổn định.

## Ba trình độ

| `levelCode` | Tên trên web | Level cục bộ hiện tại |
|---|---|---:|
| `BEGINNER` | Sơ cấp | 1 |
| `INTERMEDIATE` | Trung cấp | 2 |
| `ADVANCED` | Cao cấp | 7 |

`levelCode` phải ổn định. `levelName` có thể đổi để phục vụ hiển thị.

## Định danh và vòng đời bài học

- `lessonCode` là khóa nghiệp vụ bất biến dùng để nối API với ID cục bộ.
- Không tái sử dụng `lessonCode`, kể cả khi bài bị ẩn.
- Bài đã có progress hoặc sao không được hard-delete.
- Web sử dụng `HIDDEN` hoặc `ARCHIVED`; app chỉ tải `PUBLISHED`/`ACTIVE`.
- Việc ẩn bài không xóa progress, attempt hoặc sao đã nhận.
- Phần trăm hoàn thành hiện tại chỉ tính các bài đang hiển thị; sao lịch sử vẫn giữ nguyên.
- Endpoint `DELETE /api/lessons/{id}` chỉ nên cho phép với bản nháp chưa từng có
  progress, hoặc backend phải đổi thành soft delete.

OpenAPI hiện cho phép `status` dạng chuỗi nhưng chưa công bố enum. Backend và web
cần thống nhất: `DRAFT`, `PENDING`, `PUBLISHED`, `HIDDEN`, `ARCHIVED`.

## Nội dung bài học

Một lesson có danh sách content block có thứ tự. Trong lúc API chỉ có
`content_text`, web lưu tạm một JSON document vào trường này:

```json
{
  "schema_version": 1,
  "blocks": [
    {"type": "THEORY_TEXT", "text": "Nội dung lý thuyết"},
    {"type": "TEACHER_SPEECH", "text": "Lời cô Mai", "voice_asset_id": 21},
    {"type": "VIDEO_CUE", "asset_id": 22, "start_ms": 0},
    {"type": "ANIMATION_CUE", "animation_key": "right_hand_finger_2"},
    {"type": "WAIT_FOR_NOTE", "note": "Sol1", "string": 1, "tolerance_cents": 45}
  ]
}
```

Về lâu dài backend nên có trường JSON có cấu trúc thay vì nhét JSON vào text.
Không lưu script GDScript trên web và không thực thi mã do API gửi về. App chỉ
chấp nhận các `type` và `animation_key` đã đăng ký sẵn.

## Media

OpenAPI hiện chỉ cho endpoint lesson asset nhận `REFERENCE_AUDIO` và
`SHEET_MUSIC`, với MP3/WAV hoặc ảnh. Như vậy chưa thể gắn video và hoạt ảnh vào
lesson một cách chính thức. Backend cần bổ sung:

- Asset type: `LESSON_VIDEO`, `ANIMATION`, `VOICE_OVER`, `BEAT_MAP`.
- Video: MP4 H.264/AAC hoặc HLS; có thumbnail, duration và checksum.
- Hoạt ảnh: app nên nhận `animation_key` trỏ tới animation đóng gói sẵn. Nếu cần
  tải động, dùng định dạng đã kiểm soát như Lottie và có version tương thích.
- Lời cô Mai: text để TTS/offline fallback; `VOICE_OVER` là audio thu sẵn tùy chọn.
- Asset cũ không được ghi đè tại cùng URL; upload bản mới và cập nhật liên kết.

## Thực hành có nốt

Không dùng ảnh sheet nhạc làm nguồn chấm điểm. Dữ liệu chuẩn phải là danh sách
nốt có cấu trúc, nhập tay trên web hoặc import MusicXML/MIDI:

```json
{
  "schema_version": 1,
  "type": "NOTE_SEQUENCE",
  "practice_mode": "pitch_sequence",
  "notes": ["Sol1", "La1", "Đô2"],
  "durations": [1.0, 1.0, 2.0],
  "cues": ["", "", "press"],
  "tempo_bpm": 60,
  "pass_threshold": 60
}
```

Tên nốt hiển thị (`Sol1`) và tên kỹ thuật quốc tế (`G3`) nên cùng được lưu hoặc
được quy đổi từ bảng dây chuẩn. Ảnh sheet chỉ là tài nguyên hiển thị/tham khảo.

Godot không có sẵn Optical Music Recognition đáng tin cậy. Có thể xây dịch vụ
OMR riêng để đọc ảnh, nhưng kết quả vẫn cần người quản trị xác nhận. Thứ tự triển
khai an toàn: nhập tay tên nốt trước, sau đó import MusicXML/MIDI, cuối cùng mới
coi OMR ảnh là công cụ hỗ trợ nhập liệu chứ không phải nguồn dữ liệu tự động.

## Phần thưởng

App gửi hoàn thành lesson qua `POST /api/users/me/lessons/{lessonId}/complete`.
Backend là nguồn quyết định `lessonStars`, `starsEarned`, `totalStars`,
`spendableStars` và `totalPoints`. Yêu cầu nên có `clientAttemptId` để tránh cộng
sao hai lần khi app gửi lại do mất mạng.
