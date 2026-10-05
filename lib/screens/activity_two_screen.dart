import 'package:flutter/material.dart';

class _Task {
  final String title;
  bool done;

  _Task(this.title) : done = false;
}

class ActivityTwoScreen extends StatefulWidget {
  static const String routeName = '/activity-two';

  const ActivityTwoScreen({super.key});

  @override
  State<ActivityTwoScreen> createState() => _ActivityTwoScreenState();
}

class _ActivityTwoScreenState extends State<ActivityTwoScreen> {
  final _controller = TextEditingController();
  final List<_Task> _tasks = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTask() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _tasks.add(_Task(text)));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity Two')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _addTask(),
                    decoration: const InputDecoration(
                      labelText: 'New task',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _addTask, child: const Text('Add')),
              ],
            ),
          ),
          Expanded(
            child: _tasks.isEmpty
                ? const Center(child: Text('No tasks yet.'))
                : ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (context, i) {
                      final task = _tasks[i];
                      return ListTile(
                        leading: Checkbox(
                          value: task.done,
                          onChanged: (v) =>
                              setState(() => task.done = v ?? false),
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration:
                                task.done ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => setState(() => _tasks.removeAt(i)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
