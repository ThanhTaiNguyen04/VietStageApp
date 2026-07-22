import re

def process():
    with open('scratch/LessonDanTranhTemplate.gd', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Class name
    content = content.replace('class_name LessonSaoTruc', 'class_name LessonDanTranh')
    
    # Node names
    content = content.replace('FluteBody', 'ZitherBoard')
    content = content.replace('FluteBoard', 'ZitherBoard')
    content = content.replace('FluteFrame', 'ZitherFrame')
    content = content.replace('FluteM', 'ZitherM')
    content = content.replace('FluteStack', 'ZitherStack')
    
    # Variable names
    content = content.replace('flute_body', 'zither_board')
    content = content.replace('Sáo Trúc', 'Đàn Tranh')
    content = content.replace('sáo trúc', 'đàn tranh')
    content = content.replace('SÁO TRÚC', 'ĐÀN TRANH')
    content = content.replace('cây sáo', 'cây đàn')
    
    # We need to replace NOTE_FREQS with Dan Tranh's base freqs
    note_freqs_replacement = """const NOTE_FREQS = {
	"Sol1": 196.00,
	"La1": 220.00,
	"Đô2": 261.63,
	"Rê2": 293.66,
	"Mi2": 329.63,
	"Sol2": 392.00,
	"La2": 440.00,
	"Đô3": 523.25,
	"Rê3": 587.33,
	"Mi3": 659.25,
	"Sol3": 783.99,
	"La3": 880.00,
	"Đô4": 1046.50,
	"Rê4": 1174.66,
	"Mi4": 1318.51,
	"Sol4": 1567.98,
	"La4": 1760.00
}"""
    
    # Find and replace NOTE_FREQS block
    content = re.sub(r'const NOTE_FREQS = \{[^\}]+\}', note_freqs_replacement, content)
    
    # We need to replace LESSON_NOTES (wait, LESSON_DIALOGUES might be easier to just empty out and write a few for testing)
    lesson_dialogue_replacement = """const LESSON_DIALOGUES = {
	"dan_tranh_level_1_bai_1_practice": [
		{"action": "speak", "text": "Chào mừng bạn đến với bài học Đàn Tranh đầu tiên. Hôm nay chúng ta sẽ làm quen với 5 dây cơ bản: Sol, La, Đô, Rê, Mi.", "highlight": []},
		{"action": "speak", "text": "Dây đầu tiên là dây Sol1. Hãy dùng ngón tay gảy thử xem sao.", "highlight": [0]},
		{"action": "play", "note": "Sol1", "duration": 2.0},
		{"action": "speak", "text": "Tiếp theo là dây La1.", "highlight": [1]},
		{"action": "play", "note": "La1", "duration": 2.0},
		{"action": "speak", "text": "Rất tốt. Bây giờ hãy gảy dây Đô2.", "highlight": [2]},
		{"action": "play", "note": "Đô2", "duration": 2.0},
		{"action": "speak", "text": "Tiếp tục với dây Rê2.", "highlight": [3]},
		{"action": "play", "note": "Rê2", "duration": 2.0},
		{"action": "speak", "text": "Và cuối cùng là dây Mi2.", "highlight": [4]},
		{"action": "play", "note": "Mi2", "duration": 2.0},
		{"action": "speak", "text": "Tuyệt vời! Bây giờ chúng ta sẽ chuyển sang phần thực hành nốt rơi nhé.", "highlight": []}
	]
}"""

    # We need to replace LESSON_NOTES completely
    content = re.sub(r'const LESSON_NOTES = \{.*?(?=\nvar melody_sequence)', lesson_dialogue_replacement + '\n', content, flags=re.DOTALL)
    
    # Change _flute_body.finger_holes() to zither_board.pluck() or highlight
    content = content.replace('zither_board.finger_holes(', 'zither_board.highlight_strings(')
    content = content.replace('zither_board.finger_holes(curr_note.get("fingers", []))', 'zither_board.highlight_strings(curr_note.get("highlight", []))')
    
    # Dan Tranh doesn't have holes, it has strings. The highlight format will be an array of string indices.
    
    with open('scripts/LessonDanTranh.gd', 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    process()
