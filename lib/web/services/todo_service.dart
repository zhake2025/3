import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// 待办事项服务
/// 提供本地存储的待办事项管理功能
class TodoService extends ChangeNotifier {
  static TodoService? _instance;
  static TodoService get instance => _instance ??= TodoService._();
  
  TodoService._();

  // 存储键
  static const String _todosStorageKey = 'kelivo_todos';
  static const String _categoriesStorageKey = 'kelivo_todo_categories';
  
  // 数据
  List<TodoItem> _todos = [];
  List<TodoCategory> _categories = [];
  
  // 过滤和排序
  TodoFilter _currentFilter = TodoFilter.all;
  TodoSort _currentSort = TodoSort.createdDate;
  String _searchQuery = '';
  
  /// 获取所有待办事项
  List<TodoItem> get todos => _getFilteredTodos();
  
  /// 获取所有分类
  List<TodoCategory> get categories => List.unmodifiable(_categories);
  
  /// 当前过滤器
  TodoFilter get currentFilter => _currentFilter;
  
  /// 当前排序方式
  TodoSort get currentSort => _currentSort;
  
  /// 搜索查询
  String get searchQuery => _searchQuery;
  
  /// 统计信息
  TodoStats get stats => TodoStats(
    total: _todos.length,
    completed: _todos.where((todo) => todo.isCompleted).length,
    pending: _todos.where((todo) => !todo.isCompleted).length,
    overdue: _todos.where((todo) => todo.isOverdue).length,
    today: _todos.where((todo) => todo.isDueToday).length,
    thisWeek: _todos.where((todo) => todo.isDueThisWeek).length,
  );
  
  /// 初始化服务
  Future<void> initialize() async {
    try {
      await _loadTodos();
      await _loadCategories();
      
      // 如果没有默认分类，创建一些
      if (_categories.isEmpty) {
        await _createDefaultCategories();
      }
      
      debugPrint('Todo Service initialized with ${_todos.length} todos');
    } catch (e) {
      debugPrint('Failed to initialize todo service: $e');
    }
  }
  
  /// 添加待办事项
  Future<TodoItem> addTodo({
    required String title,
    String? description,
    DateTime? dueDate,
    TodoPriority priority = TodoPriority.medium,
    String? categoryId,
    List<String>? tags,
  }) async {
    final todo = TodoItem(
      id: _generateId(),
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      categoryId: categoryId,
      tags: tags ?? [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _todos.add(todo);
    await _saveTodos();
    notifyListeners();
    
    return todo;
  }
  
  /// 更新待办事项
  Future<bool> updateTodo(String id, {
    String? title,
    String? description,
    DateTime? dueDate,
    TodoPriority? priority,
    String? categoryId,
    List<String>? tags,
    bool? isCompleted,
  }) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) return false;
    
    final todo = _todos[index];
    _todos[index] = todo.copyWith(
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      categoryId: categoryId,
      tags: tags,
      isCompleted: isCompleted,
      completedAt: isCompleted == true ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );
    
    await _saveTodos();
    notifyListeners();
    return true;
  }
  
  /// 删除待办事项
  Future<bool> deleteTodo(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) return false;
    
    _todos.removeAt(index);
    await _saveTodos();
    notifyListeners();
    return true;
  }
  
  /// 切换完成状态
  Future<bool> toggleTodoCompletion(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) return false;
    
    final todo = _todos[index];
    final isCompleted = !todo.isCompleted;
    
    _todos[index] = todo.copyWith(
      isCompleted: isCompleted,
      completedAt: isCompleted ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );
    
    await _saveTodos();
    notifyListeners();
    return true;
  }
  
  /// 批量操作
  Future<void> batchUpdateTodos(List<String> ids, {
    bool? isCompleted,
    String? categoryId,
    TodoPriority? priority,
  }) async {
    bool hasChanges = false;
    
    for (final id in ids) {
      final index = _todos.indexWhere((todo) => todo.id == id);
      if (index != -1) {
        final todo = _todos[index];
        _todos[index] = todo.copyWith(
          isCompleted: isCompleted,
          categoryId: categoryId,
          priority: priority,
          completedAt: isCompleted == true ? DateTime.now() : null,
          updatedAt: DateTime.now(),
        );
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      await _saveTodos();
      notifyListeners();
    }
  }
  
  /// 删除已完成的待办事项
  Future<int> deleteCompletedTodos() async {
    final completedCount = _todos.where((todo) => todo.isCompleted).length;
    _todos.removeWhere((todo) => todo.isCompleted);
    
    if (completedCount > 0) {
      await _saveTodos();
      notifyListeners();
    }
    
    return completedCount;
  }
  
  /// 添加分类
  Future<TodoCategory> addCategory({
    required String name,
    String? description,
    int? color,
    String? icon,
  }) async {
    final category = TodoCategory(
      id: _generateId(),
      name: name,
      description: description,
      color: color ?? 0xFF2196F3,
      icon: icon ?? 'folder',
      createdAt: DateTime.now(),
    );
    
    _categories.add(category);
    await _saveCategories();
    notifyListeners();
    
    return category;
  }
  
  /// 更新分类
  Future<bool> updateCategory(String id, {
    String? name,
    String? description,
    int? color,
    String? icon,
  }) async {
    final index = _categories.indexWhere((category) => category.id == id);
    if (index == -1) return false;
    
    final category = _categories[index];
    _categories[index] = category.copyWith(
      name: name,
      description: description,
      color: color,
      icon: icon,
    );
    
    await _saveCategories();
    notifyListeners();
    return true;
  }
  
  /// 删除分类
  Future<bool> deleteCategory(String id) async {
    final index = _categories.indexWhere((category) => category.id == id);
    if (index == -1) return false;
    
    // 将该分类下的待办事项移到未分类
    for (int i = 0; i < _todos.length; i++) {
      if (_todos[i].categoryId == id) {
        _todos[i] = _todos[i].copyWith(categoryId: null);
      }
    }
    
    _categories.removeAt(index);
    await _saveCategories();
    await _saveTodos();
    notifyListeners();
    return true;
  }
  
  /// 设置过滤器
  void setFilter(TodoFilter filter) {
    if (_currentFilter != filter) {
      _currentFilter = filter;
      notifyListeners();
    }
  }
  
  /// 设置排序方式
  void setSort(TodoSort sort) {
    if (_currentSort != sort) {
      _currentSort = sort;
      notifyListeners();
    }
  }
  
  /// 设置搜索查询
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }
  
  /// 导出数据
  String exportData() {
    final data = {
      'todos': _todos.map((todo) => todo.toJson()).toList(),
      'categories': _categories.map((category) => category.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
    return jsonEncode(data);
  }
  
  /// 导入数据
  Future<bool> importData(String jsonData) async {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      
      // 导入分类
      if (data['categories'] != null) {
        final categoriesJson = data['categories'] as List;
        _categories = categoriesJson
            .map((json) => TodoCategory.fromJson(json))
            .toList();
      }
      
      // 导入待办事项
      if (data['todos'] != null) {
        final todosJson = data['todos'] as List;
        _todos = todosJson
            .map((json) => TodoItem.fromJson(json))
            .toList();
      }
      
      await _saveTodos();
      await _saveCategories();
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('Failed to import data: $e');
      return false;
    }
  }
  
  // 私有方法
  
  List<TodoItem> _getFilteredTodos() {
    var filtered = _todos.where((todo) {
      // 应用过滤器
      switch (_currentFilter) {
        case TodoFilter.all:
          break;
        case TodoFilter.active:
          if (todo.isCompleted) return false;
          break;
        case TodoFilter.completed:
          if (!todo.isCompleted) return false;
          break;
        case TodoFilter.today:
          if (!todo.isDueToday) return false;
          break;
        case TodoFilter.thisWeek:
          if (!todo.isDueThisWeek) return false;
          break;
        case TodoFilter.overdue:
          if (!todo.isOverdue) return false;
          break;
        case TodoFilter.highPriority:
          if (todo.priority != TodoPriority.high) return false;
          break;
      }
      
      // 应用搜索
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!todo.title.toLowerCase().contains(query) &&
            !(todo.description?.toLowerCase().contains(query) ?? false) &&
            !todo.tags.any((tag) => tag.toLowerCase().contains(query))) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    // 应用排序
    switch (_currentSort) {
      case TodoSort.createdDate:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case TodoSort.dueDate:
        filtered.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case TodoSort.priority:
        filtered.sort((a, b) => b.priority.index.compareTo(a.priority.index));
        break;
      case TodoSort.title:
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case TodoSort.completion:
        filtered.sort((a, b) {
          if (a.isCompleted == b.isCompleted) return 0;
          return a.isCompleted ? 1 : -1;
        });
        break;
    }
    
    return filtered;
  }
  
  Future<void> _loadTodos() async {
    try {
      final todosJson = html.window.localStorage[_todosStorageKey];
      if (todosJson != null) {
        final todosList = jsonDecode(todosJson) as List;
        _todos = todosList.map((json) => TodoItem.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Failed to load todos: $e');
    }
  }
  
  Future<void> _saveTodos() async {
    try {
      final todosJson = jsonEncode(_todos.map((todo) => todo.toJson()).toList());
      html.window.localStorage[_todosStorageKey] = todosJson;
    } catch (e) {
      debugPrint('Failed to save todos: $e');
    }
  }
  
  Future<void> _loadCategories() async {
    try {
      final categoriesJson = html.window.localStorage[_categoriesStorageKey];
      if (categoriesJson != null) {
        final categoriesList = jsonDecode(categoriesJson) as List;
        _categories = categoriesList
            .map((json) => TodoCategory.fromJson(json))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to load categories: $e');
    }
  }
  
  Future<void> _saveCategories() async {
    try {
      final categoriesJson = jsonEncode(
        _categories.map((category) => category.toJson()).toList(),
      );
      html.window.localStorage[_categoriesStorageKey] = categoriesJson;
    } catch (e) {
      debugPrint('Failed to save categories: $e');
    }
  }
  
  Future<void> _createDefaultCategories() async {
    final defaultCategories = [
      TodoCategory(
        id: _generateId(),
        name: '工作',
        description: '工作相关的任务',
        color: 0xFF2196F3,
        icon: 'work',
        createdAt: DateTime.now(),
      ),
      TodoCategory(
        id: _generateId(),
        name: '个人',
        description: '个人生活任务',
        color: 0xFF4CAF50,
        icon: 'person',
        createdAt: DateTime.now(),
      ),
      TodoCategory(
        id: _generateId(),
        name: '学习',
        description: '学习和培训任务',
        color: 0xFFFF9800,
        icon: 'school',
        createdAt: DateTime.now(),
      ),
      TodoCategory(
        id: _generateId(),
        name: '购物',
        description: '购物清单',
        color: 0xFFE91E63,
        icon: 'shopping_cart',
        createdAt: DateTime.now(),
      ),
    ];
    
    _categories.addAll(defaultCategories);
    await _saveCategories();
  }
  
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (DateTime.now().microsecond % 1000).toString();
  }
}

/// 待办事项模型
class TodoItem {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime? dueDate;
  final TodoPriority priority;
  final String? categoryId;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  
  const TodoItem({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.dueDate,
    this.priority = TodoPriority.medium,
    this.categoryId,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });
  
  /// 是否过期
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDate!);
  }
  
  /// 是否今天到期
  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final due = dueDate!;
    return now.year == due.year && 
           now.month == due.month && 
           now.day == due.day;
  }
  
  /// 是否本周到期
  bool get isDueThisWeek {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return dueDate!.isAfter(startOfWeek) && dueDate!.isBefore(endOfWeek);
  }
  
  TodoItem copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? dueDate,
    TodoPriority? priority,
    String? categoryId,
    List<String>? tags,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return TodoItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      categoryId: categoryId ?? this.categoryId,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      completedAt: completedAt ?? this.completedAt,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority.name,
      'categoryId': categoryId,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
  
  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      isCompleted: json['isCompleted'] ?? false,
      dueDate: json['dueDate'] != null 
          ? DateTime.parse(json['dueDate']) 
          : null,
      priority: TodoPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => TodoPriority.medium,
      ),
      categoryId: json['categoryId'],
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
    );
  }
}

/// 待办事项分类
class TodoCategory {
  final String id;
  final String name;
  final String? description;
  final int color;
  final String icon;
  final DateTime createdAt;
  
  const TodoCategory({
    required this.id,
    required this.name,
    this.description,
    required this.color,
    required this.icon,
    required this.createdAt,
  });
  
  TodoCategory copyWith({
    String? name,
    String? description,
    int? color,
    String? icon,
  }) {
    return TodoCategory(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  factory TodoCategory.fromJson(Map<String, dynamic> json) {
    return TodoCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      color: json['color'],
      icon: json['icon'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

/// 待办事项优先级
enum TodoPriority {
  low,
  medium,
  high,
  urgent,
}

/// 待办事项过滤器
enum TodoFilter {
  all,
  active,
  completed,
  today,
  thisWeek,
  overdue,
  highPriority,
}

/// 待办事项排序方式
enum TodoSort {
  createdDate,
  dueDate,
  priority,
  title,
  completion,
}

/// 待办事项统计
class TodoStats {
  final int total;
  final int completed;
  final int pending;
  final int overdue;
  final int today;
  final int thisWeek;
  
  const TodoStats({
    required this.total,
    required this.completed,
    required this.pending,
    required this.overdue,
    required this.today,
    required this.thisWeek,
  });
  
  double get completionRate => total > 0 ? completed / total : 0.0;
}