defmodule DopaminWeb.UserSettingsLive do
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
        <div class="max-w-2xl mx-auto">
          <div class="bg-gray-900 bg-opacity-80 rounded-xl p-8 backdrop-filter backdrop-blur-lg border border-gray-800 shadow-xl">
            <.header class="text-center text-white mb-8">
              <span class="text-yellow-400 font-bold">계정 설정</span>
              <:subtitle>
                <p class="text-gray-300 mt-2">이메일 주소와 비밀번호를 관리하세요</p>
              </:subtitle>
            </.header>

            <div class="space-y-12">
              <div class="bg-gray-800 bg-opacity-50 p-6 rounded-lg">
                <h3 class="text-lg font-semibold text-yellow-400 mb-4">이메일 변경</h3>
                <.simple_form
                  for={@email_form}
                  id="email_form"
                  phx-submit="update_email"
                  phx-change="validate_email"
                >
                  <.input field={@email_form[:email]} type="email" label="이메일" required />
                  <.input
                    field={@email_form[:current_password]}
                    name="current_password"
                    id="current_password_for_email"
                    type="password"
                    label="현재 비밀번호"
                    value={@email_form_current_password}
                    required
                  />
                  <:actions>
                    <.button phx-disable-with="변경 중..." class="mt-4">이메일 변경</.button>
                  </:actions>
                </.simple_form>
              </div>

              <div class="bg-gray-800 bg-opacity-50 p-6 rounded-lg">
                <h3 class="text-lg font-semibold text-yellow-400 mb-4">비밀번호 변경</h3>
                <.simple_form
                  for={@password_form}
                  id="password_form"
                  action={~p"/users/log_in?_action=password_updated"}
                  method="post"
                  phx-change="validate_password"
                  phx-submit="update_password"
                  phx-trigger-action={@trigger_submit}
                >
                  <input
                    name={@password_form[:email].name}
                    type="hidden"
                    id="hidden_user_email"
                    value={@current_email}
                  />
                  <.input
                    field={@password_form[:password]}
                    type="password"
                    label="새 비밀번호"
                    required
                  />
                  <.input
                    field={@password_form[:password_confirmation]}
                    type="password"
                    label="새 비밀번호 확인"
                  />
                  <.input
                    field={@password_form[:current_password]}
                    name="current_password"
                    type="password"
                    label="현재 비밀번호"
                    id="current_password_for_password"
                    value={@current_password}
                    required
                  />
                  <:actions>
                    <.button phx-disable-with="변경 중..." class="mt-4">비밀번호 변경</.button>
                  </:actions>
                </.simple_form>
              </div>
            </div>

            <div class="mt-8 text-center">
              <.link
                navigate={~p"/"}
                class="text-sm text-gray-300 hover:text-yellow-400 transition-colors duration-200"
              >
                <span class="mr-1">←</span> 홈으로 돌아가기
              </.link>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end
end
