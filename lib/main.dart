import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'habit.dart';

// Enum for sort options
enum SortOption { nameAsc, nameDesc, completed, notCompleted }

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Theme mode state
  ThemeMode _themeMode = ThemeMode.system;
  static const String _themeModeKey = 'theme_mode';

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  // Load theme mode preference
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt(_themeModeKey) ?? 0;
    setState(() {
      _themeMode = ThemeMode.values[themeModeIndex];
    });
  }

  // Save theme mode preference
  Future<void> _saveThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, _themeMode.index);
  }

  // Change theme mode
  void changeThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
      _saveThemeMode();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        cardColor: Colors.grey[850],
      ),
      themeMode: _themeMode,
      home: MyHomePage(
        changeThemeMode: changeThemeMode,
        currentThemeMode: _themeMode,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final Function(ThemeMode) changeThemeMode;
  final ThemeMode currentThemeMode;

  const MyHomePage({
    super.key,
    required this.changeThemeMode,
    required this.currentThemeMode,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Habit> _habits = [];

  // Current sort option
  SortOption _currentSortOption = SortOption.nameAsc;

  // Keys for storing data in SharedPreferences
  static const String _habitsKey = 'habits';
  static const String _firstLaunchKey = 'first_launch';
  static const String _sortOptionKey = 'sort_option';

  @override
  void initState() {
    super.initState();
    // Load habits when the app starts
    _loadHabits();
  }

  // Load habits from SharedPreferences
  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final habitStrings = prefs.getStringList(_habitsKey);
    final isFirstLaunch = prefs.getBool(_firstLaunchKey) ?? true;

    // Load sort option preference
    final sortOptionIndex = prefs.getInt(_sortOptionKey) ?? 0;
    _currentSortOption = SortOption.values[sortOptionIndex];

    if (habitStrings != null && habitStrings.isNotEmpty) {
      // We have saved habits, load them
      setState(() {
        _habits = habitStrings
            .map((habitString) => Habit.fromStorageString(habitString))
            .toList();

        // Apply the saved sort option
        _sortHabits();
      });
    } else if (isFirstLaunch) {
      // First time launching the app, set default habits
      setState(() {
        _habits = [
          Habit(name: 'Drink 8 glasses of water'),
          Habit(name: 'Read for 30 minutes', isCompleted: true),
        ];
      });

      // Save the default habits
      _saveHabits();

      // Mark that the app has been launched before
      await prefs.setBool(_firstLaunchKey, false);
    }
    // If it's not the first launch and there are no saved habits,
    // we'll just keep _habits as an empty list
  }

  // Save habits to SharedPreferences
  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final habitStrings = _habits
        .map((habit) => habit.toStorageString())
        .toList();

    await prefs.setStringList(_habitsKey, habitStrings);

    // Save sort option preference
    await prefs.setInt(_sortOptionKey, _currentSortOption.index);
  }

  // Sort habits based on current sort option
  void _sortHabits() {
    setState(() {
      switch (_currentSortOption) {
        case SortOption.nameAsc:
          _habits.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
          break;
        case SortOption.nameDesc:
          _habits.sort(
            (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
          );
          break;
        case SortOption.completed:
          _habits.sort(
            (a, b) =>
                a.isCompleted == b.isCompleted ? 0 : (a.isCompleted ? -1 : 1),
          );
          break;
        case SortOption.notCompleted:
          _habits.sort(
            (a, b) =>
                a.isCompleted == b.isCompleted ? 0 : (a.isCompleted ? 1 : -1),
          );
          break;
      }
    });
  }

  // Change sort option
  void _changeSortOption(SortOption option) {
    setState(() {
      _currentSortOption = option;
      _sortHabits();
      _saveHabits();
    });
  }

  // Function to add a new habit
  void _addHabit() {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add a new habit'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(hintText: 'Enter habit name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Only add if the text is not empty
                if (textController.text.isNotEmpty) {
                  setState(() {
                    _habits.add(Habit(name: textController.text));
                    _saveHabits(); // Save after adding a habit
                  });
                }
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Function to edit an existing habit
  void _editHabit(int index) {
    final textController = TextEditingController(text: _habits[index].name);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Habit'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(hintText: 'Enter new habit name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Only update if the text is not empty
                if (textController.text.isNotEmpty) {
                  setState(() {
                    _habits[index].name = textController.text;
                    _saveHabits(); // Save after editing a habit
                  });
                }
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Function to clear all completed habits
  void _clearCompletedHabits() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Completed'),
          content: const Text(
            'Are you sure you want to clear all completed habits?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _habits.removeWhere((habit) => habit.isCompleted);
                  _saveHabits();
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Completed habits cleared')),
                );
              },
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Helper method to build a stat item
  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Habits'),
        actions: [
          // Sort dropdown
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort habits',
            onSelected: _changeSortOption,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortOption.nameAsc,
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward, size: 16),
                    SizedBox(width: 8),
                    Text('Name (A-Z)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: SortOption.nameDesc,
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, size: 16),
                    SizedBox(width: 8),
                    Text('Name (Z-A)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: SortOption.completed,
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16),
                    SizedBox(width: 8),
                    Text('Completed first'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: SortOption.notCompleted,
                child: Row(
                  children: [
                    Icon(Icons.radio_button_unchecked, size: 16),
                    SizedBox(width: 8),
                    Text('Incomplete first'),
                  ],
                ),
              ),
            ],
          ),
          // Only show the clear button if there are completed habits
          if (_habits.any((habit) => habit.isCompleted))
            IconButton(
              icon: const Icon(Icons.cleaning_services_outlined),
              tooltip: 'Clear completed',
              onPressed: _clearCompletedHabits,
            ),
          // Theme switcher
          IconButton(
            icon: Icon(
              widget.currentThemeMode == ThemeMode.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            tooltip: widget.currentThemeMode == ThemeMode.light
                ? 'Switch to dark mode'
                : 'Switch to light mode',
            onPressed: () {
              widget.changeThemeMode(
                widget.currentThemeMode == ThemeMode.light
                    ? ThemeMode.dark
                    : ThemeMode.light,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Card
          Card(
            margin: const EdgeInsets.all(16.0),
            elevation: 4.0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Habit Statistics',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Total',
                        _habits.length.toString(),
                        Icons.list,
                        Colors.blue,
                      ),
                      _buildStatItem(
                        'Completed',
                        _habits.where((h) => h.isCompleted).length.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                      _buildStatItem(
                        'Completion Rate',
                        _habits.isEmpty
                            ? '0%'
                            : '${(_habits.where((h) => h.isCompleted).length * 100 / _habits.length).toStringAsFixed(0)}%',
                        Icons.pie_chart,
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  const Divider(),
                  const SizedBox(height: 8.0),
                  const Text(
                    'Streaks',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Current Best',
                        _habits.isEmpty
                            ? '0'
                            : (_habits
                                      .map((h) => h.currentStreak ?? 0)
                                      .fold<int>(
                                        0,
                                        (max, streak) =>
                                            streak > max ? streak : max,
                                      ))
                                  .toString(),
                        Icons.local_fire_department,
                        Colors.deepOrange,
                      ),
                      _buildStatItem(
                        'All-Time Best',
                        _habits.isEmpty
                            ? '0'
                            : (_habits
                                      .map((h) => h.longestStreak)
                                      .where((streak) => streak != null)
                                      .map((streak) => streak)
                                      .fold<int>(
                                        0,
                                        (max, streak) =>
                                            streak > max ? streak : max,
                                      ))
                                  .toString(),
                        Icons.emoji_events,
                        Colors.amber,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Habits List
          Expanded(
            child: ReorderableListView.builder(
              itemCount: _habits.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    // Adjusting the index when moving down the list
                    newIndex -= 1;
                  }
                  final habit = _habits.removeAt(oldIndex);
                  _habits.insert(newIndex, habit);
                  _saveHabits(); // Save the new order
                });
              },
              itemBuilder: (context, index) {
                return Dismissible(
                  key: Key(_habits[index].name + index.toString()),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    // Remove the habit from the list
                    setState(() {
                      _habits.removeAt(index);
                      _saveHabits(); // Save after deletion
                    });

                    // Show a snackbar to confirm deletion
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Habit deleted'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {
                            // Undo the deletion
                            setState(() {
                              _habits.insert(
                                index,
                                Habit(name: 'Restored habit'),
                              );
                              _saveHabits();
                            });
                          },
                        ),
                      ),
                    );
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    title: Text(_habits[index].name),
                    subtitle: (_habits[index].currentStreak ?? 0) > 0
                        ? Row(
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                color: Colors.deepOrange,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Streak: ${_habits[index].currentStreak} day${_habits[index].currentStreak != 1 ? 's' : ''}',
                                style: TextStyle(
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if ((_habits[index].longestStreak ?? 0) >
                                  (_habits[index].currentStreak ?? 0)) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '(Best: ${_habits[index].longestStreak})',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _editHabit(index),
                        ),
                        Checkbox(
                          value: _habits[index].isCompleted,
                          onChanged: (bool? newValue) {
                            setState(() {
                              if (newValue == true) {
                                _habits[index].completeForToday();
                              } else {
                                _habits[index].uncomplete();
                              }
                              _saveHabits(); // Save after toggling a habit
                            });
                          },
                        ),
                      ],
                    ),
                    leading: const Icon(Icons.drag_handle),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHabit,
        tooltip: 'Add Habit',
        child: const Icon(Icons.add),
      ),
    );
  }
}
