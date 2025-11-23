import 'app_theme.dart';
import '../utils/color_utils.dart';

class DarkRedTheme extends AppTheme {
  DarkRedTheme()
      : super(
          name: 'Dark Red',
          background: ColorUtils.hexToColor('0D0D0D'),
          surface: ColorUtils.hexToColor('1A1A1A'),
          primary: ColorUtils.hexToColor('FF0040'),
          secondary: ColorUtils.hexToColor('FF3366'),
          accent: ColorUtils.hexToColor('00FF88'),
          text: ColorUtils.hexToColor('E0E0E0'),
          textSecondary: ColorUtils.hexToColor('888888'),
          error: ColorUtils.hexToColor('FF0040'),
          success: ColorUtils.hexToColor('00FF88'),
          warning: ColorUtils.hexToColor('FFAA00'),
          border: ColorUtils.hexToColor('333333'),
          hover: ColorUtils.hexToColor('2A2A2A'),
          selected: ColorUtils.hexToColor('FF0040'),
        );
}

