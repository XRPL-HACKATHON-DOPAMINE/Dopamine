// assets/js/hooks/countdown_timer.js
const CountdownTimer = {
  mounted() {
    // 종료 시간 추출
    const endTimeISO = this.el.dataset.endTime;
    this.endTime = new Date(endTimeISO);

    // 타이머 설정 (1초마다 업데이트)
    this.timer = setInterval(() => this.updateTimer(), 1000);
    this.updateTimer(); // 즉시 첫 업데이트 실행
  },

  destroyed() {
    // LiveView가 언마운트되면 타이머 정리
    if (this.timer) {
      clearInterval(this.timer);
    }
  },

  updateTimer() {
    const now = new Date();
    let diff = this.endTime - now; // 밀리초 단위 차이

    if (diff <= 0) {
      // 시간이 종료된 경우
      this.setTimeDisplay(0, 0, 0, 0);
      clearInterval(this.timer);
      return;
    }

    // 일, 시간, 분, 초 계산
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));
    diff -= days * (1000 * 60 * 60 * 24);

    const hours = Math.floor(diff / (1000 * 60 * 60));
    diff -= hours * (1000 * 60 * 60);

    const minutes = Math.floor(diff / (1000 * 60));
    diff -= minutes * (1000 * 60);

    const seconds = Math.floor(diff / 1000);

    // UI 업데이트
    this.setTimeDisplay(days, hours, minutes, seconds);
  },

  setTimeDisplay(days, hours, minutes, seconds) {
    // 각 요소에 시간 값 설정
    this.el.querySelector(".days-value").textContent = days;
    this.el.querySelector(".hours-value").textContent = hours
      .toString()
      .padStart(2, "0");
    this.el.querySelector(".minutes-value").textContent = minutes
      .toString()
      .padStart(2, "0");
    this.el.querySelector(".seconds-value").textContent = seconds
      .toString()
      .padStart(2, "0");
  },
};

export default CountdownTimer;
