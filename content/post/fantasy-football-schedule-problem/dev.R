
league_size = 4
rounds <- league_size - 1
mat <- matrix(nrow = league_size, ncol = rounds)
mat

team_i <- 1
round_i <- 1
idx_team <- 1:league_size
set.seed(1)

team1_round1 <- sample(2:league_size, 1, replace = FALSE)
mat[team_i, round_i] <- team1_round1
mat

team_i <- 2
teams_possible <- setdiff(idx_team, team_i)
teams_already_indexed <- 1:(team_i - 1)
teams_already_matched <- mat[teams_already_indexed, round_i]

while(team_i <= league_size) {
  if(team_i %in% teams_already_matched) {
    team_i_round_i <- which(team_i == teams_already_matched)
    mat[team_i, round_i] <- team_i_round_i
    # print(sprintf('team %d, round %d', team_i, round_i))
    # print(mat)
    team_i <- team_i + 1
  } else {
    teams_cant_match <- unique(c(teams_already_indexed, teams_already_matched))
    teams_unmatched <- setdiff(teams_possible, teams_cant_match)
    n_matched <- length(teams_unmatched)
    if(n_matched == 0) {
      mat[2:league_size, round_i] <- NA
      team_i <- 2
    } else {
      team_i_round_i <- if(n_matched == 1) {
        teams_unmatched
      } else {
        sample(teams_unmatched, 1)
      }

      mat[team_i, round_i] <- team_i_round_i
      # print(sprintf('team %d, round %d', team_i, round_i))
      # print(mat)
      team_i <- team_i + 1
    }
  }
}
mat

teams_possible <- setdiff(idx_team, c(1, team1_round1))
team1_all_rounds <- sample(teams_possible, size = length(teams_possible))
mat[1, 2:rounds] <- team1_all_rounds
mat

round_i <- 2
idx_team <- 1:league_size
rounds <- league_size - 1

while(round_i < rounds) {
  team_i <- 2
  while(team_i <= league_size) {
    teams_possible <- setdiff(idx_team, team_i)
    teams_already_indexed <- 1:(team_i - 1)
    teams_already_matched <- mat[teams_already_indexed, round_i]
    teams_already_played <- mat[team_i, 1:(round_i - 1)]
    reset <- FALSE
    if(team_i %in% teams_already_matched) {
      teami_roundi <- which(team_i == teams_already_matched)
      if(any(teami_roundi == teams_already_played)) {
        reset <- TRUE
      }
    } else {
      teams_cant_match <-
        unique(c(teams_already_indexed, teams_already_matched, teams_already_played))
      teams_unmatched <- setdiff(teams_possible, teams_cant_match)
      n_matched <- length(teams_unmatched)
      if (n_matched == 0) {
        reset <- TRUE
      } else {
        teami_roundi <- if(n_matched == 1) {
          teams_unmatched
        } else {
          sample(teams_unmatched, 1)
        }
      }
    }
    
    if(reset) {
      mat[2:league_size, round_i] <- NA
      team_i <- 2
      retry_i <- retry_i + 1
    } else {
      mat[team_i, round_i] <- teami_roundi
      team_i <- team_i + 1
    }
  }
  round_i <- round_i + 1
}
mat

# Last round is deterministic. Also, don't need to do the first row
idx_not1 <- 2:league_size
total <- Reduce(sum, idx_team) - idx_not1
rs <- rowSums(mat[idx_not1, 1:(rounds - 1)])
teams_last <- total - rs
mat[idx_not1, rounds] <- teams_last
mat























# ----
while(round_i < rounds) {
  team_i <- 2
  while(retry_i <= retries & team_i <= league_size) {
    teams_possible <- setdiff(idx_team, team_i)
    teams_already_indexed <- 1:(team_i - 1)
    teams_already_matched <- mat[teams_already_indexed, round_i]
    teams_already_played <- mat[team_i, 1:(round_i - 1)]
    reset <- FALSE
    if(team_i %in% teams_already_matched) {
      team_i_round_i <- which(team_i == teams_already_matched)
      if(any(team_i_round_i == teams_already_played)) {
        reset <- TRUE
      }
    } else {
      teams_cant_match <-
        unique(c(teams_already_indexed, teams_already_matched, teams_already_played))
      teams_unmatched <- setdiff(teams_possible, teams_cant_match)
      n_matched <- length(teams_unmatched)
      if (n_matched == 0) {
        reset <- TRUE
      } else {
        # Note that `sample()` will assume 1:n if n is of length 1, which we don't want.
        team_i_round_i <- if(n_matched == 1) {
          teams_unmatched
        } else {
          sample(teams_unmatched, 1)
        }
      }
    }
    
    if(reset) {
      mat[2:league_size, round_i] <- NA
      team_i <- 2
      retry_i <- retry_i + 1
    } else {
      mat[team_i, round_i] <- team_i_round_i
      team_i <- team_i + 1
    }
  }
  round_i <- round_i + 1
}

# Last round is deterministic. Also, don't need to do the first row
idx_not1 <- 2:league_size
total <- Reduce(sum, idx_team) - idx_not1
rs <- rowSums(mat[idx_not1, 1:(rounds - 1)])
teams_last <- total - rs
mat[idx_not1, rounds] <- teams_last
mat
}
