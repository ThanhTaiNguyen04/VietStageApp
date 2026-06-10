/**
 * VietStage Web Prototype App Logic
 * Premium interactive features & Web Audio API synthesizers
 */

// Global State
const state = {
  currentTab: 'home',
  selectedInstrument: 'dan-tranh',
  learnInstrument: 'dan-tranh',
  difficultyFilter: 'all',
  recording: false,
  score: 75,
  streak: 7,
  xp: 1240,
  targetNote: 'Hò',
  targetStringIndex: 2,
  audioContext: null,
  practiceInterval: null,
  activeGame: null,
  gameScore: 0,
  quizCurrentQuestion: 1,
  quizCorrectNote: '',
  rhythmGameTimer: null,
  rhythmNotes: [],
  slowmo: false
};

// Web Audio API Pluck Synthesizer
function getAudioContext() {
  if (!state.audioContext) {
    state.audioContext = new (window.AudioContext || window.webkitAudioContext)();
  }
  if (state.audioContext.state === 'suspended') {
    state.audioContext.resume();
  }
  return state.audioContext;
}

const noteFreqs = {
  'Hò': 261.63,     // C4
  'Xự': 293.66,     // D4
  'Xang': 349.23,   // F4
  'Xê': 392.00,     // G4
  'Công': 440.00,   // A4
  'Liu': 523.25,    // C5
  'Ú': 587.33       // D5
};

function playPluckSound(noteName) {
  try {
    const ctx = getAudioContext();
    const freq = noteFreqs[noteName] || 261.63;
    
    const osc = ctx.createOscillator();
    const gainNode = ctx.createGain();
    
    // Add multiple harmonics for rich metallic traditional string timbre
    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(freq, ctx.currentTime);
    
    // Soft lowpass filter to make it sound like string pluck instead of harsh sawtooth
    const filter = ctx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(freq * 1.8, ctx.currentTime);
    filter.Q.setValueAtTime(3, ctx.currentTime);
    
    gainNode.gain.setValueAtTime(0.35, ctx.currentTime);
    // Exponential decay to represent natural pluck decay
    gainNode.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 1.8);
    
    osc.connect(filter);
    filter.connect(gainNode);
    gainNode.connect(ctx.destination);
    
    osc.start();
    osc.stop(ctx.currentTime + 1.8);
  } catch (e) {
    console.log("Audio not allowed yet: ", e);
  }
}

function playFluteSound(noteName) {
  try {
    const ctx = getAudioContext();
    const freq = noteFreqs[noteName] || 261.63;
    
    const osc = ctx.createOscillator();
    const gainNode = ctx.createGain();
    
    osc.type = 'sine';
    osc.frequency.setValueAtTime(freq, ctx.currentTime);
    
    // Gentle vibrato (6Hz frequency modulation)
    const vibrato = ctx.createOscillator();
    const vibratoGain = ctx.createGain();
    vibrato.frequency.value = 6;
    vibratoGain.gain.value = 3;
    
    vibrato.connect(vibratoGain);
    vibratoGain.connect(osc.frequency);
    
    gainNode.gain.setValueAtTime(0.01, ctx.currentTime);
    gainNode.gain.linearRampToValueAtTime(0.28, ctx.currentTime + 0.1);
    gainNode.gain.linearRampToValueAtTime(0.001, ctx.currentTime + 1.2);
    
    vibrato.start();
    osc.connect(gainNode);
    gainNode.connect(ctx.destination);
    
    osc.start();
    vibrato.stop(ctx.currentTime + 1.2);
    osc.stop(ctx.currentTime + 1.2);
  } catch (e) {
    console.log("Audio failure: ", e);
  }
}

// Navigation & Routing
document.addEventListener('DOMContentLoaded', () => {
  setupNavigation();
  setupCountdown();
  setupCharts();
  setupPracticeStrings();
  setupRhythmVisualizer();
});

function setupNavigation() {
  const links = document.querySelectorAll('.nav-link');
  links.forEach(link => {
    link.addEventListener('click', (e) => {
      e.preventDefault();
      const pageId = link.getAttribute('data-page');
      navigateTo(pageId);
    });
  });
}

function navigateTo(pageId) {
  // Update nav links active class
  document.querySelectorAll('.nav-link').forEach(l => {
    if (l.getAttribute('data-page') === pageId) {
      l.classList.add('active');
    } else {
      l.classList.remove('active');
    }
  });

  // Toggle pages
  document.querySelectorAll('.page').forEach(page => {
    page.classList.remove('active');
  });
  
  const targetPage = document.getElementById(`page-${pageId}`);
  if (targetPage) {
    targetPage.classList.add('active');
  }
  
  state.currentTab = pageId;
  window.scrollTo(0, 0);
  
  // Close any running game
  if (pageId !== 'games') {
    closeGame();
  }
}

// Countdown Timer for Daily Challenge
function setupCountdown() {
  const timerEl = document.getElementById('challengeTimer');
  if (!timerEl) return;
  
  let hours = 8, minutes = 42, seconds = 17;
  
  setInterval(() => {
    seconds--;
    if (seconds < 0) {
      seconds = 59;
      minutes--;
      if (minutes < 0) {
        minutes = 59;
        hours--;
        if (hours < 0) {
          hours = 23;
        }
      }
    }
    
    const hStr = String(hours).padStart(2, '0');
    const mStr = String(minutes).padStart(2, '0');
    const sStr = String(seconds).padStart(2, '0');
    timerEl.textContent = `${hStr}:${mStr}:${sStr}`;
  }, 1000);
}

// Home Page Instrument Selection
function selectInstrument(card, instId) {
  document.querySelectorAll('.instrument-card').forEach(c => {
    c.classList.remove('selected');
    const badge = c.querySelector('.instrument-select-badge');
    if (badge) badge.remove();
  });
  
  card.classList.add('selected');
  
  const badge = document.createElement('div');
  badge.className = 'instrument-select-badge';
  badge.textContent = '✓ Đã chọn';
  card.appendChild(badge);
  
  state.selectedInstrument = instId;
}

// Learn Page Category Swapping
function switchLearnTab(btn) {
  document.querySelectorAll('#learnTabs .tab-btn').forEach(b => {
    b.classList.remove('active', 'tab-active', 'text-lacquer');
  });
  btn.classList.add('active', 'tab-active', 'text-lacquer');
  state.learnInstrument = btn.getAttribute('data-tab');
  
  const pathEl = document.getElementById('lessonPath');
  if (state.learnInstrument === 'dan-tranh' || state.learnInstrument === 'sao-truc') {
    pathEl.style.opacity = 1;
    // Update labels inside the path
    const h3 = pathEl.querySelector('.path-section-header h3');
    const p = pathEl.querySelector('.path-section-header p');
    if (state.learnInstrument === 'dan-tranh') {
      h3.textContent = "Gói Cơ Bản (Đàn Tranh)";
      p.textContent = "8 bài · Đã hoàn thành 3/8";
    } else {
      h3.textContent = "Gói Cơ Bản (Sáo Trúc)";
      p.textContent = "6 bài · Đã hoàn thành 1/6";
    }
  } else {
    // Other instruments not ready yet
    pathEl.style.opacity = 0.5;
  }
}

// Difficulty Filter
function filterDifficulty(btn, diff) {
  document.querySelectorAll('.difficulty-filter .diff-btn').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  state.difficultyFilter = diff;
  
  const sections = document.querySelectorAll('.path-section');
  sections.forEach(sec => {
    const secDiff = sec.getAttribute('data-difficulty');
    if (diff === 'all' || secDiff === diff) {
      sec.style.display = 'block';
    } else {
      sec.style.display = 'none';
    }
  });
}

// Practice Strings Initialization
function setupPracticeStrings() {
  const container = document.getElementById('dtStrings');
  if (!container) return;
  
  container.innerHTML = '';
  const notes = ['Hò', 'Xự', 'Xang', 'Xê', 'Công', 'Hò', 'Xự', 'Xang', 'Xê', 'Công'];
  
  notes.forEach((note, idx) => {
    const string = document.createElement('div');
    string.className = 'dt-string';
    if (idx === state.targetStringIndex) {
      string.classList.add('is-target');
    }
    
    string.addEventListener('mousedown', () => {
      pluckString(string, note, idx);
    });
    
    container.appendChild(string);
  });
  
  updateFingerIndicator();
}

function pluckString(stringEl, note, index) {
  getAudioContext();
  
  stringEl.classList.add('active-pluck');
  setTimeout(() => {
    stringEl.classList.remove('active-pluck');
  }, 400);
  
  playPluckSound(note);
  
  // Real-time Pitch Detection Simulation
  const pitchNoteName = document.getElementById('pitchNoteName');
  const pitchCents = document.getElementById('pitchCents');
  const needle = document.getElementById('pitchNeedle');
  
  if (pitchNoteName && pitchCents && needle) {
    pitchNoteName.textContent = note;
    const centsOffset = Math.round(Math.random() * 20 - 10);
    pitchCents.textContent = (centsOffset >= 0 ? '+' : '') + centsOffset + '¢';
    
    // Position the needle
    const percent = 50 + (centsOffset / 50) * 50;
    needle.style.left = `${percent}%`;
  }
  
  // Update state check
  if (index === state.targetStringIndex) {
    // Advance target
    state.targetStringIndex = (state.targetStringIndex + 1) % 10;
    
    document.querySelectorAll('.dt-string').forEach((s, idx) => {
      if (idx === state.targetStringIndex) {
        s.classList.add('is-target');
      } else {
        s.classList.remove('is-target');
      }
    });
    
    // Speech feedback from Linh
    const speech = document.getElementById('vaSpeech');
    if (speech) {
      const positiveLines = [
        "Làm tốt lắm! Đúng cao độ rồi đó.",
        "Rung âm rất mượt mà. Tiếp tục đi nào!",
        "Chính xác! Giữ ngón đều đặn nhé.",
        "Tiếng đàn rền và sáng lắm!"
      ];
      speech.textContent = positiveLines[Math.floor(Math.random() * positiveLines.length)];
    }
    
    state.score = Math.min(100, state.score + 5);
    updateScoreArc();
    updateFingerIndicator();
  }
}

function updateFingerIndicator() {
  const indicator = document.getElementById('fingerIndicator');
  if (!indicator) return;
  
  const strings = document.querySelectorAll('.dt-string');
  if (strings.length > state.targetStringIndex) {
    const targetString = strings[state.targetStringIndex];
    const rect = targetString.getBoundingClientRect();
    const parentRect = targetString.parentElement.getBoundingClientRect();
    
    const top = targetString.offsetTop;
    indicator.style.top = `${top - 10}px`;
    indicator.style.left = '60%';
    indicator.style.display = 'flex';
  }
}

// Update Score Ring Circle Dasharray
function updateScoreArc() {
  const arc = document.getElementById('scoreArc');
  const scoreNum = document.getElementById('scoreNum');
  if (!arc || !scoreNum) return;
  
  scoreNum.textContent = state.score;
  const radius = 40;
  const circumference = 2 * Math.PI * radius; // ~251.3
  const offset = circumference - (state.score / 100) * circumference;
  arc.style.strokeDashoffset = offset;
}

// Reference Audio Playback Simulation
let isRefPlaying = false;
let refAudioInterval = null;

function toggleRefAudio() {
  const playBtn = document.getElementById('refPlayBtn');
  const timeEl = document.getElementById('refAudioTime');
  const canvas = document.getElementById('waveformCanvas');
  
  if (!playBtn || !canvas) return;
  
  getAudioContext();
  const ctx = canvas.getContext('2d');
  
  if (isRefPlaying) {
    clearInterval(refAudioInterval);
    isRefPlaying = false;
    playBtn.textContent = '▶';
    ctx.clearRect(0, 0, canvas.width, canvas.height);
  } else {
    isRefPlaying = true;
    playBtn.textContent = '⏸';
    let time = 0;
    
    const intervalTime = state.slowmo ? 1000 : 500;
    const stepTime = state.slowmo ? 0.25 : 0.5;
    
    refAudioInterval = setInterval(() => {
      time += stepTime;
      if (time > 23) {
        clearInterval(refAudioInterval);
        isRefPlaying = false;
        playBtn.textContent = '▶';
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        return;
      }
      
      const sec = Math.floor(time % 60);
      timeEl.textContent = `0:${sec.toString().padStart(2, '0')} / 0:23`;
      
      // Draw simulated waveform jumping
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      ctx.fillStyle = '#C59426';
      for (let i = 0; i < 20; i++) {
        const h = Math.random() * 40 + 5;
        ctx.fillRect(i * 11 + 5, 25 - h/2, 6, h);
      }
      
      // Play brief synth sound mimicking reference
      playPluckSound('Hò');
    }, intervalTime);
  }
}

// Recording & Real-time Evaluation Simulation
function toggleRecording() {
  const btn = document.getElementById('recordBtn');
  const text = document.getElementById('recordBtnText');
  const rcStatus = document.getElementById('rcStatus');
  
  if (!btn || !text || !rcStatus) return;
  
  getAudioContext();
  
  if (state.recording) {
    // Stop recording
    state.recording = false;
    btn.classList.remove('recording');
    text.textContent = 'Bắt đầu luyện tập';
    rcStatus.classList.remove('active');
    rcStatus.querySelector('span').textContent = 'Sẵn sàng ghi âm';
    
    clearInterval(state.practiceInterval);
    document.getElementById('micLevel').style.width = '0%';
    
    // Show results
    showResultModal();
  } else {
    // Start recording
    state.recording = true;
    btn.classList.add('recording');
    text.textContent = 'Dừng luyện tập';
    rcStatus.classList.add('active');
    rcStatus.querySelector('span').textContent = 'Đang nhận dạng âm thanh...';
    
    let time = 0;
    state.practiceInterval = setInterval(() => {
      time += 0.1;
      
      // Mic level simulation
      const level = Math.random() * 80 + 10;
      document.getElementById('micLevel').style.width = `${level}%`;
      
      // Randomly trigger pitch evaluation while recording
      if (Math.random() > 0.8) {
        const notes = ['Hò', 'Xự', 'Xang', 'Xê', 'Công'];
        const randomNote = notes[Math.floor(Math.random() * notes.length)];
        const cents = Math.round(Math.random() * 26 - 13);
        
        const pitchNoteName = document.getElementById('pitchNoteName');
        const pitchCents = document.getElementById('pitchCents');
        const needle = document.getElementById('pitchNeedle');
        
        if (pitchNoteName) pitchNoteName.textContent = randomNote;
        if (pitchCents) pitchCents.textContent = (cents >= 0 ? '+' : '') + cents + '¢';
        if (needle) needle.style.left = `${50 + (cents / 50) * 50}%`;
        
        // Random rhythm bars jump
        updateRhythmBars();
      }
    }, 100);
  }
}

function updateRhythmBars() {
  const container = document.getElementById('rhythmBars');
  const accuracy = document.getElementById('rhythmAccuracy');
  if (!container || !accuracy) return;
  
  const bars = container.querySelectorAll('.rhythm-bar');
  let correctCount = 0;
  
  bars.forEach(bar => {
    const h = Math.random() * 38 + 10;
    bar.style.height = `${h}px`;
    if (Math.random() > 0.3) {
      bar.style.backgroundColor = '#1E5E3A'; // correct match green
      correctCount++;
    } else {
      bar.style.backgroundColor = '#C59426'; // off beat orange
    }
  });
  
  const pct = Math.round((correctCount / bars.length) * 100);
  accuracy.textContent = `Khớp nhịp: ${pct}%`;
}

function setupRhythmVisualizer() {
  const container = document.getElementById('rhythmBars');
  if (!container) return;
  container.innerHTML = '';
  for (let i = 0; i < 14; i++) {
    const bar = document.createElement('div');
    bar.className = 'rhythm-bar';
    container.appendChild(bar);
  }
}

function resetPractice() {
  state.score = 75;
  state.targetStringIndex = 2;
  updateScoreArc();
  setupPracticeStrings();
  
  const speech = document.getElementById('vaSpeech');
  if (speech) speech.textContent = "Hãy bắt đầu lại nào. Gảy từng dây theo nốt chỉ định.";
}

// Modals controller
function showHint() {
  const modal = document.getElementById('hintModal');
  if (modal) modal.style.display = 'flex';
}

function showResultModal() {
  const modal = document.getElementById('resultModal');
  if (!modal) return;
  
  // Set rating depending on score
  const title = document.getElementById('resultTitle');
  const stars = document.getElementById('resultStars');
  if (state.score >= 90) {
    title.textContent = "Xuất sắc!";
    stars.textContent = "⭐⭐⭐";
  } else if (state.score >= 80) {
    title.textContent = "Tốt lắm!";
    stars.textContent = "⭐⭐☆";
  } else {
    title.textContent = "Cố gắng thêm nhé!";
    stars.textContent = "⭐☆☆";
  }
  
  modal.style.display = 'flex';
}

function closeModal(id) {
  const modal = document.getElementById(id);
  if (modal) modal.style.display = 'none';
}

function nextLesson() {
  closeModal('resultModal');
  navigateTo('learn');
}

// MINI-GAMES INTERACTION
function openGame(gameType) {
  // Hide cards
  document.querySelector('.games-grid').style.display = 'none';
  state.activeGame = gameType;
  
  if (gameType === 'rhythm') {
    document.getElementById('rhythmGame').style.display = 'block';
    startRhythmGame();
  } else if (gameType === 'quiz') {
    document.getElementById('quizGame').style.display = 'block';
    startQuizGame();
  }
}

function closeGame() {
  document.querySelector('.games-grid').style.display = 'grid';
  document.getElementById('rhythmGame').style.display = 'none';
  document.getElementById('quizGame').style.display = 'none';
  
  clearInterval(state.rhythmGameTimer);
  state.activeGame = null;
}

// Rhythm Game logic
function startRhythmGame() {
  state.gameScore = 0;
  document.getElementById('rhythmScore').textContent = '0';
  document.getElementById('rhythmFeedback').textContent = 'Sẵn sàng...';
  
  const lane = document.getElementById('rhythmLane');
  lane.innerHTML = '';
  state.rhythmNotes = [];
  
  // Spawn notes at intervals
  let tick = 0;
  state.rhythmGameTimer = setInterval(() => {
    tick++;
    
    // Move existing notes
    state.rhythmNotes.forEach((n, idx) => {
      n.pos += 4;
      n.el.style.left = `${n.pos}px`;
      
      // Auto-miss if note goes off track
      if (n.pos > 540 && !n.hit) {
        n.hit = true;
        document.getElementById('rhythmFeedback').textContent = 'MISS!';
        document.getElementById('rhythmFeedback').style.color = '#B31F14';
      }
    });
    
    // Clean up old notes
    state.rhythmNotes = state.rhythmNotes.filter(n => n.pos < 600);
    
    // Spawn new note
    if (tick % 16 === 0 || Math.random() > 0.85) {
      const noteEl = document.createElement('div');
      noteEl.className = 'rhythm-node-web';
      noteEl.style.left = '0px';
      lane.appendChild(noteEl);
      
      state.rhythmNotes.push({
        el: noteEl,
        pos: 0,
        hit: false
      });
    }
  }, 40);
  
  // Handle keyboard interaction
  window.addEventListener('keydown', handleSpacebar);
}

function handleSpacebar(e) {
  if (e.code === 'Space' && state.activeGame === 'rhythm') {
    e.preventDefault();
    tapRhythm();
  }
}

function tapRhythm() {
  getAudioContext();
  playPluckSound('Xê'); // play percussion sound
  
  // Check closest note to hit zone (hit zone is between 460px and 500px, target 480px)
  let bestNote = null;
  let minDiff = 999;
  
  state.rhythmNotes.forEach(n => {
    if (!n.hit) {
      const diff = Math.abs(n.pos - 480);
      if (diff < minDiff) {
        minDiff = diff;
        bestNote = n;
      }
    }
  });
  
  const feedback = document.getElementById('rhythmFeedback');
  
  if (bestNote && minDiff < 70) {
    bestNote.hit = true;
    bestNote.el.style.transform = 'scale(1.5)';
    bestNote.el.style.opacity = '0';
    
    if (minDiff < 15) {
      feedback.textContent = 'PERFECT!';
      feedback.style.color = '#1E5E3A';
      state.gameScore += 100;
    } else if (minDiff < 35) {
      feedback.textContent = 'GREAT!';
      feedback.style.color = '#C59426';
      state.gameScore += 70;
    } else {
      feedback.textContent = 'GOOD';
      feedback.style.color = '#6E6053';
      state.gameScore += 40;
    }
  } else {
    feedback.textContent = 'MISS!';
    feedback.style.color = '#B31F14';
  }
  
  document.getElementById('rhythmScore').textContent = state.gameScore;
}

// Pitch Quiz Game logic
function startQuizGame() {
  state.gameScore = 0;
  state.quizCurrentQuestion = 1;
  document.getElementById('quizScore').textContent = '0';
  document.getElementById('quizQ').textContent = '1';
  document.getElementById('quizFeedback').textContent = 'Nhấn nút phát nhạc và đoán nốt!';
  
  loadNextQuizQuestion();
}

function loadNextQuizQuestion() {
  if (state.quizCurrentQuestion > 10) {
    document.getElementById('quizFeedback').textContent = `Kết thúc! Bạn đạt ${state.gameScore} / 1000 điểm.`;
    return;
  }
  
  document.getElementById('quizQ').textContent = state.quizCurrentQuestion;
  
  // Pick correct note
  const notes = ['Hò', 'Xự', 'Xang', 'Xê', 'Công', 'Liu', 'Ú'];
  state.quizCorrectNote = notes[Math.floor(Math.random() * notes.length)];
  
  // Generate options
  const opts = [state.quizCorrectNote];
  while (opts.size < 4 && opts.length < 4) {
    const rNote = notes[Math.floor(Math.random() * notes.length)];
    if (!opts.includes(rNote)) {
      opts.push(rNote);
    }
  }
  opts.sort();
  
  // Render buttons
  const container = document.getElementById('quizOptions');
  container.innerHTML = '';
  
  opts.forEach(opt => {
    const btn = document.createElement('button');
    btn.className = 'quiz-opt-btn';
    btn.textContent = opt;
    btn.onclick = () => selectQuizAnswer(opt, btn);
    container.appendChild(btn);
  });
}

function playQuizNote() {
  getAudioContext();
  playFluteSound(state.quizCorrectNote);
}

function selectQuizAnswer(ans, btn) {
  const buttons = document.querySelectorAll('.quiz-opt-btn');
  buttons.forEach(b => b.disabled = true);
  
  const feedback = document.getElementById('quizFeedback');
  
  if (ans === state.quizCorrectNote) {
    btn.classList.add('correct');
    feedback.textContent = 'Chính xác! +100 điểm.';
    feedback.style.color = '#1E5E3A';
    state.gameScore += 100;
    document.getElementById('quizScore').textContent = state.gameScore;
  } else {
    btn.classList.add('wrong');
    feedback.textContent = `Sai rồi! Nốt đúng là: ${state.quizCorrectNote}`;
    feedback.style.color = '#B31F14';
    
    // Highlight correct
    buttons.forEach(b => {
      if (b.textContent === state.quizCorrectNote) {
        b.classList.add('correct');
      }
    });
  }
  
  setTimeout(() => {
    state.quizCurrentQuestion++;
    loadNextQuizQuestion();
    feedback.textContent = 'Hãy nghe nốt nhạc và chọn nốt đúng.';
    feedback.style.color = 'inherit';
  }, 2000);
}

// Render dynamic visual charts in Progress page
function setupCharts() {
  // Accuracy chart
  const accChart = document.getElementById('accuracyChart');
  if (accChart) {
    accChart.innerHTML = '';
    const days = ['Th 2', 'Th 3', 'Th 4', 'Th 5', 'Th 6', 'Th 7', 'CN'];
    const pitchData = [65, 70, 72, 75, 78, 80, 82];
    const rhythmData = [58, 62, 65, 70, 71, 74, 76];
    
    days.forEach((day, idx) => {
      const group = document.createElement('div');
      group.className = 'chart-bar-group';
      
      const doubleBars = document.createElement('div');
      doubleBars.className = 'chart-double-bars';
      
      const pBar = document.createElement('div');
      pBar.className = 'c-bar pitch';
      pBar.style.height = `${pitchData[idx]}%`;
      pBar.title = `Cao độ: ${pitchData[idx]}%`;
      
      const rBar = document.createElement('div');
      rBar.className = 'c-bar rhythm';
      rBar.style.height = `${rhythmData[idx]}%`;
      rBar.title = `Nhịp điệu: ${rhythmData[idx]}%`;
      
      doubleBars.appendChild(pBar);
      doubleBars.appendChild(rBar);
      
      const label = document.createElement('span');
      label.className = 'bar-label';
      label.textContent = day;
      
      group.appendChild(doubleBars);
      group.appendChild(label);
      accChart.appendChild(group);
    });
  }
  
  // Heatmap
  const heatmap = document.getElementById('practiceHeatmap');
  if (heatmap) {
    heatmap.innerHTML = '';
    // Generate 28 days
    for (let i = 0; i < 28; i++) {
      const day = document.createElement('div');
      // Randomly assign level of study duration
      const level = Math.floor(Math.random() * 5);
      day.className = `hm-day hm-${level}`;
      day.title = `Ngày ${i + 1}: ${level * 15} phút luyện tập`;
      heatmap.appendChild(day);
    }
  }
}

// Slowmo Toggle
function toggleSlowmo() {
  const btn = document.getElementById('slowmoBtn');
  if (!btn) return;
  
  state.slowmo = !state.slowmo;
  if (state.slowmo) {
    btn.classList.add('bg-lacquer', 'text-white');
    btn.classList.remove('text-lacquer');
  } else {
    btn.classList.remove('bg-lacquer', 'text-white');
    btn.classList.add('text-lacquer');
  }
}

// Virtual Artist Speech Interaction
window.vaSpeak = function(type) {
  getAudioContext();
  const speech = document.getElementById('vaSpeech');
  if (!speech) return;
  
  if (type === 'demo') {
    speech.textContent = "Đang phát bản nhạc mẫu cho bạn...";
    let demoNotes = ['Hò', 'Xự', 'Xang', 'Xê', 'Công'];
    let delay = 0;
    demoNotes.forEach(note => {
      setTimeout(() => {
        if (state.currentTab === 'practice') {
          playPluckSound(note);
          const noteIndex = ['Hò', 'Xự', 'Xang', 'Xê', 'Công', 'Liu', 'Ú'].indexOf(note);
          if (noteIndex !== -1) {
            const strings = document.querySelectorAll('.dt-string');
            if (strings[noteIndex]) {
              strings[noteIndex].classList.add('active-pluck');
              setTimeout(() => strings[noteIndex].classList.remove('active-pluck'), 300);
            }
          }
        }
      }, delay);
      delay += 500;
    });
  } else if (type === 'slow') {
    speech.textContent = "Hãy cùng nghe ở tốc độ chậm nhé.";
    let demoNotes = ['Hò', 'Xự', 'Xang', 'Xê', 'Công'];
    let delay = 0;
    demoNotes.forEach(note => {
      setTimeout(() => {
        if (state.currentTab === 'practice') {
          playPluckSound(note);
          const noteIndex = ['Hò', 'Xự', 'Xang', 'Xê', 'Công', 'Liu', 'Ú'].indexOf(note);
          if (noteIndex !== -1) {
            const strings = document.querySelectorAll('.dt-string');
            if (strings[noteIndex]) {
              strings[noteIndex].classList.add('active-pluck');
              setTimeout(() => strings[noteIndex].classList.remove('active-pluck'), 300);
            }
          }
        }
      }, delay);
      delay += 1000;
    });
  }
};
