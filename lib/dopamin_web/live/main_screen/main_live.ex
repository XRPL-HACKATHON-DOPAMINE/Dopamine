defmodule DopaminWeb.MainScreen.MainLive do
  use DopaminWeb, :live_view

  def mount(_params, _session, socket) do
    # 여기서 실제로는 데이터베이스에서 게임 목록을 가져올 것입니다
    games = [
      %{
        id: 1,
        category: "인기 게임",
        name: "도파만챌린지",
        description: "최고의 인기를 자랑하는 도파민 챌린지에 참여하세요. 다양한 미션을 완료하고 수익률을 높여 더 많은 보상을받아가세요.",
        players: 12_450,
        xrp: 1_250_000,
        days: 3,
        image: "🎮"
      },
      %{
        id: 2,
        category: "카드 게임",
        name: "퀸카 포커",
        description: "실력과 운이 따르는 포커 게임! 남들과 늦게 승리하면 더 높은 수익률을 얻 수 있어요.",
        players: 5_240,
        xrp: 580_000,
        days: nil,
        image: "♠️"
      },
      %{
        id: 3,
        category: "전략 게임",
        name: "타겟 마스터",
        description: "철저한 타이밍과 지적으로 목표를 달성하세요. 최고의 정확도가 최고의 수익률 보장합니다.",
        players: 3_180,
        xrp: 420_000,
        days: nil,
        image: "🎯"
      },
      %{
        id: 4,
        category: "경매",
        name: "월간 챌린지샵",
        description: "이번 월 최고의 글챌리어를 가려라 대화, 다양한 경쟁에서 상위를 등혀해보세요.",
        players: 8_760,
        xrp: 1_500_000,
        days: nil,
        image: "🏆"
      },
      %{
        id: 5,
        category: "주사위",
        name: "행운의 룰렛",
        description: "운과 전략을 결합한 룰렛 게임. 참여자에 따라 배당률이 크게 가변적이죠.",
        players: 7_130,
        xrp: 890_000,
        days: nil,
        image: "🎪"
      },
      %{
        id: 6,
        category: "스포츠",
        name: "실리 게임",
        description: "다른 플레이어와 실리를 겨루 매력적이죠. 높은 독점적이 진로 오리도록 자랑합니다.",
        players: 4_570,
        xrp: 620_000,
        days: nil,
        image: "🎮"
      },
      %{
        id: 7,
        category: "퍼즐",
        name: "퍼즐 마스터",
        description: "논리와 사고의 문제 해결 과정을 테스트하는 퍼즐 게임. 체스 도전하기 쉽진 않지만!",
        players: 2_980,
        xrp: 350_000,
        days: nil,
        image: "🧩"
      }
    ]

    # 추천 게임은 첫 번째 게임으로 설정
    featured_game = List.first(games)
    other_games = Enum.drop(games, 1)

    categories = ["전체 게임", "인기게임", "카드 게임", "슈팅게 놀고 게임", "골드룸", "인기순 정렬"]

    {:ok,
     socket
     |> assign(:featured_game, featured_game)
     |> assign(:games, other_games)
     |> assign(:categories, categories)
     |> assign(:active_category, "카드 게임")}
  end

  def render(assigns) do
    ~H"""
    <div class="bg-black text-white min-h-screen pt-16 pb-10">
      <!-- 메인 타이틀 -->
      <div class="text-center py-10">
        <h1 class="text-3xl font-bold mb-2">수익률 기반 지능형 게임 시스템</h1>
        <p class="text-gray-400 text-sm">도파민과 함께 게임을 즐기며 수익 창출의 기회를 잡아보세요</p>
      </div>
      
    <!-- 추천 게임 -->
      <div class="max-w-4xl mx-auto bg-zinc-900 rounded-lg overflow-hidden mb-12">
        <div class="p-8 flex flex-col md:flex-row">
          <div class="flex-shrink-0 flex justify-center items-center p-6 md:p-0 md:mr-8">
            <div class="text-6xl">
              {@featured_game.image}
            </div>
          </div>
          <div class="flex-grow">
            <div class="mb-4">
              <span class="bg-yellow-600 text-xs text-black px-2 py-1 rounded font-semibold">
                인기 게임
              </span>
            </div>
            <h2 class="text-xl font-bold mb-2">{@featured_game.name}</h2>
            <p class="text-gray-400 text-sm mb-6">{@featured_game.description}</p>

            <div class="grid grid-cols-3 gap-4 mb-6">
              <div>
                <p class="font-bold text-xl">{number_to_string(@featured_game.players)}명</p>
                <p class="text-gray-500 text-xs">플레이어</p>
              </div>
              <div>
                <p class="font-bold text-xl">{number_to_string(@featured_game.xrp)} XRP</p>
                <p class="text-gray-500 text-xs">누적 상금</p>
              </div>
              <div>
                <p class="font-bold text-xl">{@featured_game.days}일</p>
                <p class="text-gray-500 text-xs">남은 기간</p>
              </div>
            </div>

            <button class="bg-yellow-400 text-black font-bold py-2 px-6 rounded">
              <.link navigate={~p"/games/1"} class="block w-full py-2">
                참여하기
              </.link>
            </button>
          </div>
        </div>
      </div>
      
    <!-- 게임 목록 -->
      <div class="max-w-6xl mx-auto px-4">
        <div class="flex items-center mb-6">
          <div class="text-2xl mr-4">🎮</div>
          <h2 class="text-xl font-bold">참여 가능한 게임</h2>
        </div>
        
    <!-- 게임 그리드 -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <%= for game <- @games do %>
            <div class="bg-zinc-900 rounded-lg overflow-hidden">
              <div class="p-6 flex justify-center">
                <div class="text-5xl">
                  {game.image}
                </div>
              </div>
              <div class="p-6">
                <div class="mb-4">
                  <span class="bg-yellow-600 text-xs text-black px-2 py-1 rounded font-semibold">
                    {game.category}
                  </span>
                </div>
                <h3 class="font-bold mb-2">{game.name}</h3>
                <p class="text-gray-400 text-xs mb-4 h-16 overflow-hidden">{game.description}</p>

                <div class="grid grid-cols-2 gap-2 mb-4">
                  <div>
                    <p class="font-bold">{number_to_string(game.players)}명</p>
                    <p class="text-gray-500 text-xs">플레이어</p>
                  </div>
                  <div>
                    <p class="font-bold">{number_to_string(game.xrp)} XRP</p>
                    <p class="text-gray-500 text-xs">누적 상금</p>
                  </div>
                </div>

                <button class="w-full bg-yellow-400 text-black font-bold py-2 rounded">
                  <.link navigate={~p"/games/#{game.id}"} class="block w-full py-2">
                    참여하기
                  </.link>
                </button>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  # 숫자 포맷팅 헬퍼 함수
  defp number_to_string(number) when is_integer(number) do
    number
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=.)/, "\\1,")
    |> String.reverse()
  end

  defp number_to_string(nil), do: "-"
end
