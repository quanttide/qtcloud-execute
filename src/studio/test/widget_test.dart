import 'package:flutter_test/flutter_test.dart';

import 'package:qtcloud_execute_studio/main.dart';

void main() {
  testWidgets('任务清单渲染种子任务', (WidgetTester tester) async {
    await tester.pumpWidget(const QuantTideExecuteStudioApp());
    await tester.pumpAndSettle();

    expect(find.text('量潮课堂实训基地账本配套审批'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('量潮课堂实训基地账本对账'), 300);
    expect(find.text('量潮课堂实训基地账本对账'), findsOneWidget);
    expect(find.text('依赖前置任务'), findsOneWidget);
  });
}
