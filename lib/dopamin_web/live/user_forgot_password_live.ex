defmodule DopaminWeb.UserForgotPasswordLive do
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
              <span class="text-yellow-400 font-bold">비밀번호를 잊으셨나요?</span>
              <:subtitle>
                <p class="text-gray-300 mt-2">이메일로 비밀번호 재설정 링크를 보내드립니다</p>
              </:subtitle>
            </.header>

            <.simple_form for={@form} id="reset_password_form" phx-submit="send_email" class="mt-6">
              <.input
                field={@form[:email]}
                type="email"
                placeholder="이메일"
                label="이메일"
                required
              />
              <:actions>
                <.button phx-disable-with="전송 중..." class="w-full mt-4 py-3">
                  비밀번호 재설정 안내 메일 전송
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

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        &url(~p"/users/reset_password/#{&1}")
      )
    end

    info =
      "이메일이 저희 시스템에 등록되어 있다면, 곧 비밀번호 재설정 안내 메일을 받으실 수 있습니다."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
