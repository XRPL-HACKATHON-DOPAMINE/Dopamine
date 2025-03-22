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
end
