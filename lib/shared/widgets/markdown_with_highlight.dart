import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:gpt_markdown/custom_widgets/markdown_config.dart' show GptMarkdownConfig;
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/atom-one-dark-reasonable.dart';
import '../../icons/lucide_adapter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:convert';
import '../../utils/sandbox_path_resolver.dart';
import '../../features/chat/pages/image_viewer_page.dart';
import 'snackbar.dart';
import 'mermaid_bridge.dart';
import 'package:Kelivo/l10n/app_localizations.dart';
import 'package:Kelivo/theme/theme_factory.dart' show kDefaultFontFamilyFallback;

/// gpt_markdown with custom code block highlight and inline code styling.
class MarkdownWithCodeHighlight extends StatelessWidget {
  const MarkdownWithCodeHighlight({
    super.key,
    required this.text,
    this.onCitationTap,
  });

  final String text;
  final void Function(String id)? onCitationTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final imageUrls = _extractImageUrls(text);

    final normalized = _preprocessFences(text);
    // Base text style: increase line-height and slightly adjust letter-spacing for readability
    final baseTextStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 15.5,
          height: 1.55,
          letterSpacing: _isZh(context) ? 0.0 : 0.05,
          color: null, // let components decide foreground where needed
          // fontWeight: FontWeight.w400, // keep assistant/body text normal weight
        );

    // Replace default components and add our own where needed
    final components = List<MarkdownComponent>.from(MarkdownComponent.globalComponents);
    final hrIdx = components.indexWhere((c) => c is HrLine);
    if (hrIdx != -1) components[hrIdx] = SoftHrLine();
    final bqIdx = components.indexWhere((c) => c is BlockQuote);
    if (bqIdx != -1) components[bqIdx] = ModernBlockQuote();
    final cbIdx = components.indexWhere((c) => c is CheckBoxMd);
    if (cbIdx != -1) components[cbIdx] = ModernCheckBoxMd();
    final rbIdx = components.indexWhere((c) => c is RadioButtonMd);
    if (rbIdx != -1) components[rbIdx] = ModernRadioMd();
    // Prepend custom renderers in priority order (fence first)
    components.insert(0, LabelValueLineMd());
    // Ensure LaTeX formulas scroll instead of overflow
    components.insert(0, InlineLatexScrollableMd());
    components.insert(0, LatexBlockScrollableMd());
    components.insert(0, AtxHeadingMd());
    components.insert(0, FencedCodeBlockMd());
    return GptMarkdown(
      normalized,
      style: baseTextStyle,
      followLinkColor: true,
      // Disable built-in $...$ LaTeX so our custom scrollable handlers take over
      useDollarSignsForLatex: false,
      onLinkTap: (url, title) => _handleLinkTap(context, url),
      components: components,
      imageBuilder: (ctx, url) {
        final imgs = imageUrls.isNotEmpty ? imageUrls : [url];
        final idx = imgs.indexOf(url);
        final initial = idx >= 0 ? idx : 0;
        final provider = _imageProviderFor(url);
        return GestureDetector(
          onTap: () {
            Navigator.of(ctx).push(PageRouteBuilder(
              pageBuilder: (_, __, ___) => ImageViewerPage(images: imgs, initialIndex: initial),
              transitionDuration: const Duration(milliseconds: 360),
              reverseTransitionDuration: const Duration(milliseconds: 280),
              transitionsBuilder: (context, anim, sec, child) {
                final curved = CurvedAnimation(
                  parent: anim,
                  curve: Curves.easeOutCubic,
                  reverseCurve: Curves.easeInCubic,
                );
                return FadeTransition(
                  opacity: curved,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.02),
                      end: Offset.zero,
                    ).animate(curved),
                    child: child,
                  ),
                );
              },
            ));
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image(
                  image: provider,
                  width: constraints.maxWidth,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) => const Icon(Icons.broken_image),
                ),
              );
            },
          ),
        );
      },
      linkBuilder: (ctx, span, url, style) {
        final label = span.toPlainText().trim();
        // Special handling: [citation](index:id)
        if (label.toLowerCase() == 'citation') {
          final parts = url.split(':');
          if (parts.length == 2) {
            final indexText = parts[0].trim();
            final id = parts[1].trim();
            final cs = Theme.of(ctx).colorScheme;
            return GestureDetector(
              onTap: () {
                if (onCitationTap != null && id.isNotEmpty) {
                  onCitationTap!(id);
                } else {
                  // Fallback: do nothing
                }
              },
              child: Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  indexText,
                  style: const TextStyle(fontSize: 12, height: 1.0),
                ),
              ),
            );
          }
        }
        // Default link appearance
        final cs = Theme.of(ctx).colorScheme;
        return Text(
          span.toPlainText(),
          style: style.copyWith(
            color: cs.primary,
            decoration: TextDecoration.none,
          ),
          textAlign: TextAlign.start,
          textScaler: MediaQuery.of(ctx).textScaler,
        );
      },
      orderedListBuilder: (ctx, no, child, cfg) {
        final style = (cfg.style ?? const TextStyle()).copyWith(
          fontWeight: FontWeight.w400, // normal weight
        );
        return Directionality(
          textDirection: cfg.textDirection,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textBaseline: TextBaseline.alphabetic,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 6, end: 6),
                child: Text("$no.", style: style),
              ),
              Flexible(child: child),
            ],
          ),
        );
      },
      tableBuilder: (ctx, rows, style, cfg) {
        final cs = Theme.of(ctx).colorScheme;
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final borderColor = cs.outlineVariant.withOpacity(isDark ? 0.22 : 0.28);
        final headerBg = cs.primary.withOpacity(isDark ? 0.10 : 0.08);
        final headerStyle = (style).copyWith(fontWeight: FontWeight.w600);

        int maxCol = 0;
        for (final r in rows) {
          if (r.fields.length > maxCol) maxCol = r.fields.length;
        }

        Widget cell(String text, TextAlign align, {bool header = false, bool lastCol = false, bool lastRow = false}) {
          // Render inline markdown (bold, code, links) inside table cells
          final innerCfg = cfg.copyWith(style: header ? headerStyle : style);
          final children = MarkdownComponent.generate(ctx, text, innerCfg, true);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                right: lastCol ? BorderSide.none : BorderSide(color: borderColor, width: 0.5),
                bottom: lastRow ? BorderSide.none : BorderSide(color: borderColor, width: 0.5),
              ),
            ),
            child: Align(
              alignment: () {
                switch (align) {
                  case TextAlign.center:
                    return Alignment.center;
                  case TextAlign.right:
                    return Alignment.centerRight;
                  default:
                    return Alignment.centerLeft;
                }
              }(),
              child: RichText(
                text: TextSpan(style: header ? headerStyle : style, children: children),
                textAlign: align,
                textScaler: MediaQuery.of(ctx).textScaler,
              ),
            ),
          );
        }

        final table = Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            if (rows.isNotEmpty)
              TableRow(
                decoration: BoxDecoration(
                  color: headerBg,
                  border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
                ),
                children: List.generate(maxCol, (i) {
                  final f = i < rows.first.fields.length ? rows.first.fields[i] : null;
                  final txt = f?.data ?? '';
                  final align = f?.alignment ?? TextAlign.left;
                  return cell(txt, align, header: true, lastCol: i == maxCol - 1, lastRow: false);
                }),
              ),
            for (int r = 1; r < rows.length; r++)
              TableRow(
                children: List.generate(maxCol, (c) {
                  final f = c < rows[r].fields.length ? rows[r].fields[c] : null;
                  final txt = f?.data ?? '';
                  final align = f?.alignment ?? TextAlign.left;
                  return cell(txt, align, lastCol: c == maxCol - 1, lastRow: r == rows.length - 1);
                }),
              ),
          ],
        );

        return SelectionContainer.disabled(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            primary: false,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surface,
                  border: Border.all(color: borderColor, width: 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: table,
              ),
            ),
          ),
        );
      },
      // Inline `code` styling via highlightBuilder in gpt_markdown
      highlightBuilder: (ctx, inline, style) {
        String softened = _softBreakInline(inline);
        final bg = isDark ? Colors.white12 : const Color(0xFFF1F3F5);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.22)),
          ),
          child: Text(
            softened,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.4,
            ).copyWith(color: Theme.of(context).colorScheme.onSurface),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        );
      },
      // Fenced code block styling via codeBuilder (with collapse/expand)
      codeBuilder: (ctx, name, code, closed) {
        final lang = name.trim();
        if (lang.toLowerCase() == 'mermaid') {
          return _MermaidBlock(code: code);
        }
        return _CollapsibleCodeBlock(language: lang, code: code);
      },
    );
  }

  static String _displayLanguage(BuildContext context, String? raw) {
    final zh = _isZh(context);
    final t = raw?.trim();
    if (t != null && t.isNotEmpty) return t;
    return zh ? '代码' : 'Code';
  }

  static bool _isZh(BuildContext context) => Localizations.localeOf(context).languageCode == 'zh';

  static Map<String, TextStyle> _transparentBgTheme(Map<String, TextStyle> base) {
    final m = Map<String, TextStyle>.from(base);
    final root = base['root'];
    if (root != null) {
      m['root'] = root.copyWith(backgroundColor: Colors.transparent);
    } else {
      m['root'] = const TextStyle(backgroundColor: Colors.transparent);
    }
    return m;
  }

  static String? _normalizeLanguage(String? lang) {
    if (lang == null || lang.trim().isEmpty) return null;
    final l = lang.trim().toLowerCase();
    switch (l) {
      case 'js':
      case 'javascript':
        return 'javascript';
      case 'ts':
      case 'typescript':
        return 'typescript';
      case 'sh':
      case 'zsh':
      case 'bash':
      case 'shell':
        return 'bash';
      case 'yml':
        return 'yaml';
      case 'py':
      case 'python':
        return 'python';
      case 'rb':
      case 'ruby':
        return 'ruby';
      case 'kt':
      case 'kotlin':
        return 'kotlin';
      case 'java':
        return 'java';
      case 'c#':
      case 'cs':
      case 'csharp':
        return 'csharp';
      case 'objc':
      case 'objectivec':
        return 'objectivec';
      case 'swift':
        return 'swift';
      case 'go':
      case 'golang':
        return 'go';
      case 'php':
        return 'php';
      case 'dart':
        return 'dart';
      case 'json':
        return 'json';
      case 'html':
        return 'xml';
      case 'md':
      case 'markdown':
        return 'markdown';
      case 'sql':
        return 'sql';
      default:
        return l; // try as-is
    }
  }

  static String _preprocessFences(String input) {
    // Normalize newlines to simplify regex handling
    var out = input.replaceAll('\r\n', '\n');

    // 1) Move fenced code from list lines to the next line: "* ```lang" -> "*\n```lang"
    final bulletFence = RegExp(r"^(\s*(?:[*+-]|\d+\.)\s+)```([^\s`]*)\s*$", multiLine: true);
    out = out.replaceAllMapped(bulletFence, (m) => "${m[1]}\n```${m[2]}" );

    // 2) Dedent opening fences: leading spaces before ```lang
    final dedentOpen = RegExp(r"^[ \t]+```([^\n`]*)\s*$", multiLine: true);
    out = out.replaceAllMapped(dedentOpen, (m) => "```${m[1]}" );

    // 3) Dedent closing fences: leading spaces before ```
    final dedentClose = RegExp(r"^[ \t]+```\s*$", multiLine: true);
    out = out.replaceAllMapped(dedentClose, (m) => "```" );

    // 4) Ensure closing fences are on their own line: transform "} ```" or "}```" into "}\n```"
    final inlineClosing = RegExp(r"([^\r\n`])```(?=\s*(?:\r?\n|$))");
    out = out.replaceAllMapped(inlineClosing, (m) => "${m[1]}\n```");

    // 5) Disambiguate Setext vs HR after label-value lines:
    // If a line of only dashes follows a bold label line (e.g., "**作者:** 张三"),
    // insert a blank line so it's treated as an HR, not a Setext heading underline.
    final labelThenDash = RegExp(r"^(\*\*[^\n*]+\*\*.*)\n(\s*-{3,}\s*$)", multiLine: true);
    out = out.replaceAllMapped(labelThenDash, (m) => "${m[1]}\n\n${m[2]}");

    // 6) Allow ATX headings starting with enumerations like "## 1.引言" or "## 1. 引言"
    // Insert a zero-width non-joiner after the dot to prevent list parsing without changing visual text.
    final atxEnum = RegExp(r"^(\s{0,3}#{1,6}\s+\d+)\.(\s*)(\S)", multiLine: true);
    out = out.replaceAllMapped(atxEnum, (m) => "${m[1]}.\u200C${m[2]}${m[3]}");

    // 7) Auto-close an unmatched opening code fence at EOF
    final fenceAtBol = RegExp(r"^\s*```", multiLine: true);
    final count = fenceAtBol.allMatches(out).length;
    if (count % 2 == 1) {
      if (!out.endsWith('\n')) out += '\n';
      out += '```';
    }

    return out;
  }

  static String _softBreakInline(String input) {
    // Insert zero-width break for inline code segments with long tokens.
    if (input.length < 60) return input;
    final buf = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      buf.write(input[i]);
      if ((i + 1) % 24 == 0) buf.write('\u200B');
    }
    return buf.toString();
  }

  Future<void> _handleLinkTap(BuildContext context, String url) async {
    Uri uri;
    try {
      uri = _normalizeUrl(url);
    } catch (_) {
      showAppSnackBar(
        context,
        message: _isZh(context) ? '无效链接' : 'Invalid link',
        type: NotificationType.error,
      );
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!ok && context.mounted) {
      showAppSnackBar(
        context,
        message: _isZh(context) ? '无法打开链接' : 'Cannot open link',
        type: NotificationType.error,
      );
    }
  }

  Uri _normalizeUrl(String url) {
    var u = url.trim();
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(u)) {
      u = 'https://'+u;
    }
    return Uri.parse(u);
  }

  static List<String> _extractImageUrls(String md) {
    final re = RegExp(r"!\[[^\]]*\]\(([^)\s]+)\)");
    return re
        .allMatches(md)
        .map((m) => (m.group(1) ?? '').trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static ImageProvider _imageProviderFor(String src) {
    if (src.startsWith('http://') || src.startsWith('https://')) {
      return NetworkImage(src);
    }
    if (src.startsWith('data:')) {
      try {
        final base64Marker = 'base64,';
        final idx = src.indexOf(base64Marker);
        if (idx != -1) {
          final b64 = src.substring(idx + base64Marker.length);
          return MemoryImage(base64Decode(b64));
        }
      } catch (_) {}
    }
    final fixed = SandboxPathResolver.fix(src);
    return FileImage(File(fixed));
  }
}

class _CollapsibleCodeBlock extends StatefulWidget {
  final String language;
  final String code;

  const _CollapsibleCodeBlock({required this.language, required this.code});

  @override
  State<_CollapsibleCodeBlock> createState() => _CollapsibleCodeBlockState();
}

class _CollapsibleCodeBlockState extends State<_CollapsibleCodeBlock> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bodyBg = isDark ? Colors.white10 : const Color(0xFFF7F7F9);
    final Color headerBg = isDark ? Colors.white12 : const Color(0xFFE9ECF1);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header layout: language + copy + expand/collapse icon
          Material(
            color: headerBg,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.25), width: 0.8),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 2),
                    Text(
                      MarkdownWithCodeHighlight._displayLanguage(context, widget.language),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: cs.secondary,
                        height: 1.0,
                      ),
                    ),
                    const Spacer(),
                    // Copy button stays functional; tapping it won't toggle parent
                    IconButton(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: widget.code));
                        if (mounted) {
                          showAppSnackBar(
                            context,
                            message: AppLocalizations.of(context)!.chatMessageWidgetCopiedToClipboard,
                            type: NotificationType.success,
                          );
                        }
                      },
                      icon: Icon(
                        Lucide.Copy,
                        size: 16,
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                      tooltip: AppLocalizations.of(context)!.shareProviderSheetCopyButton,
                      visualDensity: VisualDensity.compact,
                      iconSize: 16,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expanded ? Lucide.ChevronDown : Lucide.ChevronRight,
                      size: 16,
                      color: cs.onSurface.withOpacity(0.7),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded)
            Container(
              width: double.infinity,
              color: bodyBg,
              padding: const EdgeInsets.fromLTRB(10, 6, 6, 10),
            child: SelectionContainer.disabled(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                primary: false,
                child: HighlightView(
                  widget.code,
                  language: MarkdownWithCodeHighlight._normalizeLanguage(widget.language) ?? 'plaintext',
                  theme: MarkdownWithCodeHighlight._transparentBgTheme(
                    isDark ? atomOneDarkReasonableTheme : githubTheme,
                    ),
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
            ),
            ),
        ],
      ),
    );
  }
}

class _MermaidBlock extends StatefulWidget {
  final String code;
  const _MermaidBlock({required this.code});

  @override
  State<_MermaidBlock> createState() => _MermaidBlockState();
}

class _MermaidBlockState extends State<_MermaidBlock> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bodyBg = isDark ? Colors.white10 : const Color(0xFFF7F7F9);
    final Color headerBg = isDark ? Colors.white12 : const Color(0xFFE9ECF1);

    // Build theme variables mapping for Mermaid from Material ColorScheme
    String hex(Color c) {
      final v = c.value & 0xFFFFFFFF;
      final r = (v >> 16) & 0xFF;
      final g = (v >> 8) & 0xFF;
      final b = v & 0xFF;
      return '#'
          '${r.toRadixString(16).padLeft(2, '0')}'
          '${g.toRadixString(16).padLeft(2, '0')}'
          '${b.toRadixString(16).padLeft(2, '0')}'
          .toUpperCase();
    }

    final themeVars = <String, String>{
      'primaryColor': hex(cs.primary),
      'primaryTextColor': hex(cs.onPrimary),
      'primaryBorderColor': hex(cs.primary),
      'secondaryColor': hex(cs.secondary),
      'secondaryTextColor': hex(cs.onSecondary),
      'secondaryBorderColor': hex(cs.secondary),
      'tertiaryColor': hex(cs.tertiary),
      'tertiaryTextColor': hex(cs.onTertiary),
      'tertiaryBorderColor': hex(cs.tertiary),
      'background': hex(cs.background),
      'mainBkg': hex(cs.primaryContainer),
      'secondBkg': hex(cs.secondaryContainer),
      'lineColor': hex(cs.onBackground),
      'textColor': hex(cs.onBackground),
      'nodeBkg': hex(cs.surface),
      'nodeBorder': hex(cs.primary),
      'clusterBkg': hex(cs.surface),
      'clusterBorder': hex(cs.primary),
      'actorBorder': hex(cs.primary),
      'actorBkg': hex(cs.surface),
      'actorTextColor': hex(cs.onBackground),
      'actorLineColor': hex(cs.primary),
      'taskBorderColor': hex(cs.primary),
      'taskBkgColor': hex(cs.primary),
      'taskTextLightColor': hex(cs.onPrimary),
      'taskTextDarkColor': hex(cs.onBackground),
      'labelColor': hex(cs.onBackground),
      'errorBkgColor': hex(cs.error),
      'errorTextColor': hex(cs.onError),
    };

    final handle = createMermaidView(widget.code, isDark, themeVars: themeVars);
    final mermaidView = handle?.widget;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Material(
            color: headerBg,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.25), width: 0.8),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'mermaid',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: cs.secondary,
                        height: 1.0,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: widget.code));
                        if (mounted) {
                          showAppSnackBar(
                            context,
                            message: AppLocalizations.of(context)!.chatMessageWidgetCopiedToClipboard,
                            type: NotificationType.success,
                          );
                        }
                      },
                      icon: Icon(
                        Lucide.Copy,
                        size: 16,
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                      tooltip: AppLocalizations.of(context)!.shareProviderSheetCopyButton,
                      visualDensity: VisualDensity.compact,
                      iconSize: 16,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: EdgeInsets.zero,
                    ),
                    if (handle != null) ...[
                      const SizedBox(width: 2),
                      IconButton(
                        onPressed: () async {
                          final ok = await handle.exportPng();
                          if (!mounted) return;
                          if (!ok) {
                            final l10n = AppLocalizations.of(context)!;
                            showAppSnackBar(
                              context,
                              message: l10n.mermaidExportFailed,
                              type: NotificationType.error,
                            );
                          }
                        },
                        icon: Icon(
                          Lucide.Download,
                          size: 16,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                        tooltip: AppLocalizations.of(context)!.mermaidExportPng,
                        visualDensity: VisualDensity.compact,
                        iconSize: 16,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                    const SizedBox(width: 4),
                    Icon(
                      _expanded ? Lucide.ChevronDown : Lucide.ChevronRight,
                      size: 16,
                      color: cs.onSurface.withOpacity(0.7),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded)
            Container(
              width: double.infinity,
              color: bodyBg,
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (mermaidView != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: mermaidView,
                    ),
                  ] else ...[
                    // Fallback: show raw code and a preview button (opens browser)
                    SelectionContainer.disabled(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: HighlightView(
                          widget.code,
                          language: 'plaintext',
                          theme: MarkdownWithCodeHighlight._transparentBgTheme(
                            Theme.of(context).brightness == Brightness.dark
                                ? atomOneDarkReasonableTheme
                                : githubTheme,
                          ),
                          padding: EdgeInsets.zero,
                          textStyle: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _openMermaidPreviewInBrowser(context, widget.code,
                            Theme.of(context).brightness == Brightness.dark),
                        icon: Icon(Lucide.Eye, size: 16),
                        label: Text(AppLocalizations.of(context)!.mermaidPreviewOpen),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openMermaidPreviewInBrowser(BuildContext context, String code, bool dark) async {
    final htmlStr = _buildMermaidHtml(code, dark);
    final uri = Uri.dataFromString(htmlStr, mimeType: 'text/html', encoding: utf8);
    try {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      showAppSnackBar(
        context,
        message: l10n.mermaidPreviewOpenFailed,
        type: NotificationType.error,
      );
    }
  }

  String _buildMermaidHtml(String code, bool dark) {
    final bg = dark ? '#111111' : '#ffffff';
    final fg = dark ? '#eaeaea' : '#222222';
    final escaped = code
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes, maximum-scale=5.0">
    <title>Mermaid Preview</title>
    <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
    <style>
      body{ margin:0; padding:12px; background:${bg}; color:${fg}; }
      .wrap{ max-width: 1000px; margin: 0 auto; }
      .mermaid{ text-align:center; }
    </style>
  </head>
  <body>
    <div class="wrap">
      <div class="mermaid">${escaped}</div>
    </div>
    <script>
      mermaid.initialize({ startOnLoad:false, theme: '${dark ? 'dark' : 'default'}', securityLevel:'loose' });
      mermaid.run({ querySelector: '.mermaid' });
    </script>
  </body>
</html>
''';
  }
}

// Softer horizontal rule: shorter width and subtle color
class SoftHrLine extends BlockMd {
  @override
  String get expString => (r"^\s*(?:-{3,}|⸻)\s*$");

  @override
  Widget build(BuildContext context, String text, GptMarkdownConfig config) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final lineWidth = (width * 0.42).clamp(120.0, 420.0);
    final color = cs.outlineVariant.withOpacity(0.9);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          width: lineWidth,
          height: 1,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}

// Robust fenced code block that takes precedence over other blocks
class FencedCodeBlockMd extends BlockMd {
  @override
  // Match ```lang\n...\n``` at line starts. Non-greedy to stop at first closing fence.
  String get expString => (r"^\s*```([^\n`]*)\s*\n([\s\S]*?)\n```$");

  @override
  Widget build(BuildContext context, String text, GptMarkdownConfig config) {
    final m = exp.firstMatch(text);
    if (m == null) return const SizedBox.shrink();
    final lang = (m.group(1) ?? '').trim();
    final code = (m.group(2) ?? '');
    if (lang.toLowerCase() == 'mermaid') {
      return _MermaidBlock(code: code);
    }
    return _CollapsibleCodeBlock(language: lang, code: code);
  }
}

/// Scrollable LaTeX block to prevent overflow when equations are very wide
class LatexBlockScrollableMd extends BlockMd {
  @override
  // Match either $$...$$ or \[...\] as standalone block
  String get expString => (r"^(?:\s*\$\$([\s\S]*?)\$\$\s*|\s*\\\[([\s\S]*?)\\\]\s*)$");

  @override
  Widget build(BuildContext context, String text, GptMarkdownConfig config) {
    final m = exp.firstMatch(text.trim());
    if (m == null) return const SizedBox.shrink();
    final body = ((m.group(1) ?? m.group(2) ?? '')).trim();
    if (body.isEmpty) return const SizedBox.shrink();

    final math = Math.tex(
      body,
      textStyle: (config.style ?? const TextStyle()),
    );
    // Wrap in horizontal scroll to avoid overflow; no extra background
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SelectionContainer.disabled(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              primary: false,
              child: math,
            ),
          );
        },
      ),
    );
  }
}

/// Inline LaTeX `$...$` rendered in a horizontally scrollable bubble to avoid line overflow
class InlineLatexScrollableMd extends InlineMd {
  @override
  // Match single-dollar $...$ or \(...\) inline math (avoid $$ block)
  RegExp get exp => RegExp(r"(?:(?<!\$)\$([^\$\n]+?)\$(?!\$)|\\\(([^\n]+?)\\\))");

  @override
  InlineSpan span(BuildContext context, String text, GptMarkdownConfig config) {
    final m = exp.firstMatch(text);
    if (m == null) return TextSpan(text: text, style: config.style);
    final body = ((m.group(1) ?? m.group(2) ?? '')).trim();
    if (body.isEmpty) return TextSpan(text: text, style: config.style);
    final math = Math.tex(
      body,
      mathStyle: MathStyle.text,
      textStyle: () {
        final base = (config.style ?? const TextStyle());
        final baseSize = base.fontSize ?? 15.5;
        // Slightly enlarge inline math for readability
        return base.copyWith(fontSize: baseSize * 1.2);
      }(),
    );
    // Wrap in horizontal scroll to prevent line overflow; no extra background
    final w = LayoutBuilder(
      builder: (context, constraints) {
        return SelectionContainer.disabled(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            primary: false,
            child: math,
          ),
        );
      },
    );

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: w,
    );
  }
}

// Balanced ATX-style headings (#, ##, ###, …) with consistent spacing and typography
class AtxHeadingMd extends BlockMd {
  @override
  // Restrict heading content to a single line to avoid swallowing
  // subsequent blocks (e.g., fenced code) when the engine builds
  // the regex with dotAll=true. Using [^\n]+ keeps it line-bound.
  String get expString => (r"^\s{0,3}(#{1,6})\s+([^\n]+?)(?:\s+#+\s*)?$");

  @override
  Widget build(BuildContext context, String text, GptMarkdownConfig config) {
    final m = exp.firstMatch(text.trim());
    if (m == null) return const SizedBox.shrink();
    final hashes = m.group(1) ?? '#';
    final raw = (m.group(2) ?? '').trim();
    final lvl = hashes.length;
    final level = lvl < 1 ? 1 : (lvl > 6 ? 6 : lvl);

    final innerCfg = config.copyWith(style: const TextStyle());
    final inner = TextSpan(children: MarkdownComponent.generate(context, raw, innerCfg, true));
    final style = _headingTextStyle(context, config, level);
    // Slightly tighter spacing between headings and body
    final top = switch (level) { 1 => 2.0, 2 => 2.0, _ => 2.0 };
    final bottom = switch (level) { 1 => 2.0, 2 => 2.0, 3 => 2.0, _ => 2.0 };

    return Padding(
      padding: EdgeInsets.only(top: top, bottom: bottom),
      child: RichText(
        text: TextSpan(style: style, children: [inner]),
        textScaler: MediaQuery.of(context).textScaler,
        textAlign: TextAlign.start,
      ),
    );
  }

  TextStyle _headingTextStyle(BuildContext ctx, GptMarkdownConfig cfg, int level) {
    final t = Theme.of(ctx).textTheme;
    final cs = Theme.of(ctx).colorScheme;
    final isZh = MarkdownWithCodeHighlight._isZh(ctx);
    // Start from Material styles but tighten sizes for balance with body text
    TextStyle base;
    // Explicit sizes ensure visible contrast over the body (16.0)
    switch (level) {
      case 1:
        base = const TextStyle(fontSize: 24);
        break;
      case 2:
        base = const TextStyle(fontSize: 20);
        break;
      case 3:
        base = const TextStyle(fontSize: 18);
        break;
      case 4:
        base = const TextStyle(fontSize: 16);
        break;
      case 5:
        base = const TextStyle(fontSize: 15);
        break;
      default:
        base = const TextStyle(fontSize: 14);
    }
    final weight = switch (level) { 1 => FontWeight.w700, 2 => FontWeight.w600, 3 => FontWeight.w600, _ => FontWeight.w500 };
    final ls = switch (level) { 1 => isZh ? 0.0 : 0.1, 2 => isZh ? 0.0 : 0.08, _ => isZh ? 0.0 : 0.05 };
    final h = switch (level) { 1 => 1.25, 2 => 1.3, _ => 1.35 };
    return base.copyWith(
      fontWeight: weight,
      height: h,
      letterSpacing: ls,
      color: cs.onSurface,
      fontFamilyFallback: kDefaultFontFamilyFallback,
    );
  }
}

// Setext-style headings (underlines with === or ---)
class SetextHeadingMd extends BlockMd {
  @override
  String get expString => (r"^(.+?)\n(=+|-+)\s*$");

  @override
  Widget build(BuildContext context, String text, GptMarkdownConfig config) {
    final m = exp.firstMatch(text.trimRight());
    if (m == null) return const SizedBox.shrink();
    final title = (m.group(1) ?? '').trim();
    final underline = (m.group(2) ?? '').trim();
    final level = underline.startsWith('=') ? 1 : 2;

    final innerCfg = config.copyWith(style: const TextStyle());
    final inner = TextSpan(children: MarkdownComponent.generate(context, title, innerCfg, true));
    final style = AtxHeadingMd()._headingTextStyle(context, config, level);
    // Match the tighter spacing used in ATX headings
    final top = level == 1 ? 10.0 : 9.0;
    final bottom = 6.0;

    return Padding(
      padding: EdgeInsets.only(top: top, bottom: bottom),
      child: RichText(
        text: TextSpan(style: style, children: [inner]),
        textScaler: MediaQuery.of(context).textScaler,
        textAlign: TextAlign.start,
      ),
    );
  }
}

// Label-value strong lines like "**作者:** 张三" should not render as heading-sized text
class LabelValueLineMd extends InlineMd {
  @override
  bool get inline => false;

  @override
  // Match either "**标签:** 值" (冒号在加粗内) 或 "**标签**: 值"（冒号在加粗外），支持全角/半角冒号
  RegExp get exp => RegExp(r"(?:(?:^|\n)\*\*([^*]+?)\*\*\s*:\s*.+$)", multiLine: true);

  @override
  InlineSpan span(BuildContext context, String text, GptMarkdownConfig config) {
    final match = exp.firstMatch(text);
    if (match == null) return TextSpan(text: text, style: config.style);
    final label = (match.group(1) ?? '').trim();
    final rest = text.substring(match.end - (text.endsWith('\n') ? 1 : 0)).trim();

    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final labelStyle = (t.bodyMedium ?? const TextStyle(fontSize: 14)).copyWith(
      fontWeight: FontWeight.w700,
      color: cs.onSurface,
    );
    final valueStyle = (t.bodyMedium ?? const TextStyle(fontSize: 14)).copyWith(
      fontWeight: FontWeight.w500,
      color: cs.onSurface.withOpacity(0.92),
    );
       // Split into label/value while preserving the rest of the line
    final colonIndex = text.indexOf(':');
    final prefix = text.substring(0, colonIndex + 1);
    final value = text.substring(colonIndex + 1).trim();

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: RichText(
          text: TextSpan(children: [
            TextSpan(text: prefix.replaceAll('**', ''), style: labelStyle),
            const TextSpan(text: ' '),
            TextSpan(text: value, style: valueStyle),
          ]),
          textScaler: MediaQuery.of(context).textScaler,
        ),
      ),
    );
  }
}

// Modern, app-styled block quote with soft background and accent border
class ModernBlockQuote extends InlineMd {
  @override
  bool get inline => false;

  @override
  RegExp get exp => RegExp(
    r"(?:(?:^)\ *>[^\n]+)(?:(?:\n)\ *>[^\n]+)*",
    dotAll: true,
    multiLine: true,
  );

  @override
  InlineSpan span(BuildContext context, String text, GptMarkdownConfig config) {
    final match = exp.firstMatch(text);
    final m = match?[0] ?? '';
    final sb = StringBuffer();
    for (final line in m.split('\n')) {
      if (RegExp(r'^\ *>').hasMatch(line)) {
        var sub = line.trimLeft();
        sub = sub.substring(1); // remove '>'
        if (sub.startsWith(' ')) sub = sub.substring(1);
        sb.writeln(sub);
      } else {
        sb.writeln(line);
      }
    }
    final data = sb.toString().trim();
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = cs.primaryContainer.withOpacity(isDark ? 0.18 : 0.12);
    final accent = cs.primary.withOpacity(isDark ? 0.90 : 0.80);

    final inner = TextSpan(children: MarkdownComponent.generate(context, data, config, true));
    final child = Directionality(
      textDirection: config.textDirection,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: accent, width: 3)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: config.getRich(inner),
        ),
      ),
    );

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: child,
    );
  }
}

// Modern task checkbox: square with subtle border, primary check on done
class ModernCheckBoxMd extends BlockMd {
  @override
  String get expString => (r"\[((?:\x|\ ))\]\ (\S[^\n]*?)$");

  @override
  Widget build(BuildContext context, String text, GptMarkdownConfig config) {
    final match = exp.firstMatch(text.trim());
    final checked = (match?[1] == 'x');
    final content = match?[2] ?? '';
    final cs = Theme.of(context).colorScheme;

    final contentStyle = (config.style ?? const TextStyle()).copyWith(
      decoration: checked ? TextDecoration.lineThrough : null,
      color: (config.style?.color ?? cs.onSurface).withOpacity(checked ? 0.75 : 1.0),
    );

    final child = MdWidget(
      context,
      content,
      false,
      config: config.copyWith(style: contentStyle),
    );

    return Directionality(
      textDirection: config.textDirection,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textBaseline: TextBaseline.alphabetic,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 6, end: 8),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: cs.outlineVariant.withOpacity(0.8), width: 1),
                color: checked ? cs.primary.withOpacity(0.12) : Colors.transparent,
              ),
              child: checked
                  ? Icon(Icons.check, size: 14, color: cs.primary)
                  : null,
            ),
          ),
          Flexible(child: child),
        ],
      ),
    );
  }
}

// Modern radio (optional): circle with primary dot when selected
class ModernRadioMd extends BlockMd {
  @override
  String get expString => (r"\(((?:\x|\ ))\)\ (\S[^\n]*)$");

  @override
  Widget build(BuildContext context, String text, GptMarkdownConfig config) {
    final match = exp.firstMatch(text.trim());
    final selected = (match?[1] == 'x');
    final content = match?[2] ?? '';
    final cs = Theme.of(context).colorScheme;

    final contentStyle = (config.style ?? const TextStyle()).copyWith(
      color: (config.style?.color ?? cs.onSurface).withOpacity(selected ? 0.95 : 1.0),
    );

    final child = MdWidget(
      context,
      content,
      false,
      config: config.copyWith(style: contentStyle),
    );

    return Directionality(
      textDirection: config.textDirection,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textBaseline: TextBaseline.alphabetic,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 6, end: 8),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: cs.outlineVariant.withOpacity(0.8), width: 1),
              ),
              child: selected
                  ? Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              )
                  : null,
            ),
          ),
          Flexible(child: child),
        ],
      ),
    );
  }
}
