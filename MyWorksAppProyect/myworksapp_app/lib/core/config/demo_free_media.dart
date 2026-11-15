/// Imágenes demo con [Unsplash](https://unsplash.com/license) (uso gratuito).
/// Cada clave corresponde a una foto acorde a la descripción del portafolio o perfil.
class DemoFreeMedia {
  DemoFreeMedia._();

  static const _params = 'auto=format&fit=crop&q=80';

  static const Map<String, String> _urls = {
    // —— Perfiles usuario ——
    'profile_client': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&$_params',

    // —— Perfiles trabajadores ——
    'profile_electrical_1': 'https://images.unsplash.com/photo-1621905252507-b3542da74d4d?w=400&h=400&$_params',
    'profile_electrical_2': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400&h=400&$_params',
    'profile_plumbing_1': 'https://images.unsplash.com/photo-1607990281513-2c110a25bd8c?w=400&h=400&$_params',
    'profile_plumbing_2': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=400&$_params',
    'profile_cleaning_1': 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=400&h=400&$_params',
    'profile_cleaning_2': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=400&$_params',
    'profile_construction_1': 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=400&h=400&$_params',
    'profile_construction_2': 'https://images.unsplash.com/photo-1519081420755-e393a56b3729?w=400&h=400&$_params',
    'profile_assembly_1': 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400&h=400&$_params',
    'profile_assembly_2': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&$_params',
    'profile_tech_1': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=400&$_params',
    'profile_tech_2': 'https://images.unsplash.com/photo-1573497019940-88c827e06e9d?w=400&h=400&$_params',
    'profile_garden_1': 'https://images.unsplash.com/photo-1556157382-97eda2d62296?w=400&h=400&$_params',
    'profile_garden_2': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&h=400&$_params',
    'profile_moving_1': 'https://images.unsplash.com/photo-1566492031773-4f4e44671857?w=400&h=400&$_params',
    'profile_moving_2': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&h=400&$_params',

    // —— Electricidad ——
    'electrical_led': 'https://images.unsplash.com/photo-1524484485821-3806d4c35c0c?w=600&h=450&$_params',
    'electrical_outlets': 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=600&h=450&$_params',
    'electrical_kitchen_video': 'https://images.unsplash.com/photo-1558002032-0e30cb3876ea?w=600&h=450&$_params',
    'electrical_panel': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&h=450&$_params',
    'electrical_conduit_video': 'https://images.unsplash.com/photo-1581092160562-40aa08e78837?w=600&h=450&$_params',

    // —— Gasfitería ——
    'plumbing_faucet': 'https://images.unsplash.com/photo-1585703903930-0b8e341a0895?w=600&h=450&$_params',
    'plumbing_leak_video': 'https://images.unsplash.com/photo-1607472586893-adb46a45693c?w=600&h=450&$_params',
    'plumbing_sink': 'https://images.unsplash.com/photo-1556911220-e85b92beb8e2?w=600&h=450&$_params',
    'plumbing_drain': 'https://images.unsplash.com/photo-1584622650113-497fd586344c?w=600&h=450&$_params',

    // —— Limpieza ——
    'cleaning_apartment': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=600&h=450&$_params',
    'cleaning_move_video': 'https://images.unsplash.com/photo-1628177140286-e383192be48f?w=600&h=450&$_params',
    'cleaning_kitchen_bath': 'https://images.unsplash.com/photo-1556911220-b726a5a4a525?w=600&h=450&$_params',
    'cleaning_office': 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=600&h=450&$_params',
    'cleaning_windows_video': 'https://images.unsplash.com/photo-1527515635242-2f700d21eb06?w=600&h=450&$_params',

    // —— Construcción ——
    'construction_partition': 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=600&h=450&$_params',
    'construction_wall_video': 'https://images.unsplash.com/photo-1541887878331-04bc286a601d?w=600&h=450&$_params',
    'construction_patio': 'https://images.unsplash.com/photo-1595846519845-68a22516c35c?w=600&h=450&$_params',
    'construction_waterproof': 'https://images.unsplash.com/photo-1565008576549-57569a349814?w=600&h=450&$_params',

    // —— Armado ——
    'assembly_closet': 'https://images.unsplash.com/photo-1555041469-a586c61e8bc7?w=600&h=450&$_params',
    'assembly_desk_video': 'https://images.unsplash.com/photo-1595428774226-ef9c5452e410?w=600&h=450&$_params',
    'assembly_tv_rack': 'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=600&h=450&$_params',
    'assembly_terrace': 'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?w=600&h=450&$_params',

    // —— Soporte técnico ——
    'tech_wifi': 'https://images.unsplash.com/photo-1544197150-9d43e122c4a8?w=600&h=450&$_params',
    'tech_printer_video': 'https://images.unsplash.com/photo-1498049794561-7780e7231661?w=600&h=450&$_params',
    'tech_laptop': 'https://images.unsplash.com/photo-1496181136068-2ce8ab39f198?w=600&h=450&$_params',
    'tech_backup': 'https://images.unsplash.com/photo-1517694712202-14dd65334434?w=600&h=450&$_params',

    // —— Jardinería ——
    'garden_before_after': 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=600&h=450&$_params',
    'garden_hedge_video': 'https://images.unsplash.com/photo-1598902109652-b5c23d69fc96?w=600&h=450&$_params',
    'garden_planters': 'https://images.unsplash.com/photo-1466781783364-82e17564f47a?w=600&h=450&$_params',
    'garden_irrigation': 'https://images.unsplash.com/photo-1413976741887-9f753df98f8a?w=600&h=450&$_params',

    // —— Mudanzas ——
    'moving_apartment': 'https://images.unsplash.com/photo-1600585154340-be6162a9a249?w=600&h=450&$_params',
    'moving_packing_video': 'https://images.unsplash.com/photo-1600518468010-6d62c1586477?w=600&h=450&$_params',
    'moving_office': 'https://images.unsplash.com/photo-1586528111405-b3378ce3527c?w=600&h=450&$_params',
    'moving_appliances': 'https://images.unsplash.com/photo-1558611843-3f61425a74da?w=600&h=450&$_params',
  };

  static String url(String imageKey) {
    return _urls[imageKey] ??
        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&h=450&$_params';
  }

  static String profileForWorker(String workerId) {
    // Retratos deterministas por trabajador (pravatar.cc, uso libre en demos).
    return 'https://i.pravatar.cc/400?u=$workerId';
  }

  static String profileForDemoUser() {
    return 'https://i.pravatar.cc/400?u=demo-user-001';
  }

  static String portfolioForKey(String imageKey) =>
      'https://picsum.photos/seed/mwa_$imageKey/600/450';

  static String portfolioThumbnailForKey(String imageKey) =>
      portfolioForKey(imageKey);

  /// Videos demo empaquetados en la app (funcionan sin red y en Windows).
  static const String _portfolioVideoA = 'assets/videos/demo_portfolio_1.mp4';
  static const String _portfolioVideoB = 'assets/videos/demo_portfolio_2.mp4';

  static const Map<String, String> _portfolioVideos = {
    'electrical_kitchen_video': _portfolioVideoA,
    'electrical_conduit_video': _portfolioVideoB,
    'plumbing_leak_video': _portfolioVideoA,
    'cleaning_move_video': _portfolioVideoB,
    'cleaning_windows_video': _portfolioVideoA,
    'construction_wall_video': _portfolioVideoA,
    'assembly_desk_video': _portfolioVideoB,
    'tech_printer_video': _portfolioVideoA,
    'garden_hedge_video': _portfolioVideoB,
    'moving_packing_video': _portfolioVideoA,
  };

  static String portfolioVideoForKey(String imageKey) =>
      _portfolioVideos[imageKey] ?? _portfolioVideoA;

  /// Reemplazar rutas demo antiguas o URLs de Unsplash rotas en portafolio.
  static bool shouldReplaceDemoPortfolioPath(String? path) {
    if (path == null || path.isEmpty) return true;
    if (path.startsWith('demo:')) return true;
    if (path.contains('images.unsplash.com')) return true;
    if (path.contains('picsum.photos/seed/')) return false;
    if (path.startsWith('http')) return false;
    return true;
  }

  /// Solo reemplazar fotos demo remotas rotas o URLs antiguas (Picsum/Unsplash).
  static bool shouldReplaceDemoPhoto(String? path) {
    if (path == null || path.isEmpty) return true;
    if (!path.startsWith('http')) return true;
    if (path.contains('picsum.photos')) return true;
    if (path.contains('images.unsplash.com')) return true;
    if (path.contains('i.pravatar.cc')) return false;
    return false;
  }
}
