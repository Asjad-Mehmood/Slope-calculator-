// What the Help box and Report a problem say about Slope Calculator
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../brand.dart';
import 'help.dart';

final appInfo = AppInfo(
  name: appName,
  version: appVersion,
  publisher: appPublisher,
  program: 'slope',
  guideUrl: '$websiteUrl/slope-calculation',
  whatsNewUrl: '$websiteUrl/whats-new/slope',
  openUrl: (url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  },
  icon: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset('assets/brand/icon-512.png')),
);
