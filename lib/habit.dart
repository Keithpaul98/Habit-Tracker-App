class Habit {
  String name;
  bool isCompleted;
  List<String> completionDates; // List of dates when habit was completed
  int currentStreak; // Current streak count
  int longestStreak; // Longest streak achieved

  Habit({
    required this.name,
    this.isCompleted = false,
    List<String>? completionDates,
    this.currentStreak = 0,
    this.longestStreak = 0,
  }) : completionDates = completionDates ?? [];

  // Mark habit as completed for today
  void completeForToday() {
    if (!isCompleted) {
      isCompleted = true;

      // Format today's date as yyyy-MM-dd
      final today = DateTime.now();
      final formattedDate =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      // Add today's date if not already completed today
      if (!completionDates.contains(formattedDate)) {
        completionDates.add(formattedDate);
        _calculateStreak();
      }
    }
  }

  // Mark habit as not completed for today
  void uncomplete() {
    if (isCompleted) {
      isCompleted = false;

      // Format today's date as yyyy-MM-dd
      final today = DateTime.now();
      final formattedDate =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      // Remove today's date if it exists
      completionDates.remove(formattedDate);
      _calculateStreak();
    }
  }

  // Calculate current streak based on completion dates
  void _calculateStreak() {
    if (completionDates.isEmpty) {
      currentStreak = 0;
      return;
    }

    // Sort dates in ascending order
    completionDates.sort();

    // Get today and yesterday's dates
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    final formattedToday =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final formattedYesterday =
        "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

    // Check if today or yesterday is in the completion dates
    final hasTodayOrYesterday =
        completionDates.contains(formattedToday) ||
        completionDates.contains(formattedYesterday);

    if (!hasTodayOrYesterday) {
      currentStreak = 0;
      return;
    }

    // Calculate current streak
    currentStreak = 1; // Start with 1 for today/yesterday
    DateTime previousDate = completionDates.contains(formattedToday)
        ? today
        : yesterday;

    // Go backwards through dates to find consecutive days
    for (int i = completionDates.length - 1; i >= 0; i--) {
      final dateStr = completionDates[i];
      final dateParts = dateStr.split('-');
      final date = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
      );

      // Skip if it's today or in the future
      if (date.isAfter(today) ||
          (date.year == today.year &&
              date.month == today.month &&
              date.day == today.day)) {
        continue;
      }

      // Check if this date is consecutive with previous date
      final difference = previousDate.difference(date).inDays;
      if (difference == 1) {
        currentStreak++;
        previousDate = date;
      } else if (difference > 1) {
        // Break the streak if days are skipped
        break;
      }
    }

    // Update longest streak if current streak is longer
    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }
  }

  // Convert to string format for storage
  String toStorageString() {
    return '$name|$isCompleted|${completionDates.join(",")}|$currentStreak|$longestStreak';
  }

  // Create habit from storage string
  static Habit fromStorageString(String storageString) {
    final parts = storageString.split('|');
    final name = parts[0];
    final isCompleted = parts[1] == 'true';

    List<String> completionDates = [];
    if (parts.length > 2 && parts[2].isNotEmpty) {
      completionDates = parts[2].split(',');
    }

    int currentStreak = 0;
    if (parts.length > 3) {
      currentStreak = int.tryParse(parts[3]) ?? 0;
    }

    int longestStreak = 0;
    if (parts.length > 4) {
      longestStreak = int.tryParse(parts[4]) ?? 0;
    }

    return Habit(
      name: name,
      isCompleted: isCompleted,
      completionDates: completionDates,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
    );
  }
}
