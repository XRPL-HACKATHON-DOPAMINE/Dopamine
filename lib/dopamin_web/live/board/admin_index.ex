defmodule DopaminWeb.BoardLive.AdminIndex do
  use DopaminWeb, :live_view

  alias Dopamin.Board
  alias Dopamin.Board.Board, as: BoardSchema

  def mount(_params, _session, socket) do
    boards = Board.list_boards()

    {:ok,
     socket
     |> assign(:boards, boards)
     |> assign(:page_title, "게시판 관리")
     |> assign(:form, to_form(Board.change_board(%BoardSchema{})))}
  end

  def handle_event("save", %{"board" => board_params}, socket) do
    case Board.create_board(board_params) do
      {:ok, _board} ->
        boards = Board.list_boards()

        {:noreply,
         socket
         |> assign(:boards, boards)
         |> assign(:form, to_form(Board.change_board(%BoardSchema{})))
         |> put_flash(:info, "게시판이 생성되었습니다.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(:form, to_form(changeset))
         |> put_flash(:error, "게시판 생성에 실패했습니다.")}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    board = Board.get_board!(id)

    case Board.delete_board(board) do
      {:ok, _} ->
        boards = Board.list_boards()

        {:noreply,
         socket
         |> assign(:boards, boards)
         |> put_flash(:info, "게시판이 삭제되었습니다.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "게시판 삭제에 실패했습니다.")}
    end
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
          <h1 class="text-3xl font-bold mb-2">게시판 관리</h1>
          <p class="text-gray-400 text-sm">게시판을 생성하고 관리할 수 있습니다</p>
        </div>

        <div class="max-w-4xl mx-auto px-4">
          <!-- 게시판 생성 폼 -->
          <div class="bg-zinc-900 rounded-lg overflow-hidden mb-8">
            <div class="p-6">
              <h2 class="text-xl font-bold mb-6">새 게시판 생성</h2>

              <.form for={@form} phx-submit="save">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <.label>게시판 이름</.label>
                    <.input
                      field={@form[:name]}
                      type="text"
                      placeholder="예: 자유게시판"
                      required
                    />
                  </div>

                  <div>
                    <.label>Slug (URL 경로)</.label>
                    <.input field={@form[:slug]} type="text" placeholder="예: free-board" required />
                    <p class="text-xs text-gray-400 mt-1">영문 소문자, 숫자, 하이픈만 사용 가능</p>
                  </div>

                  <div class="md:col-span-2">
                    <.label>설명</.label>
                    <.input
                      field={@form[:description]}
                      type="textarea"
                      rows="3"
                      placeholder="게시판 설명을 입력하세요"
                    />
                  </div>

                  <div>
                    <.label>공개 여부</.label>
                    <.input field={@form[:is_public]} type="checkbox" />
                    <span class="text-sm text-gray-400">체크하면 모든 사용자가 접근할 수 있습니다</span>
                  </div>
                </div>

                <div class="mt-6 flex justify-end">
                  <button
                    type="submit"
                    class="px-6 py-2 bg-yellow-500 hover:bg-yellow-400 text-black rounded"
                  >
                    게시판 생성
                  </button>
                </div>
              </.form>
            </div>
          </div>
          
    <!-- 게시판 목록 -->
          <div class="bg-zinc-900 rounded-lg overflow-hidden">
            <div class="p-6">
              <h2 class="text-xl font-bold mb-6">게시판 목록</h2>

              <div class="overflow-x-auto">
                <table class="min-w-full">
                  <thead>
                    <tr class="border-b border-zinc-700">
                      <th class="py-3 px-4 text-left text-sm font-medium text-gray-400">이름</th>
                      <th class="py-3 px-4 text-left text-sm font-medium text-gray-400">Slug</th>
                      <th class="py-3 px-4 text-left text-sm font-medium text-gray-400">설명</th>
                      <th class="py-3 px-4 text-left text-sm font-medium text-gray-400">공개</th>
                      <th class="py-3 px-4 text-left text-sm font-medium text-gray-400">작업</th>
                    </tr>
                  </thead>
                  <tbody>
                    <%= for board <- @boards do %>
                      <tr class="border-b border-zinc-800">
                        <td class="py-4 px-4 text-sm font-medium">{board.name}</td>
                        <td class="py-4 px-4 text-sm text-gray-400">{board.slug}</td>
                        <td class="py-4 px-4 text-sm text-gray-400">{board.description}</td>
                        <td class="py-4 px-4 text-sm">
                          <%= if board.is_public do %>
                            <span class="text-green-400">공개</span>
                          <% else %>
                            <span class="text-red-400">비공개</span>
                          <% end %>
                        </td>
                        <td class="py-4 px-4 text-sm">
                          <button
                            phx-click="delete"
                            phx-value-id={board.id}
                            phx-confirm="정말 이 게시판을 삭제하시겠습니까? 모든 게시글과 댓글이 삭제됩니다."
                            class="text-red-400 hover:text-red-300"
                          >
                            삭제
                          </button>
                        </td>
                      </tr>
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
