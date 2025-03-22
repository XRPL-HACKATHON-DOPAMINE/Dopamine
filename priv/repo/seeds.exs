alias Dopamin.Repo

alias Dopamin.Games.{
  Game,
  GameRule,
  BettingOption,
  RewardTier,
  TopPlayer,
  GameParticipants
}

# 기존 데이터 삭제 (깨끗한 시작을 위해)
IO.puts("기존 게임 데이터 삭제 중...")
Repo.delete_all(GameParticipants)
Repo.delete_all(TopPlayer)
Repo.delete_all(RewardTier)
Repo.delete_all(BettingOption)
Repo.delete_all(GameRule)
Repo.delete_all(Game)

# 공통 게임 규칙
common_rules = [
  "참가자는 제한 시간 안에 주어진 미션을 완료해야 합니다.",
  "승자는 시간 내에 가장 높은 점수를 획득한 사람이 선정됩니다.",
  "동점인 경우 먼저 완료한 사람이 우승자로 선정됩니다.",
  "특별 보너스 라운드에서 추가 보상을 얻을 수 있습니다.",
  "불공정 행위가 적발될 경우 즉시 실격 처리됩니다."
]

# 공통 베팅 옵션
common_betting_options = [
  %{name: "소액 투자", description: "낮은 위험, 안정적인 수익", amount: 10_000, selected: false},
  %{name: "중액 투자", description: "적절한 위험과 수익의 균형", amount: 50_000, selected: true},
  %{name: "고액 투자", description: "높은 위험, 높은 수익 가능성", amount: 100_000, selected: false},
  %{name: "직접 입력", description: "원하는 금액에 직접 설정", amount: nil, selected: false}
]

# 공통 보상 등급
common_reward_tiers = [
  %{rank: "1위", condition: "최고 근접 정답", reward: 50_000},
  %{rank: "2위~10위", condition: "상위 2~10위 정답", reward: 20_000},
  %{rank: "11위~50위", condition: "상위 11~50위 정답", reward: 10_000},
  %{rank: "51위~100위", condition: "상위 51~100위 정답", reward: 5_000}
]

# =====================
# 게임 데이터 정의
# =====================

game1_data = %{
  category: "인기 게임",
  name: "도파만챌린지",
  description: "최고의 인기를 자랑하는 도파민 챌린지에 참여하세요. 다양한 미션을 완료하고 수익률을 높여 더 많은 보상을받아가세요.",
  players: 12_450,
  xrp: 1_250_000,
  win_rate: 42.6,
  plays: 230,
  end_time: DateTime.add(DateTime.utc_now(), 3, :day),
  image: "🎮"
}

game1_rules = [
  "도파만 챌린지는 매일 새로운 미션이 주어집니다.",
  "지식 테스트, 논리 퍼즐, 확률 게임 등 다양한 유형의 미션이 제공됩니다.",
  "각 미션마다 다른 난이도와 보상이 설정되어 있습니다.",
  "참가자는 자신의 선호도에 따라 미션을 선택할 수 있습니다.",
  "주간 리더보드에서 상위권을 유지하면 추가 보너스가 제공됩니다."
]

game1_top_players = [
  %{rank: 1, username: "포리딘", win_rate: 82.4, games_played: 94, icon: "P"},
  %{rank: 2, username: "메가스타", win_rate: 78.9, games_played: 88, icon: "L"},
  %{rank: 3, username: "게임마스터", win_rate: 75.2, games_played: 76, icon: "M"},
  %{rank: 4, username: "탑플레이어", win_rate: 68.7, games_played: 65, icon: "T"},
  %{rank: 5, username: "도맹사", win_rate: 64.3, games_played: 61, icon: "D"}
]

game2_data = %{
  category: "카드 게임",
  name: "퀸카 포커",
  description: "실력과 운이 따르는 포커 게임! 남들과 늦게 승리하면 더 높은 수익률을 얻을 수 있어요.",
  players: 5_240,
  xrp: 580_000,
  win_rate: 33.1,
  plays: 180,
  end_time: DateTime.add(DateTime.utc_now(), 5, :day),
  image: "♠️"
}

game2_rules = [
  "텍사스 홀덤 포커 규칙을 기반으로 합니다.",
  "각 라운드마다 플레이어는 베팅, 콜, 레이즈, 폴드 중 하나를 선택합니다.",
  "퀸카 카드(퀸)이 나오면 특별한 보너스 포인트가 적립됩니다.",
  "최종 승자는 가장 강한 패를 가진 플레이어입니다.",
  "게임은 총 5라운드로 진행되며, 각 라운드마다 새로운 카드가 공개됩니다."
]

game2_top_players = [
  %{rank: 1, username: "카드왕", win_rate: 76.8, games_played: 105, icon: "K"},
  %{rank: 2, username: "포커페이스", win_rate: 72.3, games_played: 98, icon: "F"},
  %{rank: 3, username: "블러퍼", win_rate: 68.5, games_played: 82, icon: "B"},
  %{rank: 4, username: "딜러킹", win_rate: 64.1, games_played: 76, icon: "D"},
  %{rank: 5, username: "올인마스터", win_rate: 61.7, games_played: 70, icon: "A"}
]

game3_data = %{
  category: "전략 게임",
  name: "타겟 마스터",
  description: "철저한 타이밍과 지적으로 목표를 달성하세요. 최고의 정확도가 최고의 수익률 보장합니다.",
  players: 3_180,
  xrp: 420_000,
  win_rate: 29.5,
  plays: 150,
  end_time: DateTime.add(DateTime.utc_now(), 7, :day),
  image: "🎯"
}

game3_rules = [
  "움직이는 타겟을 정확히 맞추는 게임입니다.",
  "타겟의 크기와 속도는 라운드마다 변경됩니다.",
  "연속으로 타겟을 맞추면 콤보 보너스가 적용됩니다.",
  "각 플레이어는 라운드당 10번의 기회를 가집니다.",
  "최종 점수는 정확도, 속도, 난이도를 종합하여 계산됩니다."
]

game3_top_players = [
  %{rank: 1, username: "스나이퍼", win_rate: 84.2, games_played: 67, icon: "S"},
  %{rank: 2, username: "정확왕", win_rate: 79.1, games_played: 63, icon: "A"},
  %{rank: 3, username: "에임봇", win_rate: 76.5, games_played: 58, icon: "E"},
  %{rank: 4, username: "타겟헌터", win_rate: 71.9, games_played: 52, icon: "T"},
  %{rank: 5, username: "샷마스터", win_rate: 68.3, games_played: 48, icon: "M"}
]

# 나머지 게임들 데이터...
game4_data = %{
  category: "경매",
  name: "월간 챌린지샵",
  description: "이번 월 최고의 글챌리어를 가려라 대화, 다양한 경쟁에서 상위를 등혀해보세요.",
  players: 8_760,
  xrp: 1_500_000,
  win_rate: 38.2,
  plays: 210,
  end_time: DateTime.add(DateTime.utc_now(), 12, :day),
  image: "🏆"
}

game5_data = %{
  category: "주사위",
  name: "행운의 룰렛",
  description: "운과 전략을 결합한 룰렛 게임. 참여자에 따라 배당률이 크게 가변적이죠.",
  players: 7_130,
  xrp: 890_000,
  win_rate: 36.7,
  plays: 195,
  end_time: DateTime.add(DateTime.utc_now(), 6, :day),
  image: "🎪"
}

game6_data = %{
  category: "스포츠",
  name: "실리 게임",
  description: "다른 플레이어와 실리를 겨루 매력적이죠. 높은 독점적이 진로 오리도록 자랑합니다.",
  players: 4_570,
  xrp: 620_000,
  win_rate: 31.5,
  plays: 165,
  end_time: DateTime.add(DateTime.utc_now(), 5, :day),
  image: "🎮"
}

game7_data = %{
  category: "퍼즐",
  name: "퍼즐 마스터",
  description: "논리와 사고의 문제 해결 과정을 테스트하는 퍼즐 게임. 체스 도전하기 쉽진 않지만!",
  players: 2_980,
  xrp: 350_000,
  win_rate: 27.3,
  plays: 140,
  end_time: DateTime.add(DateTime.utc_now(), 9, :day),
  image: "🧩"
}

IO.puts("게임 데이터 생성 중...")

# =====================
# 게임 1 생성
# =====================
{:ok, game1} = %Game{} |> Game.changeset(game1_data) |> Repo.insert()

# 게임 1 규칙 추가
Enum.each(game1_rules, fn rule_text ->
  %GameRule{} |> GameRule.changeset(%{rule: rule_text, game_id: game1.id}) |> Repo.insert!()
end)

# 게임 1 베팅 옵션 추가
Enum.each(common_betting_options, fn option_data ->
  %BettingOption{}
  |> BettingOption.changeset(Map.put(option_data, :game_id, game1.id))
  |> Repo.insert!()
end)

# 게임 1 보상 등급 추가
Enum.each(common_reward_tiers, fn tier_data ->
  %RewardTier{} |> RewardTier.changeset(Map.put(tier_data, :game_id, game1.id)) |> Repo.insert!()
end)

# 게임 1 상위 플레이어 추가
Enum.each(game1_top_players, fn player_data ->
  %TopPlayer{} |> TopPlayer.changeset(Map.put(player_data, :game_id, game1.id)) |> Repo.insert!()
end)

# =====================
# 게임 2 생성
# =====================
{:ok, game2} = %Game{} |> Game.changeset(game2_data) |> Repo.insert()

# 게임 2 규칙 추가
Enum.each(game2_rules, fn rule_text ->
  %GameRule{} |> GameRule.changeset(%{rule: rule_text, game_id: game2.id}) |> Repo.insert!()
end)

# 게임 2 베팅 옵션 추가
Enum.each(common_betting_options, fn option_data ->
  %BettingOption{}
  |> BettingOption.changeset(Map.put(option_data, :game_id, game2.id))
  |> Repo.insert!()
end)

# 게임 2 보상 등급 추가
Enum.each(common_reward_tiers, fn tier_data ->
  %RewardTier{} |> RewardTier.changeset(Map.put(tier_data, :game_id, game2.id)) |> Repo.insert!()
end)

# 게임 2 상위 플레이어 추가
Enum.each(game2_top_players, fn player_data ->
  %TopPlayer{} |> TopPlayer.changeset(Map.put(player_data, :game_id, game2.id)) |> Repo.insert!()
end)

# =====================
# 게임 3 생성
# =====================
{:ok, game3} = %Game{} |> Game.changeset(game3_data) |> Repo.insert()

# 게임 3 규칙 추가
Enum.each(game3_rules, fn rule_text ->
  %GameRule{} |> GameRule.changeset(%{rule: rule_text, game_id: game3.id}) |> Repo.insert!()
end)

# 게임 3 베팅 옵션 추가
Enum.each(common_betting_options, fn option_data ->
  %BettingOption{}
  |> BettingOption.changeset(Map.put(option_data, :game_id, game3.id))
  |> Repo.insert!()
end)

# 게임 3 보상 등급 추가
Enum.each(common_reward_tiers, fn tier_data ->
  %RewardTier{} |> RewardTier.changeset(Map.put(tier_data, :game_id, game3.id)) |> Repo.insert!()
end)

# 게임 3 상위 플레이어 추가
Enum.each(game3_top_players, fn player_data ->
  %TopPlayer{} |> TopPlayer.changeset(Map.put(player_data, :game_id, game3.id)) |> Repo.insert!()
end)

# =====================
# 나머지 게임들 생성 (간소화)
# =====================
# 게임 4
{:ok, game4} = %Game{} |> Game.changeset(game4_data) |> Repo.insert()

Enum.each(common_rules, fn rule_text ->
  %GameRule{} |> GameRule.changeset(%{rule: rule_text, game_id: game4.id}) |> Repo.insert!()
end)

Enum.each(common_betting_options, fn option_data ->
  %BettingOption{}
  |> BettingOption.changeset(Map.put(option_data, :game_id, game4.id))
  |> Repo.insert!()
end)

Enum.each(common_reward_tiers, fn tier_data ->
  %RewardTier{} |> RewardTier.changeset(Map.put(tier_data, :game_id, game4.id)) |> Repo.insert!()
end)

# 게임 5
{:ok, game5} = %Game{} |> Game.changeset(game5_data) |> Repo.insert()

Enum.each(common_rules, fn rule_text ->
  %GameRule{} |> GameRule.changeset(%{rule: rule_text, game_id: game5.id}) |> Repo.insert!()
end)

Enum.each(common_betting_options, fn option_data ->
  %BettingOption{}
  |> BettingOption.changeset(Map.put(option_data, :game_id, game5.id))
  |> Repo.insert!()
end)

Enum.each(common_reward_tiers, fn tier_data ->
  %RewardTier{} |> RewardTier.changeset(Map.put(tier_data, :game_id, game5.id)) |> Repo.insert!()
end)

# 게임 6
{:ok, game6} = %Game{} |> Game.changeset(game6_data) |> Repo.insert()

Enum.each(common_rules, fn rule_text ->
  %GameRule{} |> GameRule.changeset(%{rule: rule_text, game_id: game6.id}) |> Repo.insert!()
end)

Enum.each(common_betting_options, fn option_data ->
  %BettingOption{}
  |> BettingOption.changeset(Map.put(option_data, :game_id, game6.id))
  |> Repo.insert!()
end)

Enum.each(common_reward_tiers, fn tier_data ->
  %RewardTier{} |> RewardTier.changeset(Map.put(tier_data, :game_id, game6.id)) |> Repo.insert!()
end)

# 게임 7
{:ok, game7} = %Game{} |> Game.changeset(game7_data) |> Repo.insert()

Enum.each(common_rules, fn rule_text ->
  %GameRule{} |> GameRule.changeset(%{rule: rule_text, game_id: game7.id}) |> Repo.insert!()
end)

Enum.each(common_betting_options, fn option_data ->
  %BettingOption{}
  |> BettingOption.changeset(Map.put(option_data, :game_id, game7.id))
  |> Repo.insert!()
end)

Enum.each(common_reward_tiers, fn tier_data ->
  %RewardTier{} |> RewardTier.changeset(Map.put(tier_data, :game_id, game7.id)) |> Repo.insert!()
end)

# 게임 참가자 추가 함수
add_participants = fn game_id ->
  now = DateTime.utc_now()

  Enum.each(1..5, fn user_id ->
    # 참가자 데이터 생성
    bet_amount = Enum.random([10_000, 50_000, 100_000])
    status = Enum.random(["active", "completed"])

    participant_data = %{
      game_id: game_id,
      user_id: user_id + 100,
      bet_amount: bet_amount,
      status: status,
      joined_at: DateTime.add(now, -1 * Enum.random(1..48), :hour)
    }

    # 완료된 참가에 대한 결과 추가
    participant_data =
      if status == "completed" do
        result = Enum.random(["win", "lose"])
        reward_amount = if result == "win", do: bet_amount * Enum.random([2, 3, 4]), else: 0

        Map.merge(participant_data, %{
          result: result,
          reward_amount: reward_amount
        })
      else
        participant_data
      end

    # 참가자 생성
    %GameParticipants{}
    |> GameParticipants.changeset(participant_data)
    |> Repo.insert!()
  end)
end

IO.puts("게임 참가자 데이터 생성 중...")

# 각 게임에 참가자 추가
add_participants.(game1.id)
add_participants.(game2.id)
add_participants.(game3.id)
add_participants.(game4.id)
add_participants.(game5.id)
add_participants.(game6.id)
add_participants.(game7.id)

IO.puts("✅ 게임 데이터 시드가 성공적으로 완료되었습니다!")
