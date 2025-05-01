defmodule DopaminWeb.UserRegistrationLive do
  use DopaminWeb, :live_view

  alias Dopamin.Accounts
  alias Dopamin.Accounts.User

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
              <span class="text-yellow-400 font-bold">도파민</span>
              회원가입
              <:subtitle>
                <p class="text-gray-300 flex items-center justify-center space-x-1">
                  <span>이미 계정이 있으신가요?</span>
                  <.link
                    navigate={~p"/users/log_in"}
                    class="font-semibold text-yellow-400 hover:text-yellow-300 transition-colors"
                  >
                    로그인하기
                  </.link>
                </p>
              </:subtitle>
            </.header>

            <.simple_form
              for={@form}
              id="registration_form"
              phx-submit="save"
              phx-change="validate"
              phx-trigger-action={@trigger_submit}
              action={~p"/users/log_in?_action=registered"}
              method="post"
              class="space-y-6"
            >
              <.error :if={@check_errors}>
                오류가 발생했습니다. 아래의 내용을 확인해주세요.
              </.error>

              <div class="space-y-4">
                <.input
                  field={@form[:email]}
                  type="email"
                  label="이메일"
                  required
                  class="bg-gray-800 text-white border-gray-700 focus:border-yellow-400 focus:ring-yellow-400"
                />
                <.input
                  field={@form[:password]}
                  type="password"
                  label="비밀번호"
                  required
                  class="bg-gray-800 text-white border-gray-700 focus:border-yellow-400 focus:ring-yellow-400"
                />
              </div>

              <:actions>
                <.button
                  phx-disable-with="계정 생성 중..."
                  class="w-full bg-yellow-400 hover:bg-yellow-500 text-black font-bold py-3 transition-colors"
                >
                  계정 생성하기
                </.button>
              </:actions>
            </.simple_form>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
