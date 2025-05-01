// Auto Hide Flash Hook
// 플래시 메시지를 1.5초 후에 자동으로 숨기는 훅 (프로그레스 바 포함)

const AutoHideFlash = {
  mounted() {
    // 표시 시간 설정 (1초 = 1000ms)
    const displayTime = 1000;

    // 프로그레스 바 요소 찾기
    const progressBar = this.el.querySelector(".flash-progress");

    // 프로그레스 바 애니메이션 설정
    if (progressBar) {
      // 초기 상태로 설정
      progressBar.style.width = "100%";

      // 부드러운 애니메이션을 위한 트랜지션 설정
      progressBar.style.transition = `width ${displayTime}ms cubic-bezier(0.25, 0.46, 0.45, 0.94)`;

      // 약간의 지연 후 애니메이션 시작 (DOM에 렌더링 시간 주기)
      requestAnimationFrame(() => {
        // 브라우저가 변경을 적용할 시간을 주기 위해 약간 지연
        setTimeout(() => {
          progressBar.style.width = "0%";
        }, 10);
      });
    }

    // 나타나는 효과
    this.el.classList.add("animate-shake");

    // 지정된 시간 후에 숨김
    this.timer = setTimeout(() => {
      // fade-out 효과 추가
      this.el.style.transition = "all 0.5s ease-in-out";
      this.el.style.opacity = "0";
      this.el.style.transform = "translateY(-10px)";

      // 애니메이션 완료 후 요소 숨김
      setTimeout(() => {
        this.el.style.display = "none";
      }, 500);
    }, displayTime);
  },

  // 페이지를 떠날 때 타이머 정리
  destroyed() {
    clearTimeout(this.timer);
  },
};

export default AutoHideFlash;
