import 'themes/admin_theme.dart';
import 'themes/ant.dart';
import 'themes/carbon.dart';
import 'themes/fluent.dart';
import 'themes/iris.dart';
import 'themes/material.dart';
import 'themes/shadcn.dart';

export 'themes/admin_theme.dart';
export 'themes/ant.dart';
export 'themes/carbon.dart';
export 'themes/fluent.dart';
export 'themes/iris.dart';
export 'themes/material.dart';
export 'themes/shadcn.dart';

/// The themes the kit ships: Iris, Material, shadcn, Ant, Fluent and Carbon.
/// The list is unmodifiable; to offer other themes, build your own list
/// (`[...adminThemes, myTheme]`) of [AdminTheme]s made with [AdminTheme.from].
/// Listing them loads nothing: each builds its tokens, and fetches its Google
/// Font, when they are first read.
final adminThemes = List<AdminTheme>.unmodifiable([
  irisTheme,
  materialTheme,
  shadcnTheme,
  antTheme,
  fluentTheme,
  carbonTheme,
]);
