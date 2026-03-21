import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_constants.dart';
import '../core/routing/app_router.dart';
import '../core/routing/route_names.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_spacing.dart';
import '../core/responsive/responsive_layout.dart';
import '../services/app_state_service.dart';
import '../services/history_service.dart';
import '../widgets/native_ad_widget.dart';

/// Screen showing all previously processed images in a responsive grid.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _history = HistoryService();
  final AppStateService _appState = AppStateService();
  bool _isLoading = true;
  bool _isSelectionMode = false;
  bool _showFavoritesOnly = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    await _history.load();
    if (mounted) setState(() => _isLoading = false);
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Images'),
        content: Text('Delete $count processed image${count > 1 ? 's' : ''}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (final id in _selectedIds) {
        await _history.delete(id);
      }
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text(
            'This will delete all processed images. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _history.clearAll();
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
    }
  }

  void _openResult(HistoryEntry entry) {
    final resultFile = File(entry.resultPath);
    if (!resultFile.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image file not found')),
      );
      return;
    }

    final resultBytes = resultFile.readAsBytesSync();

    context.push(
      RouteNames.result,
      extra: ResultScreenArgs(
        originalFile: File(entry.originalPath),
        resultPngBytes: Uint8List.fromList(resultBytes),
        processingTimeMs: entry.processingTimeMs,
      ),
    );
  }

  List<HistoryEntry> get _filteredEntries {
    final entries = _history.entries;
    if (!_showFavoritesOnly) return entries;
    final fav = _appState.favoriteIds;
    return entries.where((e) => fav.contains(e.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = _filteredEntries;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (_isSelectionMode) {
              setState(() {
                _isSelectionMode = false;
                _selectedIds.clear();
              });
            } else {
              context.pop();
            }
          },
          icon: Icon(_isSelectionMode ? Icons.close : Icons.arrow_back),
        ),
        title: Text(
          _isSelectionMode ? '${_selectedIds.length} Selected' : 'History',
          style: theme.textTheme.titleLarge,
        ),
        centerTitle: true,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              onPressed: _selectedIds.isNotEmpty ? _deleteSelected : null,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete selected',
            ),
          ] else if (entries.isNotEmpty) ...[
            IconButton(
              onPressed: () {
                setState(() => _isSelectionMode = true);
              },
              icon: const Icon(Icons.checklist),
              tooltip: 'Select',
            ),
            IconButton(
              onPressed: _clearAll,
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear all',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : entries.isEmpty
              ? _buildEmptyState(theme, _showFavoritesOnly)
              : _buildGrid(entries, theme),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool favoritesOnly) {
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: AppSpacing.paddingAllXxl,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surfaceContainer,
            ),
            child: Icon(
              favoritesOnly ? Icons.star_border : Icons.photo_library_outlined,
              size: 48,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            favoritesOnly ? 'NO FAVORITES YET' : 'NO PROCESSED IMAGES YET',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            favoritesOnly
                ? 'Tap the star on any result to add it to Favorites'
                : 'Your results will appear here',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<HistoryEntry> entries, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final gridColumns = context.responsiveGridColumns;

    return Column(
      children: [
        // Filter and count
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('ALL')),
                  ButtonSegment(value: true, label: Text('FAVORITES')),
                ],
                selected: {_showFavoritesOnly},
                onSelectionChanged: (set) {
                  setState(() => _showFavoritesOnly = set.first);
                },
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '${entries.length} IMAGE${entries.length != 1 ? 'S' : ''}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),

        // Native ad
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: NativeAdWidget(),
        ),

        // Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridColumns,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
            ),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isSelected = _selectedIds.contains(entry.id);

              return _HistoryTile(
                entry: entry,
                isSelected: isSelected,
                isSelectionMode: _isSelectionMode,
                isFavorite: _appState.isFavorite(entry.id),
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleSelection(entry.id);
                  } else {
                    _openResult(entry);
                  }
                },
                onLongPress: () {
                  if (!_isSelectionMode) {
                    HapticFeedback.mediumImpact();
                    setState(() => _isSelectionMode = true);
                    _toggleSelection(entry.id);
                  }
                },
                onFavoriteTap: () async {
                  await _appState.toggleFavorite(entry.id);
                  if (mounted) setState(() {});
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Single history tile in the grid.
class _HistoryTile extends StatelessWidget {
  final HistoryEntry entry;
  final bool isSelected;
  final bool isSelectionMode;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onFavoriteTap;

  const _HistoryTile({
    required this.entry,
    required this.isSelected,
    required this.isSelectionMode,
    required this.isFavorite,
    required this.onTap,
    required this.onLongPress,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resultFile = File(entry.resultPath);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: Duration(milliseconds: AppConstants.shortAnimationMs),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryContainer
                : AppColors.outlineVariant.withOpacity(0.2),
            width: isSelected ? 2.5 : 1,
          ),
          color: colorScheme.surfaceContainer,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isSelected ? 11.5 : 13),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: 6,
                right: 6,
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: isFavorite ? AppColors.primaryContainer : colorScheme.onSurface.withOpacity(0.6),
                    size: 22,
                  ),
                  onPressed: onFavoriteTap,
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainer.withOpacity(0.9),
                    padding: const EdgeInsets.all(4),
                    minimumSize: const Size(32, 32),
                  ),
                ),
              ),
              // Checkerboard background
              CustomPaint(
                painter: _MiniCheckerPainter(
                  color1: colorScheme.surfaceContainer,
                  color2: colorScheme.surfaceContainerHigh,
                ),
              ),

              // Result image
              if (resultFile.existsSync())
                Image.file(
                  resultFile,
                  fit: BoxFit.cover,
                  cacheWidth: AppConstants.thumbnailCacheSize,
                  cacheHeight: AppConstants.thumbnailCacheSize,
                  filterQuality: FilterQuality.low,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.broken_image_outlined,
                    color: colorScheme.onSurface.withOpacity(0.3),
                  ),
                )
              else
                Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),

              // Time badge
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatDate(entry.processedAt).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              // Selection check
              if (isSelectionMode)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.surface.withOpacity(0.4),
                      border: Border.all(
                        color: colorScheme.onSurface.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? Icon(Icons.check,
                            size: 16, color: colorScheme.onPrimary)
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.day}/${date.month}';
  }
}

class _MiniCheckerPainter extends CustomPainter {
  final Color color1;
  final Color color2;

  _MiniCheckerPainter({required this.color1, required this.color2});

  @override
  void paint(Canvas canvas, Size size) {
    const cellSize = 10.0;
    final paint1 = Paint()..color = color1;
    final paint2 = Paint()..color = color2;

    for (double y = 0; y < size.height; y += cellSize) {
      for (double x = 0; x < size.width; x += cellSize) {
        final isEven =
            ((x / cellSize).floor() + (y / cellSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          isEven ? paint1 : paint2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniCheckerPainter old) =>
      old.color1 != color1 || old.color2 != color2;
}
