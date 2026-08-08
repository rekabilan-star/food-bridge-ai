import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class RadioGroup extends StatelessWidget {
  final String selectedValue;
  final Function(String) onChanged;
  final List<String> options;

  const RadioGroup({
    super.key,
    required this.selectedValue,
    required this.onChanged,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((option) => Expanded(
        child: InkWell(
          onTap: () => onChanged(option),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selectedValue == option ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selectedValue == option ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent),
            ),
            child: Center(
              child: Text(option, style: TextStyle(
                fontSize: 12, 
                fontWeight: selectedValue == option ? FontWeight.bold : FontWeight.normal,
                color: selectedValue == option ? AppColors.primary : Colors.grey[600],
              )),
            ),
          ),
        ),
      )).toList(),
    );
  }
}
