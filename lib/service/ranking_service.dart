import 'rank_list.dart';
import 'shared_preferences_service.dart';

class RankingService {
  static final RankingService _instance = RankingService._internal();

  factory RankingService() => _instance;

  int driveScore = 0;
  int scoreStreak = 0;

  int previousRankIndex = 0;
  int currentRankIndex = 0;
  String currentRankName = "Toyota";

  RankingService._internal() {
    driveScore = 0;
    scoreStreak = 0;
    previousRankIndex = 0;
    currentRankIndex = 0;
    currentRankName = "Toyota";
  }

  void updateDriveScore(int score) {
    driveScore += score;
    SharedPreferencesService.setInt('driveScore', driveScore);
  }

  void removeSessionScore(int score, int sessionListIndex, int duration) {
    driveScore -= score;
    SharedPreferencesService.setInt('driveScore', driveScore);
    if (score == duration) {
      if (sessionListIndex < scoreStreak) {
        scoreStreak -= 1;
      }
    }
    if (scoreStreak < 0) scoreStreak = 0;
    SharedPreferencesService.setInt('scoreStreak', scoreStreak);
  }

  void updateScoreStreak(int score, int duration) {
    var minutes = (duration / 60).ceil();
    if (score != minutes) {
      scoreStreak = 0;
    } else if (score == minutes) {
      scoreStreak++;
    }
    SharedPreferencesService.setInt('scoreStreak', scoreStreak);
  }

  void getScores() {
    driveScore = SharedPreferencesService.getInt('driveScore', 0);
    scoreStreak = SharedPreferencesService.getInt('scoreStreak', 0);
  }

  void getRank() {
    previousRankIndex = currentRankIndex;
    currentRankIndex = rankList
        .lastIndexWhere((element) => driveScore >= element["requiredScore"]);
    currentRankName = rankList[currentRankIndex]["name"];
  }
}
