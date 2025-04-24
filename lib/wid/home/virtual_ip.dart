import 'package:astral/wid/home_box.dart';
import 'package:flutter/material.dart';

class VirtualIpBox extends StatelessWidget {
  const VirtualIpBox({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeBox(
      widthSpan: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.vpn_key, size: 20),
              SizedBox(width: 8),
              Text(
                '虚拟 IP',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text('192.168.1.1', style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
