---
name: flutter-add-widget-test
description: Implement a component-level test using `WidgetTester` to verify UI rendering and user interactions (tapping, scrolling, entering text). Use when validating that a specific widget displays correct data and responds to events as expected.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Tue, 21 Apr 2026 21:15:41 GMT
---
# Writing Flutter Widget Tests

## Contents
- [Setup & Configuration](#setup--configuration)
- [Core Components](#core-components)
- [Workflow: Implementing a Widget Test](#workflow-implementing-a-widget-test)
- [Interaction & State Management](#interaction--state-management)
- [Examples](#examples)

## Setup & Configuration

Ensure the testing environment is properly configured before authoring widget tests.

1. Add the `flutter_test` dependency to the `dev_dependencies` section of `pubspec.yaml`.
2. Place all test files in the `test/` directory at the root of the project.
3. Suffix all test file names with `_test.dart` (e.g., `widget_test.dart`).

## Core Components

Utilize the following `flutter_test` components to interact with and validate the widget tree:

*   **`WidgetTester`**: The primary interface for building and interacting with widgets in the test environment. Provided automatically by the `testWidgets()` function.
*   **`Finder`**: Locates widgets in the test environment (e.g., `find.text('Submit')`, `find.byType(TextField)`, `find.byKey(Key('submit_btn'))`).
*   **`Matcher`**: Verifies the presence or state of widgets located by a `Finder` (e.g., `findsOneWidget`, `findsNothing`, `findsNWidgets(2)`, `matchesGoldenFile`).

## Workflow: Implementing a Widget Test

Copy the following checklist to track progress when implementing a new widget test.

### Task Progress
- [ ] **Step 1: Define the test.** Use `testWidgets('description', (WidgetTester tester) async { ... })`.
- [ ] **Step 2: Build the widget.** Call `await tester.pumpWidget(MyWidget())` to render the UI. Wrap the widget in a `MaterialApp` or `Directionality` widget if it requires inherited directional or theme data.
- [ ] **Step 3: Locate elements.** Instantiate `Finder` objects for the target widgets.
- [ ] **Step 4: Verify initial state.** Use `expect(finder, matcher)` to validate the initial render.
- [ ] **Step 5: Simulate interactions.** Execute gestures or inputs (e.g., `await tester.tap(buttonFinder)`).
- [ ] **Step 6: Rebuild the tree.** Call `await tester.pump()` or `await tester.pumpAndSettle()` to process state changes.
- [ ] **Step 7: Verify updated state.** Use `expect()` to validate the UI after the interaction.
- [ ] **Step 8: Run and validate.** Execute `flutter test test/your_test_file_test.dart`.
- [ ] **Step 9: Feedback Loop.** Review test output -> identify failing matchers -> adjust widget logic or test assertions -> re-run until passing.

## Interaction & State Management

Apply the following conditional logic based on the type of interaction or state change being tested:

*   **If testing static rendering:** Call `await tester.pumpWidget()` once, then immediately run `expect()` assertions.
*   **If testing standard state changes (e.g., button taps):**
    1. Call `await tester.tap(finder)`.
    2. Call `await tester.pump()` to trigger a single frame rebuild.
*   **If testing animations, transitions, or asynchronous UI updates:**
    1. Trigger the action (e.g., `await tester.drag(finder, Offset(500, 0))`).
    2. Call `await tester.pumpAndSettle()` to repeatedly pump frames until no more frames are scheduled (animation completes).
*   **If testing text input:** Call `await tester.enterText(textFieldFinder, 'Input string')`.
*   **If testing items in a dynamic or long list:** Call `await tester.scrollUntilVisible(itemFinder, 500.0, scrollable: listFinder)` to ensure the target widget is rendered before interacting with it.

## Examples

### High-Fidelity Widget Test Implementation

**Target Widget (`lib/todo_list.dart`):**
```dart
import 'package:flutter/material.dart';

class TodoList extends StatefulWidget {
  const TodoList({super.key});

  @override
  State<TodoList> createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  final todos = <String>[];
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            TextField(controller: controller),
            Expanded(
              child: ListView.builder(
                itemCount: todos.length,
                itemBuilder: (context, index) {
                  final todo = todos[index];
                  return Dismissible(
                    key: Key('$todo$index'),
                    onDismissed: (_) => setState(() => todos.removeAt(index)),
                    child: ListTile(title: Text(todo)),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              todos.add(controller.text);
              controller.clear();
            });
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
```

**Test Implementation (`test/todo_list_test.dart`):**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/todo_list.dart';

void main() {
  testWidgets('Add and remove a todo item', (WidgetTester tester) async {
    // 1. Build the widget
    await tester.pumpWidget(const TodoList());

    // 2. Verify initial state
    expect(find.byType(ListTile), findsNothing);

    // 3. Enter text into the TextField
    await tester.enterText(find.byType(TextField), 'Buy groceries');

    // 4. Tap the add button
    await tester.tap(find.byType(FloatingActionButton));

    // 5. Rebuild the widget to reflect the new state
    await tester.pump();

    // 6. Verify the item was added
    expect(find.text('Buy groceries'), findsOneWidget);

    // 7. Swipe the item to dismiss it
    await tester.drag(find.byType(Dismissible), const Offset(500, 0));

    // 8. Build the widget until the dismiss animation ends
    await tester.pumpAndSettle();

    // 9. Verify the item was removed
    expect(find.text('Buy groceries'), findsNothing);
  });
}
```
