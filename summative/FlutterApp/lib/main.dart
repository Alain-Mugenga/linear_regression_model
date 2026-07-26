import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api_service.dart';

void main() {
  runApp(const FootballValueApp());
}

class FootballValueApp extends StatelessWidget {
  const FootballValueApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF123B6D),
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'African Football Value Predictor',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: colorScheme.primary,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
      ),
      home: const PredictionPage(),
    );
  }
}

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  late final Map<String, TextEditingController> _controllers;

  String _nationality = 'RWA';
  String _positionCode = 'F';
  bool _isLoading = false;
  double? _prediction;
  String? _errorMessage;

  static const Map<String, String> _nationalities = {
    'ALG': 'Algeria',
    'BUR': 'Burkina Faso',
    'CIV': "Côte d'Ivoire",
    'CMR': 'Cameroon',
    'COD': 'DR Congo',
    'EGY': 'Egypt',
    'GAM': 'Gambia',
    'GBS': 'Guinea-Bissau',
    'GHA': 'Ghana',
    'MAR': 'Morocco',
    'MLI': 'Mali',
    'NGR': 'Nigeria',
    'RWA': 'Rwanda',
    'SEN': 'Senegal',
    'ZAM': 'Zambia',
    'ZIM': 'Zimbabwe',
  };

  static const Map<String, String> _positions = {
    'D': 'Defender',
    'OS': 'Midfielder',
    'F': 'Forward',
  };

  @override
  void initState() {
    super.initState();

    _controllers = {
      'age': TextEditingController(text: '21'),
      'season': TextEditingController(text: '24/25'),
      'league': TextEditingController(text: 'Premier League'),
      'competition_category': TextEditingController(text: 'Domestic League'),
      'matches_played': TextEditingController(text: '24'),
      'minutes_played': TextEditingController(text: '1800'),
      'goals': TextEditingController(text: '8'),
      'assists': TextEditingController(text: '5'),
      'average_rating': TextEditingController(text: '7.1'),
      'total_shots': TextEditingController(text: '55'),
      'shots_on_target': TextEditingController(text: '24'),
      'big_chances_missed': TextEditingController(text: '6'),
      'key_passes': TextEditingController(text: '31'),
      'big_chances_created': TextEditingController(text: '9'),
      'successful_dribbles': TextEditingController(text: '42'),
      'accurate_passes': TextEditingController(text: '820'),
      'pass_accuracy_percent': TextEditingController(text: '82'),
      'accurate_long_balls': TextEditingController(text: '68'),
      'long_ball_accuracy_percent': TextEditingController(text: '59'),
      'accurate_crosses': TextEditingController(text: '22'),
      'cross_accuracy_percent': TextEditingController(text: '31'),
      'clearances': TextEditingController(text: '18'),
      'yellow_cards': TextEditingController(text: '3'),
      'red_cards': TextEditingController(text: '0'),
      'errors_leading_to_goal': TextEditingController(text: '0'),
      'dribbled_past': TextEditingController(text: '14'),
      'tackles': TextEditingController(text: '36'),
      'interceptions': TextEditingController(text: '19'),
      'blocked_shots': TextEditingController(text: '4'),
      'aerial_duels_won': TextEditingController(text: '27'),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _apiService.close();
    super.dispose();
  }

  Future<void> _predict() async {
    FocusScope.of(context).unfocus();

    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      setState(() {
        _prediction = null;
        _errorMessage = 'Correct the highlighted fields before predicting.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _prediction = null;
      _errorMessage = null;
    });

    try {
      final prediction = await _apiService.predict(_buildPayload());

      if (!mounted) {
        return;
      }

      setState(() {
        _prediction = prediction;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _buildPayload() {
    return {
      'age': _requiredInt('age'),
      'nationality': _nationality,
      'position_code': _positionCode,
      'season': _controllers['season']!.text.trim(),
      'league': _controllers['league']!.text.trim(),
      'competition_category':
          _controllers['competition_category']!.text.trim(),
      'matches_played': _requiredInt('matches_played'),
      'minutes_played': _requiredInt('minutes_played'),
      'goals': _requiredInt('goals'),
      'assists': _requiredInt('assists'),
      'average_rating': _nullableDouble('average_rating'),
      'total_shots': _nullableDouble('total_shots'),
      'shots_on_target': _nullableDouble('shots_on_target'),
      'big_chances_missed': _nullableInt('big_chances_missed'),
      'key_passes': _nullableInt('key_passes'),
      'big_chances_created': _nullableInt('big_chances_created'),
      'successful_dribbles': _nullableInt('successful_dribbles'),
      'accurate_passes': _nullableDouble('accurate_passes'),
      'pass_accuracy_percent': _nullableDouble('pass_accuracy_percent'),
      'accurate_long_balls': _nullableDouble('accurate_long_balls'),
      'long_ball_accuracy_percent':
          _nullableDouble('long_ball_accuracy_percent'),
      'accurate_crosses': _nullableDouble('accurate_crosses'),
      'cross_accuracy_percent': _nullableDouble('cross_accuracy_percent'),
      'clearances': _nullableInt('clearances'),
      'yellow_cards': _nullableInt('yellow_cards'),
      'red_cards': _nullableInt('red_cards'),
      'errors_leading_to_goal': _nullableInt('errors_leading_to_goal'),
      'dribbled_past': _nullableInt('dribbled_past'),
      'tackles': _nullableInt('tackles'),
      'interceptions': _nullableInt('interceptions'),
      'blocked_shots': _nullableDouble('blocked_shots'),
      'aerial_duels_won': _nullableDouble('aerial_duels_won'),
    };
  }

  int _requiredInt(String key) {
    return int.parse(_controllers[key]!.text.trim());
  }

  int? _nullableInt(String key) {
    final value = _controllers[key]!.text.trim();
    return value.isEmpty ? null : int.parse(value);
  }

  double? _nullableDouble(String key) {
    final value = _controllers[key]!.text.trim();
    return value.isEmpty ? null : double.parse(value);
  }

  void _reset() {
    _formKey.currentState?.reset();

    setState(() {
      _nationality = 'RWA';
      _positionCode = 'F';
      _prediction = null;
      _errorMessage = null;

      _controllers['age']!.text = '21';
      _controllers['season']!.text = '24/25';
      _controllers['league']!.text = 'Premier League';
      _controllers['competition_category']!.text = 'Domestic League';
      _controllers['matches_played']!.text = '24';
      _controllers['minutes_played']!.text = '1800';
      _controllers['goals']!.text = '8';
      _controllers['assists']!.text = '5';

      for (final entry in _controllers.entries) {
        if (!{
          'age',
          'season',
          'league',
          'competition_category',
          'matches_played',
          'minutes_played',
          'goals',
          'assists',
        }.contains(entry.key)) {
          entry.value.clear();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('African Football Value Predictor'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1050),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 20),
                    _SectionCard(
                      title: 'Player profile',
                      subtitle: 'Required information about the player.',
                      child: _responsiveFields(
                        context,
                        [
                          _numberField(
                            keyName: 'age',
                            label: 'Age',
                            required: true,
                            min: 16,
                            max: 25,
                            decimal: false,
                          ),
                          _nationalityField(),
                          _positionField(),
                          _seasonField(),
                          _textField(
                            keyName: 'league',
                            label: 'League',
                            required: true,
                            hint: 'Example: Premier League',
                          ),
                          _textField(
                            keyName: 'competition_category',
                            label: 'Competition category',
                            required: true,
                            hint: 'Example: Domestic League',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Match contribution',
                      subtitle: 'Required match and attacking statistics.',
                      child: _responsiveFields(
                        context,
                        [
                          _numberField(
                            keyName: 'matches_played',
                            label: 'Matches played',
                            required: true,
                            min: 1,
                            max: 80,
                            decimal: false,
                          ),
                          _numberField(
                            keyName: 'minutes_played',
                            label: 'Minutes played',
                            required: true,
                            min: 1,
                            max: 7000,
                            decimal: false,
                          ),
                          _numberField(
                            keyName: 'goals',
                            label: 'Goals',
                            required: true,
                            min: 0,
                            max: 100,
                            decimal: false,
                          ),
                          _numberField(
                            keyName: 'assists',
                            label: 'Assists',
                            required: true,
                            min: 0,
                            max: 100,
                            decimal: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAdvancedInputs(context),
                    const SizedBox(height: 22),
                    _buildActions(),
                    const SizedBox(height: 18),
                    _buildResultArea(context),
                    const SizedBox(height: 16),
                    Text(
                      'The prediction is an estimate from historical data and '
                      'should support—not replace—professional scouting.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary,
            colors.primaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.sports_soccer,
            size: 42,
            color: colors.onPrimary,
          ),
          const SizedBox(height: 14),
          Text(
            'Estimate a young player’s market value',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter player and performance information, then press Predict. '
            'Required fields are marked with an asterisk.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.onPrimary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedInputs(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        title: const Text(
          'Advanced performance inputs',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: const Text(
          'Optional fields improve the information supplied to the model.',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        children: [
          _subheading(context, 'Rating, shooting and creation'),
          _responsiveFields(
            context,
            [
              _numberField(
                keyName: 'average_rating',
                label: 'Average rating',
                min: 0,
                max: 10,
              ),
              _numberField(
                keyName: 'total_shots',
                label: 'Total shots',
                min: 0,
                max: 500,
              ),
              _numberField(
                keyName: 'shots_on_target',
                label: 'Shots on target',
                min: 0,
                max: 500,
              ),
              _numberField(
                keyName: 'big_chances_missed',
                label: 'Big chances missed',
                min: 0,
                max: 100,
                decimal: false,
              ),
              _numberField(
                keyName: 'key_passes',
                label: 'Key passes',
                min: 0,
                max: 500,
                decimal: false,
              ),
              _numberField(
                keyName: 'big_chances_created',
                label: 'Big chances created',
                min: 0,
                max: 100,
                decimal: false,
              ),
              _numberField(
                keyName: 'successful_dribbles',
                label: 'Successful dribbles',
                min: 0,
                max: 500,
                decimal: false,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _subheading(context, 'Passing and crossing'),
          _responsiveFields(
            context,
            [
              _numberField(
                keyName: 'accurate_passes',
                label: 'Accurate passes',
                min: 0,
                max: 10000,
              ),
              _numberField(
                keyName: 'pass_accuracy_percent',
                label: 'Pass accuracy (%)',
                min: 0,
                max: 100,
              ),
              _numberField(
                keyName: 'accurate_long_balls',
                label: 'Accurate long balls',
                min: 0,
                max: 2000,
              ),
              _numberField(
                keyName: 'long_ball_accuracy_percent',
                label: 'Long-ball accuracy (%)',
                min: 0,
                max: 100,
              ),
              _numberField(
                keyName: 'accurate_crosses',
                label: 'Accurate crosses',
                min: 0,
                max: 1000,
              ),
              _numberField(
                keyName: 'cross_accuracy_percent',
                label: 'Cross accuracy (%)',
                min: 0,
                max: 100,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _subheading(context, 'Defensive contribution'),
          _responsiveFields(
            context,
            [
              _numberField(
                keyName: 'clearances',
                label: 'Clearances',
                min: 0,
                max: 1000,
                decimal: false,
              ),
              _numberField(
                keyName: 'yellow_cards',
                label: 'Yellow cards',
                min: 0,
                max: 50,
                decimal: false,
              ),
              _numberField(
                keyName: 'red_cards',
                label: 'Red cards',
                min: 0,
                max: 20,
                decimal: false,
              ),
              _numberField(
                keyName: 'errors_leading_to_goal',
                label: 'Errors leading to goal',
                min: 0,
                max: 50,
                decimal: false,
              ),
              _numberField(
                keyName: 'dribbled_past',
                label: 'Times dribbled past',
                min: 0,
                max: 500,
                decimal: false,
              ),
              _numberField(
                keyName: 'tackles',
                label: 'Tackles',
                min: 0,
                max: 1000,
                decimal: false,
              ),
              _numberField(
                keyName: 'interceptions',
                label: 'Interceptions',
                min: 0,
                max: 1000,
                decimal: false,
              ),
              _numberField(
                keyName: 'blocked_shots',
                label: 'Blocked shots',
                min: 0,
                max: 500,
              ),
              _numberField(
                keyName: 'aerial_duels_won',
                label: 'Aerial duels won',
                min: 0,
                max: 1000,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          onPressed: _isLoading ? null : _predict,
          icon: _isLoading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_graph),
          label: Text(_isLoading ? 'Predicting…' : 'Predict'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(190, 52),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _isLoading ? null : _reset,
          icon: const Icon(Icons.restart_alt),
          label: const Text('Reset'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(140, 52),
          ),
        ),
      ],
    );
  }

  Widget _buildResultArea(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Color background;
    Color foreground;
    IconData icon;
    String title;
    String message;

    if (_prediction != null) {
      background = const Color(0xFFE7F7ED);
      foreground = const Color(0xFF176B3A);
      icon = Icons.check_circle;
      title = 'Predicted market value';
      message = '€${_formatNumber(_prediction!)}';
    } else if (_errorMessage != null) {
      background = colors.errorContainer;
      foreground = colors.onErrorContainer;
      icon = Icons.error_outline;
      title = 'Prediction could not be completed';
      message = _errorMessage!;
    } else {
      background = colors.surfaceContainerHighest;
      foreground = colors.onSurfaceVariant;
      icon = Icons.insights;
      title = 'Prediction result';
      message = 'Your predicted value or an error message will appear here.';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 5),
                SelectableText(
                  message,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: foreground,
                        fontWeight:
                            _prediction == null ? FontWeight.w500 : FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _responsiveFields(
    BuildContext context,
    List<Widget> fields,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final width = isWide
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: fields
              .map(
                (field) => SizedBox(
                  width: width,
                  child: field,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _subheading(BuildContext context, String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }

  Widget _textField({
    required String keyName,
    required String label,
    bool required = false,
    String? hint,
  }) {
    return TextFormField(
      controller: _controllers[keyName],
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
      ),
      validator: (value) {
        final trimmed = value?.trim() ?? '';

        if (required && trimmed.isEmpty) {
          return '$label is required.';
        }

        if (trimmed.length > 100) {
          return '$label must be 100 characters or fewer.';
        }

        return null;
      },
    );
  }

  Widget _seasonField() {
    return TextFormField(
      controller: _controllers['season'],
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Season *',
        hintText: '24/25 or 2024',
      ),
      validator: (value) {
        final trimmed = value?.trim() ?? '';

        if (trimmed.isEmpty) {
          return 'Season is required.';
        }

        final pattern = RegExp(r'^(\d{2}/\d{2}|\d{4})$');

        if (!pattern.hasMatch(trimmed)) {
          return 'Use a format such as 24/25 or 2024.';
        }

        return null;
      },
    );
  }

  Widget _numberField({
    required String keyName,
    required String label,
    bool required = false,
    double? min,
    double? max,
    bool decimal = true,
  }) {
    return TextFormField(
      controller: _controllers[keyName],
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          decimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]'),
        ),
      ],
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: required ? null : 'Optional',
      ),
      validator: (value) {
        final trimmed = value?.trim() ?? '';

        if (trimmed.isEmpty) {
          return required ? '$label is required.' : null;
        }

        final number = double.tryParse(trimmed);

        if (number == null) {
          return 'Enter a valid number.';
        }

        if (!decimal && number % 1 != 0) {
          return 'Enter a whole number.';
        }

        if (min != null && number < min) {
          return '$label must be at least ${_cleanLimit(min)}.';
        }

        if (max != null && number > max) {
          return '$label must be at most ${_cleanLimit(max)}.';
        }

        return null;
      },
    );
  }

  Widget _nationalityField() {
    return DropdownButtonFormField<String>(
      initialValue: _nationality,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Nationality *',
      ),
      items: _nationalities.entries
          .map(
            (entry) => DropdownMenuItem(
              value: entry.key,
              child: Text('${entry.value} (${entry.key})'),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _nationality = value;
          });
        }
      },
    );
  }

  Widget _positionField() {
    return DropdownButtonFormField<String>(
      initialValue: _positionCode,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Position *',
      ),
      items: _positions.entries
          .map(
            (entry) => DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _positionCode = value;
          });
        }
      },
    );
  }

  String _cleanLimit(double value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toString();
  }

  String _formatNumber(double value) {
    final rounded = value.round().toString();
    final buffer = StringBuffer();

    for (var index = 0; index < rounded.length; index++) {
      final remaining = rounded.length - index;

      buffer.write(rounded[index]);

      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }

    return buffer.toString();
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}
