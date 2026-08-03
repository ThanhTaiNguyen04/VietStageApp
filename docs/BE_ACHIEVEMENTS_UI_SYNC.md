# Dong bo FE/BE cho Achievements

## 1. Nguon doi chieu

- Swagger UI: `https://vietstage-web-backend.onrender.com/swagger-ui/index.html#/Achievements/createAchievement`
- OpenAPI da kiem tra ngay `2026-08-03`: `GET https://vietstage-web-backend.onrender.com/api-docs`

## 2. Contract BE hien tai

### 2.1 Quan tri thanh tuu

- `GET /api/achievements`
- `POST /api/achievements`
- `PUT /api/achievements/{id}`
- `DELETE /api/users/{learnerId}/achievements/{achievementId}`

### 2.2 Learner xem thanh tuu cua minh

- `GET /api/users/me/achievements`

### 2.3 Schema tao/cap nhat

`AchievementRequest`

```json
{
  "name": "string",
  "description": "string",
  "iconUrl": "string",
  "conditionJson": "string"
}
```

Rang buoc tu Swagger:

- Bat buoc: `name`, `iconUrl`, `conditionJson`
- `name`: `minLength = 1`
- `iconUrl`: `minLength = 1`
- `conditionJson`: `minLength = 1`

### 2.4 Schema hien thi

`AchievementResponse`

```json
{
  "id": 1,
  "name": "string",
  "description": "string",
  "iconUrl": "string",
  "conditionJson": "string",
  "earnedAt": "2026-08-03T10:00:00Z"
}
```

`GET /api/users/me/achievements` tra:

```json
{
  "success": true,
  "message": "string",
  "data": {
    "earned": [AchievementResponse],
    "locked": [AchievementResponse]
  }
}
```

## 3. Ket luan cho FE hien tai

Repo hien tai chi co man learner o [scripts/ProgressScreen.gd](/E:/VietStageApp/scripts/ProgressScreen.gd:1), dung `GET /users/me/achievements`.

Cac diem da lech contract:

- FE dang dung `iconUrl` nhu text icon. Neu BE tra URL anh that, UI se hien thi nguyen URL.
- FE chua co wrapper cho `GET/POST/PUT /api/achievements`.
- FE chua co luong thu hoi thanh tuu `DELETE /api/users/{learnerId}/achievements/{achievementId}`.
- `conditionJson` moi ton tai o BE, chua co UI nhap lieu/preview tuong ung.

## 4. Goi y giao dien dong bo voi du an

### 4.1 Learner ProgressScreen

Giu cung visual language hien tai:

- Cot trai: ho so, level, streak, total points.
- Cot phai: grid huy hieu.
- Card earned: nen kem sang, vien vang, subtitle uu tien `earnedAt`.
- Card locked: nen mo, vien xam, subtitle dung `description`.

Nen bo sung:

- Neu `iconUrl` la URL anh: hien thi `TextureRect` hoac fallback glyph local.
- Neu `description` co du lieu: dung lam tooltip hoac dong phu cho huy hieu da dat khi `earnedAt` rong.
- Khong render truc tiep `conditionJson` o man learner.

### 4.2 Admin/Instructor Achievement Manager

Nen lam thanh man rieng, khong tron vao `ProgressScreen` cua learner.

Layout de xuat:

1. Danh sach trai:
   - Tim kiem theo `name`
   - Card ngan: icon preview, ten, mo ta ngan
2. Form phai:
   - `Ten thanh tuu`
   - `Mo ta`
   - `Icon URL`
   - `Dieu kien`
3. Footer hanh dong:
   - `Tao moi`
   - `Cap nhat`
   - `Lam moi`

### 4.3 Input cho `conditionJson`

Khong nen de mot o text trong hoan toan vi de sai du lieu.

Nen dung:

- 1 dropdown `Loai dieu kien`
- 1 nhom field dong theo loai
- 1 o preview JSON read-only

Vi du cac preset FE co the ho tro:

- Hoan thanh `N` bai hoc
- Dat `N` ngay streak
- Tich luy `N` diem
- Hoan thanh bai cua mot nhac cu cu the

## 5. Khuyen nghi phoi hop voi BE

- BE nen cong bo mau `conditionJson` hop le hoac enum `conditionType`, vi Swagger hien chi mo ta la `string`.
- Neu `iconUrl` luon la URL anh, BE va FE nen thong nhat dieu nay de FE bo han gia dinh icon dang emoji/text.
- Neu endpoint quan tri can phan quyen `ADMIN` hoac `INSTRUCTOR`, Swagger nen ghi ro de FE quyet dinh co an menu hay khong.
- Neu learner can xem tien do mo khoa theo dieu kien, BE nen tra them `progressCurrent`, `progressTarget` thay vi chi `locked/earned`.

## 6. Viec da cap nhat trong repo

- Them route va API wrapper cho:
  - `GET /api/achievements`
  - `POST /api/achievements`
  - `PUT /api/achievements/{id}`
  - `DELETE /api/users/{learnerId}/achievements/{achievementId}`
- Va `ProgressScreen` de khong render `iconUrl` nhu text tho khi BE tra URL.
