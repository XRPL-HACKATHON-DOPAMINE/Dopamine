const ConfirmModal = {
  mounted() {
    this.handleEvent("show_confirm", ({ message, event, id }) => {
      // Create modal backdrop
      const backdrop = document.createElement('div');
      backdrop.className = 'fixed inset-0 bg-black bg-opacity-75 z-50 flex items-center justify-center';
      
      // Create modal content
      const modal = document.createElement('div');
      modal.className = 'bg-zinc-900 rounded-lg p-6 max-w-md w-full mx-4 border border-yellow-500/30';
      
      modal.innerHTML = `
        <h3 class="text-xl font-bold text-yellow-400 mb-4">확인</h3>
        <p class="text-gray-300 mb-6">${message}</p>
        <div class="flex justify-end space-x-3">
          <button class="px-4 py-2 bg-zinc-700 hover:bg-zinc-600 text-white rounded" id="cancel-btn">
            취소
          </button>
          <button class="px-4 py-2 bg-red-600 hover:bg-red-500 text-white rounded" id="confirm-btn">
            삭제
          </button>
        </div>
      `;
      
      backdrop.appendChild(modal);
      document.body.appendChild(backdrop);
      
      // Handle confirm
      modal.querySelector('#confirm-btn').addEventListener('click', () => {
        this.pushEvent(event, { id: id });
        document.body.removeChild(backdrop);
      });
      
      // Handle cancel
      modal.querySelector('#cancel-btn').addEventListener('click', () => {
        document.body.removeChild(backdrop);
      });
      
      // Close on backdrop click
      backdrop.addEventListener('click', (e) => {
        if (e.target === backdrop) {
          document.body.removeChild(backdrop);
        }
      });
      
      // Close on Escape key
      const handleEscape = (e) => {
        if (e.key === 'Escape') {
          document.body.removeChild(backdrop);
          document.removeEventListener('keydown', handleEscape);
        }
      };
      document.addEventListener('keydown', handleEscape);
    });
  }
};

export default ConfirmModal;
