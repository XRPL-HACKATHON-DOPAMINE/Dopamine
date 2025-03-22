defmodule DopaminWeb.GameIndexLive do
  use DopaminWeb, :live_view

  alias Dopamin.Game

  def mount(%{"id" => id}, _session, socket) do
    game_id = String.to_integer(id)
    user_id = socket.assigns.current_user.id

    # 이미 게임에 참가했는지 확인
    case Game.get_participant_by_user_and_game(user_id, game_id) do
      %{id: participant_id} ->
        # 이미 참가한 경우 베팅 페이지로 리다이렉트
        {:ok, socket |> redirect(to: ~p"/betting/#{participant_id}")}

      nil ->
        # 참가하지 않은 경우 정상적으로 페이지 표시
        # 데이터베이스에서 게임 정보를 가져옵니다
        game = Game.get_game_with_details(game_id)

        # 베팅 옵션에서 선택된 옵션을 찾습니다
        selected_bet = Enum.find(game.betting_options, fn opt -> opt.selected end)

        socket =
          socket
          |> assign(:game, game)
          |> assign(:game_rules, game.rules)
          |> assign(:betting_options, game.betting_options)
          |> assign(:selected_bet, selected_bet)
          |> assign(:reward_tiers, game.reward_tiers)
          |> assign(:top_players, game.top_players)
          |> assign(:page_title, game.name)

        {:ok, socket}
    end
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

  def handle_event("join_game", _params, socket) do
    game = socket.assigns.game
    selected_bet = socket.assigns.selected_bet

    # 유저 ID는 현재 세션에서 가져옵니다 (실제 인증 시스템에 맞게 조정 필요)
    user_id = socket.assigns.current_user.id

    # 베팅 금액 확인
    bet_amount = selected_bet && selected_bet.amount

    if bet_amount do
      # 게임 참가 정보를 데이터베이스에 기록
      case Game.join_game(game.id, user_id, bet_amount) do
        {:ok, participant} ->
          # 참가 성공: 베팅 페이지로 리다이렉트
          {:noreply,
           socket
           |> put_flash(:info, "게임에 성공적으로 참여했습니다!")
           |> redirect(to: ~p"/betting/#{participant.id}")}

        {:error, changeset} when is_map(changeset) ->
          # 참가 실패: 오류 메시지 표시 (Ecto Changeset 오류)
          error_message = error_message_from_changeset(changeset)
          {:noreply, socket |> put_flash(:error, "참가 실패: #{error_message}")}

        {:error, message} when is_binary(message) ->
          # 참가 실패: 문자열 오류 메시지 (이미 참여한 경우 등)
          {:noreply, socket |> put_flash(:error, message)}

        error ->
          # 기타 오류
          {:noreply, socket |> put_flash(:error, "알 수 없는 오류가 발생했습니다")}
      end
    else
      # 베팅 금액이 선택되지 않은 경우
      {:noreply, socket |> put_flash(:error, "베팅 금액을 선택해주세요")}
    end
  end

  defp error_message_from_changeset(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {k, v} -> "#{k} #{v}" end)
    |> Enum.join(", ")
  end

  # 종료 시간까지 남은 시간 계산
  defp calculate_remaining_time(end_time) do
    now = DateTime.utc_now()

    if DateTime.compare(end_time, now) == :gt do
      # 종료 시간이 현재보다 미래인 경우
      diff_seconds = DateTime.diff(end_time, now, :second)

      days = div(diff_seconds, 86400)
      diff_seconds = rem(diff_seconds, 86400)

      hours = div(diff_seconds, 3600)
      diff_seconds = rem(diff_seconds, 3600)

      minutes = div(diff_seconds, 60)
      seconds = rem(diff_seconds, 60)

      %{days: days, hours: hours, minutes: minutes, seconds: seconds}
    else
      # 이미 종료된 경우
      %{days: 0, hours: 0, minutes: 0, seconds: 0}
    end
  end

  def render(assigns) do
    # 게임 종료 시간으로부터 남은 시간 계산
    assigns = assign(assigns, :timer, calculate_remaining_time(assigns.game.end_time))

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
                    <p class="text-xl font-bold">{number_to_string(@game.xrp)} XRP</p>
                    <p class="text-xs text-gray-400">총상금</p>
                  </div>
                </div>
                <div class="bg-zinc-800 p-4 rounded-lg">
                  <div class="text-center">
                    <p class="text-xl font-bold">{@game.win_rate}%</p>
                    <p class="text-xs text-gray-400">평균 승률</p>
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
                      <p class="text-sm text-gray-300">{rule.rule}</p>
                    </li>
                  <% end %>
                </ul>
              </div>
              
    <!-- 투자 금액 선택 -->
              <div class="mb-6">
                <h3 class="font-bold mb-3">투자 금액 설정</h3>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                  <%= for option <- @betting_options do %>
                    <div
                      class="bg-zinc-800 p-4 rounded-lg cursor-pointer hover:bg-zinc-700 transition duration-150"
                      phx-click="select_bet"
                      phx-value-id={option.id}
                    >
                      <div class="flex items-center">
                        <%= if option.selected do %>
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            class="h-3 w-3 text-yellow-400"
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
                            {number_to_string(option.amount)} XRP
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
                    <%= if @selected_bet && @selected_bet.amount do %>
                      {number_to_string(@selected_bet.amount)} XRP
                    <% else %>
                      직접 입력
                    <% end %>
                  </span>
                </p>
                <button
                  phx-click="join_game"
                  class="bg-yellow-400 text-black font-bold py-3 px-6 rounded"
                >
                  참여하기
                </button>
              </div>
            </div>
            
    <!-- 게임 종료까지 카운트다운 -->
            <div class="bg-zinc-900 rounded-lg p-6 mb-6">
              <h2 class="text-lg font-bold mb-4">게임 종료까지</h2>

              <div id="countdown-timer" phx-hook="CountdownTimer" data-end-time={@game.end_time}>
                <div class="grid grid-cols-4 gap-4 text-center">
                  <div class="bg-zinc-800 bg-opacity-50 p-4 rounded-lg">
                    <div class="text-2xl font-bold text-yellow-400 days-value">
                      {@timer.days}
                    </div>
                    <div class="text-xs text-gray-400">일</div>
                  </div>
                  <div class="bg-zinc-800 bg-opacity-50 p-4 rounded-lg">
                    <div class="text-2xl font-bold text-yellow-400 hours-value">
                      {@timer.hours}
                    </div>
                    <div class="text-xs text-gray-400">시간</div>
                  </div>
                  <div class="bg-zinc-800 bg-opacity-50 p-4 rounded-lg">
                    <div class="text-2xl font-bold text-yellow-400 minutes-value">
                      {@timer.minutes}
                    </div>
                    <div class="text-xs text-gray-400">분</div>
                  </div>
                  <div class="bg-zinc-800 bg-opacity-50 p-4 rounded-lg">
                    <div class="text-2xl font-bold text-yellow-400 seconds-value">
                      {@timer.seconds}
                    </div>
                    <div class="text-xs text-gray-400">초</div>
                  </div>
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
                        {number_to_string(tier.reward)} XRP
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
