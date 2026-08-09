1. Learner Application (Godot Desktop/Mobile)
● Register/login with learner profile; select instrument of interest and current skill level

Register/login with learner profile: Chức năng xác thực qua API POST /api/auth/register và POST /api/auth/login.
select instrument of interest: API PUT /api/users/me/profile (Lưu instrumentId ưa thích vào bảng learner_profiles).
and current skill level: API PUT /api/users/me/profile (Lưu skillLevelId trình độ ban đầu vào bảng learner_profiles).
● Explore 2.5D isometric virtual music room with interactive instrument stations

Explore 2.5D isometric virtual music room: Tính năng Client-side (Godot render môi trường đồ họa 2.5D).
with interactive instrument stations: Godot gọi API GET /api/instruments để tải danh sách nhạc cụ có thể tương tác trên bản đồ.
● Watch virtual artist demonstrate techniques with synchronized animation and audio playback

Watch virtual artist demonstrate techniques: API GET /api/lessons/{id} (Tải siêu dữ liệu và mô tả kỹ thuật LessonTechnique).
with synchronized animation: (Client-side, Godot xử lý đồng bộ hoạt ảnh).
and audio playback: API GET /api/lessons/{id}/assets (Backend cung cấp URL tệp âm thanh gốc để Godot phát đồng bộ).
● Enter practice mode: system captures microphone input and provides real-time visual feedback (pitch indicator, rhythm bar, accuracy meter)

Enter practice mode: API POST /api/practice-sessions (Khởi tạo phiên học thực hành).
system captures microphone input: (Native C++ Client-side lấy luồng âm thanh từ Microphone).
and provides real-time visual feedback (pitch indicator, rhythm bar, accuracy meter): (Xử lý UI và luồng tín hiệu theo thời gian thực dưới C++ GDExtension). Sau khi kết thúc, gọi API POST /api/practice-attempts đẩy kết quả lên Backend.
● Complete structured lessons organized by instrument → technique → difficulty tier (Beginner / Intermediate / Advanced)

Complete structured lessons: API POST /api/lessons/{id}/progress (Đánh dấu tiến độ status = COMPLETED).
organized by instrument → technique → difficulty tier: Sử dụng API lọc bài học GET /api/lessons?instrumentId={id}&techniqueId={id}&skillLevelId={id} để phân cấp giáo trình.
● Play mini-games: rhythm matching challenges, note recognition quizzes, melody completion exercises

Play mini-games: Gọi API GET /api/minigames (Tải danh sách trò chơi nhỏ).
rhythm matching challenges: Backend chấm điểm qua API POST /api/minigames/attempts (Dành cho Minigame RHYTHM_MATCH).
note recognition quizzes: API GET /api/lessons/{id}/quizzes (Tải bộ câu hỏi trắc nghiệm) và nộp đáp án qua POST /api/quizzes/{id}/attempts.
melody completion exercises: Tương tự cơ chế của Minigame.
● Earn stars (1-3) per lesson based on accuracy; unlock new lessons and cosmetic rewards for virtual room

Earn stars (1-3) per lesson based on accuracy: Backend tính toán số sao dựa trên điểm số khi Client gọi API POST /api/lessons/{id}/progress.
unlock new lessons: API GET /api/users/me/progress sẽ tự động trả về các bài học có trạng thái UNLOCKED.
and cosmetic rewards for virtual room: Gọi API GET /api/cosmetics (Kiểm tra kho đồ trang trí) và POST /api/cosmetics/equip (Đeo/sử dụng vật phẩm).
● View personal progress dashboard: accuracy trends, practice time, completed lessons, achievement badges

View personal progress dashboard: Sử dụng API tổng GET /api/users/me/progress/summary.
accuracy trends: (Biểu đồ vẽ từ mảng dữ liệu của PracticeAttempt).
practice time & completed lessons: Trích xuất từ bảng learner_profiles và learner_lesson_progress.
achievement badges: Gọi API GET /api/users/me/achievements (Tải danh sách danh hiệu đã thu thập).
● Access reference audio library with slow-motion playback and waveform visualization

Access reference audio library: Gọi API GET /api/lessons/{id}/assets và lọc theo assetType = REFERENCE_AUDIO.
with slow-motion playback and waveform visualization: Tính năng phát chậm và vẽ sóng âm do Engine Godot (Client-side) đảm nhiệm.
● Daily practice challenges with streak rewards and leaderboard ranking

Daily practice challenges: Gọi API GET /api/daily-challenges (Nhận nhiệm vụ ngày).
with streak rewards: Hệ thống tự động cộng dồn current_streak khi học viên điểm danh hoặc hoàn thành phiên tập.
and leaderboard ranking: Gọi API GET /api/leaderboards (Trả về bảng xếp hạng danh dự).
2. AI Audio Analysis Features (GDExtension C++)
(Lưu ý: Nhóm tính năng đòi hỏi độ trễ cực thấp <100ms nên đa số chạy độc lập dưới dạng Native C++ tại Client. Backend đóng vai trò cấp cấu hình tham chiếu và lưu trữ kết quả cuối cùng).

● Real-time pitch detection using autocorrelation and YIN algorithm optimized in C++ for low-latency response (<100ms)

(Tính năng phân tích cao độ bằng YIN/autocorrelation chạy nội bộ bằng C++ GDExtension).
● Rhythm accuracy evaluation comparing onset timing against reference beat map

Rhythm accuracy evaluation comparing onset timing: C++ phân tích thời điểm phát âm (Onset).
against reference beat map: Tải dữ liệu nhịp điệu từ Backend qua API GET /api/lessons/{id}/assets (lọc assetType = BEAT_MAP).
● Tonal quality assessment for string instruments using spectral centroid and harmonic ratio analysis

(Tính năng phân tích chất âm dải phổ chạy nội bộ bằng C++ GDExtension).
● Breath pattern analysis for wind instruments (sáo trúc) measuring sustain and attack consistency
(Tính năng phân tích làn hơi chuyên dụng cho Sáo trúc chạy nội bộ bằng C++ GDExtension).
● Performance scoring engine aggregating pitch, rhythm, dynamics, and technique metrics into composite score

Performance scoring engine: Client tính toán các chỉ số độ chuẩn xác.
into composite score: Gửi cấu trúc điểm số chi tiết lên Backend lưu trữ qua API POST /api/practice-attempts.
● Adaptive difficulty adjustment based on rolling accuracy of last 10 practice attempts

Adaptive difficulty adjustment: Dựa vào thông số cấu hình độ khó gốc từ API GET /api/configs.
based on rolling accuracy of last 10 practice attempts: Tải 10 lượt tập gần nhất qua API GET /api/practice-attempts?limit=10 để Engine tự động tinh chỉnh tốc độ nhịp (tempo).
● Audio noise gate and filtering to isolate instrument signal from background noise

(Tính năng lọc nhiễu tín hiệu số DSP chạy nội bộ bằng C++ GDExtension).
3. Instructor Dashboard (Web)
● Upload lesson content: reference audio recordings, sheet notation images, technique descriptions

Upload lesson content: Giao thức chung POST /api/upload (Upload file gốc lên Cloud Storage / AWS S3).
reference audio recordings & sheet notation images: API POST /api/lessons/{id}/assets (Lưu định danh tệp vào CSDL bài học).
technique descriptions: API POST /api/lessons/{id}/techniques (Thêm các ghi chú kỹ thuật gảy/thổi).
● Configure lesson structure: define exercises, set scoring thresholds, arrange curriculum order

Configure lesson structure: API POST /api/lessons (Khởi tạo bài học mới).
define exercises: API POST /api/lessons/{id}/exercises (Tạo các chặng bài tập nhỏ trong bài học).
set scoring thresholds: Cấu hình thông qua trường passThreshold của API PUT /api/exercises/{id}.
arrange curriculum order: Định tuyến thông qua trường orderIndex của API PUT /api/lessons/{id}.
● Monitor learner progress: aggregate statistics, individual scorecards, practice frequency reports

aggregate statistics: Thống kê toàn cảnh qua API GET /api/users/me/progress/summary.
individual scorecards: Trích xuất bảng điểm cá nhân qua API GET /api/lessons/{id}/learners/{learnerId}/progress.
practice frequency reports: Truy vấn API GET /api/practice-attempts kết hợp tham số thời gian để kết xuất tần suất.
● Provide feedback via text comments on specific lesson attempts

Provide feedback via text comments: API POST /api/practice-attempts/{attemptId}/feedbacks (Lưu phản hồi văn bản).
on specific lesson attempts: Phản hồi được liên kết chặt chẽ vào Khóa ngoại attemptId cụ thể của lượt tập đó.
4. Admin Panel (Web)
● User management: learner/instructor accounts, role assignment, access control

learner/instructor accounts: API GET /api/admin/users (Liệt kê) và POST /api/admin/users (Tạo mới).
role assignment: Cấp quyền qua API PUT /api/admin/users/{id}/role.
access control: Quản lý vòng đời tài khoản qua API PUT /api/admin/users/{id}/status (Thay đổi cờ is_active).
● Content moderation: review and approve uploaded lessons and audio materials

Content moderation: Quy trình duyệt nội dung đa bước trạng thái (DRAFT -> PENDING -> APPROVED).
review and approve uploaded lessons and audio materials: API PUT /api/lessons/{id}/status (Chuyển trạng thái sang APPROVED để phát hành công khai).
● System analytics: active users, popular instruments, session duration, retention metrics

System analytics: Dữ liệu tổng hợp từ API GET /api/admin/dashboard.
active users / popular instruments / session duration / retention metrics: Dữ liệu thô (raw data) được tích hợp trong List <ChartData> của Response, giúp Web Frontend tự do kết xuất đồ thị.
● Application configuration: scoring parameters, difficulty curves, feature toggles

Application configuration: Quản trị tập trung qua Controller AppConfigController.
scoring parameters & difficulty curves: Tùy chỉnh hệ số điểm/độ khó qua API PUT /api/admin/configs/{key}.
feature toggles: Bật/tắt nhanh các sự kiện qua API PUT /api/admin/configs/{key} (Với cờ Boolean tương ứng).
