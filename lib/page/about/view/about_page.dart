import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/main.dart';

import 'package:zephyr/service/update/check_update.dart';

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
  String _appVersion = t.about.loading;
  List<Map<String, dynamic>> _contributors = [];
  bool _contributorsLoading = true;
  String? _contributorsError;

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
      final response = await fetch(
        'https://api.github.com/repos/deretame/Breeze/contributors',
        query: {'per_page': 20},
      );

      if (response.ok && mounted) {
        final data = response.json;
        setState(() {
          _contributors = List<Map<String, dynamic>>.from(
            data is List ? data : const [],
          );
          _contributorsLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _contributorsError = t.about.fetchFailed;
          _contributorsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _contributorsError = t.about.networkError;
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
                        title: t.about.projectAddress,
                        desc: t.about.projectAddressDesc,
                        linkText: t.about.projectLink,
                        url: "https://github.com/deretame/Breeze",
                        delay: 200,
                      ),

                      // --- Contributors Section ---
                      _buildContributorsSection(),

                      _buildSection(
                        icon: "💬",
                        title: t.about.contact,
                        desc: t.about.contactDesc,
                        linkText: "Telegram: @breeze_zh_cn",
                        url: "https://t.me/breeze_zh_cn",
                        delay: 400,
                      ),
                      _buildSection(
                        icon: "🛠️",
                        title: t.about.feedback,
                        desc: t.about.feedbackDesc,
                        linkText: t.about.feedbackLink,
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
                        child: Text(t.about.disclaimer),
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
                  t.about.version(version: _appVersion),
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
          hoverColor: kAccentColor.withValues(alpha: 0.05),
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
                Text(
                  t.about.contributors,
                  style: const TextStyle(
                    fontSize: 22,
                    color: kAccentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  t.about.contributorsCount(count: _contributors.length),
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
      message: t.about.contributionsTooltip(login: login, count: contributions),
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
                  Text(
                    t.about.disclaimer,
                    style: const TextStyle(
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
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        t.about.disclaimerTitle,
                        style: const TextStyle(
                          color: kAccentColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),

                      _DisclaimerItem(
                        t.about.disclaimerItem1Title,
                        t.about.disclaimerItem1Content,
                      ),
                      _DisclaimerItem(
                        t.about.disclaimerItem2Title,
                        t.about.disclaimerItem2Content,
                      ),
                      _DisclaimerItem(
                        t.about.disclaimerItem3Title,
                        t.about.disclaimerItem3Content,
                      ),
                      _DisclaimerItem(
                        t.about.disclaimerItem4Title,
                        t.about.disclaimerItem4Content,
                      ),
                      _DisclaimerItem(
                        t.about.disclaimerItem5Title,
                        t.about.disclaimerItem5Content,
                      ),
                      _DisclaimerItem(
                        t.about.disclaimerItem6Title,
                        t.about.disclaimerItem6Content,
                      ),
                      _DisclaimerItem(
                        t.about.disclaimerItem7Title,
                        t.about.disclaimerItem7Content,
                      ),
                      _DisclaimerItem(
                        t.about.disclaimerItem8Title,
                        t.about.disclaimerItem8Content,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        t.about.disclaimerImportant,
                        style: const TextStyle(
                          color: kAccentColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        t.about.disclaimerImportantContent,
                        style: const TextStyle(
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
