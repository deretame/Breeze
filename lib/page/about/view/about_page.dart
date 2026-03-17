import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:zephyr/util/ui/fluent_compat.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zephyr/main.dart';

import '../../../util/update/check_update.dart';

// --- 风格常量 ---
const Color kBgColor = Color(0xFF12121C); // --bg-color
const Color kCardBgColor = Color(0xCC232332); // --card-bg-color (80% opacity)
const Color kPrimaryText = Color(0xFFE0E0E0); // --primary-text-color
const Color kSecondaryText = Color(0xFFA0A0C0); // --secondary-text-color
const Color kAccentColor = Color(0xFF00FFFF); // --accent-color
const Color kAccentHover = Color(0xFF00E6E6);
const double kBorderRadius = 15.0;

@RoutePage()
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _appVersion = "加载中...";
  List<Map<String, dynamic>> _contributors = [];
  bool _contributorsLoading = true;
  String? _contributorsError;

  final Dio _dio = Dio(BaseOptions(validateStatus: (status) => true));

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final version = await getAppVersion();
    await _fetchContributors();

    if (mounted) {
      setState(() {
        _appVersion = version;
      });
    }
  }

  Future<void> _fetchContributors() async {
    try {
      final response = await _dio.get(
        'https://api.github.com/repos/deretame/Breeze/contributors',
        queryParameters: {'per_page': 20},
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _contributors = List<Map<String, dynamic>>.from(response.data);
          _contributorsLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _contributorsError = '获取失败';
          _contributorsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _contributorsError = '网络错误';
          _contributorsLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // 配合渐变背景
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: kPrimaryText),
      ),
      body: Container(
        decoration: const BoxDecoration(
          // CSS: background: linear-gradient(135deg, #1a1a2e 0%, #12121c 100%);
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF12121C)],
          ),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                20,
                80,
                20,
                60,
              ), // Top padding for AppBar
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 600,
                  ), // container max-width
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // --- Header ---
                      _buildHeader(),
                      const SizedBox(height: 30),

                      // --- Sections ---
                      _buildSection(
                        icon: "🚀",
                        title: "项目地址",
                        desc: "喜欢这个项目吗？点个star支持一下吧！",
                        linkText: "前往 GitHub 仓库 (deretame/Breeze) ⭐",
                        url: "https://github.com/deretame/Breeze",
                        delay: 200,
                      ),

                      // --- Contributors Section ---
                      _buildContributorsSection(),

                      _buildSection(
                        icon: "💬",
                        title: "联系方式",
                        desc: "有任何想法或问题，欢迎来找我聊聊~",
                        linkText: "Telegram: @breeze_zh_cn",
                        url: "https://t.me/breeze_zh_cn",
                        delay: 400,
                      ),
                      _buildSection(
                        icon: "🛠️",
                        title: "反馈与建议",
                        desc: "发现BUG或者有新的点子？",
                        linkText: "在 GitHub Issues 中提出",
                        url: "https://github.com/deretame/Breeze/issues",
                        delay: 600,
                      ),

                      const SizedBox(height: 30),

                      // --- Disclaimer Button ---
                      OutlinedButton(
                        onPressed: _showDisclaimerDialog,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kAccentColor,
                          side: const BorderSide(color: kAccentColor, width: 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(kBorderRadius),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        child: const Text("免责声明"),
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ),

            // --- Bottom Version Bar ---
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: const Color(0xE612121C), // slightly transparent
                alignment: Alignment.center,
                child: Text(
                  "版本号: $_appVersion",
                  style: const TextStyle(color: kSecondaryText, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 组件构建方法 ---

  Widget _buildHeader() {
    return Column(
      children: [
        // Avatar with glow
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: kAccentColor, width: 4),
            boxShadow: [
              BoxShadow(
                color: kAccentColor.withValues(alpha: 0.7),
                blurRadius: 20,
              ),
            ],
            image: const DecorationImage(
              // 如果网络图片加载慢，可以换成 asset/image/app-icon.png
              image: NetworkImage(
                "https://avatars.githubusercontent.com/u/81013544",
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Name
        const Text(
          "windy",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: kAccentColor, blurRadius: 10)],
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          "BREEZE PROJECT",
          style: TextStyle(
            fontSize: 18,
            color: kAccentColor,
            letterSpacing: 2,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String icon,
    required String title,
    required String desc,
    required String linkText,
    required String url,
    required int delay,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      width: double.infinity,
      decoration: BoxDecoration(
        color: kCardBgColor,
        borderRadius: BorderRadius.circular(kBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(kBorderRadius),
          onTap: () => _launchURL(url),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        color: kAccentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: Color(0x4D00FFFF), height: 1),
                const SizedBox(height: 10),
                Text(
                  desc,
                  style: const TextStyle(color: kPrimaryText, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  linkText,
                  style: const TextStyle(
                    color: kAccentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContributorsSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      width: double.infinity,
      decoration: BoxDecoration(
        color: kCardBgColor,
        borderRadius: BorderRadius.circular(kBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text("❤️", style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                const Text(
                  "贡献者",
                  style: TextStyle(
                    fontSize: 22,
                    color: kAccentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  "${_contributors.length}人",
                  style: const TextStyle(color: kSecondaryText, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(color: Color(0x4D00FFFF), height: 1),
            const SizedBox(height: 15),
            if (_contributorsLoading)
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: kAccentColor,
                  ),
                ),
              )
            else if (_contributorsError != null)
              Center(
                child: Text(
                  _contributorsError!,
                  style: const TextStyle(color: kSecondaryText),
                ),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _contributors.map((contributor) {
                  return _buildContributorAvatar(
                    avatarUrl: contributor['avatar_url'] ?? '',
                    login: contributor['login'] ?? '',
                    contributions: contributor['contributions'] ?? 0,
                    htmlUrl: contributor['html_url'] ?? '',
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributorAvatar({
    required String avatarUrl,
    required String login,
    required int contributions,
    required String htmlUrl,
  }) {
    return Tooltip(
      message: "$login ($contributions 次提交)",
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () => _launchURL(htmlUrl),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: kAccentColor.withValues(alpha: 0.5),
              width: 2,
            ),
            image: DecorationImage(
              image: NetworkImage(avatarUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  // --- 免责声明弹窗 ---
  void _showDisclaimerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1E1E2C), // 深色弹窗背景
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
          side: const BorderSide(color: kAccentColor, width: 1), // 边框
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "免责声明",
                    style: TextStyle(
                      color: kAccentColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: kSecondaryText),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: Color(0x4D00FFFF)),

              // Body (Scrollable)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SizedBox(height: 10),
                      Text(
                        "开源项目免责声明",
                        style: TextStyle(
                          color: kAccentColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),

                      _DisclaimerItem(
                        "1. 项目性质与声明",
                        "本项目为开源软件，由本人独立开发并维护。项目以\"原样\"形式提供，开发者不对项目的功能完整性、稳定性、安全性或适用性作出任何明示或暗示的担保。",
                      ),
                      _DisclaimerItem(
                        "2. 责任限制",
                        "开发者对因使用、修改或分发本项目（包括但不限于直接使用、二次开发或集成至其他项目）而导致的任何直接、间接、特殊、附带或后果性损害不承担任何责任。这些损害可能包括但不限于数据丢失、设备损坏、业务中断、利润损失或其他经济损失。",
                      ),
                      _DisclaimerItem(
                        "3. 用户责任",
                        "用户在使用本项目时，应自行评估其适用性并承担所有风险。用户须确保其使用行为符合所在国家或地区的法律法规及道德规范。开发者不对用户因违反法律法规或不当使用本项目而导致的任何后果负责。",
                      ),
                      _DisclaimerItem(
                        "4. 第三方依赖与资源",
                        "本项目可能依赖或引用第三方库、工具、服务或其他资源。开发者不对这些第三方资源的内容、功能、安全性或合法性负责。用户应自行评估并承担使用第三方资源的风险。",
                      ),
                      _DisclaimerItem(
                        "5. 无担保声明",
                        "开发者明确声明不对本项目提供任何形式的担保，包括但不限于：适销性担保；特定用途适用性担保；不侵犯第三方权利担保；无错误或无中断运行担保。",
                      ),
                      _DisclaimerItem(
                        "6. 项目修改与终止",
                        "开发者保留随时修改、暂停或终止本项目的权利，且无需提前通知用户。开发者不对因项目修改、暂停或终止而导致的任何后果负责。",
                      ),
                      _DisclaimerItem(
                        "7. 贡献者责任",
                        "如果本项目接受外部贡献，贡献者的行为仅代表其个人立场，不代表开发者的观点或立场。开发者对贡献者的行为及其贡献内容不承担责任。",
                      ),
                      _DisclaimerItem(
                        "8. 法律合规性",
                        "用户在使用本项目时，应确保其行为符合所在国家或地区的法律法规。开发者不对用户因违反法律法规而导致的任何后果负责。",
                      ),
                      SizedBox(height: 20),
                      Text(
                        "重要提示",
                        style: TextStyle(
                          color: kAccentColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "在使用本项目之前，请仔细阅读并理解本免责声明。如果您不同意本声明的任何条款，请立即停止使用本项目。继续使用本项目即表示您已阅读、理解并同意本免责声明的全部内容。",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      logger.e("无法打开链接: $url");
    }
  }
}

// 辅助组件：免责声明条目
class _DisclaimerItem extends StatelessWidget {
  final String title;
  final String content;
  const _DisclaimerItem(this.title, this.content);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: kPrimaryText,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            content,
            style: const TextStyle(color: kSecondaryText, fontSize: 14),
          ),
        ],
      ),
    );
  }
}


