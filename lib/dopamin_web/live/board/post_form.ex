defmodule DopaminWeb.BoardLive.PostForm do
  use DopaminWeb, :live_view

  alias Dopamin.Board
  alias Dopamin.Board.Post

  def mount(%{"slug" => slug} = params, _session, socket) do
    board = Board.get_board_by_slug!(slug)

    # 게시글 작성인지 수정인지 결정
    {post, title, action} =
      case params do
        %{"id" => id} ->
          post = Board.get_post!(id)
          {post, "게시글 수정", :edit}

        _ ->
          {%Post{}, "새 게시글 작성", :new}
      end

    form = Board.change_post(post) |> to_form()

    {:ok,
     socket
     |> assign(:board, board)
     |> assign(:post, post)
     |> assign(:form, form)
     |> assign(:live_action, action)
     |> assign(:page_title, title)}
  end

  def handle_event("validate", %{"post" => post_params}, socket) do
    changeset =
      socket.assigns.post
      |> Board.change_post(post_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :form, changeset)}
  end

  def handle_event("save", %{"post" => post_params}, socket) do
    %{post: post, board: board, current_user: current_user} = socket.assigns

    complete_params =
      post_params
      |> Map.put("board_id", board.id)
      |> Map.put("user_id", current_user.id)

    save_post(socket, socket.assigns.live_action, post, complete_params)
  end

  defp save_post(socket, :new, _post, post_params) do
    case Board.create_post(post_params) do
      {:ok, post} ->
        # Broadcast new post creation
        Phoenix.PubSub.broadcast(
          Dopamin.PubSub,
          "board:#{socket.assigns.board.id}",
          {:post_created, post}
        )

        {:noreply,
         socket
         |> put_flash(:info, "게시글이 작성되었습니다.")
         |> push_navigate(to: ~p"/boards/#{socket.assigns.board.slug}/posts/#{post.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, changeset |> to_form())}
    end
  end

  defp save_post(socket, :edit, post, post_params) do
    # 현재 사용자가 글 작성자인지 확인
    if socket.assigns.current_user.id != post.user_id do
      {:noreply,
       socket
       |> put_flash(:error, "권한이 없습니다.")
       |> push_navigate(to: ~p"/boards/#{socket.assigns.board.slug}/posts/#{post.id}")}
    else
      case Board.update_post(post, post_params) do
        {:ok, post} ->
          {:noreply,
           socket
           |> put_flash(:info, "게시글이 수정되었습니다.")
           |> push_navigate(to: ~p"/boards/#{socket.assigns.board.slug}/posts/#{post.id}")}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, :form, changeset |> to_form())}
      end
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
        <!-- 게시글 폼 -->
        <div class="max-w-4xl mx-auto px-4 mb-8 mt-8">
          <div class="flex items-center mb-6">
            <.link
              navigate={~p"/boards/#{@board.slug}"}
              class="text-yellow-400 hover:text-yellow-300 mr-2"
            >
              <div class="flex items-center">
                <span>←</span>
                <span class="ml-1">{@board.name}</span>
              </div>
            </.link>
            <span class="text-gray-500">
              / {if @live_action == :new, do: "새 게시글", else: "게시글 수정"}
            </span>
          </div>

          <div class="bg-zinc-900 rounded-lg overflow-hidden">
            <div class="p-6">
              <h1 class="text-2xl font-bold mb-6">
                {if @live_action == :new, do: "새 게시글 작성", else: "게시글 수정"}
              </h1>

              <.form for={@form} phx-change="validate" phx-submit="save" id="post-form">
                <div class="space-y-6">
                  <div>
                    <.label>제목</.label>
                    <.input
                      field={@form[:title]}
                      type="text"
                      placeholder="제목을 입력하세요"
                      required={true}
                    />
                  </div>

                  <div>
                    <.label>내용</.label>
                    <.input
                      field={@form[:content]}
                      type="textarea"
                      rows="12"
                      placeholder="내용을 입력하세요"
                      required={true}
                    />
                  </div>

                  <div class="flex justify-end space-x-3">
                    <.link
                      navigate={~p"/boards/#{@board.slug}"}
                      class="px-4 py-2 rounded bg-zinc-700 hover:bg-zinc-600 text-white"
                    >
                      취소
                    </.link>
                    <button
                      type="submit"
                      class="px-4 py-2 rounded bg-yellow-500 hover:bg-yellow-400 text-black"
                    >
                      {if @live_action == :new, do: "작성 완료", else: "수정 완료"}
                    </button>
                  </div>
                </div>
              </.form>
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
