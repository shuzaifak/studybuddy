import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/task_list_item.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'All',
                child: Text('All Categories'),
              ),
              const PopupMenuItem(
                value: 'Homework',
                child: Text('Homework'),
              ),
              const PopupMenuItem(
                value: 'Exam',
                child: Text('Exam'),
              ),
              const PopupMenuItem(
                value: 'Project',
                child: Text('Project'),
              ),
              const PopupMenuItem(
                value: 'Reading',
                child: Text('Reading'),
              ),
              const PopupMenuItem(
                value: 'Other',
                child: Text('Other'),
              ),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskList(taskProvider, (task) => _filterByCategory(task)),
          _buildTaskList(
            taskProvider,
                (task) => !task.isCompleted && _filterByCategory(task),
          ),
          _buildTaskList(
            taskProvider,
                (task) => task.isCompleted && _filterByCategory(task),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTaskDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  bool _filterByCategory(Task task) {
    if (_selectedFilter == 'All') return true;
    return task.category == _selectedFilter;
  }

  Widget _buildTaskList(TaskProvider provider, bool Function(Task) filter) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredTasks = provider.tasks.where(filter).toList();

    if (filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add a new task',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    // Sort tasks: first by completion, then by due date
    filteredTasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }

      if (a.dueDate == null && b.dueDate == null) {
        return a.priority.compareTo(b.priority);
      }

      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;

      final dateComparison = a.dueDate!.compareTo(b.dueDate!);
      if (dateComparison != 0) return dateComparison;

      return a.priority.compareTo(b.priority);
    });

    return ListView.builder(
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        return Dismissible(
          key: Key(task.id.toString()),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Task'),
                content: const Text('Are you sure you want to delete this task?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) {
            provider.deleteTask(task.id!);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Task deleted'),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () {
                    provider.addTask(task);
                  },
                ),
              ),
            );
          },
          child: TaskListItem(
            task: task,
            onToggle: () {
              provider.toggleTaskCompletion(task.id!);
            },
            onTap: () {
              _showEditTaskDialog(context, task);
            },
          ),
        );
      },
    );
  }

  Future<void> _showAddTaskDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    String selectedCategory = 'Homework';
    int selectedPriority = 0;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add New Task'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter task title',
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'Enter task description',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  const Text('Due Date (optional)'),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      selectedDate == null
                          ? 'Select date'
                          : DateFormat('MMM dd, yyyy').format(selectedDate!),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          selectedDate = date;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text('Reminder Time (optional)'),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      selectedTime == null
                          ? 'Select time'
                          : selectedTime!.format(context),
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          selectedTime = time;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Category'),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: const [
                      DropdownMenuItem(
                        value: 'Homework',
                        child: Text('Homework'),
                      ),
                      DropdownMenuItem(
                        value: 'Exam',
                        child: Text('Exam'),
                      ),
                      DropdownMenuItem(
                        value: 'Project',
                        child: Text('Project'),
                      ),
                      DropdownMenuItem(
                        value: 'Reading',
                        child: Text('Reading'),
                      ),
                      DropdownMenuItem(
                        value: 'Other',
                        child: Text('Other'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Priority'),
                  Slider(
                    value: selectedPriority.toDouble(),
                    min: 0,
                    max: 2,
                    divisions: 2,
                    label: ['Low', 'Medium', 'High'][selectedPriority],
                    onChanged: (value) {
                      setState(() {
                        selectedPriority = value.toInt();
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Low', style: Theme.of(context).textTheme.bodySmall),
                      Text('Medium', style: Theme.of(context).textTheme.bodySmall),
                      Text('High', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (titleController.text.isEmpty) {
                    return;
                  }

                  // Calculate reminder time if both date and time are selected
                  DateTime? reminderTime;
                  if (selectedDate != null && selectedTime != null) {
                    reminderTime = DateTime(
                      selectedDate!.year,
                      selectedDate!.month,
                      selectedDate!.day,
                      selectedTime!.hour,
                      selectedTime!.minute,
                    );
                  }

                  final newTask = Task(
                    title: titleController.text,
                    description: descriptionController.text.isEmpty ? null : descriptionController.text,
                    dueDate: selectedDate,
                    priority: selectedPriority,
                    category: selectedCategory,
                    reminderTime: reminderTime,
                  );

                  Provider.of<TaskProvider>(context, listen: false).addTask(newTask);
                  Navigator.of(context).pop();
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showEditTaskDialog(BuildContext context, Task task) async {
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description ?? '');
    DateTime? selectedDate = task.dueDate;
    TimeOfDay? selectedTime = task.reminderTime != null
        ? TimeOfDay(hour: task.reminderTime!.hour, minute: task.reminderTime!.minute)
        : null;
    String selectedCategory = task.category ?? 'Homework';
    int selectedPriority = task.priority;

    return showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
        builder: (context, setState) {
      return AlertDialog(
          title: const Text('Edit Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter task title',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Enter task description',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text('Due Date (optional)'),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    selectedDate == null
                        ? 'Select date'
                        : DateFormat('MMM dd, yyyy').format(selectedDate!),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selectedDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              selectedDate = null;
                            });
                          },
                        ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        selectedDate = date;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                const Text('Reminder Time (optional)'),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    selectedTime == null
                        ? 'Select time'
                        : selectedTime!.format(context),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selectedTime != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              selectedTime = null;
                            });
                          },
                        ),
                      const Icon(Icons.access_time),
                    ],
                  ),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime ?? TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        selectedTime = time;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text('Category'),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: const [
                    DropdownMenuItem(
                      value: 'Homework',
                      child: Text('Homework'),
                    ),
                    DropdownMenuItem(
                      value: 'Exam',
                      child: Text('Exam'),
                    ),
                    DropdownMenuItem(
                      value: 'Project',
                      child: Text('Project'),
                    ),
                    DropdownMenuItem(
                      value: 'Reading',
                      child: Text('Reading'),
                    ),
                    DropdownMenuItem(
                      value: 'Other',
                      child: Text('Other'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Priority'),
                Slider(
                  value: selectedPriority.toDouble(),
                  min: 0,
                  max: 2,
                  divisions: 2,
                  label: ['Low', 'Medium', 'High'][selectedPriority],
                  onChanged: (value) {
                    setState(() {
                      selectedPriority = value.toInt();
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Low', style: Theme.of(context).textTheme.bodySmall),
                    Text('Medium', style: Theme.of(context).textTheme.bodySmall),
                    Text('High', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          actions: [
          TextButton(
          onPressed: () {
        Navigator.of(context).pop();
      },
    child: const Text('Cancel'),
    ),
    TextButton(
    onPressed: () {
    if (titleController.text.isEmpty) {
    return;
    }

    // Calculate reminder time if both date and time are selected
    DateTime? reminderTime;
    if (selectedDate != null && selectedTime != null) {
    reminderTime = DateTime(
    selectedDate!.year,
    selectedDate!.month,
    selectedDate!.day,
    selectedTime!.hour,
    selectedTime!.minute,
    );
    }

    final updatedTask = task.copy(
    title: titleController.text,
    description: descriptionController.text.isEmpty ? null : descriptionController.text,
    dueDate: selectedDate,
    priority: selectedPriority,
    category: selectedCategory,
    reminderTime: reminderTime,
    );

    Provider.of<TaskProvider>(context, listen: false).updateTask(updatedTask);
    Navigator.of(context).pop();
    },
      child: const Text('Save'),
    ),
          ],
      );
        },
        ),
    );
  }
}