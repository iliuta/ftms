import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
import '../../core/config/live_data_display_config.dart';
import 'model/training_session.dart';
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
  Widget build(BuildContext context) {
    return FutureBuilder<LiveDataDisplayConfig?>(
      future: _loadConfig(),
      builder: (context, snapshot) {
        return ChangeNotifierProvider(
          create: (_) => TrainingSessionController(
            session: widget.session,
            ftmsDevice: widget.ftmsDevice,
          ),
          child: Consumer<TrainingSessionController>(
            builder: (context, controller, _) {
              return TrainingSessionScaffold(
                session: widget.session,
                controller: controller,
                config: snapshot.data,
                ftmsDevice: widget.ftmsDevice,
              );
            },
          ),
        );
      },
    );
  }

  Future<LiveDataDisplayConfig?> _loadConfig() {
    return LiveDataDisplayConfig.loadForFtmsMachineType(widget.session.ftmsMachineType);
  }
}
