defmodule DopaminWeb.GameIndexLive do
  use DopaminWeb, :live_view

  def mount(%{"id" => id}, _session, socket) do
    # 실제 애플리케이션에서는 DB에서 게임 데이터를 가져옵니다
    game_id = String.to_integer(id)

    game =
      case game_id do
        1 ->
          %{
            id: 1,
            category: "인기 게임",
            name: "도파만챌린지",
            description: "최고의 인기를 자랑하는 도파민 챌린지에 참여하세요. 다양한 미션을 완료하고 수익률을 높여 더 많은 보상을받아가세요.",
            players: 12_450,
            xrp: 1_250_000,
            win_rate: 42.6,
            plays: 230,
            image: "🎮",
            updated_at: ~U[2023-10-12 12:30:00Z]
          }

        2 ->
          %{
            id: 2,
            category: "카드 게임",
            name: "퀸카 포커",
            description: "실력과 운이 따르는 포커 게임! 남들과 늦게 승리하면 더 높은 수익률을 얻 수 있어요.",
            players: 5_240,
            xrp: 580_000,
            win_rate: 33.1,
            plays: 180,
            image: "♠️",
            updated_at: ~U[2023-10-10 15:45:00Z]
          }

        3 ->
          %{
            id: 3,
            category: "전략 게임",
            name: "타겟 마스터",
            description: "철저한 타이밍과 지적으로 목표를 달성하세요. 최고의 정확도가 최고의 수익률 보장합니다.",
            players: 3_180,
            xrp: 420_000,
            win_rate: 29.5,
            plays: 150,
            image: "🎯",
            updated_at: ~U[2023-10-08 09:20:00Z]
          }

        _ ->
          %{
            id: game_id,
            category: "카드 게임",
            name: "근사치 맞추기 게임",
            description:
              "실력과 운을 겸비한 근사치 맞추기 게임에 도전하세요! 여러분 경험으로 얼마나 수 있으며, 특히 경쟁에 비례한 수익률을 낼 수 있습니다. 실시간으로 다른 참가자들과 경쟁하며, 가장 근접한 숫자를 맞추어 더 큰 보상을 얻으세요. 높은 예측 정확도에 참여 확율에 따라 더 큰 보상을 보너스 게임도 제공합니다.",
            players: 5_240,
            xrp: 580_000,
            win_rate: 35.8,
            plays: 128,
            image: "🎲",
            updated_at: ~U[2023-10-12 12:30:00Z]
          }
      end

    game_rules = [
      "참가자는 제한 시간 안에 주어 근접해 상정합니다.",
      "승자는 시간 통화 기준 가장온 숫자를 맞추는 도전이 선정됩니다.",
      "가장 근접한 숫자를 맞춘 사람이 우승을 얻게됩니다. (동점 경우에 대비)",
      "특별 보너스 라운드에서 추가 보상을 얻을 수 있습니다.",
      "근사치를 맞춰 최소에 따라 누적 보상의 범위 수 있습니다"
    ]

    betting_options = [
      %{id: 1, name: "소액 투자", description: "낮은 위험, 안정적인 수익", amount: 10_000, selected: false},
      %{id: 2, name: "중액 투자", description: "적절한 위험과 수익의 균형", amount: 50_000, selected: true},
      %{id: 3, name: "고액 투자", description: "높은 위험, 높은 수익 가능성", amount: 100_000, selected: false},
      %{id: 4, name: "직접 입력", description: "원하는 금액에 직접 설정", amount: nil, selected: false}
    ]

    reward_tiers = [
      %{rank: "1위", condition: "최고 근접 정답", reward: 50_000},
      %{rank: "2위~10위", condition: "상위 2~10위 정답", reward: 20_000},
      %{rank: "11위~50위", condition: "상위 11~50위 정답", reward: 10_000},
      %{rank: "51위~100위", condition: "상위 51~100위 정답", reward: 5_000}
    ]

    timer = %{
      days: 2,
      hours: 10,
      minutes: 36,
      seconds: 18
    }

    top_players = [
      %{rank: 1, username: "포리딘", win_rate: 82.4, games_played: 94, icon: "P"},
      %{rank: 2, username: "메가스타", win_rate: 78.9, games_played: 88, icon: "L"},
      %{rank: 3, username: "게임마스터", win_rate: 75.2, games_played: 76, icon: "M"},
      %{rank: 4, username: "탑플레이어", win_rate: 68.7, games_played: 65, icon: "T"},
      %{rank: 5, username: "도맹사", win_rate: 64.3, games_played: 61, icon: "D"}
    ]

    socket =
      socket
      |> assign(:game, game)
      |> assign(:game_rules, game_rules)
      |> assign(:betting_options, betting_options)
      |> assign(:selected_bet, Enum.find(betting_options, fn opt -> opt.selected end))
      |> assign(:reward_tiers, reward_tiers)
      |> assign(:timer, timer)
      |> assign(:top_players, top_players)
      |> assign(:page_title, "근사치 맞추기 게임")

    {:ok, socket}
  end

  def handle_event("select_bet", %{"id" => id}, socket) do
    id = String.to_integer(id)

    betting_options =
      socket.assigns.betting_options
      |> Enum.map(fn opt ->
        Map.put(opt, :selected, opt.id == id)
      end)

    selected_bet = Enum.find(betting_options, fn opt -> opt.selected end)

    {:noreply,
     socket
     |> assign(:betting_options, betting_options)
     |> assign(:selected_bet, selected_bet)}
  end

  def handle_event("start_game", _params, socket) do
    # 실제로 게임을 시작하는 로직 구현
    # 여기서는 알림 메시지만 표시
    {:noreply, socket |> put_flash(:info, "게임이 시작되었습니다!")}
  end

  def render(assigns) do
    ~H"""
    <div class="bg-black text-white pt-16 pb-10">
      <!-- 게임 기본 정보 -->
      <div class="max-w-6xl mx-auto">
        <div class="bg-zinc-900 rounded-lg overflow-hidden mb-6">
          <div class="grid grid-cols-1 md:grid-cols-4">
            <!-- 게임 이미지 -->
            <div class="md:col-span-1 flex justify-center items-center p-8 bg-zinc-800">
              <div class="text-8xl">
                {@game.image}
              </div>
            </div>
            
    <!-- 게임 정보 -->
            <div class="md:col-span-3 p-8">
              <div class="flex items-center mb-4">
                <span class="bg-yellow-600 text-xs text-black px-2 py-1 rounded font-semibold">
                  {@game.category}
                </span>
              </div>

              <h1 class="text-2xl font-bold mb-2">{@game.name}</h1>

              <div class="flex items-center text-sm text-gray-400 mb-4">
                <div class="flex items-center mr-4">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-4 w-4 mr-1"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                  <span>최종 업데이트: {Calendar.strftime(@game.updated_at, "%Y-%m-%d %H:%M")}</span>
                </div>
                <div class="flex items-center">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-4 w-4 mr-1"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
                    />
                  </svg>
                  <span>총 참여: {@game.players}명</span>
                </div>
              </div>

              <p class="text-gray-300 text-sm mb-6 leading-relaxed">
                {@game.description}
              </p>
              
    <!-- 게임 통계 -->
              <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-4">
                <div class="bg-zinc-800 p-4 rounded-lg">
                  <div class="text-center">
                    <p class="text-xl font-bold">{@game.players}명</p>
                    <p class="text-xs text-gray-400">현재 참여자</p>
                  </div>
                </div>
                <div class="bg-zinc-800 p-4 rounded-lg">
                  <div class="text-center">
                    <p class="text-xl font-bold">580,000 XRP</p>
                    <p class="text-xs text-gray-400">총상금</p>
                  </div>
                </div>
                <div class="bg-zinc-800 p-4 rounded-lg">
                  <div class="text-center">
                    <p class="text-xl font-bold">{@game.win_rate}%</p>
                    <p class="text-xs text-gray-400">평균 승률률</p>
                  </div>
                </div>
                <div class="bg-zinc-800 p-4 rounded-lg">
                  <div class="text-center">
                    <p class="text-xl font-bold">{@game.plays}회</p>
                    <p class="text-xs text-gray-400">게임 횟수</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <!-- 게임 참여하기 섹션 -->
          <div class="lg:col-span-2">
            <div class="bg-zinc-900 rounded-lg p-6 mb-6">
              <h2 class="text-lg font-bold mb-4">게임 참여하기</h2>
              
    <!-- 게임 규칙 -->
              <div class="mb-6">
                <h3 class="font-bold mb-3">게임 규칙</h3>
                <ul class="space-y-2">
                  <%= for {rule, index} <- Enum.with_index(@game_rules) do %>
                    <li class="flex items-start">
                      <div class="flex-shrink-0 w-6 h-6 rounded-full bg-yellow-400 text-black flex items-center justify-center mr-3 mt-0.5 font-bold text-xs">
                        {index + 1}
                      </div>
                      <p class="text-sm text-gray-300">{rule}</p>
                    </li>
                  <% end %>
                </ul>
              </div>
              
    <!-- 투자 금액 선택 -->
              <div class="mb-6">
                <h3 class="font-bold mb-3">투자 금액 설정</h3>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                  <%= for option <- @betting_options do %>
                    <div phx-click="select_bet" phx-value-id={option.id}>
                      <div class="flex items-center">
                        <%= if option.selected do %>
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            class="h-3 w-3 text-black"
                            viewBox="0 0 20 20"
                            fill="currentColor"
                          >
                            <path
                              fill-rule="evenodd"
                              d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                              clip-rule="evenodd"
                            />
                          </svg>
                        <% end %>
                      </div>
                      <div>
                        <h4 class="font-bold text-sm">{option.name}</h4>
                        <p class="text-xs text-gray-400">{option.description}</p>
                        <%= if option.amount do %>
                          <p class="text-right text-yellow-400 font-bold mt-2">
                            {case option.amount do
                              10_000 -> "10,000"
                              50_000 -> "50,000"
                              100_000 -> "100,000"
                              _ -> "#{option.amount}"
                            end}
                          </p>
                        <% else %>
                          <div class="flex justify-end mt-2">
                            <input
                              type="text"
                              class="bg-zinc-700 border border-zinc-600 rounded w-24 px-2 py-1 text-right text-sm"
                              placeholder="금액 입력"
                              disabled={!option.selected}
                            />
                          </div>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>

              <div class="flex justify-between items-center border-t border-zinc-800 pt-4">
                <p class="text-sm">
                  선택한 투자 금액:
                  <span class="text-yellow-400 font-bold">
                    <%= if @selected_bet.amount do %>
                      {case @selected_bet.amount do
                        10_000 -> "10,000"
                        50_000 -> "50,000"
                        100_000 -> "100,000"
                        _ -> "#{@selected_bet.amount}"
                      end} XRP
                    <% else %>
                      직접 입력
                    <% end %>
                  </span>
                </p>
                <button class="bg-yellow-400 text-black font-bold py-3 px-6 rounded">
                  <.link navigate={~p"/betting"} class="block w-full py-2">
                    참여하기
                  </.link>
                </button>
              </div>
            </div>
            
    <!-- 게임 종료까지 -->
            <div class="bg-zinc-900 rounded-lg p-6 mb-6">
              <h2 class="text-lg font-bold mb-4">게임 종료까지</h2>

              <div class="grid grid-cols-4 gap-4 text-center">
                <div class="bg-zinc-800 bg-opacity-50 p-4 rounded-lg">
                  <div class="text-2xl font-bold text-yellow-400">{@timer.days}</div>
                  <div class="text-xs text-gray-400">일</div>
                </div>
                <div class="bg-zinc-800 bg-opacity-50 p-4 rounded-lg">
                  <div class="text-2xl font-bold text-yellow-400">{@timer.hours}</div>
                  <div class="text-xs text-gray-400">시간</div>
                </div>
                <div class="bg-zinc-800 bg-opacity-50 p-4 rounded-lg">
                  <div class="text-2xl font-bold text-yellow-400">{@timer.minutes}</div>
                  <div class="text-xs text-gray-400">분</div>
                </div>
                <div class="bg-zinc-800 bg-opacity-50 p-4 rounded-lg">
                  <div class="text-2xl font-bold text-yellow-400">{@timer.seconds}</div>
                  <div class="text-xs text-gray-400">초</div>
                </div>
              </div>
            </div>
            
    <!-- 상위 참가자 -->
            <div class="bg-zinc-900 rounded-lg p-6">
              <h2 class="text-lg font-bold mb-4">상위 참가자</h2>

              <div class="space-y-3">
                <%= for player <- @top_players do %>
                  <div class="flex items-center justify-between py-2 border-b border-zinc-800">
                    <div class="flex items-center">
                      <div class={[
                        "w-8 h-8 rounded-full flex items-center justify-center font-bold mr-3",
                        cond do
                          player.rank == 1 -> "bg-yellow-500 text-black"
                          player.rank == 2 -> "bg-gray-300 text-black"
                          player.rank == 3 -> "bg-yellow-700 text-black"
                          true -> "bg-zinc-700 text-white"
                        end
                      ]}>
                        {player.icon}
                      </div>
                      <div>
                        <p class="font-bold">{player.username}</p>
                        <p class="text-xs text-gray-400">
                          승률 {player.win_rate}%, 참여 {player.games_played}회
                        </p>
                      </div>
                    </div>
                    <div class="text-lg">
                      <%= cond do %>
                        <% player.rank == 1 -> %>
                          <span class="text-yellow-400">1</span>
                        <% player.rank == 2 -> %>
                          <span class="text-gray-300">2</span>
                        <% player.rank == 3 -> %>
                          <span class="text-yellow-700">3</span>
                        <% true -> %>
                          <span class="text-gray-400">{player.rank}</span>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
          
    <!-- 보상 정보 -->
          <div class="lg:col-span-1">
            <div class="bg-zinc-900 rounded-lg p-6">
              <h2 class="text-lg font-bold mb-4">보상 정보</h2>

              <div class="mb-6">
                <p class="text-sm text-gray-300 mb-6">게임의 최종 결과에 따라 다양한 보상 분배가 지급됩니다.</p>

                <div class="space-y-4">
                  <div class="grid grid-cols-3 text-sm font-bold text-gray-400 pb-2 border-b border-zinc-800">
                    <div>순위</div>
                    <div>조건</div>
                    <div class="text-right">보상금</div>
                  </div>

                  <%= for tier <- @reward_tiers do %>
                    <div class="grid grid-cols-3 text-sm">
                      <div class="font-bold">{tier.rank}</div>
                      <div class="text-gray-400">{tier.condition}</div>
                      <div class="text-right text-yellow-400 font-bold">
                        {case tier.reward do
                          50_000 -> "50,000"
                          20_000 -> "20,000"
                          10_000 -> "10,000"
                          5_000 -> "5,000"
                          _ -> "#{tier.reward}"
                        end}
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>

              <div>
                <h3 class="font-bold text-sm mb-2">추가 보상 정보</h3>
                <div class="bg-zinc-800 rounded p-4">
                  <div class="flex justify-between items-center mb-2">
                    <span class="text-sm text-gray-300">예상 수익률</span>
                    <span class="font-bold">정가대비 1.5배</span>
                  </div>
                  <div class="flex justify-between items-center">
                    <span class="text-sm text-gray-300">승리 확률</span>
                    <span class="font-bold">90% 이상 근접</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
