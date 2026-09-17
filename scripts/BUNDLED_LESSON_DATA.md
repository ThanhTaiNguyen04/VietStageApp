# Dữ liệu bài học có sẵn

- `DanTranhBundledLessonData.gd`: danh sách cấp/bài, lời cô Mai, bộ nốt, trường độ Sứ Thanh Hoa, cấu hình Á/nhấn/rung/vê và ánh xạ dây/tần số.
- `SaoTrucBundledLessonData.gd`: danh sách bài, lời cô Mai, nốt bài học, bài nhạc thực hành, trường độ, thế bấm và tần số.

Hai file này là nguồn dữ liệu local đang được màn hình sử dụng qua preload, không gọi API. Các file CourseData cũ vẫn phụ trách lộ trình và tiến độ. Không đổi ID bài, khóa lưu tiến độ hoặc sao.

Khi thêm API: chuyển response sang cấu trúc nội bộ ở adapter riêng; không ghi đè các constant local. Với dữ liệu cần chỉnh lúc chạy, dùng duplicate(true), như songs_list của PracticeSaoTruc. Chưa bật cơ chế chọn API/cache trong thay đổi này.

Phạm vi: tách nguyên vẹn 23 khai báo dữ liệu từ các script bài học và thực hành. Đây không phải backup toàn project: logic tạo bài động, nhận diện/chấm điểm, dữ liệu quiz/minigame dùng chung và file audio/video vẫn ở vị trí cũ. Cần giữ Git commit/project cùng assets để khôi phục toàn bộ chức năng. Không xóa các script hay assets cũ chỉ vì đã có hai file này.

Kiểm tra: `godot --headless --path . --script res://tests/test_bundled_lesson_data.gd`.
