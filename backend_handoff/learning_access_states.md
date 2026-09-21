# Trạng thái truy cập và tiến độ học (đề xuất, chưa tích hợp)

App hiện tạm mở tất cả level/bài học; card level hiển thị xanh. Không tự hoàn thành bài, cộng sao hoặc thay đổi tiến độ đã lưu. Backend chưa cần đổi dữ liệu để phục vụ chế độ tạm này.

Tên trường dưới đây là đề xuất cần backend đối chiếu OpenAPI, không phải khẳng định API hiện có các trường này. Chỉ ghi chú trong code, chưa đọc/gửi các trường này.

| Trường đề xuất | Ý nghĩa |
| --- | --- |
| `isUnlocked` | Quyền truy cập level/bài học của học viên hiện tại |
| `learningStatus` | `NOT_STARTED`, `IN_PROGRESS`, `COMPLETED` |

Quy ước màu khi tích hợp sau này:
- `isUnlocked = false`: trắng mờ (alpha 0.45), chặn vào học.
- `isUnlocked = true`, `learningStatus = NOT_STARTED`: trắng đục (alpha 0.82), được vào học.
- `isUnlocked = true`, `learningStatus = IN_PROGRESS` hoặc `COMPLETED`: xanh.

Backend cần xác nhận tên trường và quy tắc tổng hợp trạng thái level từ các bài; phân biệt đã bắt đầu nhưng chưa hoàn thành bài nào với chưa học. Không dùng phần trăm bằng 0 để suy ra chưa học. Các trạng thái này thuộc tiến độ cá nhân, không dùng chung trạng thái kiểm duyệt bài (`DRAFT`, `PENDING`, `APPROVED`, `REJECTED`).

Khi tích hợp thật, thay các điểm tạm mở bằng dữ liệu quyền truy cập đã xác nhận; backend vẫn phải kiểm tra quyền khi nhận yêu cầu. Sao, điểm và phần thưởng chỉ được cấp theo kết quả hợp lệ, không dựa trên màu card hay chế độ mở tạm.
