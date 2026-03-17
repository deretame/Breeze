import 'package:zephyr/util/ui/fluent_compat.dart';

/// A small helper to standardize pages during the Material -> Fluent migration.
///
/// It renders a [ScaffoldPage] with a [PageHeader]. If the widget tree doesn't
/// have a [NavigationView] ancestor, it wraps the page in a [NavigationView]
/// using the `content:` slot.
class AppScaffoldPage extends StatelessWidget {
  const AppScaffoldPage({
    super.key,
    required this.title,
    required this.content,
    this.leading,
    this.commandBar,
    this.bottomBar,
    this.floatingActionButton,
    this.padding,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget title;
  final Widget content;

  final Widget? leading;
  final Widget? commandBar;
  final Widget? bottomBar;

  final Widget? floatingActionButton;
  final EdgeInsets? padding;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final headerLeading =
        leading ??
        (canPop
            ? IconButton(
                icon: const Icon(FluentIcons.back),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null);

    Widget page = ScaffoldPage(
      header: PageHeader(
        leading: headerLeading,
        title: title,
        commandBar: commandBar,
      ),
      content: content,
      bottomBar: bottomBar,
      padding: padding,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );

    if (floatingActionButton != null) {
      page = Stack(
        children: [
          page,
          PositionedDirectional(
            end: 16,
            bottom: 16,
            child: floatingActionButton!,
          ),
        ],
      );
    }

    if (NavigationView.maybeOf(context) != null) {
      return page;
    }

    return NavigationView(content: page);
  }
}
