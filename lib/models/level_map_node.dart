import 'package:flutter/material.dart';

class LevelMapNode {
  final int lessonIndex;
  final String title;
  final String subtitleKk;
  final String description;
  final Offset center;

  const LevelMapNode({
    required this.lessonIndex,
    required this.title,
    required this.subtitleKk,
    required this.description,
    required this.center,
  });
}
