import 'package:flutter/material.dart';

import '../../../../core/domain/user_role.dart';

extension UserRoleUi on UserRole {
  IconData get icon {
    switch (this) {
      case UserRole.cliente:
        return Icons.person_outline_rounded;
      case UserRole.especialista:
        return Icons.engineering_outlined;
      case UserRole.administrador:
        return Icons.shield_outlined;
    }
  }
}
