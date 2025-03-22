import 'dart:io';

class FirewallController {
  static const String _powerShellPath = 'powershell.exe';
  
  static Future<Map<String, bool>> getFirewallStatus() async {
    final result = await Process.run(_powerShellPath, [
      'Get-NetFirewallProfile | Select-Object Name,Enabled | ConvertTo-Json'
    ]);
    
    if (result.exitCode != 0) return {};
    
    final List<dynamic> profiles = RegExp(r'\{[^}]+\}')
        .allMatches(result.stdout.toString())
        .map((m) => m.group(0))
        .toList();
        
    Map<String, bool> status = {};
    for (var profile in profiles) {
      if (profile.toString().contains('"Name"')) {
        final name = RegExp(r'"Name"\s*:\s*"([^"]+)"').firstMatch(profile)?.group(1);
        final enabled = profile.toString().contains('"Enabled" : true');
        if (name != null) {
          status[name] = enabled;
        }
      }
    }
    
    return status;
  }

  static Future<bool> setFirewallStatus(String profile, bool enable) async {
    final result = await Process.run(_powerShellPath, [
      'Set-NetFirewallProfile -Profile $profile -Enabled ${enable ? "True" : "False"}'
    ], runInShell: true);
    
    return result.exitCode == 0;
  }

  static Future<bool> setAllFirewallStatus(bool enable) async {
    final result = await Process.run(_powerShellPath, [
      'Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled ${enable ? "True" : "False"}'
    ], runInShell: true);
    
    return result.exitCode == 0;
  }
}