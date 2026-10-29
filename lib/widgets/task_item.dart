import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskItem extends StatelessWidget {
  final Task task;

  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TaskItem({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme = Theme.of(context).colorScheme;
    final TextTheme = Theme.of(context).textTheme;
    final isCompleted = task.isCompleted;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading Checkbox(
          value: isCompleted,
          onChanged: (_) => onToggle(),
        ),

        title: Text(
          task.title,
          style: TextTheme.bodyLarge?.copyWith(
            decoration: isCompleted ?
            TextDecoration.lineThrough :
            null,
            color: isCompleted ?
            ColorScheme.onSurface.withValues(alpha: 0.45) :
            ColorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
