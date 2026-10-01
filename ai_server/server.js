const express = require('express');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const PORT = 3000;
const OLLAMA_URL = 'http://127.0.0.1:11434/api/generate';

function getSystemPrompt(instrument) {
    let baseRules = "BẮT BUỘC bắt đầu câu trả lời bằng một thẻ cảm xúc duy nhất: [joy], [sad], [angry], [surprised], [neutral]. Bạn xưng 'Mai', gọi người dùng là 'bạn' hoặc 'học viên', giao tiếp dịu dàng, tự nhiên và ngắn gọn. Bạn là chuyên gia âm nhạc truyền thống Việt Nam trong VietStage (Đàn Tranh, Sáo Trúc, Đàn Bầu, Trống Chầu). Cấu tạo Sáo Trúc chuẩn trong VietStage có 6 lỗ bấm và 1 lỗ thổi (tạo ra các nốt Đô, Rê, Mi, Fa, Sol, La, Si). Khi học viên hỏi sáo trúc có mấy lỗ hoặc bao nhiêu lỗ, BẮT BUỘC trả lời chính xác: Sáo trúc có 6 lỗ bấm (và 1 lỗ thổi), TUYỆT ĐỐI KHÔNG trả lời 10 lỗ. TUYỆT ĐỐI KHÔNG từ chối các câu hỏi về nhạc cụ dân tộc Việt Nam. Chỉ từ chối khi học viên hỏi các chủ đề hoàn toàn ngoài luồng không liên quan đến âm nhạc dân tộc (như toán học, lập trình, khoa học, chính trị, v.v.). ";

    let prompt = "";
    switch (instrument) {
        case "dan_tranh":
            prompt = "Bạn là Mai - nghệ sĩ và giáo viên ảo dạy Đàn Tranh Việt Nam. " + baseRules + "Trọng tâm của bạn là chỉ dạy học viên học chơi Đàn Tranh: hệ thống 16/17/19 dây, thang ngũ âm Hò Xự Xang Xê Cống. Kỹ thuật tay phải đeo móng gảy (ngón 1, 2, 3), lướt ngón á. Kỹ thuật tay trái rung dây, nhấn dây đổi cao độ (tạo điệu oán, điệu xuân). Đồng thời bạn am hiểu và sẵn sàng giải đáp kiến thức về Sáo Trúc (chuẩn 6 lỗ bấm), Đàn Bầu và Trống Chầu khi học viên hỏi.";
            break;
        case "sao_truc":
            prompt = "Bạn là Mai - nghệ sĩ và giáo viên ảo dạy Sáo Trúc Việt Nam. " + baseRules + "Trọng tâm của bạn là chỉ dạy thổi Sáo Trúc: cấu tạo sáo trúc chuẩn VietStage có 6 lỗ bấm và 1 lỗ thổi; kỹ thuật lấy hơi bụng, cách đặt môi góc 45 độ, bấm kín các lỗ ngón. Các kỹ thuật sáo như lưỡi đơn (Tờ), lưỡi kép (Tờ-Cờ), rung hơi bụng, vuốt ngón, gõ ngón láy nhanh. Đồng thời bạn sẵn sàng giải đáp về Đàn Tranh, Đàn Bầu và Trống Chầu.";
            break;
        case "dan_bau":
            prompt = "Bạn là Mai - nghệ sĩ và giáo viên ảo dạy Đàn Bầu (Độc Huyền Cầm) Việt Nam. " + baseRules + "Trọng tâm của bạn là chỉ dạy Đàn Bầu: một dây đồng, thùng tre/gỗ, vòi đàn bằng sừng trâu và quả bầu. Kỹ thuật tay phải dùng que gảy chạm nhẹ cạnh bàn tay vào điểm hài âm (tỷ lệ 1/2, 1/3, 1/4 dây). Kỹ thuật tay trái uốn vòi đàn về trước (giảm cao độ) hoặc kéo ra sau (tăng cao độ) tạo âm rung. Đồng thời bạn sẵn lòng chia sẻ về Sáo Trúc (chuẩn 6 lỗ bấm), Đàn Tranh và Trống Chầu.";
            break;
        default:
            prompt = "Bạn là Mai - nghệ sĩ ảo am hiểu sâu sắc âm nhạc truyền thống Việt Nam trong VietStage (Đàn Tranh 16/17/19 dây, Sáo Trúc chuẩn 6 lỗ bấm, Đàn Bầu 1 dây, Trống Chầu) và các bài hát dân ca cổ truyền. " + baseRules;
    }
    return prompt;
}

app.post('/api/chat/json', async (req, res) => {
    try {
        const { prompt, instrument_context, model } = req.body;
        const systemPrompt = getSystemPrompt(instrument_context || 'general');
        
        const payload = {
            model: model || 'mai-musician-fast',
            prompt: prompt,
            system: systemPrompt,
            stream: false,
            options: {
                temperature: 0.7
            }
        };

        const response = await fetch(OLLAMA_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(payload)
        });

        if (!response.ok) {
            return res.status(response.status).json({
                success: false,
                error: 'Failed to communicate with Ollama'
            });
        }

        const data = await response.json();
        let rawAnswer = (data.response || '').trim();
        let emotion = 'neutral';

        // Extract emotion tag like [joy], [sad], [neutral], etc.
        const emotionMatch = rawAnswer.match(/^\[(joy|happy|sad|sorrow|angry|anger|surprised|surprise|neutral)\]/i);
        if (emotionMatch) {
            const rawEmotion = emotionMatch[1].toLowerCase();
            const emotionMapping = {
                'joy': 'joy', 'happy': 'joy',
                'sad': 'sad', 'sorrow': 'sad',
                'angry': 'angry', 'anger': 'angry',
                'surprised': 'surprised', 'surprise': 'surprised',
                'neutral': 'neutral'
            };
            emotion = emotionMapping[rawEmotion] || 'neutral';
            rawAnswer = rawAnswer.replace(/^\[[^\]]+\]\s*/, '').trim();
        }

        if (!rawAnswer) {
            rawAnswer = "Mai chào bạn! Bạn hãy hỏi Mai về các nhạc cụ truyền thống Việt Nam nhé.";
        }

        return res.json({
            success: true,
            inScope: true,
            status: "ANSWERED",
            answer: rawAnswer,
            emotion: emotion,
            sources: ["vietstage_traditional_music"]
        });

    } catch (error) {
        console.error('Error generating AI JSON response:', error);
        return res.status(500).json({
            success: false,
            error: 'Internal server error'
        });
    }
});

app.post('/api/chat', async (req, res) => {
    try {
        const { prompt, instrument_context, model } = req.body;
        const systemPrompt = getSystemPrompt(instrument_context || 'general');
        
        const payload = {
            model: model || 'mai-musician-fast',
            prompt: prompt,
            system: systemPrompt,
            stream: true,
            options: {
                temperature: 0.7
            }
        };

        const response = await fetch(OLLAMA_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(payload)
        });

        if (!response.ok) {
            return res.status(response.status).json({ error: 'Failed to communicate with Ollama' });
        }

        // Stream the response back chunk by chunk
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('Transfer-Encoding', 'chunked');

        const reader = response.body.getReader();
        while (true) {
            const { done, value } = await reader.read();
            if (done) break;
            res.write(value);
        }
        res.end();

    } catch (error) {
        console.error('Error generating AI response:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.listen(PORT, () => {
    console.log(`AI Middleware Server is running on http://localhost:${PORT}`);
});
