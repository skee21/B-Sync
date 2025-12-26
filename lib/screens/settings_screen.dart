import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../data/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final colorProfile = ref.watch(colorProfileProvider);
    final appStyle = ref.watch(appStyleProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'Theme Mode', Icons.brightness_6),
            const SizedBox(height: 12),
            _buildThemeModeSelector(context, ref, themeMode, colorScheme),
            const SizedBox(height: 28),
            _buildSectionHeader(context, 'App Style', Icons.style),
            const SizedBox(height: 12),
            _buildAppStyleGrid(context, ref, appStyle),
            const SizedBox(height: 28),
            _buildSectionHeader(context, 'Color', Icons.palette),
            const SizedBox(height: 12),
            _buildColorProfileRow(context, ref, colorProfile, appStyle),
            const SizedBox(height: 28),
            _buildEffectsToggle(context, ref, appStyle, colorScheme),
            const SizedBox(height: 28),
            _buildPreviewCard(context, colorProfile, appStyle, isDark, colorScheme),
            const SizedBox(height: 20),
            Center(
              child: Text(
                "Developed by Skee",
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withAlpha(100),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withAlpha(30),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.05);
  }

  Widget _buildThemeModeSelector(BuildContext context, WidgetRef ref, ThemeMode themeMode, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(150),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withAlpha(50)),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          _buildThemeModeButton(context, ref, ThemeMode.system, 'Auto', Icons.brightness_auto, themeMode, colorScheme),
          _buildThemeModeButton(context, ref, ThemeMode.light, 'Light', Icons.light_mode, themeMode, colorScheme),
          _buildThemeModeButton(context, ref, ThemeMode.dark, 'Dark', Icons.dark_mode, themeMode, colorScheme),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.98, 0.98));
  }

  Widget _buildThemeModeButton(BuildContext context, WidgetRef ref, ThemeMode mode, String label, IconData icon, ThemeMode currentMode, ColorScheme colorScheme) {
    final isSelected = mode == currentMode;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(mode),
        child: AnimatedContainer(
          duration: 250.ms,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [
              BoxShadow(
                color: colorScheme.primary.withAlpha(60),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface.withAlpha(180),
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface.withAlpha(180),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppStyleGrid(BuildContext context, WidgetRef ref, AppStyle currentStyle) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: AppStyle.values.length,
      itemBuilder: (context, index) {
        final style = AppStyle.values[index];
        final isSelected = style == currentStyle;
        final gradientColors = style.previewGradient;
        
        return GestureDetector(
          onTap: () => ref.read(appStyleProvider.notifier).setAppStyle(style),
          child: AnimatedContainer(
            duration: 300.ms,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withAlpha(isSelected ? 100 : 40),
                  blurRadius: isSelected ? 16 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                if (style == AppStyle.nightcore)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Icon(Icons.star, color: Colors.white.withAlpha(100), size: 16),
                  ),
                if (style == AppStyle.nightcore)
                  Positioned(
                    top: 20,
                    right: 15,
                    child: Icon(Icons.favorite, color: Colors.white.withAlpha(80), size: 12),
                  ),
                if (style == AppStyle.cyberpunk)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(100),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '2077',
                        style: TextStyle(
                          color: const Color(0xFF00F5D4),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          shadows: [
                            Shadow(color: const Color(0xFF00F5D4).withAlpha(150), blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Icon(
                            style.icon,
                            color: Colors.white,
                            size: 18,
                            shadows: const [Shadow(color: Colors.black38, blurRadius: 4)],
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              style.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        style.description,
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 11,
                          shadows: const [Shadow(color: Colors.black38, blurRadius: 4)],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 10,
                    right: style == AppStyle.cyberpunk ? 50 : 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: gradientColors.first,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ).animate(delay: (50 * index).ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
      },
    );
  }

  Widget _buildColorProfileRow(BuildContext context, WidgetRef ref, ColorProfile currentProfile, AppStyle currentStyle) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Override theme color (or use Default for theme\'s own colors)',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface.withAlpha(150),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ColorProfile.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final profile = ColorProfile.values[index];
              final isSelected = profile == currentProfile;
              final isDefault = profile == ColorProfile.defaultColor;
              
              return GestureDetector(
                onTap: () => ref.read(colorProfileProvider.notifier).setColorProfile(profile),
                child: AnimatedContainer(
                  duration: 300.ms,
                  width: 60,
                  decoration: BoxDecoration(
                    gradient: isDefault ? LinearGradient(
                      colors: currentStyle.previewGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ) : LinearGradient(
                      colors: [profile.displayColor, profile.accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: (isDefault ? currentStyle.defaultSeedColor : profile.displayColor).withAlpha(120),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isDefault)
                        const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                      if (isSelected && !isDefault)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            size: 14,
                            color: profile.displayColor,
                          ),
                        ),
                      if (isSelected && isDefault)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.check, size: 12, color: Colors.black),
                          ),
                        ),
                    ],
                  ),
                ),
              ).animate(delay: (40 * index).ms).fadeIn().slideX(begin: 0.1);
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          currentProfile == ColorProfile.defaultColor 
            ? 'Using ${currentStyle.displayName} theme colors'
            : currentProfile.displayName,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildEffectsToggle(BuildContext context, WidgetRef ref, AppStyle appStyle, ColorScheme colorScheme) {
    final effectsEnabled = ref.watch(themeEffectsEnabledProvider);
    
    String effectDescription;
    switch (appStyle) {
      case AppStyle.normal:
        effectDescription = 'Floating particles';
      case AppStyle.glass:
        effectDescription = 'Rising bubbles';
      case AppStyle.nightcore:
        effectDescription = 'Cats, hearts & stars';
      case AppStyle.cyberpunk:
        effectDescription = 'Glitch effects';
      case AppStyle.highContrast:
        effectDescription = 'Scanlines';
    }
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(150),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withAlpha(50)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.auto_awesome,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visual Effects',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  effectDescription,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withAlpha(150),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: effectsEnabled,
            onChanged: (value) => ref.read(themeEffectsEnabledProvider.notifier).setEnabled(value),
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildPreviewCard(BuildContext context, ColorProfile profile, AppStyle style, bool isDark, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.preview, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Live Preview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  style.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Play'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.pause, size: 18),
                  label: const Text('Pause'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              value: 0.65,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '2:15',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withAlpha(150)),
              ),
              Text(
                '3:45',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withAlpha(150)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Selected'),
                selected: true,
                onSelected: (_) {},
              ),
              FilterChip(
                label: const Text('Filter'),
                selected: false,
                onSelected: (_) {},
              ),
              ActionChip(
                avatar: Icon(Icons.add, size: 16, color: colorScheme.primary),
                label: const Text('Action'),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: colorScheme.primary,
                child: Icon(Icons.music_note, color: colorScheme.onPrimary),
              ),
              title: Text('Sample Track', style: TextStyle(color: colorScheme.onSurface)),
              subtitle: Text('Preview item', style: TextStyle(color: colorScheme.onSurface.withAlpha(150))),
              trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withAlpha(100)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }
}
