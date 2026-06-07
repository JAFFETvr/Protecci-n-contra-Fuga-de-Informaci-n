import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/session_service.dart';
import '../widgets/inactivity_detector.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('DLP Seguro'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Cerrar sesión',
              onPressed: () {
                SessionService.instance.logout( /////////
                  reason: SessionCloseReason.manual,
                );
              },
            ),
          ],
        ),
        body: const _DashboardBody(),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WelcomeBanner(),
          const SizedBox(height: 20),
          const _InactivityTimer(),
          const SizedBox(height: 28),
          _SectionTitle(title: 'Estado de seguridad'),
          const SizedBox(height: 14),
          const _SecurityStatusCard(),
          const SizedBox(height: 28),
          _SectionTitle(title: 'Funciones DLP'),
          const SizedBox(height: 14),
          const _FeatureGrid(),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Widget: Contador de inactividad
// ────────────────────────────────────────────────────────────────

class _InactivityTimer extends StatelessWidget {
  const _InactivityTimer();

  @override
  Widget build(BuildContext context) {
    final detector = InactivityDetector.of(context);

    if (detector == null) return const SizedBox.shrink();

    return ValueListenableBuilder<int>(
      valueListenable: detector.secondsRemaining,
      builder: (context, seconds, _) {
        final total = kInactivityTimeout.inSeconds;
        final progress = seconds / total;
        final isWarning = seconds <= 5;

        final barColor = isWarning
            ? const Color(0xFFFF4757)
            : const Color(0xFF7B61FF);
        final bgColor = isWarning
            ? const Color(0xFFFF4757).withAlpha(20)
            : const Color(0xFF7B61FF).withAlpha(20);
        final borderColor = isWarning
            ? const Color(0xFFFF4757).withAlpha(80)
            : const Color(0xFF7B61FF).withAlpha(60);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isWarning
                        ? Icons.timer_off_rounded
                        : Icons.timer_rounded,
                    color: barColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isWarning
                          ? '⚠️  Sesión expirará pronto'
                          : 'Tiempo de sesión activa',
                      style: TextStyle(
                        color: barColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: barColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${seconds}s',
                      style: TextStyle(
                        color: barColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: barColor.withAlpha(30),
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Toca la pantalla para mantener la sesión activa.',
                style: TextStyle(
                  color: barColor.withAlpha(160),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Widgets existentes (sin cambios de lógica)
// ────────────────────────────────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B61FF), Color(0xFF5B41DF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_rounded, color: Colors.white, size: 40),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenido',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Protección activa contra fuga de información',
                  style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _SecurityStatusCard extends StatelessWidget {
  const _SecurityStatusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: const Column(
        children: [
          _StatusRow(
            icon: Icons.no_photography_rounded,
            label: 'Capturas bloqueadas',
            active: true,
          ),
          Divider(color: Color(0xFF2A2A2A), height: 24),
          _StatusRow(
            icon: Icons.screen_share_rounded,
            label: 'Grabación bloqueada',
            active: true,
          ),
          Divider(color: Color(0xFF2A2A2A), height: 24),
          _StatusRow(
            icon: Icons.lock_rounded,
            label: 'Sesión cifrada',
            active: true,
          ),
          Divider(color: Color(0xFF2A2A2A), height: 24),
          _StatusRow(
            icon: Icons.timer_rounded,
            label: 'Cierre por inactividad (15s)',
            active: true,
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.active,
  });
  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color =
        active ? const Color(0xFF00C853) : const Color(0xFFFF4757);
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF777777), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            active ? 'Activo' : 'Inactivo',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    final features = [
      (Icons.lock_open_rounded, 'Archivos\nProtegidos', const Color(0xFF7B61FF)),
      (Icons.policy_rounded, 'Políticas\nDLP', const Color(0xFF00D4FF)),
      (Icons.history_rounded, 'Registro\nde Eventos', const Color(0xFFFFB300)),
      (Icons.admin_panel_settings_rounded, 'Admin\nPanel', const Color(0xFF00C853)),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.2,
      children: features
          .map((f) => _FeatureCard(icon: f.$1, label: f.$2, color: f.$3))
          .toList(),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
