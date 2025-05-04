defmodule Dopamin.Board do
  @moduledoc """
  The Board context manages forum functionality including boards, posts, and comments.
  """

  import Ecto.Query, warn: false
  alias Dopamin.Repo
  alias Dopamin.Board.{Board, Post, Comment}
  alias Dopamin.Accounts.User

  #
  # Board
  #

  def list_boards do
    Repo.all(Board)
  end

  def list_public_boards do
    Board
    |> where(is_public: true)
    |> Repo.all()
  end

  def get_board!(id), do: Repo.get!(Board, id)

  def get_board_by_slug!(slug) do
    Repo.get_by!(Board, slug: slug)
  end

  def create_board(attrs \\ %{}) do
    %Board{}
    |> Board.changeset(attrs)
    |> Repo.insert()
  end

  def update_board(%Board{} = board, attrs) do
    board
    |> Board.changeset(attrs)
    |> Repo.update()
  end

  def delete_board(%Board{} = board) do
    Repo.delete(board)
  end

  def change_board(%Board{} = board, attrs \\ %{}) do
    Board.changeset(board, attrs)
  end

  #
  # Post
  #

  def list_posts(board_id) do
    Post
    |> where(board_id: ^board_id)
    |> order_by(desc: :inserted_at)
    |> preload([:user])
    |> Repo.all()
  end

  def get_post!(id) do
    Post
    |> Repo.get!(id)
    |> Repo.preload([:user, :board, comments: [:user, replies: [:user]]])
  end

  def get_post(id) do
    Post
    |> Repo.get(id)
    |> case do
      nil -> nil
      post -> Repo.preload(post, [:user, :board, comments: [:user, replies: [:user]]])
    end
  end

  def create_post(attrs \\ %{}) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
  end

  def delete_post(%Post{} = post) do
    Repo.delete(post)
  end

  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  def inc_post_views(%Post{} = post) do
    post
    |> Post.inc_views()
    |> Repo.update()
  end

  #
  # Comment
  #

  def list_comments(post_id) do
    Comment
    |> where([c], c.post_id == ^post_id and is_nil(c.parent_id))
    |> order_by(asc: :inserted_at)
    |> preload([:user, replies: [:user]])
    |> Repo.all()
  end

  def get_comment!(id) do
    Comment
    |> Repo.get!(id)
    |> Repo.preload([:user, :post, replies: [:user]])
  end

  def create_comment(attrs \\ %{}) do
    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, comment} ->
        {:ok, Repo.preload(comment, [:user, :post, replies: [:user]])}

      error ->
        error
    end
  end

  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated_comment} ->
        {:ok, Repo.preload(updated_comment, [:user, :post, replies: [:user]])}

      error ->
        error
    end
  end

  def delete_comment(%Comment{} = comment) do
    Repo.delete(comment)
  end

  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end

  #
  # Post Search
  #

  def search_posts(query, board_id) when is_binary(query) and byte_size(query) > 0 do
    search_term = "%#{query}%"

    Post
    |> where(board_id: ^board_id)
    |> where([p], ilike(p.title, ^search_term) or ilike(p.content, ^search_term))
    |> order_by(desc: :inserted_at)
    |> preload([:user, :board])
    |> Repo.all()
  end

  def search_posts(_, board_id) do
    list_posts(board_id)
  end
end
