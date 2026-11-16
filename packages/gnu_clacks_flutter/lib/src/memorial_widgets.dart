import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:gnu_clacks_core/gnu_clacks_core.dart';

import 'localizations.dart';
import 'signal.dart';
import 'theme.dart';

/// A responsive gallery screen. Only display-enabled definitions are rendered.
class MemorialGallery extends StatelessWidget {
  const MemorialGallery({
    super.key,
    required this.registry,
    this.appearance,
    this.showIntroduction = true,
    this.animate = true,
    this.displayComparator,
    this.onOpenMemorial,
    this.onOpenCredits,
  });
  final MemorialRegistry registry;
  final ClacksAppearance? appearance;
  final Comparator<Memorial>? displayComparator;
  final bool showIntroduction;
  final bool animate;
  final ValueChanged<Memorial>? onOpenMemorial;
  final VoidCallback? onOpenCredits;

  @override
  Widget build(BuildContext context) => _TributeScope(
    appearance: appearance,
    child: Builder(
      builder: (context) {
        final strings = ClacksLocalizations.of(context);
        final tokens = ClacksTheme.of(context);
        final entries = registry.displayEntries.toList();
        if (displayComparator != null) entries.sort(displayComparator);
        void open(Memorial entry) {
          if (onOpenMemorial != null) {
            onOpenMemorial!(entry);
            return;
          }
          final theme = Theme.of(context);
          Widget detail(BuildContext _) => Theme(
            data: theme,
            child: MemorialDetailScreen(
              registry: registry,
              memorialId: entry.id,
              animate: animate,
              onOpenCredits: onOpenCredits,
            ),
          );
          Navigator.of(context).push(
            (!animate || MediaQuery.disableAnimationsOf(context))
                ? PageRouteBuilder<void>(
                    pageBuilder: (context, animation, secondary) =>
                        detail(context),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  )
                : MaterialPageRoute<void>(builder: detail),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(strings.title)),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(tokens.safeSpacing),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showIntroduction) ...[
                        Text(
                          'GNU',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                letterSpacing: 5,
                                color: tokens.accentOn(tokens.background),
                              ),
                        ),
                        const SizedBox(height: 12),
                        Semantics(
                          header: true,
                          child: Text(
                            strings.introduction,
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: Text(
                            strings.introductionBody,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        SizedBox(height: tokens.safeSpacing * 1.5),
                      ],
                      if (entries.isEmpty)
                        _EmptyState(
                          title: strings.emptyTitle,
                          body: strings.emptyBody,
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final textScale =
                                MediaQuery.textScalerOf(context).scale(16) / 16;
                            final minimum =
                                290 * math.max(1, textScale.clamp(1, 2));
                            final columns = math.max(
                              1,
                              ((constraints.maxWidth + tokens.safeSpacing) /
                                      (minimum + tokens.safeSpacing))
                                  .floor(),
                            );
                            final width =
                                (constraints.maxWidth -
                                    (columns - 1) * tokens.safeSpacing) /
                                columns;
                            return FocusTraversalGroup(
                              policy: ReadingOrderTraversalPolicy(),
                              child: Wrap(
                                spacing: tokens.safeSpacing,
                                runSpacing: tokens.safeSpacing,
                                children: [
                                  for (final entry in entries)
                                    SizedBox(
                                      width: width,
                                      child: MemorialCard(
                                        memorial: entry,
                                        onTap: () => open(entry),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      SizedBox(height: tokens.safeSpacing * 2),
                      if (onOpenCredits != null)
                        TextButton(
                          onPressed: onOpenCredits,
                          child: Text(strings.credits),
                        ),
                      Text(
                        strings.nonAffiliation,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      SizedBox(height: tokens.safeSpacing),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// A composable card. Disabled entries are empty, even when used directly.
class MemorialCard extends StatefulWidget {
  const MemorialCard({super.key, required this.memorial, required this.onTap});
  final Memorial memorial;
  final VoidCallback onTap;
  @override
  State<MemorialCard> createState() => _MemorialCardState();
}

class _MemorialCardState extends State<MemorialCard> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    final entry = widget.memorial;
    if (!entry.displayEnabled) return const SizedBox.shrink();
    final tokens = ClacksTheme.of(context);
    final strings = ClacksLocalizations.of(context);
    final ink = tokens.ink(tokens.surface);
    final radius = BorderRadius.circular(tokens.safeRadius);
    final dedication = entry.dedication;
    final teaser = dedication == null
        ? null
        : String.fromCharCodes(dedication.runes.take(180));
    return Theme(
      data: _materialTheme(context, tokens, onSurface: true),
      child: MergeSemantics(
        child: Semantics(
          button: true,
          child: Material(
            color: tokens.surface,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(
                color: _focused
                    ? tokens.accentOn(tokens.surface)
                    : ink.withValues(alpha: .25),
                width: _focused ? 3 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              onFocusChange: (value) => setState(() => _focused = value),
              borderRadius: radius,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MemorialPortrait(memorial: entry, height: 156),
                  Padding(
                    padding: EdgeInsets.all(tokens.safeSpacing),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExcludeSemantics(
                          child: Text(
                            'GNU',
                            style: TextStyle(
                              color: tokens.accentOn(tokens.surface),
                              letterSpacing: 4,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          entry.displayName,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: ink),
                        ),
                        if (entry.birthDate != null ||
                            entry.deathDate != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            strings.lifespan(entry.birthDate, entry.deathDate),
                            style: TextStyle(color: ink),
                          ),
                        ],
                        if (teaser != null && teaser.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            '$teaser${dedication!.runes.length > 180 ? '…' : ''}',
                            style: TextStyle(color: ink, height: 1.5),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Text(
                              strings.openMemorial(entry.displayName),
                              style: TextStyle(
                                color: tokens.accentOn(tokens.surface),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            ExcludeSemantics(
                              child: Icon(
                                Icons.arrow_forward,
                                size: 18,
                                color: tokens.accentOn(tokens.surface),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Local asset portrait with an original static tower fallback. Never fetches.
class MemorialPortrait extends StatelessWidget {
  const MemorialPortrait({
    super.key,
    required this.memorial,
    this.height = 240,
  });
  final Memorial memorial;
  final double height;
  @override
  Widget build(BuildContext context) {
    if (!memorial.displayEnabled) return const SizedBox.shrink();
    final tokens = ClacksTheme.of(context);
    final placeholder = ExcludeSemantics(
      child: ColoredBox(
        color: tokens.surface,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: CustomPaint(
            painter: TowerPainter(tokens.accentOn(tokens.surface), 0),
            size: Size(double.infinity, height),
          ),
        ),
      ),
    );
    return SizedBox(
      height: height,
      width: double.infinity,
      child: memorial.imageAsset == null
          ? placeholder
          : Image.asset(
              memorial.imageAsset!,
              fit: BoxFit.cover,
              semanticLabel: memorial.imageAltText,
              excludeFromSemantics:
                  memorial.imageAltText == null ||
                  memorial.imageAltText!.trim().isEmpty,
              frameBuilder: (context, child, frame, synchronouslyLoaded) =>
                  synchronouslyLoaded || frame != null ? child : placeholder,
              errorBuilder: (context, error, stack) => placeholder,
            ),
    );
  }
}

/// Full detail route; registry lookup enforces display eligibility on direct use.
class MemorialDetailScreen extends StatelessWidget {
  const MemorialDetailScreen({
    super.key,
    required this.registry,
    required this.memorialId,
    this.appearance,
    this.animate = true,
    this.onOpenCredits,
  });
  final MemorialRegistry registry;
  final String memorialId;
  final ClacksAppearance? appearance;
  final bool animate;
  final VoidCallback? onOpenCredits;

  @override
  Widget build(BuildContext context) => _TributeScope(
    appearance: appearance,
    child: Builder(
      builder: (context) {
        final strings = ClacksLocalizations.of(context);
        final tokens = ClacksTheme.of(context);
        Memorial? entry;
        for (final candidate in registry.entries) {
          if (candidate.id == memorialId && candidate.displayEnabled) {
            entry = candidate;
            break;
          }
        }
        final memorial = entry;
        return Scaffold(
          appBar: AppBar(title: Text(strings.title)),
          body: _ImageBackdrop(
            asset: memorial?.imageAsset,
            background: tokens.background,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(tokens.safeSpacing),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: memorial == null
                        ? _EmptyState(title: strings.unavailable)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // No placeholder when the person has no image.
                              if (memorial.imageAsset != null) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    tokens.safeRadius,
                                  ),
                                  child: MemorialPortrait(memorial: memorial),
                                ),
                                SizedBox(height: tokens.safeSpacing * 1.5),
                              ],
                              Semantics(
                                header: true,
                                child: Text(
                                  memorial.displayName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge,
                                ),
                              ),
                              if (memorial.birthDate != null ||
                                  memorial.deathDate != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  strings.lifespan(
                                    memorial.birthDate,
                                    memorial.deathDate,
                                  ),
                                ),
                              ],
                              SizedBox(height: tokens.safeSpacing),
                              Text(
                                'GNU ${memorial.displayName}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: tokens.accentOn(tokens.background),
                                    ),
                              ),
                              if (memorial.dedication != null &&
                                  memorial.dedication!.isNotEmpty) ...[
                                SizedBox(height: tokens.safeSpacing),
                                SelectableText(
                                  memorial.dedication!,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(height: 1.65),
                                ),
                              ],
                              SizedBox(height: tokens.safeSpacing * 1.5),
                              Theme(
                                data: _materialTheme(
                                  context,
                                  tokens,
                                  onSurface: true,
                                ),
                                child: Material(
                                  color: tokens.surface,
                                  borderRadius: BorderRadius.circular(
                                    tokens.safeRadius,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(tokens.safeSpacing),
                                    child: ClacksSignal(
                                      message: 'GNU ${memorial.displayName}',
                                      animate: animate,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => showDialog<void>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(strings.explanationTitle),
                                    content: SingleChildScrollView(
                                      child: Text(strings.explanation),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: Text(
                                          MaterialLocalizations.of(context)
                                              .closeButtonLabel,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                child: Text(strings.explanationTitle),
                              ),
                              if (memorial.imageAttribution != null) ...[
                                SizedBox(height: tokens.safeSpacing),
                                Semantics(
                                  header: true,
                                  child: Text(
                                    strings.assetCredits,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${strings.creator}: ${memorial.imageAttribution!.creator}',
                                ),
                                Text(
                                  '${strings.source}: ${memorial.imageAttribution!.source}',
                                ),
                                Text(
                                  '${strings.licence}: ${memorial.imageAttribution!.licence}',
                                ),
                                if (memorial.imageAttribution!.notice != null)
                                  Text(memorial.imageAttribution!.notice!),
                                if (memorial.imageAttribution!.modifications !=
                                    null)
                                  Text(
                                    '${strings.modifications}: ${memorial.imageAttribution!.modifications}',
                                  ),
                              ],
                              if (onOpenCredits != null)
                                TextButton(
                                  onPressed: onOpenCredits,
                                  child: Text(strings.credits),
                                ),
                              SizedBox(height: tokens.safeSpacing),
                              Text(
                                strings.nonAffiliation,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// Compact, optional host entry point. It does not cover primary app content.
class MemorialBadge extends StatelessWidget {
  const MemorialBadge({super.key, required this.memorial, this.onTap});
  final Memorial memorial;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    if (!memorial.displayEnabled) return const SizedBox.shrink();
    final tokens = ClacksTheme.of(context);
    final label = Text(
      'GNU · ${memorial.displayName}',
      style: TextStyle(color: tokens.ink(tokens.surface)),
    );
    return Theme(
      data: _materialTheme(context, tokens, onSurface: true),
      child: Material(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.safeRadius),
        child: onTap == null
            ? Padding(padding: const EdgeInsets.all(12), child: label)
            : InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(tokens.safeRadius),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 48,
                    minWidth: 48,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: label,
                  ),
                ),
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, this.body});
  final String title;
  final String? body;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
        ),
        if (body != null) ...[const SizedBox(height: 12), Text(body!)],
      ],
    ),
  );
}

class _TributeScope extends StatelessWidget {
  const _TributeScope({required this.child, this.appearance});
  final Widget child;
  final ClacksAppearance? appearance;
  @override
  Widget build(BuildContext context) {
    final tokens = appearance == null
        ? ClacksTheme.of(context)
        : ClacksTheme.appearance(appearance!, Theme.of(context));
    return Theme(data: _materialTheme(context, tokens), child: child);
  }
}

ThemeData _materialTheme(
  BuildContext context,
  ClacksTheme tokens, {
  bool onSurface = false,
}) {
  final host = Theme.of(context);
  final background = onSurface ? tokens.surface : tokens.background;
  final ink = tokens.ink(background);
  final accent = tokens.accentOn(background);
  return host.copyWith(
    extensions: [
      ...host.extensions.values.where((e) => e is! ClacksTheme),
      tokens,
    ],
    scaffoldBackgroundColor: tokens.background,
    colorScheme: host.colorScheme.copyWith(
      surface: background,
      onSurface: ink,
      primary: accent,
      onPrimary: tokens.ink(accent),
      secondary: accent,
    ),
    textTheme: (tokens.textTheme ?? host.textTheme).apply(
      bodyColor: ink,
      displayColor: ink,
    ),
    iconTheme: IconThemeData(color: ink),
    appBarTheme: AppBarThemeData(
      backgroundColor: tokens.background,
      foregroundColor: tokens.ink(tokens.background),
      elevation: 0,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accent,
        minimumSize: const Size(48, 48),
      ),
    ),
  );
}

/// The person's own image behind the detail page, blurred and heavily faded
/// into the theme background. Shown only when the memorial has an image;
/// a missing or broken asset shows nothing. Decorative: hidden from screen
/// readers and pointer input, and fixed while the page scrolls.
class _ImageBackdrop extends StatelessWidget {
  const _ImageBackdrop({
    required this.asset,
    required this.background,
    required this.child,
  });
  final String? asset;
  final Color background;
  final Widget child;

  /// Share of the image that shows through the background wash.
  static const strength = .1;

  @override
  Widget build(BuildContext context) {
    final image = asset;
    if (image == null) return child;
    return Stack(
      children: [
        Positioned.fill(
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Image.asset(
                  image,
                  key: const ValueKey('clacks-detail-backdrop'),
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  color: background.withValues(alpha: 1 - strength),
                  colorBlendMode: BlendMode.srcOver,
                  excludeFromSemantics: true,
                  errorBuilder: (context, error, stack) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
