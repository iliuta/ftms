import 'package:flutter/material.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
import '../../../core/config/ftms_display_config.dart';
import '../model/training_session.dart';
import '../training_session_controller.dart';
import '../managers/session_dialog_manager.dart';
import '../managers/session_snackbar_manager.dart';
import 'training_session_app_bar.dart';
import 'training_session_body.dart';

/// Main scaffold widget for the training session
class TrainingSessionScaffold extends StatefulWidget {
  final TrainingSessionDefinition session;
  final TrainingSessionController controller;
  final FtmsDisplayConfig? config;
  final BluetoothDevice ftmsDevice;

  const TrainingSessionScaffold({
    super.key,
    required this.session,
    required this.controller,
    this.config,
    required this.ftmsDevice,
  });

  @override
  State<TrainingSessionScaffold> createState() =>
      _TrainingSessionScaffoldState();
}

class _TrainingSessionScaffoldState extends State<TrainingSessionScaffold> {
  final _dialogManager = SessionDialogManager();
  final _snackBarManager = SessionSnackBarManager();

  @override
  Widget build(BuildContext context) {
    // Handle post-frame callbacks for dialogs and snackbars
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dialogManager.handleCompletionDialog(context, widget.controller);
      _snackBarManager.handlePauseSnackBar(context, widget.controller);
    });

    return Scaffold(
      appBar: TrainingSessionAppBar(
        session: widget.session,
        controller: widget.controller,
      ),
      body: TrainingSessionBody(
        session: widget.session,
        controller: widget.controller,
        config: widget.config,
        ftmsDevice: widget.ftmsDevice,
      ),
    );
  }
}
