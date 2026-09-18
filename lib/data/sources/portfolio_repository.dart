import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/portfolio.dart';

const portfolioAssetPath = 'assets/data/portfolio.json';

/// Reads the portfolio content from the bundled JSON. Swapping the asset for
/// real CV data needs no UI change.
Future<PortfolioData> loadPortfolio() async {
  final raw = await rootBundle.loadString(portfolioAssetPath);
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return PortfolioData.fromJson(json);
}

final portfolioProvider =
    FutureProvider<PortfolioData>((ref) => loadPortfolio());
