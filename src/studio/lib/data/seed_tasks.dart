import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/task.dart';

/// 从种子数据加载任务清单
Future<TaskList> loadSeedTasks() async {
  final String raw = await rootBundle.loadString('assets/data/seed_tasks.json');
  return TaskList.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
