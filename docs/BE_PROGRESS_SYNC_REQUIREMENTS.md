# Yêu cầu BE: Chuẩn hóa API đồng bộ tiến trình học tập

## 1. Mục tiêu

FE phải đồng bộ chính xác tiến trình theo nhạc cụ và bài học mà không suy luận từ `title`. `title` là nội dung hiển thị, có thể đổi hoặc dịch ngôn ngữ và không được dùng làm khóa liên kết.

Endpoint liên quan:

- `GET /api/users/me/progress`
- `GET /api/users/me/progress/summary`
- `GET /api/instruments`
- `GET /api/lessons`

## 2. Lỗi production đã xác nhận ngày 02/08/2026

`GET /api/users/me/progress` trả HTTP 200 nhưng chỉ có `lessonId`, `title`, `completed`, `stars`; thiếu mã nhạc cụ và mã bài học ổn định.

Dữ liệu từ `/api/lessons` đang mâu thuẫn:

| lessonId | title | lessonCode | instrument hiện tại | Vấn đề |
|---:|---|---|---|---|
| 1 | Bài 1: Làm quen Đàn Tranh | LSN-DA-BEGINNER-234 | id=1, Dan Bau | Nội dung Đàn Tranh nhưng gắn Đàn Bầu |
| 2 | Bài 2: Nốt nhạc cơ bản | LSN-DA-BEGINNER-485 | id=1, Dan Bau | Mô tả là các nốt Đàn Tranh nhưng gắn Đàn Bầu |
| 3 | Bài 1: Cách thổi Sáo | LSN-SA-BEGINNER-033 | id=3, Trong | Nội dung/mã Sáo nhưng gắn Trống |
| 5 | Bài 3: Kỹ thuật Rung dây trên Đàn Tranh | LSN-DA-034-INTERMEDIATE-004 | id=1, Dan Bau | Nội dung Đàn Tranh nhưng gắn Đàn Bầu |
| 9 | âsfadsadas | LSN-DA-965-BEGINNER-006 | id=2, Sao Truc | Tiêu đề lỗi; mã Đàn nhưng gắn Sáo; trạng thái DRAFT |

Danh mục nhạc cụ hiện tại:

- id=1: Dan Bau
- id=2: Sao Truc
- id=3: Trong
- id=4: Dan Tranh

## 3. Migration dữ liệu bắt buộc

1. Chuyển lesson `1`, `2`, `5` sang instrument id `4` (Đàn Tranh).
2. Chuyển lesson `3` sang instrument id `2` (Sáo Trúc).
3. Với lesson `9`: sửa đúng `title`, `lessonCode`, instrument và nội dung trước khi publish; nếu là dữ liệu test thì archive/xóa và không trả cho learner.
4. Chuẩn hóa `instrumentCode` thành enum bất biến, không dùng mã sinh ngẫu nhiên:
   - `DAN_TRANH`
   - `SAO_TRUC`
   - `DAN_BAU`
   - `TRONG_CHAU`
5. Chuẩn hóa `lessonCode` thành khóa nghiệp vụ bất biến. Ví dụ: `DAN_TRANH_BEGINNER_01`. Không thay code khi sửa title.
6. Không trả lesson `DRAFT`, `PENDING` hoặc dữ liệu đã archive trong progress của learner, trừ khi learner đã có progress lịch sử và BE có chính sách migration rõ ràng.

## 4. Contract bắt buộc cho progress

### Request

```http
GET /api/users/me/progress?instrumentId=4&skillLevelId=1
Authorization: Bearer <access-token>
Accept: application/json
```

BE có thể tiếp tục hỗ trợ tên query cũ trong giai đoạn chuyển đổi, nhưng Swagger và implementation phải thống nhất một chuẩn camelCase.

### Response 200

```json
{
  "success": true,
  "message": "Get learner progress successfully",
  "data": [
    {
      "lessonId": 1,
      "lessonCode": "DAN_TRANH_BEGINNER_01",
      "title": "Bài 1: Làm quen Đàn Tranh",
      "instrumentId": 4,
      "instrumentCode": "DAN_TRANH",
      "instrumentName": "Đàn Tranh",
      "skillLevelId": 1,
      "skillLevelCode": "BEGINNER",
      "orderIndex": 1,
      "completed": false,
      "stars": 0,
      "completedAt": null,
      "updatedAt": "2026-08-02T00:00:00Z"
    }
  ]
}
```

Ràng buộc:

- `lessonId`, `instrumentId`, `orderIndex`, `stars`: JSON integer, không null.
- `lessonCode`, `instrumentCode`: không rỗng, duy nhất và bất biến.
- `completed`: JSON boolean.
- `title`: chỉ dùng hiển thị, không dùng làm khóa.
- Mỗi `lessonId` phải liên kết đúng một instrument.
- Không trả cùng `lessonId` nhiều lần cho một learner.
- Sắp xếp ổn định theo `instrumentCode`, `skillLevelId`, `orderIndex`.

### Response lỗi

Giữ một envelope thống nhất:

```json
{
  "status": 401,
  "path": "/api/users/me/progress",
  "message": "Token không hợp lệ hoặc đã hết hạn. Vui lòng đăng nhập lại.",
  "error": "Unauthorized"
}
```

Không trả HTTP 200 kèm `success=false` cho lỗi nghiệp vụ/hệ thống.

## 5. Summary contract

Endpoint `/api/users/me/progress/summary` hiện trả đúng HTTP 200. Giữ nguyên các field snake_case trong giai đoạn hiện tại để không phá FE:

```json
{
  "adaptive_difficulty": 0,
  "completed_lessons": 0,
  "current_streak": 0,
  "longest_streak": 0,
  "total_points": 0,
  "total_stars": 0
}
```

Nếu muốn chuyển camelCase, cần version API hoặc hỗ trợ song song trong ít nhất một release.

## 6. Tiêu chí nghiệm thu BE

1. Learner không có tiến trình nhận `200`, `success=true`, `data=[]` hoặc danh sách lesson với `completed=false` theo contract đã thống nhất.
2. Hoàn thành lesson Đàn Tranh id `1` rồi gọi progress phải trả `instrumentCode=DAN_TRANH`, `lessonCode` hợp lệ, `completed=true` và số sao đúng.
3. Đổi `title` của lesson không làm thay đổi liên kết progress.
4. Filter theo instrument không trả lesson thuộc instrument khác.
5. Lesson DRAFT/PENDING/test không xuất hiện trong learner progress.
6. Không tồn tại lesson có `instrumentId` mâu thuẫn với `instrumentCode`.
7. Swagger mô tả đúng request, query params, response schema và mã lỗi 200/400/401/403/500.
8. Có migration test cho lesson `1`, `2`, `3`, `5`, `9` và kiểm tra không mất progress hiện có.

## 7. Kế hoạch rollout FE/BE

1. BE migration dữ liệu và bổ sung canonical fields.
2. Deploy BE, xác minh contract production bằng một learner test.
3. FE hiện ưu tiên canonical fields, sau đó mới dùng mapping `lessonId` tạm để tương thích.
4. Sau khi production không còn record thiếu canonical fields trong tối thiểu một release, FE xóa `LEGACY_BACKEND_LESSON_MAP` và title fallback.