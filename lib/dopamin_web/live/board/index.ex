defmodule DopaminWeb.BoardLive.Index do
  use DopaminWeb, :live_view

  alias Dopamin.Board
  alias Dopamin.Board.Board, as: BoardSchema

  def mount(_params, _session, socket) do
    boards = Board.list_public_boards()

    {:ok,
     socket
     |> assign(:boards, boards)
     |> assign(:page_title, "게시판")}
  end

  def render(assigns) do
    ~H"""
    <div class="relative min-h-screen pb-24">
      <!-- 우주 배경 애니메이션 -->
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
          <h1 class="text-3xl font-bold mb-2">도파민 커뮤니티</h1>
          <p class="text-gray-400 text-sm">게임과 투자에 대한 정보를 공유하고 토론하세요</p>
        </div>
        
    <!-- 게시판 목록 -->
        <div class="max-w-4xl mx-auto px-4 mb-12">
          <div class="bg-zinc-900 rounded-lg overflow-hidden board-list">
            <div class="p-6">
              <div class="flex items-center mb-6">
                <div class="text-2xl mr-4">📋</div>
                <h2 class="text-xl font-bold">게시판 목록</h2>
              </div>

              <div class="overflow-hidden">
                <table class="min-w-full bg-zinc-800 rounded-lg overflow-hidden">
                  <thead class="bg-zinc-700">
                    <tr>
                      <th class="py-3 px-4 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                        게시판
                      </th>
                      <th class="py-3 px-4 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                        설명
                      </th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-zinc-600">
                    <%= if Enum.empty?(@boards) do %>
                      <tr>
                        <td colspan="2" class="py-4 px-6 text-center text-gray-400">
                          아직 게시판이 없습니다.
                        </td>
                      </tr>
                    <% else %>
                      <%= for board <- @boards do %>
                        <tr class="hover:bg-zinc-700">
                          <td class="py-4 px-6">
                            <.link
                              navigate={~p"/boards/#{board.slug}"}
                              class="text-yellow-400 hover:text-yellow-300 font-medium"
                            >
                              {board.name}
                            </.link>
                          </td>
                          <td class="py-4 px-6 text-gray-300">
                            {board.description}
                          </td>
                        </tr>
                      <% end %>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
        
    <!-- 푸터 표시를 위한 여백 -->
        <div class="h-20"></div>
      </div>
    </div>
    """
  end
end
