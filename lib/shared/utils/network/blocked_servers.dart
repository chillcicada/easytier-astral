class BlockedServers {
  static const List<String> blockedUrls = [
    'js.629957.xyz:11012',
    'nmg.629957.xyz:11010',
    'nmg.629957.xyz:11010',
  ];

  static bool isBlocked(String url) {
    return blockedUrls.contains(url);
  }

  static bool hasBlockedEnabledServer(List<dynamic> servers) {
    return servers.any(
      (server) => server.enable == true && isBlocked(server.url),
    );
  }
}
