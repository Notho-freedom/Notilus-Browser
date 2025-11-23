import '../app_theme.dart';
import '../../utils/color_utils.dart';

class DraculaTheme extends AppTheme {
  DraculaTheme()
      : super(
          name: 'Dracula',
          background: ColorUtils.hexToColor('282A36'),
          surface: ColorUtils.hexToColor('343746'),
          primary: ColorUtils.hexToColor('FF5555'),
          secondary: ColorUtils.hexToColor('BD93F9'),
          accent: ColorUtils.hexToColor('50FA7B'),
          text: ColorUtils.hexToColor('F8F8F2'),
          textSecondary: ColorUtils.hexToColor('6272A4'),
          error: ColorUtils.hexToColor('FF5555'),
          success: ColorUtils.hexToColor('50FA7B'),
          warning: ColorUtils.hexToColor('F1FA8C'),
          border: ColorUtils.hexToColor('44475A'),
          hover: ColorUtils.hexToColor('3E4152'),
          selected: ColorUtils.hexToColor('BD93F9'),
        );
}

