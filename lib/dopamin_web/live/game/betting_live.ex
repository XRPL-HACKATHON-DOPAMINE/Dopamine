defmodule DopaminWeb.BettingLive do
  use DopaminWeb, :live_view
  alias Dopamin.Game

  def mount(%{"participant_id" => participant_id}, _session, socket) do
    # 참가자 정보 로드
    case Game.get_participant(String.to_integer(participant_id)) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "참가 정보를 찾을 수 없습니다")
         |> redirect(to: ~p"/")}

      participant ->
        # 게임 정보 로드
        game = Game.get_game_with_details(participant.game_id)

        # 남은 시간 계산
        remaining_time = calculate_remaining_time(game.end_time)

        # 예상 수익금 계산
        expected_reward = calculate_expected_reward(participant.bet_amount, game.win_rate)

        # 게임 정보
        game_data = %{
          id: game.id,
          name: "#{game.name} - 코인 가격 예측",
          # 실제로는 API에서 가져오거나 DB에서 가져와야 함
          current_price: "W14,500",
          current_price_change: "+17.4%",
          win_rate: "#{game.win_rate}%",
          my_investment: "W#{number_to_string(participant.bet_amount)}",
          total_reward: "W#{number_to_string(expected_reward)}",
          end_time: remaining_time,
          current_price_raw: 14500,
          reference_price: "W12,250",
          reference_change: "+2.5%",
          up_percent: 62,
          down_percent: 38,
          price_high: "W20,200",
          user_prediction: "W14,500"
        }

        # DB에서 참여자 목록 가져오기
        all_participants = Game.list_game_participants(game.id, limit: 50)

        # 참여자 데이터 변환
        participants_data = convert_participants_data(all_participants, participant.user_id)

        # 투자 옵션 (베팅 금액 옵션) - DB에서 가져온 베팅 옵션 사용
        investment_options =
          Enum.map(game.betting_options, fn option ->
            %{
              amount: "#{number_to_string(option.amount)}",
              label: option.name,
              selected: option.selected
            }
          end)

        # 투자 계산 정보
        investment_stats = %{
          initial_investment: "#{number_to_string(participant.bet_amount)}",
          # 초기에는 0
          accumulated_rewards: "0",
          # 초기에는 0
          current_rewards: "0",
          total_rewards: "#{number_to_string(expected_reward)}"
        }

        # 하단 요약 정보
        summary = [
          %{value: "W#{number_to_string(participant.bet_amount)}", label: "초기 투자금"},
          %{value: "W#{number_to_string(participant.bet_amount)}", label: "총 예측 금액"},
          %{value: "W#{number_to_string(expected_reward)}", label: "예상 최종 금액"},
          %{
            value: "상위 #{calculate_rank_percentage(all_participants, participant)}%",
            label: "현재 순위"
          }
        ]

        # 차트 시간 필터
        time_filters = [
          %{label: "1H", value: "1h", selected: false},
          %{label: "6H", value: "6h", selected: true},
          %{label: "24H", value: "24h", selected: false},
          %{label: "ALL", value: "all", selected: false}
        ]

        # 배지 - 사용자 성취에 기반한 배지 표시
        badges = calculate_badges(participant)

        # 트레이딩뷰 차트 설정
        chart_settings = %{
          symbol: "BINANCE:XRPUSDT",
          interval: "60",
          theme: "dark",
          height: 400,
          width: "100%"
        }

        {:ok,
         socket
         |> assign(:game, game_data)
         |> assign(:original_game, game)
         |> assign(:participant, participant)
         |> assign(:participants, participants_data)
         |> assign(:investment_options, investment_options)
         |> assign(:investment_stats, investment_stats)
         |> assign(:summary, summary)
         |> assign(:time_filters, time_filters)
         |> assign(:badges, badges)
         |> assign(:custom_amount, "#{participant.bet_amount}")
         |> assign(:selected_amount, "W#{number_to_string(participant.bet_amount)}")
         |> assign(:chart_settings, chart_settings)
         |> assign(:page_title, "#{game.name} - 코인 가격 예측")}
    end
  end

  def handle_event("select_amount", %{"amount" => amount}, socket) do
    investment_options =
      socket.assigns.investment_options
      |> Enum.map(fn opt ->
        Map.put(opt, :selected, opt.amount == amount)
      end)

    {:noreply,
     socket
     |> assign(:investment_options, investment_options)
     |> assign(:selected_amount, amount)}
  end

  def handle_event("change_amount", %{"value" => value}, socket) do
    {:noreply, socket |> assign(:custom_amount, value)}
  end

  def handle_event("place_bet", _params, socket) do
    # 실제로 베팅 금액을 업데이트하는 로직
    participant = socket.assigns.participant
    custom_amount = socket.assigns.custom_amount

    # 금액을 정수로 변환
    {bet_amount, _} = Integer.parse(custom_amount)

    # 데이터베이스에 베팅 금액 업데이트
    case Game.update_participant_bet(participant.id, bet_amount) do
      {:ok, updated_participant} ->
        # 업데이트된 정보로 재계산
        game = socket.assigns.original_game
        expected_reward = calculate_expected_reward(bet_amount, game.win_rate)

        # 업데이트된 투자 통계
        investment_stats = %{
          initial_investment: socket.assigns.investment_stats.initial_investment,
          accumulated_rewards: socket.assigns.investment_stats.accumulated_rewards,
          current_rewards: "#{number_to_string(bet_amount - participant.bet_amount)}",
          total_rewards: "#{number_to_string(expected_reward)}"
        }

        # 업데이트된 요약 정보
        summary =
          Enum.map(socket.assigns.summary, fn item ->
            case item.label do
              "총 예측 금액" -> %{value: "W#{number_to_string(bet_amount)}", label: item.label}
              "예상 최종 금액" -> %{value: "W#{number_to_string(expected_reward)}", label: item.label}
              _ -> item
            end
          end)

        # 게임 데이터 업데이트
        game_data =
          Map.merge(socket.assigns.game, %{
            my_investment: "W#{number_to_string(bet_amount)}",
            total_reward: "W#{number_to_string(expected_reward)}"
          })

        {:noreply,
         socket
         |> assign(:participant, updated_participant)
         |> assign(:investment_stats, investment_stats)
         |> assign(:summary, summary)
         |> assign(:game, game_data)
         |> put_flash(:info, "추가 매수가 성공적으로 설정되었습니다!")}

      {:error, _changeset} ->
        {:noreply, socket |> put_flash(:error, "베팅 금액 업데이트에 실패했습니다.")}
    end
  end

  def handle_event("update_chart_interval", %{"interval" => interval}, socket) do
    # 차트 간격 업데이트
    chart_settings = Map.put(socket.assigns.chart_settings, :interval, interval)

    # 시간 필터 업데이트
    time_filters =
      socket.assigns.time_filters
      |> Enum.map(fn filter ->
        Map.put(filter, :selected, filter.value == interval)
      end)

    {:noreply,
     socket
     |> assign(:chart_settings, chart_settings)
     |> assign(:time_filters, time_filters)}
  end

  # 남은 시간 계산 함수
  defp calculate_remaining_time(end_time) do
    now = DateTime.utc_now()

    case DateTime.compare(end_time, now) do
      :gt ->
        # 종료 시간이 미래인 경우
        diff_seconds = DateTime.diff(end_time, now, :second)

        days = div(diff_seconds, 86400)
        diff_seconds = rem(diff_seconds, 86400)

        hours = div(diff_seconds, 3600)

        "#{days}일 #{hours}시간"

      _ ->
        # 이미 종료된 경우
        "종료됨"
    end
  end

  # 예상 수익 계산 함수
  defp calculate_expected_reward(bet_amount, win_rate) do
    trunc(bet_amount * (1 + win_rate / 100))
  end

  # 참여자 목록 변환 함수
  defp convert_participants_data(participants, current_user_id) do
    # 베팅 금액 기준으로 정렬 (높은 순)
    sorted_participants = Enum.sort_by(participants, & &1.bet_amount, :desc)

    # 순위 부여 및 형식 변환
    Enum.with_index(sorted_participants, 1)
    |> Enum.map(fn {participant, index} ->
      is_current_user = participant.user_id == current_user_id
      username = if is_current_user, do: "나", else: "사용자#{participant.user_id}"

      # 랜덤 예측 가격과 변동률 (실제로는 DB에서 가져와야 함)
      {prediction, change} = generate_prediction_data()

      %{
        rank: index,
        username: username,
        avatar: if(is_current_user, do: "yellow", else: random_avatar_color()),
        prediction: prediction,
        change: change,
        investment: "W#{number_to_string(participant.bet_amount)}",
        reward: "W#{number_to_string(calculate_expected_reward(participant.bet_amount, 35))}"
      }
    end)
  end

  # 랜덤 아바타 색상
  defp random_avatar_color do
    Enum.random(["yellow", "gray", "blue", "green", "red"])
  end

  # 랜덤 예측 데이터 생성
  defp generate_prediction_data do
    base_price = 12_250
    change_percent = Enum.random(-25..25)
    new_price = trunc(base_price * (1 + change_percent / 100))

    prediction = "W#{number_to_string(new_price)}"
    change = "#{if change_percent >= 0, do: "+", else: ""}#{change_percent}.#{Enum.random(0..9)}%"

    {prediction, change}
  end

  # 순위 백분율 계산
  defp calculate_rank_percentage(participants, current_participant) do
    total_count = length(participants)

    # 현재 참가자보다 베팅 금액이 높은 참가자 수 찾기
    higher_bet_count =
      Enum.count(participants, fn p ->
        p.bet_amount > current_participant.bet_amount
      end)

    # 백분율 계산 (상위 n%)
    percentage = trunc(higher_bet_count / total_count * 100)
    percentage
  end

  # 배지 계산 함수
  defp calculate_badges(participant) do
    # 예시 배지 (실제로는 사용자 활동에 기반하여 계산해야 함)
    [
      %{icon: "🏆", label: "소액 거래왕"},
      %{icon: "🏅", label: "승률 상승 기록"},
      %{icon: "🏆", label: "온라인 지속 보상"}
    ]
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

  def render(assigns) do
    ~H"""
    <div class="bg-black text-white min-h-screen pt-16 pb-10">
      <!-- 메인 타이틀 -->
      <div class="max-w-6xl mx-auto px-4">
        <div class="flex flex-col md:flex-row md:items-center md:justify-between py-4">
          <h1 class="text-xl font-bold">{@game.name}</h1>
          <div class="flex items-center mt-2 md:mt-0 space-x-6">
            <div class="flex flex-col">
              <span class="text-xs text-gray-400">
                내 투자금: <span class="text-white">{@game.my_investment}</span>
              </span>
              <span class="text-xs text-gray-400">
                현재 예수금: <span class="text-yellow-400">{@game.total_reward}</span>
              </span>
            </div>
            <div class="flex items-center bg-zinc-800 px-2 py-1 rounded">
              <span class="text-xs text-gray-400 mr-1">종료까지:</span>
              <span class="text-xs font-bold">{@game.end_time}</span>
            </div>
          </div>
        </div>
        
    <!-- 메인 게임 콘텐츠 -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <!-- 차트 및 예측 영역 -->
          <div class="lg:col-span-2">
            <div class="bg-zinc-900 rounded-lg overflow-hidden mb-6">
              <div class="p-4 border-b border-zinc-800">
                <h2 class="text-sm font-bold">실시간 코인 그래프</h2>
                
    <!-- 시간 필터 버튼 -->
                <div class="flex items-center justify-end space-x-1 -mt-6">
                  <%= for filter <- @time_filters do %>
                    <button
                      phx-click="update_chart_interval"
                      phx-value-interval={filter.value}
                      class={"text-xs px-2 py-1 rounded " <> if(filter.selected, do: "bg-blue-500", else: "bg-zinc-800")}
                    >
                      {filter.label}
                    </button>
                  <% end %>
                </div>
              </div>

              <div class="p-6">
                <!-- 가격 정보 -->
                <div class="flex justify-end items-center mb-4">
                  <div class="text-right">
                    <div class="text-xs text-gray-400">현재가:</div>
                    <div class="flex items-center">
                      <span class="font-bold mr-2">{@game.reference_price}</span>
                      <span class="text-xs text-green-400">{@game.reference_change}</span>
                    </div>
                  </div>
                </div>
                
    <!-- 트레이딩뷰 차트 추가 -->
                <div
                  class="tradingview-widget-container mb-6"
                  id="tradingview-container"
                  phx-update="ignore"
                >
                  <div
                    id="tradingview_xrp_chart"
                    style={"height: #{@chart_settings.height}px; width: #{@chart_settings.width}"}
                  >
                  </div>
                </div>

                <div class="mb-4">
                  <!-- 상한가 및 예측가 정보 -->
                  <div class="flex justify-between text-xs mb-2">
                    <div class="flex items-center">
                      <span class="h-3 w-3 bg-yellow-400 rounded-full inline-block mr-1"></span>
                      <span>고점 기준가: {@game.price_high}</span>
                    </div>
                    <div class="flex items-center">
                      <span class="h-3 w-3 bg-green-400 rounded-full inline-block mr-1"></span>
                      <span>내 예측가: {@game.user_prediction}</span>
                    </div>
                  </div>
                </div>
                
    <!-- 상승/하락 예측 버튼 -->
                <div class="grid grid-cols-2 gap-4">
                  <div class="border border-green-500 bg-zinc-800 rounded p-3 text-center cursor-pointer">
                    <div class="text-green-500 font-bold mb-1">상승 예측</div>
                    <div class="text-xs text-gray-400">현재 참여자 {@game.up_percent}%</div>
                  </div>
                  <div class="border border-red-500 bg-zinc-800 rounded p-3 text-center cursor-pointer">
                    <div class="text-red-500 font-bold mb-1">하락 예측</div>
                    <div class="text-xs text-gray-400">현재 참여자 {@game.down_percent}%</div>
                  </div>
                </div>
              </div>
            </div>
            
    <!-- 하단 요약 정보 -->
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
              <%= for item <- @summary do %>
                <div class="bg-zinc-900 rounded-lg p-4 text-center">
                  <div class="text-xl font-bold">{item.value}</div>
                  <div class="text-xs text-gray-400">{item.label}</div>
                </div>
              <% end %>
            </div>
            
    <!-- 참여자 순위 테이블 -->
            <div class="bg-zinc-900 rounded-lg overflow-hidden">
              <div class="p-4 border-b border-zinc-800">
                <h2 class="text-sm font-bold">참여자 순위</h2>
              </div>

              <div class="overflow-x-auto">
                <table class="w-full">
                  <thead>
                    <tr class="text-left text-xs text-gray-400 border-b border-zinc-800">
                      <th class="p-4">순위</th>
                      <th class="p-4">사용자</th>
                      <th class="p-4">예측 가격</th>
                      <th class="p-4">예측 변동</th>
                      <th class="p-4">투자 금액</th>
                      <th class="p-4">예상 수익</th>
                    </tr>
                  </thead>
                  <tbody>
                    <%= for participant <- @participants do %>
                      <tr class={if participant.username == "나", do: "bg-zinc-800", else: ""}>
                        <td class="p-4">{participant.rank}</td>
                        <td class="p-4">
                          <div class="flex items-center">
                            <div class={"w-6 h-6 rounded-full bg-#{participant.avatar}-500 flex items-center justify-center text-xs mr-2"}>
                              {String.first(participant.username)}
                            </div>
                            <span>{participant.username}</span>
                          </div>
                        </td>
                        <td class="p-4">{participant.prediction}</td>
                        <td class="p-4">
                          <span class={
                            if String.starts_with?(participant.change, "+"),
                              do: "text-green-400",
                              else: "text-red-400"
                          }>
                            {participant.change}
                          </span>
                        </td>
                        <td class="p-4">{participant.investment}</td>
                        <td class="p-4">{participant.reward}</td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
          
    <!-- 예측 정보 및 베팅 섹션 -->
          <div class="lg:col-span-1">
            <div class="bg-zinc-900 rounded-lg p-6 mb-6">
              <h2 class="text-lg font-bold mb-4">내 예측 정보</h2>

              <div class="mb-8">
                <div class="text-center mb-4">
                  <div class="text-4xl font-bold mb-1">{@game.current_price}</div>
                  <div class="text-sm">내 예측 가격</div>
                  <div class="text-green-400 text-sm font-bold">
                    {@game.current_price_change} 상승 예측
                  </div>
                </div>

                <div class="text-center mb-6">
                  <div class="text-2xl font-bold">{@game.win_rate}</div>
                  <div class="text-xs text-gray-400">예상 수익률</div>
                </div>
              </div>
              
    <!-- 금액 선택 및 베팅 -->
              <div>
                <div class="flex items-center justify-between mb-4">
                  <h3 class="font-bold text-sm">추가 매수하기</h3>
                </div>
                
    <!-- 금액 선택 버튼 -->
                <div class="grid grid-cols-3 gap-2 mb-4">
                  <%= for option <- @investment_options do %>
                    <button
                      phx-click="select_amount"
                      phx-value-amount={option.amount}
                      class={"bg-zinc-800 rounded p-2 text-center " <> if(option.selected, do: "border border-blue-500", else: "")}
                    >
                      <div class="text-xs font-bold">{option.amount}</div>
                      <div class="text-xs">{option.label}</div>
                    </button>
                  <% end %>
                </div>
                
    <!-- 직접 입력 -->
                <div class="mb-6">
                  <label class="block text-sm font-bold mb-2">직접 입력</label>
                  <div class="flex">
                    <input
                      type="number"
                      value={@custom_amount}
                      phx-change="change_amount"
                      class="bg-zinc-800 rounded-l p-2 w-full text-right"
                    />
                    <span class="bg-zinc-700 rounded-r p-2 text-sm">원</span>
                  </div>
                </div>
                
    <!-- 투자 통계 -->
                <div class="mb-6 space-y-2">
                  <div class="flex justify-between text-sm">
                    <span>초기 투자금</span>
                    <span class="font-bold">{@investment_stats.initial_investment}</span>
                  </div>
                  <div class="flex justify-between text-sm">
                    <span>기존 추가 매수</span>
                    <span class="font-bold">{@investment_stats.accumulated_rewards}</span>
                  </div>
                  <div class="flex justify-between text-sm">
                    <span>현재 추가 매수</span>
                    <span class="font-bold">{@investment_stats.current_rewards}</span>
                  </div>
                  <div class="flex justify-between text-sm border-t border-zinc-800 pt-2">
                    <span>총계/수금액</span>
                    <span class="text-blue-400 font-bold">{@investment_stats.total_rewards}</span>
                  </div>
                </div>
                
    <!-- 배지 -->
                <div class="grid grid-cols-3 gap-2 mb-6">
                  <%= for badge <- @badges do %>
                    <div class="bg-zinc-800 rounded p-2 text-center">
                      <div class="text-xl mb-1">{badge.icon}</div>
                      <div class="text-xs">{badge.label}</div>
                    </div>
                  <% end %>
                </div>
                
    <!-- 베팅 버튼 -->
                <button
                  phx-click="place_bet"
                  class="w-full bg-blue-500 text-white font-bold py-3 rounded"
                >
                  추가 매수 확정하기
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- TradingView 스크립트 추가 -->
    <script type="text/javascript" src="https://s3.tradingview.com/tv.js">
    </script>
    <script>
      document.addEventListener("phx:update", function() {
        if (document.getElementById("tradingview_xrp_chart") && typeof TradingView !== 'undefined') {
          new TradingView.widget({
            "container_id": "tradingview_xrp_chart",
            "width": "100%",
            "height": 400,
            "symbol": "<%= @chart_settings.symbol %>",
            "interval": "<%= @chart_settings.interval %>",
            "timezone": "Etc/UTC",
            "theme": "<%= @chart_settings.theme %>",
            "style": "1",
            "locale": "kr",
            "toolbar_bg": "#f1f3f6",
            "enable_publishing": false,
            "allow_symbol_change": true,
            "studies": [
              "MACD@tv-basicstudies",
              "RSI@tv-basicstudies"
            ],
            "hideideas": true
          });
        }
      });

      // 페이지 로드 시 초기화
      window.addEventListener("load", function() {
        if (document.getElementById("tradingview_xrp_chart") && typeof TradingView !== 'undefined') {
          new TradingView.widget({
            "container_id": "tradingview_xrp_chart",
            "width": "100%",
            "height": 400,
            "symbol": "BINANCE:XRPUSDT",
            "interval": "60",
            "timezone": "Etc/UTC",
            "theme": "dark",
            "style": "1",
            "locale": "kr",
            "toolbar_bg": "#f1f3f6",
            "enable_publishing": false,
            "allow_symbol_change": true,
            "studies": [
              "MACD@tv-basicstudies",
              "RSI@tv-basicstudies"
            ],
            "hideideas": true
          });
        }
      });
    </script>
    """
  end
end
