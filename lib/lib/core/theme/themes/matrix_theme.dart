import '../app_theme.dart';
import '../../utils/color_utils.dart';

class MatrixTheme extends AppTheme {
  MatrixTheme()
      : super(
          name: 'Matrix',
          background: ColorUtils.hexToColor('000000'),
          surface: ColorUtils.hexToColor('0A0A0A'),
          primary: ColorUtils.hexToColor('00FF00'),
          secondary: ColorUtils.hexToColor('00CC00'),
          accent: ColorUtils.hexToColor('00FF88'),
          text: ColorUtils.hexToColor('00FF00'),
          textSecondary: ColorUtils.hexToColor('00AA00'),
          error: ColorUtils.hexToColor('FF0000'),
          success: ColorUtils.hexToColor('00FF00'),
          warning: ColorUtils.hexToColor('FFFF00'),
          border: ColorUtils.hexToColor('003300'),
          hover: ColorUtils.hexToColor('0F0F0F'),
          selected: ColorUtils.hexToColor('00FF00'),
        );
}

