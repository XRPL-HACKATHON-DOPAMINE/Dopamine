defmodule Dopamin.Game do
  @moduledoc """
  게임 관련 컨텍스트입니다.
  """

  import Ecto.Query, warn: false
  alias Dopamin.Repo
  alias Dopamin.Games.{Game, GameParticipants, TopPlayer}

  @doc """
  모든 게임 목록을 조회합니다.
  """
  def list_games() do
    Repo.all(Game)
  end

  @doc """
  게임 카테고리별로 게임을 조회합니다.
  """
  def list_games_by_category(category) when category in ["", "전체 게임"] do
    list_games()
  end

  def list_games_by_category(category) do
    Repo.all(from g in Game, where: g.category == ^category)
  end

  @doc """
  ID로 특정 게임을 조회합니다.
  """
  def get_game!(id), do: Repo.get!(Game, id)

  @doc """
  주어진 속성으로 게임을 생성합니다.
  """
  def create_game(attrs \\ %{}) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  주어진 속성으로 게임을 업데이트합니다.
  """
  def update_game(%Game{} = game, attrs) do
    game
    |> Game.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  게임을 삭제합니다.
  """
  def delete_game(%Game{} = game) do
    Repo.delete(game)
  end

  @doc """
  사용 가능한 모든 게임 카테고리를 조회합니다.
  """
  def list_categories do
    ["전체 게임" | Repo.all(from g in Game, select: g.category, distinct: true)]
  end

  # GameParticipants 관련 함수들

  @doc """
  게임에 참가합니다.
  """
  def join_game(game_id, user_id, bet_amount) do
    now = DateTime.utc_now()

    %GameParticipants{}
    |> GameParticipants.changeset(%{
      game_id: game_id,
      user_id: user_id,
      bet_amount: bet_amount,
      status: "active",
      joined_at: now
    })
    |> Repo.insert()
  end

  @doc """
  사용자의 게임 참가 여부를 확인합니다.
  """
  def user_joined_game?(game_id, user_id) do
    query =
      from p in GameParticipants,
        where: p.game_id == ^game_id and p.user_id == ^user_id,
        where: p.status == "active"

    Repo.exists?(query)
  end

  @doc """
  게임의 참가자 수를 조회합니다.
  """
  def count_participants(game_id) do
    query =
      from p in GameParticipants,
        where: p.game_id == ^game_id,
        where: p.status == "active"

    Repo.aggregate(query, :count)
  end

  @doc """
  게임 ID로 게임의 모든 관련 데이터를 불러옵니다.
  """
  def get_game_with_details(id) do
    game =
      Repo.get(Game, id)
      |> Repo.preload([
        :rules,
        :betting_options,
        :reward_tiers,
        top_players: from(tp in TopPlayer, order_by: tp.rank)
      ])
  end

  @doc """
  게임에 참가합니다.
  """
  def join_game(game_id, user_id, bet_amount) do
    now = DateTime.utc_now()

    # 이미 참여한 경우 중복 참여 방지
    if user_joined_game?(game_id, user_id) do
      {:error, "이미 게임에 참여하셨습니다"}
    else
      %GameParticipants{}
      |> GameParticipants.changeset(%{
        game_id: game_id,
        user_id: user_id,
        bet_amount: bet_amount,
        status: "active",
        joined_at: now
      })
      |> Repo.insert()
      |> case do
        {:ok, participant} = result ->
          # 게임 참가자 수 증가 로직 (필요한 경우)
          update_game_participants_count(game_id)

          # 이벤트 로깅 또는 추가 작업 (필요한 경우)
          log_participant_joined(participant)

          result

        error ->
          error
      end
    end
  end

  # 참여자 수 업데이트 (필요한 경우)
  defp update_game_participants_count(game_id) do
    game = Repo.get(Game, game_id)
    participants_count = count_participants(game_id)

    Game.changeset(game, %{players: participants_count})
    |> Repo.update()
  end

  # 참여 로그 기록 (선택적)
  defp log_participant_joined(participant) do
    # 로깅 로직이 필요한 경우 구현
    IO.puts(
      "Player #{participant.user_id} joined game #{participant.game_id} with bet #{participant.bet_amount}"
    )
  end

  @doc """
  참가자 ID로 참가 정보를 조회합니다.
  """
  def get_participant(participant_id) do
    Repo.get(GameParticipants, participant_id)
    |> Repo.preload(:game)
  end

  @doc """
  참가자 ID로 참가 정보를 조회합니다.
  """
  def get_participant(participant_id) do
    Repo.get(GameParticipants, participant_id)
    |> Repo.preload(:game)
  end

  @doc """
  참가자의 베팅 금액을 업데이트합니다.
  """
  def update_participant_bet(participant_id, bet_amount) do
    participant = get_participant(participant_id)

    if participant do
      GameParticipants.changeset(participant, %{bet_amount: bet_amount})
      |> Repo.update()
    else
      {:error, :not_found}
    end
  end

  @doc """
  게임 ID에 해당하는 참가자 목록을 조회합니다.
  """
  def list_game_participants(game_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)
    status = Keyword.get(opts, :status)

    query =
      from p in GameParticipants,
        where: p.game_id == ^game_id,
        order_by: [desc: p.bet_amount],
        limit: ^limit,
        offset: ^offset

    query = if status, do: from(q in query, where: q.status == ^status), else: query

    Repo.all(query)
  end

  @doc """
  유저 ID와 게임 ID로 참가 정보를 조회합니다.
  """
  def get_participant_by_user_and_game(user_id, game_id) do
    Repo.get_by(GameParticipants, user_id: user_id, game_id: game_id)
  end

  @doc """
  게임의 총 참가자 수를 조회합니다.
  """
  def count_game_participants(game_id, status \\ "active") do
    query =
      from p in GameParticipants,
        where: p.game_id == ^game_id,
        where: p.status == ^status

    Repo.aggregate(query, :count)
  end

  @doc """
  참가자 결과를 업데이트합니다.
  """
  def update_participant_result(participant_id, result, reward_amount) do
    participant = get_participant(participant_id)

    if participant do
      GameParticipants.changeset(participant, %{
        status: "completed",
        result: result,
        reward_amount: reward_amount
      })
      |> Repo.update()
    else
      {:error, :not_found}
    end
  end

  @doc """
  사용자의 모든 게임 참가 이력을 조회합니다.
  """
  def list_user_participations(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)
    offset = Keyword.get(opts, :offset, 0)
    status = Keyword.get(opts, :status)

    query =
      from p in GameParticipants,
        join: g in Game,
        on: p.game_id == g.id,
        where: p.user_id == ^user_id,
        order_by: [desc: p.inserted_at],
        limit: ^limit,
        offset: ^offset,
        select: %{
          id: p.id,
          game_id: p.game_id,
          game_name: g.name,
          bet_amount: p.bet_amount,
          status: p.status,
          result: p.result,
          reward_amount: p.reward_amount,
          joined_at: p.joined_at
        }

    query = if status, do: from(q in query, where: q.status == ^status), else: query

    Repo.all(query)
  end
end
