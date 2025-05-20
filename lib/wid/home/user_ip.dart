import 'package:astral/k/app_s/aps.dart';
import 'package:astral/wid/home_box.dart';
import 'package:astral/wid/canvas_jump.dart';
import 'package:astral/k/models/room.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class UserIpBox extends StatefulWidget {
  const UserIpBox({super.key});

  @override
  State<UserIpBox> createState() => _UserIpBoxState();
}

class _UserIpBoxState extends State<UserIpBox> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _virtualIPController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();

  final FocusNode _usernameControllerFocusNode = FocusNode();
  final FocusNode _virtualIPFocusNode = FocusNode();

  final Aps _aps = Aps();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _usernameController.text = _aps.PlayerName.value;
      _virtualIPController.text = _aps.ipv4.value;
      _roomController.text = _aps.selectroom.value?.name ?? '';

      effect(() {
        final value = _aps.PlayerName.value;
        final value2 = _aps.ipv4.value;
        final value3 = _aps.selectroom.value?.name ?? '';
        if (_usernameController.text != value) {
          _usernameController.text = value;
        }
        if (_virtualIPController.text != value2) {
          _virtualIPController.text = value2;
        }
        if (_roomController.text != value3) {
          _roomController.text = value3;
        }
      });
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _virtualIPController.dispose();
    _usernameControllerFocusNode.dispose();
    _virtualIPFocusNode.dispose();
    _roomController.dispose();
    super.dispose();
  }

  bool _isValidIPv4(String ip) {
    final RegExp ipRegex = RegExp(
      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );
    return ipRegex.hasMatch(ip);
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var isValidIP = _isValidIPv4(_aps.ipv4.value);

    return HomeBox(
      widthSpan: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              const Text(
                '用户信息',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
              ),
              const Spacer(),
              if (Aps().Connec_state.watch(context) == CoState.connected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '已锁定',
                    style: TextStyle(
                      color: colorScheme.onSecondaryContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _usernameController,
            focusNode: _usernameControllerFocusNode,
            enabled: (Aps().Connec_state.watch(context) == CoState.connected)
                ? false
                : true,
            onChanged: (value) {
              _aps.updatePlayerName(value);
            },
            decoration: InputDecoration(
              labelText: '用户名',
              border: const OutlineInputBorder(),
              prefixIcon: Icon(Icons.person, color: colorScheme.primary),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12), 
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _roomController,
            readOnly: true,
            enabled: Aps().Connec_state.watch(context) != CoState.connected,
            decoration: InputDecoration(
              labelText: '选择房间',
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: const OutlineInputBorder(),
              prefixIcon: Icon(
                Icons.apartment,
                color: colorScheme.primary,
                size: 24,
              ),
              suffixIcon: IconButton(
                icon: Icon(Icons.menu),
                color: colorScheme.primary,
                iconSize: 24,
                onPressed: () => CanvasJump.show(
                  context,
                  rooms: _aps.rooms.watch(context).cast<Room>(),
                  onSelect: (Room room) {
                    _aps.setRoom(room);
                    _roomController.text = room.name;
                  },
                ),
              ),
              errorText: _aps.selectroom.watch(context) == null
                  ? '请选择房间'
                  : null,
            ),
          ),
          const SizedBox(height: 9), 

          SizedBox(
            height: 60,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _virtualIPController,
                    focusNode: _virtualIPFocusNode,
                    enabled: !_aps.dhcp.watch(context) &&
                        (Aps().Connec_state.watch(context) != CoState.connected),
                    onChanged: (value) {
                      if (!_aps.dhcp.watch(context)) {
                        setState(() {
                          isValidIP = _aps.dhcp.watch(context) || _isValidIPv4(value);
                        });
                        _aps.updateIpv4(value);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: '虚拟网IP',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lan, color: colorScheme.primary),
                      floatingLabelBehavior: FloatingLabelBehavior.always, 
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12), 
                      errorText: !isValidIP && !_aps.dhcp.watch(context)
                          ? '请输入有效的IPv4地址'
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: [
                    Switch(
                      value: _aps.dhcp.watch(context),
                      onChanged: (value) {
                        if (Aps().Connec_state.watch(context) == CoState.idle) {
                          _aps.updateDhcp(value);
                        }
                      },
                    ),
                    Text(
                      _aps.dhcp.watch(context) ? "自动" : "手动",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_aps.dhcp.watch(context))
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                '系统将自动分配虚拟网IP',
                style: TextStyle(fontSize: 12),
              ),
            )
          else
            const SizedBox(height: 12),
        ],
      ),
    );
  }
}
