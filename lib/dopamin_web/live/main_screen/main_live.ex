defmodule DopaminWeb.MainScreen.MainLive do
  use DopaminWeb, :live_view

  alias Dopamin.Game

  def mount(_params, _session, socket) do
    # 데이터베이스에서 게임 목록을 가져옵니다
    games = Game.list_games()

    # 플레이어 수 기준으로 인기 게임(추천 게임) 선정
    featured_game = Enum.max_by(games, & &1.players, fn -> nil end)

    # 나머지 게임 목록 (인기 게임 제외)
    other_games =
      if featured_game do
        Enum.filter(games, fn game -> game.id != featured_game.id end)
      else
        games
      end

    # 카테고리 목록 (중복 제거)
    categories = ["전체 게임" | Enum.uniq(Enum.map(games, & &1.category))]

    {:ok,
     socket
     |> assign(:featured_game, featured_game)
     |> assign(:games, other_games)
     |> assign(:categories, categories)
     |> assign(:active_category, "전체 게임")}
  end

  def handle_event("select_category", %{"category" => category}, socket) do
    games =
      if category == "전체 게임" do
        # 전체 게임을 선택한 경우 인기 게임을 제외한 모든 게임 표시
        featured_game = socket.assigns.featured_game
        all_games = Game.list_games()

        if featured_game do
          Enum.filter(all_games, fn game -> game.id != featured_game.id end)
        else
          all_games
        end
      else
        # 특정 카테고리만 필터링
        Game.list_games_by_category(category)
      end

    {:noreply,
     socket
     |> assign(:games, games)
     |> assign(:active_category, category)}
  end

  def render(assigns) do
    ~H"""
    <div class="relative min-h-screen pb-24">
      <!-- 성능 최적화된 우주 배경 애니메이션 -->
      <div class="animated-bg">
        <div class="stars">
          <span></span><span></span><span></span><span></span><span></span>
          <span></span><span></span><span></span><span></span><span></span>
          <span></span><span></span><span></span><span></span><span></span>
          <span></span><span></span><span></span><span></span><span></span>
        </div>
        <div class="shooting-star"></div>
        <div class="shooting-star"></div>
        <div class="floating-light"></div>
        <div class="floating-light"></div>
        <!-- 추가 우주 배경 요소 -->
        <div class="space-planet planet-1"></div>
        <div class="space-planet planet-2"></div>
        <div class="space-nebula"></div>
      </div>
      
    <!-- 콘텐츠 래퍼 -->
      <div class="content-wrapper">
        <!-- 메인 타이틀 -->
        <div class="text-center py-10">
          <h1 class="text-3xl font-bold mb-2">수익률 기반 지능형 게임 시스템</h1>
          <p class="text-gray-400 text-sm">도파민과 함께 게임을 즐기며 수익 창출의 기회를 잡아보세요</p>
          
    <!-- 게시판 바로가기 버튼 추가 -->
          <div class="mt-6">
            <.link
              navigate={~p"/boards"}
              class="inline-flex items-center px-6 py-3 bg-zinc-800 hover:bg-zinc-700 text-yellow-400 rounded-lg transition-colors"
            >
              <span class="mr-2">📋</span> 커뮤니티 게시판 보기
            </.link>
          </div>
        </div>
        
    <!-- 카테고리 선택 메뉴 -->
        <div class="max-w-6xl mx-auto px-4 mb-8">
          <div class="flex flex-wrap gap-2">
            <%= for category <- @categories do %>
              <button
                phx-click="select_category"
                phx-value-category={category}
                class={"px-4 py-2 rounded-full text-sm font-medium #{if @active_category == category, do: "bg-yellow-400 text-black", else: "bg-zinc-800 text-white hover:bg-zinc-700"}"}
              >
                {category}
              </button>
            <% end %>
          </div>
        </div>
        
    <!-- 추천 게임 -->
        <%= if @featured_game do %>
          <div class="max-w-4xl mx-auto bg-zinc-900 rounded-lg overflow-hidden mb-12 game-card">
            <div class="p-8 flex flex-col md:flex-row">
              <div class="flex-shrink-0 flex justify-center items-center p-6 md:p-0 md:mr-8">
                <div class="text-6xl">
                  {@featured_game.image}
                </div>
              </div>
              <div class="flex-grow">
                <div class="mb-4">
                  <span class="bg-yellow-600 text-xs text-black px-2 py-1 rounded font-semibold">
                    {@featured_game.category}
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
                    <p class="font-bold text-xl">{days_remaining(@featured_game.end_time)}일</p>
                    <p class="text-gray-500 text-xs">남은 기간</p>
                  </div>
                </div>

                <button class="bg-yellow-400 text-black font-bold py-2 px-6 rounded hover:bg-yellow-500 transition duration-200">
                  <.link navigate={~p"/games/#{@featured_game.id}"} class="block w-full py-2">
                    상세 보기
                  </.link>
                </button>
              </div>
            </div>
          </div>
        <% end %>
        
    <!-- 게임 목록 -->
        <div class="max-w-6xl mx-auto px-4">
          <div class="flex items-center mb-6">
            <div class="text-2xl mr-4">🎮</div>
            <h2 class="text-xl font-bold">
              {if @active_category == "전체 게임", do: "참여 가능한 게임", else: @active_category}
            </h2>
          </div>
          
    <!-- 게임 그리드 -->
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <%= for game <- @games do %>
              <div class="bg-zinc-900 rounded-lg overflow-hidden game-card">
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

                  <div class="grid grid-cols-3 gap-2 mb-4">
                    <div>
                      <p class="font-bold">{number_to_string(game.players)}명</p>
                      <p class="text-gray-500 text-xs">플레이어</p>
                    </div>
                    <div>
                      <p class="font-bold">{number_to_string(game.xrp)} XRP</p>
                      <p class="text-gray-500 text-xs">누적 상금</p>
                    </div>
                    <div>
                      <p class="font-bold">{days_remaining(game.end_time)}일</p>
                      <p class="text-gray-500 text-xs">남은 기간</p>
                    </div>
                  </div>

                  <button class="w-full bg-yellow-400 text-black font-bold py-2 rounded hover:bg-yellow-500 transition duration-200">
                    <.link navigate={~p"/games/#{game.id}"} class="block w-full py-2">
                      상세 보기
                    </.link>
                  </button>
                </div>
              </div>
            <% end %>
          </div>
        </div>
        
    <!-- 푸터 표시를 위한 여백 -->
        <div class="h-20"></div>
      </div>
    </div>

    <!-- 우주 테마 푸터 스타일을 적용하는 JavaScript -->
    <script>
      document.addEventListener('DOMContentLoaded', function() {
        // 푸터 요소에 space-footer 클래스 추가
        const footer = document.querySelector('footer');
        if (footer) {
          footer.classList.add('space-footer');
        }
      });
    </script>
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

  # 종료 시간까지 남은 일수 계산
  defp days_remaining(end_time) do
    now = DateTime.utc_now()

    case DateTime.compare(end_time, now) do
      :gt ->
        # 종료 시간이 미래인 경우
        diff = DateTime.diff(end_time, now, :second)
        days = trunc(diff / (60 * 60 * 24))
        if days == 0 and diff > 0, do: 1, else: days

      _ ->
        # 이미 종료되었거나 종료 시간이 현재인 경우
        0
    end
  end
end
