defmodule DopaminWeb.UserResetPasswordLive do
  use DopaminWeb, :live_view

  alias Dopamin.Accounts

  def render(assigns) do
    ~H"""
    <div class="relative min-h-screen pt-28 pb-24">
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
        <div class="space-planet planet-1"></div>
        <div class="space-planet planet-2"></div>
        <div class="space-nebula"></div>
      </div>

      <div class="content-wrapper">
        <div class="mx-auto max-w-sm">
          <div class="bg-gray-900 bg-opacity-80 rounded-xl p-8 backdrop-filter backdrop-blur-lg border border-gray-800 shadow-xl">
            <.header class="text-center text-white">
              <span class="text-yellow-400 font-bold">비밀번호 재설정</span>
            </.header>

            <.simple_form
              for={@form}
              id="reset_password_form"
              phx-submit="reset_password"
              phx-change="validate"
              class="mt-6"
            >
              <.error :if={@form.errors != []}>
                오류가 발생했습니다. 아래 내용을 확인해 주세요.
              </.error>

              <div class="space-y-4">
                <.input field={@form[:password]} type="password" label="새 비밀번호" required />
                <.input
                  field={@form[:password_confirmation]}
                  type="password"
                  label="새 비밀번호 확인"
                  required
                />
              </div>

              <:actions>
                <.button phx-disable-with="재설정 중..." class="w-full mt-6 py-3">
                  비밀번호 재설정
                </.button>
              </:actions>
            </.simple_form>

            <div class="flex justify-center items-center space-x-4 mt-6">
              <.link
                href={~p"/users/register"}
                class="text-sm text-gray-300 hover:text-yellow-400 transition-colors"
              >
                회원가입
              </.link>
              <span class="text-gray-500">|</span>
              <.link
                href={~p"/users/log_in"}
                class="text-sm text-gray-300 hover:text-yellow-400 transition-colors"
              >
                로그인
              </.link>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(params, _session, socket) do
    socket = assign_user_and_token(socket, params)

    form_source =
      case socket.assigns do
        %{user: user} ->
          Accounts.change_user_password(user)

        _ ->
          %{}
      end

    {:ok, assign_form(socket, form_source), temporary_assigns: [form: nil]}
  end

  # Do not log in the user after reset password to avoid a
  # leaked token giving the user access to the account.
  def handle_event("reset_password", %{"user" => user_params}, socket) do
    case Accounts.reset_user_password(socket.assigns.user, user_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "비밀번호가 성공적으로 재설정되었습니다.")
         |> redirect(to: ~p"/users/log_in")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, Map.put(changeset, :action, :insert))}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_password(socket.assigns.user, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_user_and_token(socket, %{"token" => token}) do
    if user = Accounts.get_user_by_reset_password_token(token) do
      assign(socket, user: user, token: token)
    else
      socket
      |> put_flash(:error, "비밀번호 재설정 링크가 유효하지 않거나 만료되었습니다.")
      |> redirect(to: ~p"/")
    end
  end

  defp assign_form(socket, %{} = source) do
    assign(socket, :form, to_form(source, as: "user"))
  end
end
