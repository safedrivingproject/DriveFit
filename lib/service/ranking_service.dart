import 'rank_list.dart';
import 'shared_preferences_service.dart';

class RankingService {
  static final RankingService _instance = RankingService._internal();

  factory RankingService() => _instance;

  int driveScore = 0;
  int totalScore = 0;
  int scoreStreak = 0;

  int previousRankIndex = 0;
  int currentRankIndex = 0;
  String currentRankName = "Toyota";

  RankingService._internal() {
    driveScore = 0;
    totalScore = 0;
    scoreStreak = 0;
    previousRankIndex = 0;
    currentRankIndex = 0;
    currentRankName = "Toyota";
  }

  void updateDriveScore(int score) {
    driveScore += score;
    SharedPreferencesService.setInt('driveScore', driveScore);
  }

  void removeSessionScore(int score, int sessionListIndex) {
    driveScore -= score;
    SharedPreferencesService.setInt('driveScore', driveScore);
    if (score == 5) {
      if (sessionListIndex < scoreStreak) {
        scoreStreak -= 1;
      }
    }
    if (scoreStreak < 0) scoreStreak = 0;
    SharedPreferencesService.setInt('scoreStreak', scoreStreak);
  }

  void updateScoreStreak(int score) {
    if (score != 5) {
      scoreStreak = 0;
    } else if (score == 5) {
      scoreStreak++;
    }
    SharedPreferencesService.setInt('scoreStreak', scoreStreak);
  }

  void updateTotalScore() {
    totalScore = driveScore + scoreStreak;
  }

  void getScores() {
    driveScore = SharedPreferencesService.getInt('driveScore', 0);
    scoreStreak = SharedPreferencesService.getInt('scoreStreak', 0);
    totalScore = driveScore + scoreStreak;
  }

  void getRank() {
    previousRankIndex = currentRankIndex;
    currentRankIndex = rankList
        .lastIndexWhere((element) => totalScore >= element["requiredScore"]);
    currentRankName = rankList[currentRankIndex]["name"];
  }
}
