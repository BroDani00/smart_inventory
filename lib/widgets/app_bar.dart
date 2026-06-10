import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/constants/colors.dart';
import '../providers/theme_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? leading;
  final List<AppBarMenuItem>? menuItems;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
    this.leading,
    this.menuItems,
  });

  static const double _appBarHeight = 95;
  static const double _buttonSize = 35;
  static const double _iconSize = 18;

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    final bool hasLeading = showBackButton || leading != null;

    final bool hasActions =
        (actions != null && actions!.isNotEmpty) ||
        (menuItems != null && menuItems!.isNotEmpty);

    return Container(
      height: preferredSize.height,
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.premiumGradientDark
            : AppColors.premiumGradientLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // =========================
              // LEADING
              // =========================
              if (hasLeading) ...[
                SizedBox(
                  width: _buttonSize,
                  height: _buttonSize,
                  child: showBackButton
                      ? _buildBackButton(context)
                      : leading,
                ),
                const SizedBox(width: 12),
              ],

              // =========================
              // TITLE
              // =========================
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),

              // =========================
              // ACTIONS
              // =========================
              if (hasActions) ...[
                const SizedBox(width: 8),

                if (actions != null)
                  ...actions!.map(
                    (widget) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: widget,
                    ),
                  ),

                if (menuItems != null && menuItems!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _buildPopupMenu(context, isDark),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onBackPressed ?? () => Navigator.of(context).pop(),
        child: Container(
          width: _buttonSize,
          height: _buttonSize,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.20),
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: _iconSize,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context, bool isDark) {
    return Container(
      width: _buttonSize,
      height: _buttonSize,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.20),
        ),
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        offset: const Offset(0, 50),
        color: isDark ? AppColors.cardDark : Colors.white,
        icon: const Icon(
          Icons.more_vert_rounded,
          color: Colors.white,
          size: _iconSize,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        onSelected: (value) {
          final selectedItem = menuItems?.firstWhere(
            (item) => item.value == value,
            orElse: () => const AppBarMenuItem(
              value: '',
              label: '',
              icon: Icons.close,
              iconColor: Colors.grey,
            ),
          );

          selectedItem?.onTap?.call();
        },
        itemBuilder: (context) {
          return menuItems?.map((item) {
                return PopupMenuItem<String>(
                  value: item.value,
                  child: SizedBox(
                    width: 180,
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          size: 18,
                          color: item.iconColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.label,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList() ??
              [];
        },
      ),
    );
  }

  static Widget buildIconButton({
    required VoidCallback onPressed,
    required IconData icon,
    Color? iconColor,
  }) {
    return Container(
      width: _buttonSize,
      height: _buttonSize,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.20),
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        splashRadius: 22,
        icon: Icon(
          icon,
          size: _iconSize,
          color: iconColor ?? Colors.white,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(_appBarHeight);
}

class AppBarMenuItem {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const AppBarMenuItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });
}