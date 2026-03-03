import '../app_theme.dart';
import '../../utils/color_utils.dart';

class CyberpunkTheme extends AppTheme {
  CyberpunkTheme()
      : super(
          name: 'Cyberpunk',
          background: ColorUtils.hexToColor('000000'),
          surface: ColorUtils.hexToColor('1A0033'),
          primary: ColorUtils.hexToColor('FF00FF'),
          secondary: ColorUtils.hexToColor('00FFFF'),
          accent: ColorUtils.hexToColor('FFFF00'),
          text: ColorUtils.hexToColor('FFFFFF'),
          textSecondary: ColorUtils.hexToColor('CCCCCC'),
          error: ColorUtils.hexToColor('FF0000'),
          success: ColorUtils.hexToColor('00FF00'),
          warning: ColorUtils.hexToColor('FFFF00'),
          border: ColorUtils.hexToColor('330066'),
          hover: ColorUtils.hexToColor('2A0044'),
          selected: ColorUtils.hexToColor('FF00FF'),
        );
}

