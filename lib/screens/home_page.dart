import 'package:astral/wid/home/about_home.dart';
import 'package:astral/wid/home/bugcs.dart';
import 'package:astral/wid/home/servers_home.dart';
import 'package:astral/wid/home/udp_log.dart';
import 'package:astral/wid/home/user_ip.dart';
import 'package:astral/wid/home/virtual_ip.dart';
import 'package:astral/wid/home/connect_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 根据宽度计算列数
  int _getColumnCount(double width) {
    if (width >= 1200) {
      return 5;
    } else if (width >= 900) {
      return 4;
    } else if (width >= 600) {
      return 3;
    }
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final columnCount = _getColumnCount(width);
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: StaggeredGrid.count(
                crossAxisCount: columnCount,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  VirtualIpBox(),
                  UserIpBox(),
                  ServersHome(),
                  UdpLog(),
                  AboutHome(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: const ConnectButton(),
    );
  }
}
