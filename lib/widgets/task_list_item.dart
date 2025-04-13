import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskListItem extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback? onTap;

  const TaskListItem({
    Key? key,
    required this.task,
    required this.onToggle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Define priority colors
    final priorityColors = [
      Colors.blue, // Low
      Colors.orange, // Medium
      Colors.red,   // High
    ];

    // Define category icons
    final categoryIcons = {
      'Homework': Icons.assignment,
      'Exam': Icons.school,
      'Project': Icons.build,
      'Reading': Icons.book,
      'Other': Icons.more_horiz,
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: task.isCompleted,
                  onChanged: (_) => onToggle(),
                  shape: const CircleBorder(),
                  activeColor: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),

              // Priority indicator
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: priorityColors[task.priority],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),

              // Task details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: textTheme.titleMedium?.copyWith(
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted
                            ? theme.colorScheme.onSurface.withOpacity(0.6)
                            : theme.colorScheme.onSurface,
                        fontWeight: task.isCompleted ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    if (task.description != null && task.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          task.description!,
                          style: textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (task.dueDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: _getDueDateColor(task.dueDate!, theme),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM dd, yyyy').format(task.dueDate!),
                              style: textTheme.bodySmall?.copyWith(
                                color: _getDueDateColor(task.dueDate!, theme),
                                fontWeight: _isTaskDueSoon(task.dueDate!) ? FontWeight.bold : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Category icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  categoryIcons[task.category] ?? Icons.more_horiz,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDueDateColor(DateTime dueDate, ThemeData theme) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (dueDate.isBefore(now)) {
      return Colors.red; // Overdue
    } else if (difference <= 1) {
      return Colors.redAccent; // Due today or tomorrow
    } else if (difference <= 3) {
      return Colors.orange; // Due within 3 days
    } else {
      return theme.colorScheme.onSurface.withOpacity(0.6); // Due later
    }
  }

  bool _isTaskDueSoon(DateTime dueDate) {
    final now = DateTime.now();
    return dueDate.difference(now).inDays <= 3 || dueDate.isBefore(now);
  }
}