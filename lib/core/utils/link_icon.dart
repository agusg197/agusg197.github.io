import 'package:flutter/material.dart';

/// Maps the JSON `icon` key of a social link to a Material icon.
IconData linkIcon(String key) => switch (key.toLowerCase()) {
      'github' => Icons.code,
      'linkedin' => Icons.work_outline,
      'mail' || 'email' => Icons.alternate_email,
      'twitter' || 'x' => Icons.tag,
      'web' || 'site' => Icons.public,
      _ => Icons.link,
    };
