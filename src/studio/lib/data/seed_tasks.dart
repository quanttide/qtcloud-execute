import 'dart:convert';

import 'package:flutter/services.dart';

import '../repositories/task_repository.dart';

/// 从种子 asset 构建内存仓储（应用默认数据源）
Future<TaskRepository> loadSeedRepository() async {
  final String raw = await rootBundle.loadString('assets/data/seed_tasks.json');
  return InMemoryTaskRepository.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
