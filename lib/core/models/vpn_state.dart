/// VPN connection state
enum VpnState {
  /// VPN is disconnected and idle
  disconnected,

  /// VPN is in the process of connecting
  connecting,

  /// VPN is connected and actively filtering
  connected,

  /// VPN is in the process of disconnecting
  disconnecting,

  /// VPN encountered an error
  error,

  /// VPN permission not granted
  permissionDenied,
}

/// Extension methods for VpnState
extension VpnStateExtension on VpnState {
  bool get isConnected => this == VpnState.connected;
  bool get isDisconnected => this == VpnState.disconnected;
  bool get isTransitioning =>
      this == VpnState.connecting || this == VpnState.disconnecting;
  bool get canToggle => !isTransitioning;

  String get displayName {
    switch (this) {
      case VpnState.disconnected:
        return 'Disconnected';
      case VpnState.connecting:
        return 'Connecting...';
      case VpnState.connected:
        return 'Protected';
      case VpnState.disconnecting:
        return 'Disconnecting...';
      case VpnState.error:
        return 'Error';
      case VpnState.permissionDenied:
        return 'Permission Required';
    }
  }

  String get description {
    switch (this) {
      case VpnState.disconnected:
        return 'Tap to enable protection';
      case VpnState.connecting:
        return 'Setting up privacy shield...';
      case VpnState.connected:
        return 'Your device is protected';
      case VpnState.disconnecting:
        return 'Shutting down...';
      case VpnState.error:
        return 'Something went wrong';
      case VpnState.permissionDenied:
        return 'VPN permission is required';
    }
  }
}
