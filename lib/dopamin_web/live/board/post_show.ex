defmodule DopaminWeb.BoardLive.PostShow do
  use DopaminWeb, :live_view

  alias Dopamin.Board
  alias Dopamin.Board.{Post, Comment}
  alias Dopamin.Accounts

  def mount(%{"slug" => slug, "id" => id}, _session, socket) do
    try do
      board = Board.get_board_by_slug!(slug)

      case Board.get_post(id) do
        nil ->
          {:ok,
           socket
           |> put_flash(:error, "게시글을 찾을 수 없습니다.")
           |> push_navigate(to: ~p"/boards/#{board.slug}")}

        post ->
          # Subscribe to PubSub topics for real-time updates
          Phoenix.PubSub.subscribe(Dopamin.PubSub, "board:#{board.id}")
          Phoenix.PubSub.subscribe(Dopamin.PubSub, "post:#{post.id}")

          # 조회수 증가
          {:ok, post} = Board.inc_post_views(post)

          # 댓글 목록 가져오기
          comments = Board.list_comments(post.id)

          # 새 댓글 작성을 위한 changeset
          comment_form = Board.change_comment(%Comment{}) |> to_form()

          {:ok,
           socket
           |> assign(:board, board)
           |> assign(:post, post)
           |> assign(:comments, comments)
           |> assign(:comment_form, comment_form)
           |> assign(:reply_to, nil)
           |> assign(:editing_comment_id, nil)
           |> assign(:page_title, post.title)}
      end
    rescue
      Ecto.NoResultsError ->
        {:ok,
         socket
         |> put_flash(:error, "게시판을 찾을 수 없습니다.")
         |> push_navigate(to: ~p"/boards")}
    end
  end

  def handle_event("save_comment", %{"comment" => comment_params}, socket) do
    %{post: post, current_user: current_user, reply_to: reply_to} = socket.assigns

    complete_params =
      comment_params
      |> Map.put("post_id", post.id)
      |> Map.put("user_id", current_user.id)

    complete_params =
      if reply_to do
        Map.put(complete_params, "parent_id", reply_to)
      else
        complete_params
      end

    case Board.create_comment(complete_params) do
      {:ok, comment} ->
        # Broadcast comment creation to all subscribers
        Phoenix.PubSub.broadcast(
          Dopamin.PubSub,
          "post:#{post.id}",
          {:comment_created, comment}
        )

        comments = Board.list_comments(post.id)

        {:noreply,
         socket
         |> assign(:comments, comments)
         |> assign(:comment_form, Board.change_comment(%Comment{}) |> to_form())
         |> assign(:reply_to, nil)
         |> put_flash(:info, "댓글이 등록되었습니다.")
         |> push_event("reset_form", %{})}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(:comment_form, changeset |> to_form())
         |> put_flash(:error, "댓글 등록에 실패했습니다.")}
    end
  end

  def handle_event("reply_to", %{"id" => comment_id}, socket) do
    comment_id = if is_binary(comment_id), do: String.to_integer(comment_id), else: comment_id
    {:noreply, assign(socket, :reply_to, comment_id)}
  end

  def handle_event("cancel_reply", _, socket) do
    {:noreply, assign(socket, :reply_to, nil)}
  end

  def handle_event("confirm_delete_post", _, socket) do
    {:noreply,
     push_event(socket, "show_confirm", %{
       message: "정말 이 게시글을 삭제하시겠습니까?",
       event: "delete_post",
       id: socket.assigns.post.id
     })}
  end

  def handle_event("delete_post", %{"id" => _post_id}, socket) do
    %{post: post, current_user: current_user, board: board} = socket.assigns

    if current_user.id == post.user_id do
      case Board.delete_post(post) do
        {:ok, _} ->
          # Broadcast deletion to all subscribers
          Phoenix.PubSub.broadcast(
            Dopamin.PubSub,
            "board:#{board.id}",
            {:post_deleted, post.id}
          )

          {:noreply,
           socket
           |> put_flash(:info, "게시글이 삭제되었습니다.")
           |> push_navigate(to: ~p"/boards/#{board.slug}")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "게시글 삭제에 실패했습니다.")}
      end
    else
      {:noreply, put_flash(socket, :error, "권한이 없습니다.")}
    end
  end

  def handle_event("confirm_delete_comment", %{"id" => comment_id}, socket) do
    {:noreply,
     push_event(socket, "show_confirm", %{
       message: "정말 이 댓글을 삭제하시겠습니까?",
       event: "delete_comment",
       id: comment_id
     })}
  end

  def handle_event("edit_comment", %{"id" => comment_id}, socket) do
    %{current_user: current_user} = socket.assigns
    comment = Board.get_comment!(comment_id)

    if current_user.id == comment.user_id do
      {:noreply,
       socket
       |> assign(:editing_comment_id, String.to_integer(comment_id))
       |> maybe_assign_comment_form()}
    else
      {:noreply, put_flash(socket, :error, "권한이 없습니다.")}
    end
  end

  def handle_event("cancel_edit", _, socket) do
    {:noreply,
     socket
     |> assign(:editing_comment_id, nil)}
  end

  def handle_event("update_comment", %{"comment" => comment_params}, socket) do
    %{current_user: current_user, post: post, editing_comment_id: comment_id} = socket.assigns
    comment = Board.get_comment!(comment_id)

    if current_user.id == comment.user_id do
      case Board.update_comment(comment, comment_params) do
        {:ok, updated_comment} ->
          # Broadcast comment update
          Phoenix.PubSub.broadcast(
            Dopamin.PubSub,
            "post:#{post.id}",
            {:comment_updated, updated_comment}
          )

          comments = Board.list_comments(post.id)

          {:noreply,
           socket
           |> assign(:comments, comments)
           |> assign(:editing_comment_id, nil)
           |> put_flash(:info, "댓글이 수정되었습니다.")}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, put_flash(socket, :error, "댓글 수정에 실패했습니다.")}
      end
    else
      {:noreply, put_flash(socket, :error, "권한이 없습니다.")}
    end
  end

  def handle_event("delete_comment", %{"id" => comment_id}, socket) do
    %{current_user: current_user, post: post} = socket.assigns
    comment = Board.get_comment!(comment_id)

    if current_user.id == comment.user_id do
      case Board.delete_comment(comment) do
        {:ok, _} ->
          # Broadcast comment deletion to all subscribers
          Phoenix.PubSub.broadcast(
            Dopamin.PubSub,
            "post:#{post.id}",
            {:comment_deleted, comment.id}
          )

          comments = Board.list_comments(socket.assigns.post.id)

          {:noreply,
           socket
           |> assign(:comments, comments)
           |> put_flash(:info, "댓글이 삭제되었습니다.")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "댓글 삭제에 실패했습니다.")}
      end
    else
      {:noreply, put_flash(socket, :error, "권한이 없습니다.")}
    end
  end

  def handle_info({:post_deleted, post_id}, socket) do
    if socket.assigns.post.id == post_id do
      {:noreply,
       socket
       |> put_flash(:error, "이 게시글이 삭제되었습니다.")
       |> push_navigate(to: ~p"/boards/#{socket.assigns.board.slug}")}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:comment_created, comment}, socket) do
    # Always update comments list when a new comment is created
    comments = Board.list_comments(socket.assigns.post.id)

    # Only show notification if comment is from another user
    if comment.user_id != socket.assigns.current_user.id do
      {:noreply,
       socket
       |> assign(:comments, comments)
       |> put_flash(:info, "새로운 댓글이 등록되었습니다.")}
    else
      {:noreply, assign(socket, :comments, comments)}
    end
  end

  def handle_info({:comment_updated, updated_comment}, socket) do
    # Always update comments list when a comment is updated
    comments = Board.list_comments(socket.assigns.post.id)

    # Only show notification if comment is from another user
    if updated_comment.user_id != socket.assigns.current_user.id do
      {:noreply,
       socket
       |> assign(:comments, comments)
       |> put_flash(:info, "댓글이 수정되었습니다.")}
    else
      {:noreply, assign(socket, :comments, comments)}
    end
  end

  def handle_info({:comment_deleted, comment_id}, socket) do
    # Update comments list when a comment is deleted
    comments = Board.list_comments(socket.assigns.post.id)

    {:noreply,
     socket
     |> assign(:comments, comments)
     |> put_flash(:info, "댓글이 삭제되었습니다.")}
  end

  def render(assigns) do
    ~H"""
    <div class="relative min-h-screen pb-24" phx-hook="ConfirmModal" id="post-show-container">
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
        <!-- 게시글 내용 -->
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
            <span class="text-gray-500">/ 게시글</span>
          </div>

          <div class="bg-zinc-900 rounded-lg overflow-hidden mb-8">
            <div class="p-6">
              <h1 class="text-2xl font-bold mb-3">{@post.title}</h1>

              <div class="flex justify-between text-sm text-gray-400 mb-6 pb-4 border-b border-zinc-700">
                <div>
                  작성자:
                  <span class="text-gray-300">{@post.user.email |> String.split("@") |> hd()}</span>
                </div>
                <div class="flex space-x-4">
                  <div>
                    작성일:
                    <span class="text-gray-300">
                      {Calendar.strftime(@post.inserted_at, "%Y-%m-%d %H:%M")}
                    </span>
                  </div>
                  <div>
                    조회수: <span class="text-gray-300">{@post.views}</span>
                  </div>
                </div>
              </div>

              <div class="post-content prose prose-invert max-w-none">
                {raw(@post.content |> String.replace("\n", "<br/>"))}
              </div>

              <%= if @current_user && @current_user.id == @post.user_id do %>
                <div class="mt-6 flex justify-end space-x-3">
                  <.link
                    navigate={~p"/boards/#{@board.slug}/posts/#{@post.id}/edit"}
                    class="px-4 py-2 rounded bg-zinc-700 hover:bg-zinc-600 text-white"
                  >
                    수정
                  </.link>
                  <button
                    phx-click="confirm_delete_post"
                    class="px-4 py-2 rounded bg-red-700 hover:bg-red-600 text-white"
                  >
                    삭제
                  </button>
                </div>
              <% end %>
            </div>
          </div>
          
    <!-- 댓글 섹션 -->
          <div class="bg-zinc-900 rounded-lg overflow-hidden mb-8">
            <div class="p-6">
              <h2 class="text-xl font-bold mb-6">댓글 ({length(@comments)})</h2>
              
    <!-- 댓글 목록 -->
              <div class="space-y-6 mb-8">
                <%= if Enum.empty?(@comments) do %>
                  <p class="text-gray-400 text-center py-4">아직 댓글이 없습니다.</p>
                <% else %>
                  <%= for comment <- @comments do %>
                    <.comment
                      comment={comment}
                      current_user={@current_user}
                      editing_comment_id={@editing_comment_id}
                    />
                  <% end %>
                <% end %>
              </div>
              
    <!-- 댓글 작성 폼 -->
              <%= if !@editing_comment_id do %>
                <div class="mt-8">
                  <h3 class="text-lg font-semibold mb-3">
                    <%= if @reply_to do %>
                      답글 작성
                    <% else %>
                      댓글 작성
                    <% end %>
                  </h3>

                  <%= if @reply_to do %>
                    <div class="mb-3 p-3 bg-zinc-800 rounded-lg flex justify-between items-center">
                      <div>
                        <% comment_to_reply =
                          Enum.find(@comments, fn c -> to_string(c.id) == to_string(@reply_to) end) %>
                        <%= if comment_to_reply do %>
                          <span class="text-yellow-400">
                            @{comment_to_reply.user.email |> String.split("@") |> hd()}
                          </span>
                          <span class="text-gray-400">님에게 답글 작성 중</span>
                        <% else %>
                          <span class="text-gray-400">답글 작성 중</span>
                        <% end %>
                      </div>
                      <button phx-click="cancel_reply" class="text-gray-400 hover:text-gray-300">
                        취소
                      </button>
                    </div>
                  <% end %>

                  <.form
                    for={@comment_form}
                    phx-submit="save_comment"
                    id="comment-form"
                    phx-hook="FormReset"
                  >
                    <div class="mb-4">
                      <.input
                        field={@comment_form[:content]}
                        type="textarea"
                        rows="4"
                        placeholder="댓글을 입력하세요"
                        required={true}
                      />
                    </div>

                    <div class="flex justify-end">
                      <button
                        type="submit"
                        class="px-4 py-2 bg-yellow-500 hover:bg-yellow-400 text-black rounded"
                      >
                        {if @reply_to, do: "답글 등록", else: "댓글 등록"}
                      </button>
                    </div>
                  </.form>
                </div>
              <% end %>
            </div>
          </div>
        </div>
        
    <!-- 푸터 표시를 위한 여백 -->
        <div class="h-20"></div>
      </div>
    </div>
    """
  end

  # 댓글 컴포넌트
  def comment(assigns) do
    assigns = assign_new(assigns, :editing_comment_id, fn -> nil end)

    changeset =
      if assigns.editing_comment_id == assigns.comment.id do
        Board.change_comment(assigns.comment) |> to_form()
      else
        nil
      end

    assigns = assign(assigns, :edit_form, changeset)

    ~H"""
    <div id={"comment-#{@comment.id}"} class="bg-zinc-800 rounded-lg p-4">
      <%= if @editing_comment_id == @comment.id do %>
        <div class="mb-3">
          <div class="flex items-center mb-2">
            <span class="text-yellow-400 font-semibold mr-2">댓글 수정</span>
            <span class="text-gray-400 text-sm">
              작성자: {@comment.user.email |> String.split("@") |> hd()}
            </span>
          </div>

          <.form
            for={@edit_form}
            phx-submit="update_comment"
            phx-hook="FormReset"
            id={"edit-comment-form-#{@comment.id}"}
          >
            <div class="mb-4">
              <.input
                field={@edit_form[:content]}
                type="textarea"
                rows="4"
                required={true}
                value={@comment.content}
              />
            </div>
            <div class="flex justify-end space-x-2">
              <button
                type="button"
                phx-click="cancel_edit"
                class="px-4 py-2 bg-zinc-700 hover:bg-zinc-600 text-white rounded"
              >
                취소
              </button>
              <button
                type="submit"
                class="px-4 py-2 bg-yellow-500 hover:bg-yellow-400 text-black rounded"
              >
                수정 완료
              </button>
            </div>
          </.form>
        </div>
      <% else %>
        <div class="flex justify-between mb-2">
          <div class="text-yellow-400 font-semibold">
            {@comment.user.email |> String.split("@") |> hd()}
          </div>
          <div class="text-gray-400 text-sm">
            {Calendar.strftime(@comment.inserted_at, "%Y-%m-%d %H:%M")}
          </div>
        </div>

        <div class="text-gray-300 mb-3">
          {raw(@comment.content |> String.replace("\n", "<br/>"))}
        </div>

        <div class="flex justify-between items-center mt-2">
          <%= if !@editing_comment_id do %>
            <button
              phx-click="reply_to"
              phx-value-id={@comment.id}
              class="text-sm text-gray-400 hover:text-yellow-400"
            >
              답글
            </button>
          <% else %>
            <div></div>
          <% end %>

          <%= if @current_user && @current_user.id == @comment.user_id do %>
            <div class="flex space-x-2">
              <button
                phx-click="edit_comment"
                phx-value-id={@comment.id}
                class="text-sm text-gray-400 hover:text-gray-300"
              >
                수정
              </button>
              <button
                phx-click="confirm_delete_comment"
                phx-value-id={@comment.id}
                class="text-sm text-gray-400 hover:text-red-400"
              >
                삭제
              </button>
            </div>
          <% end %>
        </div>
      <% end %>
      
    <!-- 대댓글 목록 -->
      <%= if @comment.replies && length(@comment.replies) > 0 do %>
        <div class="mt-4 pl-4 border-l-2 border-zinc-700 space-y-3">
          <%= for reply <- @comment.replies do %>
            <%= if @editing_comment_id == reply.id do %>
              <% edit_reply_form = Board.change_comment(reply) |> to_form() %>
              <div class="bg-zinc-700 rounded-lg p-3">
                <div class="mb-3">
                  <div class="flex items-center mb-2">
                    <span class="text-yellow-400 font-semibold mr-2">답글 수정</span>
                    <span class="text-gray-400 text-sm">
                      작성자: {reply.user.email |> String.split("@") |> hd()}
                    </span>
                  </div>

                  <.form
                    for={edit_reply_form}
                    phx-submit="update_comment"
                    phx-hook="FormReset"
                    id={"edit-reply-form-#{reply.id}"}
                  >
                    <div class="mb-4">
                      <.input
                        field={edit_reply_form[:content]}
                        type="textarea"
                        rows="3"
                        required={true}
                        value={reply.content}
                      />
                    </div>
                    <div class="flex justify-end space-x-2">
                      <button
                        type="button"
                        phx-click="cancel_edit"
                        class="px-3 py-1.5 bg-zinc-600 hover:bg-zinc-500 text-white rounded text-sm"
                      >
                        취소
                      </button>
                      <button
                        type="submit"
                        class="px-3 py-1.5 bg-yellow-500 hover:bg-yellow-400 text-black rounded text-sm"
                      >
                        수정 완료
                      </button>
                    </div>
                  </.form>
                </div>
              </div>
            <% else %>
              <div class="bg-zinc-700 rounded-lg p-3">
                <div class="flex justify-between mb-2">
                  <div class="text-yellow-400 font-semibold">
                    {reply.user.email |> String.split("@") |> hd()}
                  </div>
                  <div class="text-gray-400 text-sm">
                    {Calendar.strftime(reply.inserted_at, "%Y-%m-%d %H:%M")}
                  </div>
                </div>

                <div class="text-gray-300">
                  {raw(reply.content |> String.replace("\n", "<br/>"))}
                </div>

                <%= if @current_user && @current_user.id == reply.user_id do %>
                  <div class="flex justify-end space-x-2 mt-2">
                    <button
                      phx-click="edit_comment"
                      phx-value-id={reply.id}
                      class="text-sm text-gray-400 hover:text-gray-300"
                    >
                      수정
                    </button>
                    <button
                      phx-click="confirm_delete_comment"
                      phx-value-id={reply.id}
                      class="text-sm text-gray-400 hover:text-red-400"
                    >
                      삭제
                    </button>
                  </div>
                <% end %>
              </div>
            <% end %>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp maybe_assign_comment_form(socket) do
    if socket.assigns[:comment_form] do
      socket
    else
      assign(socket, :comment_form, Board.change_comment(%Comment{}) |> to_form())
    end
  end
end
