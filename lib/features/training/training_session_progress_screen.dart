import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
import '../../core/config/live_data_display_config.dart';
import '../settings/model/user_settings.dart';
import 'model/training_session.dart';
import 'model/expanded_training_session_definition.dart';
import 'training_session_controller.dart';
import 'widgets/training_session_scaffold.dart';

/// Main screen for displaying training session progress
class TrainingSessionProgressScreen extends StatefulWidget {
  final TrainingSessionDefinition session;
  final BluetoothDevice ftmsDevice;

  const TrainingSessionProgressScreen({
    super.key,
    required this.session,
    required this.ftmsDevice,
  });

  @override
  State<TrainingSessionProgressScreen> createState() => _TrainingSessionProgressScreenState();
}

class _TrainingSessionProgressScreenState extends State<TrainingSessionProgressScreen> {
  @override
  void initState() {
    super.initState();
    // Force landscape orientation for this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Allow all orientations when leaving this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LiveDataDisplayConfig?>(
      future: _loadConfig(),
      builder: (context, snapshot) {
        return FutureBuilder<ExpandedTrainingSessionDefinition>(
          future: _expandSession(),
          builder: (context, sessionSnapshot) {
            if (sessionSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            
            final expandedSession = sessionSnapshot.data;
            if (expandedSession == null) {
              return const Scaffold(
                body: Center(child: Text('Failed to load session')),
              );
            }
            
            return ChangeNotifierProvider(
              create: (_) => TrainingSessionController(
                session: expandedSession,
                ftmsDevice: widget.ftmsDevice,
              ),
              child: Consumer<TrainingSessionController>(
                builder: (context, controller, _) {
                  return TrainingSessionScaffold(
                    session: expandedSession,
                    controller: controller,
                    config: snapshot.data,
                    ftmsDevice: widget.ftmsDevice,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<ExpandedTrainingSessionDefinition> _expandSession() async {
    try {
      final userSettings = await UserSettings.loadDefault();
      final config = await LiveDataDisplayConfig.loadForFtmsMachineType(widget.session.ftmsMachineType);
      return widget.session.expand(
        userSettings: userSettings,
        config: config,
      );
    } catch (e) {
      // If expansion fails, create a minimal expanded session from the original
      debugPrint('Failed to expand session: $e');
      final userSettings = await UserSettings.loadDefault();
      return widget.session.expand(
        userSettings: userSettings,
        config: null,
      );
    }
  }

  Future<LiveDataDisplayConfig?> _loadConfig() {
    return LiveDataDisplayConfig.loadForFtmsMachineType(widget.session.ftmsMachineType);
  }
}
