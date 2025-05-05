const EmotionAnalyzer = {
  mounted() {
    this.handleInput = this.handleInput.bind(this);
    this.contentInput = this.el.querySelector("textarea");
    
    if (this.contentInput) {
      this.contentInput.addEventListener("input", this.handleInput);
    }
    
    // 감정 분석 결과를 표시할 UI 요소 생성
    this.emotionResult = document.createElement("div");
    this.emotionResult.className = "emotion-result mt-2 text-sm flex items-center";
    this.el.appendChild(this.emotionResult);
    
    // 서버로부터의 감정 분석 결과 이벤트 처리
    this.handleEvent("emotion_result", (result) => {
      this.updateEmotionResult(result);
    });
  },

  handleInput(event) {
    clearTimeout(this.debounceTimer);
    
    const content = event.target.value.trim();
    
    // 글자 수가 너무 적으면 분석하지 않음
    if (content.length < 5) {
      this.emotionResult.innerHTML = "";
      return;
    }
    
    // 디바운스 적용 (300ms)
    this.debounceTimer = setTimeout(() => {
      this.pushEventTo(this.el, "analyze_emotion", { content });
    }, 300);
  },
  
  destroyed() {
    if (this.contentInput) {
      this.contentInput.removeEventListener("input", this.handleInput);
    }
  },
  
  // 서버에서 감정 분석 결과를 받아서 표시
  updateEmotionResult(result) {
    let emoji, label, colorClass;
    
    // 가장 높은 점수의 감정 레이블 찾기
    if (result.label === "LABEL_0") {
      emoji = "😊";
      label = "긍정적";
      colorClass = "text-green-400";
    } else if (result.label === "LABEL_1") {
      emoji = "😡";
      label = "부정적";
      colorClass = "text-red-400";
    } else {
      emoji = "😐";
      label = "중립적";
      colorClass = "text-gray-400";
    }
    
    // 점수를 퍼센트로 변환
    const score = Math.round(result.score * 100);
    
    // 결과 UI 업데이트
    this.emotionResult.innerHTML = `
      <span class="mr-1">${emoji}</span>
      <span class="${colorClass}">${label} (${score}%)</span>
    `;
  }
};

export default EmotionAnalyzer;