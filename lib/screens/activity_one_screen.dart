import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';

class ActivityOneScreen extends StatefulWidget {
  static const String routeName = '/activity-one';

  const ActivityOneScreen({super.key});

  @override
  State<ActivityOneScreen> createState() => _ActivityOneScreenState();
}

class _ActivityOneScreenState extends State<ActivityOneScreen> {
  // Local, screen-specific state (StatefulWidget)
  int _count = 0;
  bool _liked = false;

  final List<String> _items = const [
    'Project setup',
    'Multi-screen navigation',
    'Stateless vs Stateful',
    'Responsive layout',
    'Provider state management',
  ];
  late final List<bool> _checked = List<bool>.filled(_items.length, false);

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AppState>().userName;
    final done = _checked.where((c) => c).length;

    final counterCard = _SectionCard(
      title: 'Counter',
      child: Column(
        children: [
          Text('$_count', style: Theme.of(context).textTheme.displayMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () => setState(() => _count--),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => setState(() => _count++),
              ),
            ],
          ),
        ],
      ),
    );

    final favoriteCard = _SectionCard(
      title: 'Favorite',
      child: Column(
        children: [
          IconButton(
            iconSize: 56,
            color: Colors.red,
            icon: Icon(_liked ? Icons.favorite : Icons.favorite_border),
            onPressed: () => setState(() => _liked = !_liked),
          ),
          Text(_liked ? 'Liked' : 'Not liked'),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Activity One')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Hi, $name! Local state demo:'),
          const SizedBox(height: 12),
          // Row on wide screens, Column on narrow screens
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 600) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: counterCard),
                    const SizedBox(width: 12),
                    Expanded(child: favoriteCard),
                  ],
                );
              }
              return Column(
                children: [
                  counterCard,
                  const SizedBox(height: 12),
                  favoriteCard,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Lab checklist  ($done/${_items.length})',
            child: Column(
              children: [
                LinearProgressIndicator(value: done / _items.length),
                for (var i = 0; i < _items.length; i++)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_items[i]),
                    value: _checked[i],
                    onChanged: (v) => setState(() => _checked[i] = v ?? false),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Static card (StatelessWidget).
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: child),
          ],
        ),
      ),
    );
  }
}
