import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simpson/modals/pidDataset.model.dart' show Code, PiCodeVariables;
import 'package:simpson/views/screens/psf_homeScreen/controllers/pfs_lane.dart';

/// Same palette as the lane card — kept identical so every screen in
/// the app reads as one consistent product rather than a patchwork of
/// one-off colors per dialog.
class _LaneColors {
  static const navy = Color(0xFF003874);
  static const navyLight = Color(0xFF1D5FA0);
  static const green = Color(0xFF2ECC71);
  static const greenDark = Color(0xFF1B7A3E);
  static const greenBg = Color(0xFFEAFAF1);
  static const red = Color(0xFFD64545);
  static const redBg = Color(0xFFFDEDED);
  static const slate = Color(0xFF7C8698);
  static const slateBorder = Color(0xFFDDE1E9);
  static const slateBg = Color(0xFFF7F8FA);
}

/// Same signature diagonal sheen used across the lane card — the one
/// glossy device repeated everywhere so gradients read as "this
/// product's glass/lacquer style" rather than a one-off effect.
class _GlossOverlay extends StatelessWidget {
  const _GlossOverlay({this.borderRadius, this.opacity = 0.16});
  final BorderRadius? borderRadius;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.42, 0.55],
                colors: [
                  Colors.white.withOpacity(opacity),
                  Colors.white.withOpacity(opacity * 0.28),
                  Colors.white.withOpacity(0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<BoxShadow> _raisedShadow(Color tint, {double strength = 1}) => [
      BoxShadow(color: tint.withOpacity(0.22 * strength), blurRadius: 3, offset: const Offset(0, 1)),
      BoxShadow(color: tint.withOpacity(0.14 * strength), blurRadius: 12, offset: const Offset(0, 5)),
    ];

class PsfLiveParameterDialog extends StatelessWidget {
  const PsfLiveParameterDialog({
    super.key,
    required this.lane,
    required this.onRefresh,
    required this.onTogglePlayback,
  });

  final PsfLane lane;
  final VoidCallback onRefresh;
  final VoidCallback onTogglePlayback;

  static void show(PsfLane lane, VoidCallback onRefresh, VoidCallback onTogglePlayback) {
    Get.dialog(PsfLiveParameterDialog(lane: lane, onRefresh: onRefresh, onTogglePlayback: onTogglePlayback));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 520,
        height: 600,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _raisedShadow(Colors.black, strength: 1.4),
        ),
        clipBehavior: Clip.antiAlias,
        child: DefaultTabController(
          length: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _tabBar(),
                      const SizedBox(height: 14),
                      Expanded(
                        child: Obx(() {
                          if (lane.isLoadingPid.value) {
                            return const Center(
                              child: CircularProgressIndicator(color: _LaneColors.navy),
                            );
                          }
                          if (lane.pidError.value.isNotEmpty) {
                            return Center(
                              child: Text(
                                lane.pidError.value,
                                style: const TextStyle(color: _LaneColors.red, fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return TabBarView(
                            children: [
                              _liveParameterList(),
                              _iqaWrittenList(),
                            ],
                          );
                        }),
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

  /// Navy gradient header with the gloss sheen — same treatment as
  /// the lane card's ECU header bar, so this dialog reads as part of
  /// the same surface rather than a separate plain-white popup.
  Widget _header() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_LaneColors.navyLight, _LaneColors.navy],
        ),
      ),
      child: Stack(
        children: [
          const _GlossOverlay(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: const Icon(Icons.speed_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Live Parameters — Lane ${lane.laneNumber}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Obx(() {
                  final playing = lane.pidPlaying.value;
                  return _glossyPillButton(
                    label: playing ? 'Stop' : 'Run',
                    icon: playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    colors: playing ? [_LaneColors.red, const Color(0xFF9E2E2E)] : [_LaneColors.green, _LaneColors.greenDark],
                    onPressed: onTogglePlayback,
                  );
                }),
                const SizedBox(width: 8),
                Obx(
                  () => IconButton(
                    icon: lane.isLoadingPid.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.refresh, size: 20, color: Colors.white70),
                    tooltip: 'Reload parameter list',
                    onPressed: lane.isLoadingPid.value ? null : onRefresh,
                    splashRadius: 18,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.white70),
                  onPressed: () => Get.back(),
                  splashRadius: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glossyPillButton({
    required String label,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: colors),
        boxShadow: _raisedShadow(colors.first, strength: 0.7),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Stack(
            children: [
              _GlossOverlay(borderRadius: BorderRadius.circular(20), opacity: 0.2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tab bar — glass pill container with a raised white tab indicator
  /// instead of the flat grey chrome before.
  Widget _tabBar() {
    return Container(
      decoration: BoxDecoration(
        color: _LaneColors.slateBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _LaneColors.slateBorder),
      ),
      padding: const EdgeInsets.all(4),
      child: Obx(
        () => TabBar(
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: _raisedShadow(_LaneColors.navy, strength: 0.35),
          ),
          labelColor: _LaneColors.navy,
          unselectedLabelColor: _LaneColors.slate,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
          tabs: [
            Tab(text: 'Live Parameters (${lane.liveParameterCodes.length})'),
            Tab(text: 'IQA (${lane.iqaControllers.length})'),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // LIVE PARAMETERS TAB — real ECU reads
  // ═══════════════════════════════════════════════

  Widget _liveParameterList() {
    final rows = <_ParamRow>[];
    for (final code in lane.liveParameterCodes) {
      final variables = code.piCodeVariable ?? [];
      if (variables.isEmpty) {
        rows.add(_ParamRow(code: code, variable: null));
        continue;
      }
      for (final v in variables) {
        rows.add(_ParamRow(code: code, variable: v));
      }
    }

    if (rows.isEmpty) {
      return const Center(
        child: Text('No live parameters found for this lane.', style: TextStyle(color: _LaneColors.slate)),
      );
    }

    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (context, i) => _liveParameterTile(rows[i]),
    );
  }

  Widget _liveParameterTile(_ParamRow row) {
    final code = row.code;
    final variable = row.variable;
    final unit = variable?.unit ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_LaneColors.slateBg, Colors.white],
        ),
        border: Border.all(color: _LaneColors.slateBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  variable?.longName ?? variable?.shortName ?? code.shortName ?? code.code ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black87),
                ),
                if ((code.code ?? '').isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(code.code!, style: const TextStyle(fontSize: 11.5, color: _LaneColors.slate)),
                ],
              ],
            ),
          ),
          // Scoped Obx — only this value chip rebuilds when
          // lane.livePidValues changes, not the whole list.
          Obx(() {
            final liveValue = variable?.id != null ? lane.livePidValues[variable!.id] : null;
            final isError = liveValue != null && (liveValue == 'Not Found' || liveValue.toUpperCase().contains('ERROR'));
            final hasValue = liveValue != null;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isError
                      ? [_LaneColors.redBg, _LaneColors.redBg.withOpacity(0.6)]
                      : (hasValue
                          ? [_LaneColors.greenBg, _LaneColors.greenBg.withOpacity(0.6)]
                          : [_LaneColors.slateBg, Colors.white]),
                ),
                border: Border.all(color: isError ? _LaneColors.red : (hasValue ? _LaneColors.green : _LaneColors.slateBorder)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                liveValue != null ? '$liveValue${unit.isNotEmpty ? ' $unit' : ''}' : (unit.isEmpty ? '--' : '-- $unit'),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isError ? _LaneColors.red : (hasValue ? _LaneColors.greenDark : _LaneColors.slate),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // IQA TAB — exactly the entered/written values,
  // capped to lane.iqaControllers.length (e.g. 4)
  // ═══════════════════════════════════════════════

  Widget _iqaWrittenList() {
    final count = lane.iqaControllers.length;
    if (count == 0) {
      return const Center(
        child: Text('No IQA fields configured for this lane.', style: TextStyle(color: _LaneColors.slate)),
      );
    }

    return ListView.builder(
      itemCount: count,
      itemBuilder: (context, i) => _iqaWrittenTile(i),
    );
  }

  Widget _iqaWrittenTile(int i) {
    // Each tile owns its own Obx, scoped to just this controller's text
    // and the overall write-status line — same reasoning as the live
    // parameter tiles above.
    return Obx(() {
      final value = lane.iqaControllers[i].text.trim();
      final hasValue = value.isNotEmpty;
      final writeStatus = lane.iqaWriteStatus.value;
      final wasWritten = writeStatus.toLowerCase().contains('successful');

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: wasWritten
                ? [_LaneColors.greenBg, _LaneColors.greenBg.withOpacity(0.6)]
                : [_LaneColors.slateBg, Colors.white],
          ),
          border: Border.all(color: wasWritten ? _LaneColors.green : _LaneColors.slateBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lane.iqaLabelFor(i), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black87)),
                  if (wasWritten) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, size: 12, color: _LaneColors.greenDark),
                        const SizedBox(width: 4),
                        Text('Written to ECU', style: TextStyle(fontSize: 11.5, color: _LaneColors.greenDark.withOpacity(0.9), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: hasValue ? _LaneColors.navy.withOpacity(0.35) : _LaneColors.slateBorder),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                hasValue ? value : '--',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: hasValue ? _LaneColors.navy : _LaneColors.slate,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// One flattened, displayable row: a Code paired with one of its
/// piCodeVariable sub-entries (or null if the Code has none at all).
class _ParamRow {
  const _ParamRow({required this.code, required this.variable});
  final Code code;
  final PiCodeVariables? variable;
}