import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:lab_activity4/main.dart';
import 'package:lab_activity4/providers/mesh_chat_state.dart';

void main() {
  testWidgets('Home screen shows the Local Mesh Chat button', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => MeshChatState(),
        child: const LabActivityApp(),
      ),
    );

    expect(find.text('Local Mesh Chat'), findsOneWidget);
  });
}