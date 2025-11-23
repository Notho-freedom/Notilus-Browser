import '../app_theme.dart';
import '../../utils/color_utils.dart';

class DarkBlueTheme extends AppTheme {
  DarkBlueTheme()
      : super(
          name: 'Dark Blue',
          background: ColorUtils.hexToColor('0A0E27'),
          surface: ColorUtils.hexToColor('151B3D'),
          primary: ColorUtils.hexToColor('00D4FF'),
          secondary: ColorUtils.hexToColor('0099CC'),
          accent: ColorUtils.hexToColor('00FF88'),
          text: ColorUtils.hexToColor('E0E0E0'),
          textSecondary: ColorUtils.hexToColor('888888'),
          error: ColorUtils.hexToColor('FF3366'),
          success: ColorUtils.hexToColor('00FF88'),
          warning: ColorUtils.hexToColor('FFAA00'),
          border: ColorUtils.hexToColor('1F2A4D'),
          hover: ColorUtils.hexToColor('1F2A5D'),
          selected: ColorUtils.hexToColor('00D4FF'),
        );
}

