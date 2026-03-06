import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/lang.dart';

class Activity {
  String title;
  bool isCompleted;
  List<Activity> subActivities;

  Activity({
    required this.title,
    this.isCompleted = false,
    List<Activity>? subActivities,
  }) : subActivities = subActivities ?? [];

  Map<String, dynamic> toJson() => {
    'title': title,
    'isCompleted': isCompleted,
    'subActivities': subActivities.map((s) => s.toJson()).toList(),
  };

  factory Activity.fromJson(Map<String, dynamic> json) {
    var subs =
        (json['subActivities'] as List?)
            ?.map((s) => Activity.fromJson(s))
            .toList() ??
        [];
    return Activity(
      title: json['title'],
      isCompleted: json['isCompleted'],
      subActivities: subs,
    );
  }

  double get completionPercentage {
    if (subActivities.isEmpty) return isCompleted ? 1.0 : 0.0;
    int completed = subActivities.where((s) => s.isCompleted).length;
    return completed / subActivities.length;
  }
}

class ActivityList extends StatefulWidget {
  final VoidCallback onLanguageChanged;
  const ActivityList({super.key, required this.onLanguageChanged});

  @override
  State<ActivityList> createState() => _ActivityListState();
}

class _ActivityListState extends State<ActivityList> {
  List<Activity> _activities = [];
  final TextEditingController _controller = TextEditingController();
  final Set<int> _expandedIndices = {};
  static const String _prefsKey = 'pomo_activities';

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final String? activitiesJson = prefs.getString(_prefsKey);
    if (activitiesJson != null) {
      final List<dynamic> decoded = jsonDecode(activitiesJson);
      setState(() {
        _activities = decoded.map((item) => Activity.fromJson(item)).toList();
      });
    }
  }

  Future<void> _saveActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      _activities.map((a) => a.toJson()).toList(),
    );
    await prefs.setString(_prefsKey, encoded);
  }

  void _addActivity() {
    final title = _controller.text.trim();
    if (title.isNotEmpty) {
      setState(() {
        _activities.insert(0, Activity(title: title));
        _controller.clear();
      });
      _saveActivities();
    }
  }

  void _addSubActivity(int parentIndex, String title) {
    if (title.trim().isNotEmpty) {
      setState(() {
        _activities[parentIndex].subActivities.add(
          Activity(title: title.trim()),
        );
        _activities[parentIndex].isCompleted = false; // Re-open if was closed
      });
      _saveActivities();
    }
  }

  void _toggleActivity(int index) {
    setState(() {
      _activities[index].isCompleted = !_activities[index].isCompleted;
      // If we mark main task as done, mark all subs as done (optional but helpful)
      if (_activities[index].isCompleted) {
        for (var sub in _activities[index].subActivities) {
          sub.isCompleted = true;
        }
      }
    });
    _saveActivities();
  }

  void _toggleSubActivity(int parentIndex, int subIndex) {
    setState(() {
      _activities[parentIndex].subActivities[subIndex].isCompleted =
          !_activities[parentIndex].subActivities[subIndex].isCompleted;

      // Auto-complete parent if all subs are done
      bool allDone = _activities[parentIndex].subActivities.every(
        (s) => s.isCompleted,
      );
      if (allDone && _activities[parentIndex].subActivities.isNotEmpty) {
        _activities[parentIndex].isCompleted = true;
      } else if (!allDone) {
        _activities[parentIndex].isCompleted = false;
      }
    });
    _saveActivities();
  }

  void _removeActivity(int index) {
    setState(() {
      _activities.removeAt(index);
      _expandedIndices.remove(index);
    });
    _saveActivities();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // App Title / Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.tealAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'PomoSpace',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Input Field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _addActivity(),
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: AppLang.addActivityHint,
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.tealAccent),
                  onPressed: _addActivity,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // List Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${AppLang.tasksHeader} (${_activities.where((a) => !a.isCompleted).length} ${AppLang.pendingSuffix})',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // The List
        Expanded(
          child: _activities.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _activities.length,
                  itemBuilder: (context, index) {
                    final activity = _activities[index];
                    final isExpanded = _expandedIndices.contains(index);

                    return AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: activity.isCompleted
                                    ? Colors.greenAccent.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  dense: true,
                                  leading: Checkbox(
                                    value: activity.isCompleted,
                                    onChanged: (_) => _toggleActivity(index),
                                    activeColor: Colors.tealAccent,
                                    checkColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  title: Text(
                                    activity.title,
                                    style: TextStyle(
                                      decoration: activity.isCompleted
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                      color: activity.isCompleted
                                          ? Colors.white.withOpacity(0.3)
                                          : Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          isExpanded
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                          color: Colors.white70,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            if (isExpanded) {
                                              _expandedIndices.remove(index);
                                            } else {
                                              _expandedIndices.add(index);
                                            }
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                          size: 20,
                                        ),
                                        onPressed: () => _removeActivity(index),
                                      ),
                                    ],
                                  ),
                                ),
                                if (activity.subActivities.isNotEmpty ||
                                    isExpanded)
                                  _buildSubActivitiesList(
                                    index,
                                    activity,
                                    isExpanded,
                                  ),
                                if (activity.subActivities.isNotEmpty)
                                  _buildProgressBar(
                                    activity.completionPercentage,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Icon(
              Icons.assignment_turned_in_outlined,
              size: 48,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLang.noActivities,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLang.isSpanish
                ? '¡Añade una tarea arriba!'
                : 'Add a task above!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubActivitiesList(int index, Activity parent, bool isExpanded) {
    return Visibility(
      visible: isExpanded,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            ...parent.subActivities.asMap().entries.map((entry) {
              int subIdx = entry.key;
              Activity sub = entry.value;
              return Padding(
                padding: const EdgeInsets.only(left: 32.0, bottom: 4),
                child: Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: sub.isCompleted,
                        onChanged: (_) => _toggleSubActivity(index, subIdx),
                        activeColor: Colors.tealAccent.withOpacity(0.7),
                        checkColor: Colors.black,
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sub.title,
                        style: TextStyle(
                          fontSize: 13,
                          color: sub.isCompleted
                              ? Colors.white24
                              : Colors.white70,
                          decoration: sub.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            Padding(
              padding: const EdgeInsets.only(left: 32.0, bottom: 8, top: 4),
              child: TextField(
                style: const TextStyle(fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  hintText: AppLang.isSpanish
                      ? 'Añadir sub-tarea...'
                      : 'Add sub-task...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onSubmitted: (val) => _addSubActivity(index, val),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(double percentage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: LinearProgressIndicator(
        value: percentage,
        backgroundColor: Colors.transparent,
        valueColor: AlwaysStoppedAnimation<Color>(
          Colors.tealAccent.withOpacity(percentage == 1.0 ? 0.3 : 0.15),
        ),
        minHeight: 3,
      ),
    );
  }
}
