import FlutterMacOS
import Foundation

import permission_handler_macos

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  PermissionHandlerPlugin.register(with: registry.registrar(forPlugin: "PermissionHandlerPlugin"))
}
