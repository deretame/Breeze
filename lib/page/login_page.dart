import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unified_plugin_envelope.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/widgets/toast.dart';

import 'package:zephyr/config/router/router.gr.dart';
import 'package:zephyr/util/error_filter.dart';
import 'package:zephyr/util/json/json_value.dart';

@RoutePage()
class LoginPage extends StatefulWidget {
  final String? from;

  const LoginPage({super.key, this.from});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginFieldSpec {
  const _LoginFieldSpec({
    required this.key,
    required this.kind,
    required this.label,
    this.required = false,
    this.placeholder = '',
    this.help = '',
  });

  final String key;
  final String kind;
  final String label;
  final bool required;
  final String placeholder;
  final String help;

  bool get obscure => kind == 'password';

  bool get multiline => kind == 'multiline';
}

class _LoginPageState extends State<LoginPage> {
  final Map<String, TextEditingController> _controllers = {};

  String title = '';
  late String from;
  List<_LoginFieldSpec> _fields = const [];
  String _submitFnPath = '';
  String _submitLabel = '';
  bool _loadingScheme = true;
  bool _submitting = false;
  String? _schemeError;

  @override
  void initState() {
    super.initState();
    from = (widget.from ?? '').trim();
    _loadLoginScheme();
  }

  Future<void> _loadLoginScheme() async {
    if (from.isEmpty) {
      if (mounted) {
        setState(() {
          _schemeError = t.login.missingPluginId;
          _loadingScheme = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _schemeError = null;
        _loadingScheme = true;
      });
    }

    try {
      final response = await callUnifiedComicPlugin(
        from: from,
        fnPath: 'getLoginBundle',
        core: const <String, dynamic>{},
        extern: const <String, dynamic>{},
      );
      final envelope = UnifiedPluginEnvelope.fromMap(response);
      _applyLoginBundle(envelope.scheme, envelope.data);
    } catch (e) {
      if (mounted) {
        final raw = e.toString();
        final missingBundle =
            raw.contains('getLoginBundle') ||
            raw.contains('function path not found') ||
            raw.contains('target is not function');
        setState(() {
          _schemeError = missingBundle
              ? t.login.loginNotSupported
              : t.login.loadConfigFailed(error: e);
          _loadingScheme = false;
        });
      }
    }
  }

  void _applyLoginBundle(
    Map<String, dynamic> scheme,
    Map<String, dynamic>? data,
  ) {
    final action = asJsonMap(scheme['action']);
    final submitFnPath =
        (action['fnPath'] ?? scheme['submitFnPath'] ?? scheme['fnPath'])
            ?.toString()
            .trim() ??
        '';
    final fields = asJsonList(
      scheme['fields'],
    ).map((item) => asJsonMap(item)).toList();
    final specs = <_LoginFieldSpec>[];
    for (final field in fields) {
      final key = field['key']?.toString().trim() ?? '';
      if (key.isEmpty) {
        continue;
      }
      specs.add(
        _LoginFieldSpec(
          key: key,
          kind: field['kind']?.toString().trim().isNotEmpty == true
              ? field['kind'].toString().trim()
              : 'text',
          label: field['label']?.toString().trim().isNotEmpty == true
              ? field['label'].toString().trim()
              : key,
          required: field['required'] == true,
          placeholder: field['placeholder']?.toString() ?? '',
          help: field['help']?.toString() ?? '',
        ),
      );
    }
    if (specs.isEmpty || submitFnPath.isEmpty) {
      if (mounted) {
        setState(() {
          _schemeError = t.login.insufficientFields;
          _loadingScheme = false;
        });
      }
      return;
    }

    for (final entry in _controllers.values) {
      entry.dispose();
    }
    _controllers.clear();
    final values = <String, dynamic>{
      ...asJsonMap(data),
      ...asJsonMap(data?['values']),
    };
    for (final spec in specs) {
      _controllers[spec.key] = TextEditingController(
        text: values[spec.key]?.toString() ?? '',
      );
    }

    if (mounted) {
      setState(() {
        title = scheme['title']?.toString().trim() ?? '';
        _fields = specs;
        _submitFnPath = submitFnPath;
        _submitLabel =
            (action['submitText'] ?? action['label'] ?? scheme['submitText'])
                ?.toString()
                .trim() ??
            '';
        _schemeError = null;
        _loadingScheme = false;
      });
    }
  }

  @override
  void dispose() {
    for (final entry in _controllers.values) {
      entry.dispose();
    }
    super.dispose();
  }

  Future<void> _showDialog(String title, String message) async {
    if (message.contains("invalid email or password")) {
      message = t.login.invalidCredentials;
    }

    if (!mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(children: <Widget>[Text(message)]),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(t.common.ok),
              onPressed: () => context.pop(),
            ),
          ],
        );
      },
    );
  }

  void _submitForm() async {
    if (!mounted) return;
    if (_loadingScheme || _schemeError != null || _submitting) {
      if (!_submitting) {
        showErrorToast(t.login.configNotReady);
      }
      return;
    }
    final values = <String, dynamic>{};
    for (final spec in _fields) {
      final text = _controllers[spec.key]?.text ?? '';
      if (spec.required && text.trim().isEmpty) {
        showErrorToast(t.login.requiredFieldEmpty(label: spec.label));
        return;
      }
      values[spec.key] = text;
    }
    setState(() {
      _submitting = true;
    });
    showInfoToast(t.login.loggingIn);

    try {
      // 新旧兼容：新插件读 core.values，旧插件读顶层 account/password。
      await callUnifiedComicPlugin(
        from: from,
        fnPath: _submitFnPath,
        core: {...values, 'values': values},
        extern: const <String, dynamic>{},
      );
      showSuccessToast(t.login.loginSuccess);

      if (!mounted) return;
      context.maybePop();
    } catch (e) {
      logger.e(e);
      _showDialog(t.login.loginFailed, normalizeSearchErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingScheme) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_schemeError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.login.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_schemeError!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _loadLoginScheme,
                  child: Text(t.login.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final submitLabel = _submitLabel.isEmpty
        ? t.login.loginButton
        : _submitLabel;
    return Scaffold(
      appBar: AppBar(
        title: Text(title.isEmpty ? t.login.title : title),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => context.pushRoute(GlobalSettingRoute()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (var i = 0; i < _fields.length; i++) ...[
              if (i > 0) const SizedBox(height: 20),
              _buildField(_fields[i]),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _submitting ? null : _submitForm,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(submitLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(_LoginFieldSpec spec) {
    final controller = _controllers[spec.key];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: spec.required ? '${spec.label} *' : spec.label,
            hintText: spec.placeholder.isEmpty ? null : spec.placeholder,
            border: const OutlineInputBorder(),
          ),
          obscureText: spec.obscure,
          maxLines: spec.multiline ? 5 : 1,
          minLines: spec.multiline ? 3 : 1,
        ),
        if (spec.help.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(spec.help, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}
