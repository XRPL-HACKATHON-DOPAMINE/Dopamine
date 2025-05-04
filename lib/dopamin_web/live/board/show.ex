defmodule DopaminWeb.BoardLive.Show do
  use DopaminWeb, :live_view

  alias Dopamin.Board
  alias Dopamin.Board.Post

  def mount(%{"slug" => slug}, _session, socket) do
    board = Board.get_board_by_slug!(slug)
    posts = Board.list_posts(board.id)

    # Subscribe to board topic for real-time updates
    Phoenix.PubSub.subscribe(Dopamin.PubSub, "board:#{board.id}")

    {:ok,
     socket
     |> assign(:board, board)
     |> assign(:posts, posts)
     |> assign(:search_query, nil)
     |> assign(:page_title, board.name)}
  end

  def handle_event("search", %{"search" => %{"query" => query}}, socket) do
    %{board: board} = socket.assigns
    posts = Board.search_posts(query, board.id)

    {:noreply,
     socket
     |> assign(:posts, posts)
     |> assign(:search_query, query)}
  end

  # Handle PubSub messages
  def handle_info({:post_deleted, post_id}, socket) do
    # Remove the deleted post from the list
    updated_posts = Enum.reject(socket.assigns.posts, fn post -> post.id == post_id end)

    {:noreply,
     socket
     |> assign(:posts, updated_posts)
     |> put_flash(:info, "게시글이 삭제되었습니다.")}
  end

  def handle_info({:post_created, post}, socket) do
    # Load post with associations
    post_with_preloads = Board.get_post!(post.id)

    # Add the new post to the list (prepend to show newest first)
    updated_posts = [post_with_preloads | socket.assigns.posts]

    {:noreply,
     socket
     |> assign(:posts, updated_posts)
     |> put_flash(:info, "새로운 게시글이 등록되었습니다.")}
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
          <h1 class="text-3xl font-bold mb-2">{@board.name}</h1>
          <p class="text-gray-400 text-sm">{@board.description}</p>
        </div>
        
    <!-- 게시글 목록 -->
        <div class="max-w-4xl mx-auto px-4 mb-12">
          <div class="bg-zinc-900 rounded-lg overflow-hidden board-list">
            <div class="p-6">
              <div class="flex justify-between items-center mb-6">
                <div class="flex items-center">
                  <div class="text-2xl mr-4">📝</div>
                  <h2 class="text-xl font-bold">게시글 목록</h2>
                </div>
                <div class="flex space-x-3">
                  <.form for={%{}} as={:search} phx-submit="search" class="flex">
                    <input
                      type="text"
                      name="search[query]"
                      value={@search_query}
                      placeholder="검색..."
                      class="rounded-l px-4 py-2 bg-zinc-800 text-white border-zinc-700 border focus:outline-none focus:ring-2 focus:ring-yellow-500"
                    />
                    <button
                      type="submit"
                      class="rounded-r px-4 py-2 bg-zinc-700 hover:bg-zinc-600 text-white"
                    >
                      🔍
                    </button>
                  </.form>
                  <button class="px-4 py-2 bg-yellow-500 hover:bg-yellow-400 text-black rounded">
                    <.link navigate={~p"/boards/#{@board.slug}/new"} class="flex items-center">
                      <span class="mr-1">✚</span> 글쓰기
                    </.link>
                  </button>
                </div>
              </div>

              <div class="overflow-hidden">
                <table class="min-w-full bg-zinc-800 rounded-lg overflow-hidden">
                  <thead class="bg-zinc-700">
                    <tr>
                      <th class="py-3 px-4 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                        제목
                      </th>
                      <th class="py-3 px-4 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                        작성자
                      </th>
                      <th class="py-3 px-4 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                        작성일
                      </th>
                      <th class="py-3 px-4 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                        조회수
                      </th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-zinc-600">
                    <%= if Enum.empty?(@posts) do %>
                      <tr>
                        <td colspan="4" class="py-4 px-6 text-center text-gray-400">
                          <%= if @search_query do %>
                            검색 결과가 없습니다.
                          <% else %>
                            아직 게시글이 없습니다.
                          <% end %>
                        </td>
                      </tr>
                    <% else %>
                      <%= for post <- @posts do %>
                        <tr class="hover:bg-zinc-700">
                          <td class="py-4 px-6">
                            <.link
                              navigate={~p"/boards/#{@board.slug}/posts/#{post.id}"}
                              class="text-yellow-400 hover:text-yellow-300"
                            >
                              {post.title}
                            </.link>
                          </td>
                          <td class="py-4 px-6 text-gray-300">
                            {post.user.email |> String.split("@") |> hd()}
                          </td>
                          <td class="py-4 px-6 text-gray-300">
                            {Calendar.strftime(post.inserted_at, "%Y-%m-%d")}
                          </td>
                          <td class="py-4 px-6 text-gray-300">
                            {post.views}
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
