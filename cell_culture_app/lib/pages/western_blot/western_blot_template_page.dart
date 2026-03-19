import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/western_blot_excel_service.dart';
import 'dialogs/edit_sample_dialog.dart';
import 'dialogs/edit_standard_dialog.dart';
import 'helpers/western_blot_calculator.dart';
import 'models/gel_mix_recipe.dart';
import 'models/western_sample_row.dart';
import 'models/western_standard_row.dart';
import 'widgets/gel_recipe_card.dart';
import 'widgets/legend_widget.dart';
import 'widgets/sample_card.dart';
import 'widgets/standard_card.dart';
import 'widgets/summary_cards.dart';
import 'widgets/western_form_widgets.dart';