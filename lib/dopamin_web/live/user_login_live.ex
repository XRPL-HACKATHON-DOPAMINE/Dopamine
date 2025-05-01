defmodule DopaminWeb.UserLoginLive do
  use DopaminWeb, :live_view

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
              로그인
              <:subtitle>
                <p class="text-gray-300 flex items-center justify-center space-x-1">
                  <span>계정이 없으신가요?</span>
                  <.link
                    navigate={~p"/users/register"}
                    class="font-semibold text-yellow-400 hover:text-yellow-300 transition-colors"
                  >
                    회원가입하기
                  </.link>
                </p>
              </:subtitle>
            </.header>

            <.simple_form
              for={@form}
              id="login_form"
              action={~p"/users/log_in"}
              phx-update="ignore"
              class="space-y-6"
            >
              <div class="space-y-4">
                <.input field={@form[:email]} type="email" label="이메일" required />
                <.input field={@form[:password]} type="password" label="비밀번호" required />
              </div>

              <:actions>
                <div class="flex items-center">
                  <.input field={@form[:remember_me]} type="checkbox" label="로그인 상태 유지" />
                </div>
                <.link
                  href={~p"/users/reset_password"}
                  class="text-sm font-semibold text-yellow-400 hover:text-yellow-300 transition-colors"
                >
                  비밀번호를 잊으셨나요?
                </.link>
              </:actions>
              <:actions>
                <.button phx-disable-with="로그인 중..." class="w-full py-3">
                  로그인 <span aria-hidden="true" class="ml-1">→</span>
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
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
