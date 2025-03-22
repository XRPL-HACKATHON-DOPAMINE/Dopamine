import { MetaMaskSDK, SDKProvider } from "@metamask/sdk";

let Hooks = {};

Hooks.MetaMaskHeader = {
  mounted() {
    console.log("MetaMask 헤더 훅 마운트됨");
    // 지연 시작으로 DOM이 완전히 로드된 후 초기화
    setTimeout(() => this.initMetaMask(), 100);

    // 연결 버튼 이벤트 리스너 추가
    this.el
      .querySelector("#connect-wallet-btn")
      ?.addEventListener("click", () => {
        this.connectMetaMask();
      });
  },

  initMetaMask() {
    console.log("MetaMask 초기화 시작");

    // 전역 ethereum 객체 확인 (MetaMask 확장 프로그램이 제공)
    if (window.ethereum) {
      console.log("MetaMask 확장 프로그램 감지됨");
      this.provider = window.ethereum;

      // 이벤트 리스너 설정
      this.provider.on("accountsChanged", (accounts) => {
        console.log("계정 변경됨:", accounts);
        if (accounts.length > 0) {
          this.currentAccount = accounts[0]; // 현재 계정 저장
          this.updateHeaderUI(accounts[0]);
          this.getWalletInfo(accounts[0]);
        } else {
          this.currentAccount = null;
          this.updateHeaderUI(null);
        }
      });

      this.provider.on("chainChanged", (chainId) => {
        console.log("체인 변경됨:", chainId);
        // 체인 변경 시 자동으로 지갑 정보 업데이트
        if (this.currentAccount) {
          this.getWalletInfo(this.currentAccount);
        }
      });

      this.provider.on("disconnect", (error) => {
        console.log("MetaMask 연결 해제:", error);
        this.currentAccount = null;
        this.updateHeaderUI(null);
      });

      // 자동 연결 시도
      this.provider
        .request({ method: "eth_accounts" })
        .then((accounts) => {
          if (accounts.length > 0) {
            this.currentAccount = accounts[0]; // 현재 계정 저장
            this.updateHeaderUI(accounts[0]);
            // 연결 후 자동으로 지갑 정보 조회
            this.getWalletInfo(accounts[0]);
          }
        })
        .catch((error) => {
          console.error("자동 연결 오류:", error);
        });
    } else {
      console.warn(
        "MetaMask를 찾을 수 없습니다. 확장 프로그램이 설치되어 있나요?",
      );
      this.updateHeaderUI(null, true);
    }
  },

  async connectMetaMask() {
    console.log("MetaMask 연결 시도");

    if (!this.provider) {
      console.error("MetaMask 제공자가 초기화되지 않았습니다");
      // MetaMask 설치 페이지로 이동
      window.open("https://metamask.io/download/", "_blank");
      return null;
    }

    try {
      // 계정 요청
      const accounts = await this.provider.request({
        method: "eth_requestAccounts",
      });
      const account = accounts[0];
      this.currentAccount = account; // 현재 계정 저장

      console.log("MetaMask 연결 성공:", account);
      this.updateHeaderUI(account);

      // 연결 직후 지갑 정보 조회
      this.getWalletInfo(account);

      return account;
    } catch (error) {
      console.error("MetaMask 연결 오류:", error);
      return null;
    }
  },

  // 계정 잔액 조회
  async getBalance(address) {
    if (!this.provider) {
      console.error("Provider가 초기화되지 않았습니다");
      return null;
    }

    try {
      // 이더리움 잔액 조회 (wei 단위로 반환됨)
      const balanceWei = await this.provider.request({
        method: "eth_getBalance",
        params: [address, "latest"],
      });

      // wei를 이더 단위로 변환 (10^18 wei = 1 ETH)
      const balanceEth = parseInt(balanceWei, 16) / Math.pow(10, 18);

      console.log(`지갑 ${address}의 잔액: ${balanceEth} ETH`);
      return {
        wei: balanceWei,
        eth: balanceEth,
      };
    } catch (error) {
      console.error("잔액 조회 오류:", error);
      return null;
    }
  },

  // 현재 네트워크 정보 조회
  async getNetworkInfo() {
    if (!this.provider) {
      console.error("Provider가 초기화되지 않았습니다");
      return null;
    }

    try {
      // 체인 ID 조회
      const chainId = await this.provider.request({ method: "eth_chainId" });

      // 체인 ID에 따른 네트워크 이름 매핑
      const networks = {
        "0x1": "Ethereum Mainnet",
        "0x3": "Ropsten Testnet",
        "0x4": "Rinkeby Testnet",
        "0x5": "Goerli Testnet",
        "0xaa36a7": "Sepolia Testnet",
        "0x2a": "Kovan Testnet",
        "0x38": "Binance Smart Chain",
        "0x89": "Polygon (Matic)",
        "0xa86a": "Avalanche",
      };

      const networkName = networks[chainId] || `Unknown Network (${chainId})`;
      const isTestnet = networkName.toLowerCase().includes("testnet");

      return {
        chainId,
        networkName,
        isTestnet,
      };
    } catch (error) {
      console.error("네트워크 정보 조회 오류:", error);
      return null;
    }
  },

  // 지갑의 모든 주요 정보를 한 번에 조회
  async getWalletInfo(address) {
    if (!address || !this.provider) {
      console.error("주소 또는 Provider가 유효하지 않습니다");
      return null;
    }

    try {
      // 병렬로 여러 정보 조회
      const [balanceInfo, networkInfo] = await Promise.all([
        this.getBalance(address),
        this.getNetworkInfo(),
      ]);

      // 종합 정보
      const walletInfo = {
        address,
        balance: balanceInfo,
        network: networkInfo,
        timestamp: new Date().toISOString(),
      };

      console.log("지갑 정보 조회 결과:", walletInfo);

      // 헤더 UI 업데이트
      this.updateHeaderBalance(walletInfo);

      // LiveView로 정보 전송 (백엔드에서 필요한 경우)
      this.pushEvent("metamask-wallet-info", walletInfo);

      return walletInfo;
    } catch (error) {
      console.error("지갑 정보 조회 오류:", error);
      return null;
    }
  },

  // 헤더 UI 업데이트 함수
  updateHeaderUI(account, notInstalled = false) {
    const walletInfo = this.el.querySelector("#wallet-info");
    const coinValue = this.el.querySelector("#coin-value");
    const connectBtn = this.el.querySelector("#connect-wallet-btn");

    if (notInstalled) {
      // MetaMask가 설치되지 않은 경우
      if (walletInfo) walletInfo.textContent = "MetaMask 필요";
      if (walletInfo) walletInfo.classList.add("text-red-500");
      if (coinValue) coinValue.classList.add("hidden");
      if (connectBtn) {
        connectBtn.textContent = "MetaMask 설치";
        connectBtn.onclick = () =>
          window.open("https://metamask.io/download/", "_blank");
      }
      return;
    }

    if (account) {
      // 연결된 경우
      const shortAddress = `${account.substring(0, 6)}...${account.substring(38)}`;
      if (walletInfo) {
        walletInfo.textContent = shortAddress;
        walletInfo.classList.remove("text-red-500");
        walletInfo.classList.add("text-green-500");
      }
      if (connectBtn) {
        connectBtn.textContent = "연결됨";
        connectBtn.disabled = true;
        connectBtn.classList.add("bg-gray-500");
        connectBtn.classList.remove("bg-yellow-400", "hover:bg-yellow-500");
      }
    } else {
      // 연결되지 않은 경우
      if (walletInfo) {
        walletInfo.textContent = "지갑 연결 필요";
        walletInfo.classList.remove("text-red-500", "text-green-500");
      }
      if (coinValue) coinValue.classList.add("hidden");
      if (connectBtn) {
        connectBtn.textContent = "지갑 연결";
        connectBtn.disabled = false;
        connectBtn.classList.remove("bg-gray-500");
        connectBtn.classList.add("bg-yellow-400", "hover:bg-yellow-500");
      }
    }
  },

  // 잔액 업데이트 함수
  updateHeaderBalance(walletInfo) {
    const coinValue = this.el.querySelector("#coin-value");
    if (!coinValue) return;

    if (walletInfo && walletInfo.balance) {
      const balance = walletInfo.balance.eth;
      const networkName = walletInfo.network?.networkName || "";
      const isTestnet = walletInfo.network?.isTestnet || false;

      // 잔액 표시
      coinValue.textContent = `${balance.toFixed(4)} ETH`;
      coinValue.classList.remove("hidden");

      // 테스트넷이면 다른 색상으로 표시
      if (isTestnet) {
        coinValue.classList.remove("text-yellow-400");
        coinValue.classList.add("text-blue-400");
      } else {
        coinValue.classList.remove("text-blue-400");
        coinValue.classList.add("text-yellow-400");
      }
    } else {
      coinValue.classList.add("hidden");
    }
  },
};

export default Hooks;
