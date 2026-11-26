// GENERADO por scripts/cobertura/gen_widgets.py. No editar a mano.
// Tests de humo de widgets: montan cada widget contra el backend falso,
// tocan sus botones y escriben en sus campos (test/support/widget_harness.dart).
// ignore_for_file: prefer_const_constructors, deprecated_member_use, unused_import
// ignore_for_file: prefer_single_quotes, avoid_dynamic_calls
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:myworksapp/core/map/app_map_tiles.dart' as f0;
import 'package:myworksapp/core/presentation/pages/help_center_page.dart' as f1;
import 'package:myworksapp/core/presentation/pages/maintenance_page.dart' as f2;
import 'package:myworksapp/core/widgets/app_guided_tour.dart' as f3;
import 'package:myworksapp/core/widgets/confirmation_dialog.dart' as f4;
import 'package:myworksapp/core/widgets/demo_tour_overlay.dart' as f5;
import 'package:myworksapp/core/widgets/design_system/app_auth_scaffold.dart'
    as f6;
import 'package:myworksapp/core/widgets/design_system/app_brand_logo.dart'
    as f7;
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart'
    as f8;
import 'package:myworksapp/core/widgets/design_system/apple_card.dart' as f9;
import 'package:myworksapp/core/widgets/design_system/apple_segmented_picker.dart'
    as f10;
import 'package:myworksapp/core/widgets/design_system/auth_soft_background.dart'
    as f11;
import 'package:myworksapp/core/widgets/design_system/before_after_slider.dart'
    as f12;
import 'package:myworksapp/core/widgets/design_system/danger_button.dart'
    as f13;
import 'package:myworksapp/core/widgets/design_system/empty_state_widget.dart'
    as f14;
import 'package:myworksapp/core/widgets/design_system/error_state_widget.dart'
    as f15;
import 'package:myworksapp/core/widgets/design_system/live_worker_radar_widget.dart'
    as f16;
import 'package:myworksapp/core/database/models/worker_model.dart' as f17;
import 'package:myworksapp/core/widgets/design_system/loading_skeleton.dart'
    as f18;
import 'package:myworksapp/core/widgets/design_system/mesh_gradient_backdrop.dart'
    as f19;
import 'package:myworksapp/core/widgets/design_system/myworks_guarantee_badge.dart'
    as f20;
import 'package:myworksapp/core/widgets/design_system/no_workers_empty_state.dart'
    as f21;
import 'package:myworksapp/core/widgets/design_system/predictive_trust_meter.dart'
    as f22;
import 'package:myworksapp/core/widgets/design_system/premium_glyphs.dart'
    as f23;
import 'package:myworksapp/core/widgets/design_system/primary_button.dart'
    as f24;
import 'package:myworksapp/core/widgets/design_system/responsive_shell.dart'
    as f25;
import 'package:myworksapp/core/widgets/design_system/secondary_button.dart'
    as f26;
import 'package:myworksapp/core/widgets/design_system/service_card.dart' as f27;
import 'package:myworksapp/core/theme/service_card_palettes.dart' as f28;
import 'package:myworksapp/core/database/models/service_model.dart' as f29;
import 'package:myworksapp/core/widgets/design_system/service_pin_dialog.dart'
    as f30;
import 'package:myworksapp/core/widgets/design_system/social_auth_buttons.dart'
    as f31;
import 'package:myworksapp/core/widgets/design_system/spatial_emergency_pulse.dart'
    as f32;
import 'package:myworksapp/core/widgets/design_system/status_badge.dart' as f33;
import 'package:myworksapp/core/widgets/design_system/web_ai_assistant_widget.dart'
    as f34;
import 'package:myworksapp/core/widgets/design_system/worker_card.dart' as f35;
import 'package:myworksapp/core/widgets/empty_state_widget.dart' as f36;
import 'package:myworksapp/core/widgets/error_widget.dart' as f37;
import 'package:myworksapp/core/widgets/escrow_checkout_sheet.dart' as f38;
import 'package:myworksapp/core/domain/price_quote.dart' as f39;
import 'package:myworksapp/core/widgets/evidence_photo_image.dart' as f40;
import 'package:myworksapp/core/database/models/job_photo_model.dart' as f41;
import 'package:myworksapp/core/widgets/hourly_block_selector.dart' as f42;
import 'package:myworksapp/core/widgets/job_location_map.dart' as f43;
import 'package:myworksapp/core/widgets/loading/action_button.dart' as f44;
import 'package:myworksapp/core/widgets/loading/global_loader.dart' as f45;
import 'package:myworksapp/core/widgets/loading_widget.dart' as f46;
import 'package:myworksapp/core/widgets/location_picker_widget.dart' as f47;
import 'package:myworksapp/core/widgets/notification_listener_scope.dart'
    as f48;
import 'package:myworksapp/core/widgets/paginated_list.dart' as f49;
import 'package:myworksapp/core/widgets/permissions/camera_permission_page.dart'
    as f50;
import 'package:myworksapp/core/widgets/permissions/location_permission_page.dart'
    as f51;
import 'package:myworksapp/core/widgets/permissions/permission_request_widget.dart'
    as f52;
import 'package:myworksapp/core/widgets/permissions/storage_permission_page.dart'
    as f53;
import 'package:myworksapp/core/widgets/portfolio_media_tile.dart' as f54;
import 'package:myworksapp/core/widgets/pricing_mode_selector.dart' as f55;
import 'package:myworksapp/core/widgets/pricing_quote_card.dart' as f56;
import 'package:myworksapp/core/widgets/profile_avatar_picker.dart' as f57;
import 'package:myworksapp/core/widgets/saved_card_tile.dart' as f58;
import 'package:myworksapp/core/widgets/service_disclaimer_dialog.dart' as f59;
import 'package:myworksapp/core/widgets/skeleton_loading.dart' as f60;
import 'package:myworksapp/core/widgets/webpay_webview_page.dart' as f61;
import 'support/model_samples.dart';
import 'support/widget_harness.dart';

void main() {
  testWidgets('AppMapTiles completo (core/map/app_map_tiles.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.AppMapTiles(),
        seeded: true, role: 'usuario');
  });
  testWidgets('MapTileCredits completo (core/map/app_map_tiles.dart)',
      (tester) async {
    await smokeWidget(
        tester, () => f0.MapTileCredits(alignment: Alignment.center),
        seeded: true, role: 'usuario');
  });
  testWidgets('MapTileCredits mínimo (core/map/app_map_tiles.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.MapTileCredits(),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'HelpCenterPage completo (core/presentation/pages/help_center_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f1.HelpCenterPage(userRole: 'id-1'),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'HelpCenterPage mínimo (core/presentation/pages/help_center_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f1.HelpCenterPage(),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'MaintenancePage completo (core/presentation/pages/maintenance_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.MaintenancePage(),
        seeded: true, role: 'usuario');
  });
  testWidgets('AppGuidedTour completo (core/widgets/app_guided_tour.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.AppGuidedTour(
            child: const SizedBox(),
            steps: [f3.GuidedTourStep(title: 'id-1', description: 'id-1')],
            shouldShow: () async => true,
            onComplete: () async {},
            badgeLabel: 'id-1'),
        seeded: true,
        role: 'usuario');
  });
  testWidgets('AppGuidedTour mínimo (core/widgets/app_guided_tour.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.AppGuidedTour(
            child: const SizedBox(),
            steps: [f3.GuidedTourStep(title: 'id-1', description: 'id-1')],
            shouldShow: () async => true,
            onComplete: () async {}),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'ConfirmationDialog completo (core/widgets/confirmation_dialog.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f4.ConfirmationDialog(
            title: 'id-1',
            message: 'id-1',
            confirmLabel: 'id-1',
            cancelLabel: 'id-1',
            onConfirm: () {},
            isDestructive: true),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'ConfirmationDialog mínimo (core/widgets/confirmation_dialog.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f4.ConfirmationDialog(
            title: 'id-1', message: 'id-1', onConfirm: () {}),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'CancelJobDialog completo (core/widgets/confirmation_dialog.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.CancelJobDialog(onConfirm: () {}),
        seeded: true, role: 'usuario');
  });
  testWidgets('DemoTourOverlay completo (core/widgets/demo_tour_overlay.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f5.DemoTourOverlay(
            child: const SizedBox(),
            steps: [f3.GuidedTourStep(title: 'id-1', description: 'id-1')]),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'AppAuthScaffold completo (core/widgets/design_system/app_auth_scaffold.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f6.AppAuthScaffold(
            title: 'id-1',
            subtitle: 'id-1',
            child: const SizedBox(),
            badge: 'id-1'),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'AppAuthScaffold mínimo (core/widgets/design_system/app_auth_scaffold.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f6.AppAuthScaffold(
            title: 'id-1', subtitle: 'id-1', child: const SizedBox()),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'AppBrandLogo completo (core/widgets/design_system/app_brand_logo.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f7.AppBrandLogo(
            size: 1.0,
            showText: true,
            textSize: 1.0,
            horizontal: true,
            forceOnLight: true),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'AppBrandLogo mínimo (core/widgets/design_system/app_brand_logo.dart)',
      (tester) async {
    await smokeWidget(tester, () => f7.AppBrandLogo(),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'AppBrandFooter completo (core/widgets/design_system/app_brand_logo.dart)',
      (tester) async {
    await smokeWidget(tester, () => f7.AppBrandFooter(),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'AppGradientAppBar completo (core/widgets/design_system/app_gradient_app_bar.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f8.AppGradientAppBar(
            title: const SizedBox(),
            actions: [const SizedBox()],
            leading: const SizedBox(),
            automaticallyImplyLeading: true,
            bottom: null,
            centerTitle: true),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'AppGradientAppBar mínimo (core/widgets/design_system/app_gradient_app_bar.dart)',
      (tester) async {
    await smokeWidget(tester, () => f8.AppGradientAppBar(),
        seeded: false, role: 'usuario');
  });
  testWidgets('AppleCard completo (core/widgets/design_system/apple_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f9.AppleCard(
            child: const SizedBox(),
            onTap: () {},
            padding: EdgeInsets.zero,
            margin: EdgeInsets.zero,
            backgroundColor: const Color(0xFF000000),
            accentColor: const Color(0xFF000000),
            borderRadius: 1.0,
            isGlass: true,
            enablePressEffect: true),
        seeded: true,
        role: 'usuario');
  });
  testWidgets('AppleCard mínimo (core/widgets/design_system/apple_card.dart)',
      (tester) async {
    await smokeWidget(tester, () => f9.AppleCard(child: const SizedBox()),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'AuthSoftBackground completo (core/widgets/design_system/auth_soft_background.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f11.AuthSoftBackground(
            child: const SizedBox(), showDecorations: true),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'AuthSoftBackground mínimo (core/widgets/design_system/auth_soft_background.dart)',
      (tester) async {
    await smokeWidget(
        tester, () => f11.AuthSoftBackground(child: const SizedBox()),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'BrandPrimaryButton completo (core/widgets/design_system/auth_soft_background.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f11.BrandPrimaryButton(
            label: 'id-1', onPressed: () {}, isLoading: true),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'BrandPrimaryButton mínimo (core/widgets/design_system/auth_soft_background.dart)',
      (tester) async {
    await smokeWidget(
        tester, () => f11.BrandPrimaryButton(label: 'id-1', onPressed: () {}),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'BrandLabeledField completo (core/widgets/design_system/auth_soft_background.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f11.BrandLabeledField(label: 'id-1', child: const SizedBox()),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'BeforeAfterSlider completo (core/widgets/design_system/before_after_slider.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f12.BeforeAfterSlider(
            beforeImageUrl: 'id-1',
            afterImageUrl: 'id-1',
            title: 'id-1',
            height: 1.0),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'BeforeAfterSlider mínimo (core/widgets/design_system/before_after_slider.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f12.BeforeAfterSlider(
            beforeImageUrl: 'id-1', afterImageUrl: 'id-1'),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'DangerButton completo (core/widgets/design_system/danger_button.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f13.DangerButton(
            label: 'id-1',
            onPressed: () {},
            isLoading: true,
            icon: Icons.star,
            outlined: true),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'DangerButton mínimo (core/widgets/design_system/danger_button.dart)',
      (tester) async {
    await smokeWidget(tester, () => f13.DangerButton(label: 'id-1'),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'EmptyStateWidget completo (core/widgets/design_system/empty_state_widget.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f14.EmptyStateWidget(
            icon: Icons.star,
            title: 'id-1',
            message: 'id-1',
            actionLabel: 'id-1',
            onAction: () {},
            secondaryActionLabel: 'id-1',
            onSecondaryAction: () {},
            iconColor: const Color(0xFF000000)),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'EmptyStateWidget mínimo (core/widgets/design_system/empty_state_widget.dart)',
      (tester) async {
    await smokeWidget(
        tester, () => f14.EmptyStateWidget(icon: Icons.star, title: 'id-1'),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'ErrorStateWidget completo (core/widgets/design_system/error_state_widget.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f15.ErrorStateWidget(
            title: 'id-1',
            message: 'id-1',
            actionLabel: 'id-1',
            onRetry: () {},
            icon: Icons.star),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'ErrorStateWidget mínimo (core/widgets/design_system/error_state_widget.dart)',
      (tester) async {
    await smokeWidget(tester, () => f15.ErrorStateWidget(title: 'id-1'),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'LiveWorkerRadarWidget completo (core/widgets/design_system/live_worker_radar_widget.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f16.LiveWorkerRadarWidget(
            workers: [f17.WorkerModel.fromMap(sampleWorkerModel)],
            city: 'id-1'),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'LiveWorkerRadarWidget mínimo (core/widgets/design_system/live_worker_radar_widget.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f16.LiveWorkerRadarWidget(
            workers: [f17.WorkerModel.fromMap(sampleWorkerModel)]),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'HowItWorksCard completo (core/widgets/design_system/loading_skeleton.dart)',
      (tester) async {
    await smokeWidget(tester, () => f18.HowItWorksCard(),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'LoadingSkeleton completo (core/widgets/design_system/loading_skeleton.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f18.LoadingSkeleton(
            width: 1.0, height: 1.0, borderRadius: BorderRadius.zero),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'LoadingSkeleton mínimo (core/widgets/design_system/loading_skeleton.dart)',
      (tester) async {
    await smokeWidget(tester, () => f18.LoadingSkeleton(height: 1.0),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'ListItemSkeleton completo (core/widgets/design_system/loading_skeleton.dart)',
      (tester) async {
    await smokeWidget(tester, () => f18.ListItemSkeleton(),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'JobListSkeleton completo (core/widgets/design_system/loading_skeleton.dart)',
      (tester) async {
    await smokeWidget(tester, () => f18.JobListSkeleton(itemCount: 1),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'JobListSkeleton mínimo (core/widgets/design_system/loading_skeleton.dart)',
      (tester) async {
    await smokeWidget(tester, () => f18.JobListSkeleton(),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'MeshGradientBackdrop completo (core/widgets/design_system/mesh_gradient_backdrop.dart)',
      (tester) async {
    await smokeWidget(tester, () => f19.MeshGradientBackdrop(),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'MyWorksGuaranteeBadge completo (core/widgets/design_system/myworks_guarantee_badge.dart)',
      (tester) async {
    await smokeWidget(tester, () => f20.MyWorksGuaranteeBadge(compact: true),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'MyWorksGuaranteeBadge mínimo (core/widgets/design_system/myworks_guarantee_badge.dart)',
      (tester) async {
    await smokeWidget(tester, () => f20.MyWorksGuaranteeBadge(),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'ProWorkerBadge completo (core/widgets/design_system/myworks_guarantee_badge.dart)',
      (tester) async {
    await smokeWidget(tester, () => f20.ProWorkerBadge(),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'NoWorkersEmptyState completo (core/widgets/design_system/no_workers_empty_state.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f21.NoWorkersEmptyState(
            message: 'id-1',
            hasFilters: true,
            onClearFilters: () {},
            onScheduleLater: () {},
            onExpandSearch: () {}),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'NoWorkersEmptyState mínimo (core/widgets/design_system/no_workers_empty_state.dart)',
      (tester) async {
    await smokeWidget(tester, () => f21.NoWorkersEmptyState(),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'PredictiveTrustMeterWidget completo (core/widgets/design_system/predictive_trust_meter.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f22.PredictiveTrustMeterWidget(
            score: 1.0, fairPriceIndex: 'id-1', reviewsCount: 1),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'PredictiveTrustMeterWidget mínimo (core/widgets/design_system/predictive_trust_meter.dart)',
      (tester) async {
    await smokeWidget(tester, () => f22.PredictiveTrustMeterWidget(),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'PremiumGlyph completo (core/widgets/design_system/premium_glyphs.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f23.PremiumGlyph(
            kind: f23.PremiumGlyphKind.values.first,
            size: 1.0,
            color: const Color(0xFF000000)),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'PremiumGlyph mínimo (core/widgets/design_system/premium_glyphs.dart)',
      (tester) async {
    await smokeWidget(
        tester, () => f23.PremiumGlyph(kind: f23.PremiumGlyphKind.values.first),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'PrimaryButton completo (core/widgets/design_system/primary_button.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f24.PrimaryButton(
            label: 'id-1',
            onPressed: () {},
            isLoading: true,
            icon: Icons.star,
            width: 1.0,
            height: 1.0),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'PrimaryButton mínimo (core/widgets/design_system/primary_button.dart)',
      (tester) async {
    await smokeWidget(tester, () => f24.PrimaryButton(label: 'id-1'),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'ResponsiveShell completo (core/widgets/design_system/responsive_shell.dart)',
      (tester) async {
    await smokeWidget(
        tester, () => f25.ResponsiveShell(child: const SizedBox()),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'SecondaryButton completo (core/widgets/design_system/secondary_button.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f26.SecondaryButton(
            label: 'id-1',
            onPressed: () {},
            isLoading: true,
            icon: Icons.star,
            width: 1.0),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'SecondaryButton mínimo (core/widgets/design_system/secondary_button.dart)',
      (tester) async {
    await smokeWidget(tester, () => f26.SecondaryButton(label: 'id-1'),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'ServiceCard completo (core/widgets/design_system/service_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f27.ServiceCard(
            name: 'id-1',
            description: 'id-1',
            icon: Icons.star,
            onTap: () {},
            color: const Color(0xFF000000),
            palette: f28.ServiceCardPalette(
                background: const Color(0xFF000000),
                iconBackground: const Color(0xFF000000),
                accent: const Color(0xFF000000)),
            compact: true,
            actionLabel: 'id-1',
            categoryKey: 'id-1'),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'ServiceCard mínimo (core/widgets/design_system/service_card.dart)',
      (tester) async {
    await smokeWidget(
        tester, () => f27.ServiceCard(name: 'id-1', icon: Icons.star),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'ServiceCard.fromService completo (core/widgets/design_system/service_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f27.ServiceCard.fromService(
            service: f29.ServiceModel.fromMap(sampleServiceModel),
            onTap: () {},
            compact: true),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'ServiceCard.fromService mínimo (core/widgets/design_system/service_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f27.ServiceCard.fromService(
            service: f29.ServiceModel.fromMap(sampleServiceModel),
            onTap: () {}),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'ServicePinDialog completo (core/widgets/design_system/service_pin_dialog.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f30.ServicePinDialog(
            title: 'id-1', subtitle: 'id-1', serverError: 'id-1'),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'ServicePinDialog mínimo (core/widgets/design_system/service_pin_dialog.dart)',
      (tester) async {
    await smokeWidget(tester, () => f30.ServicePinDialog(),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'SocialAuthButtons completo (core/widgets/design_system/social_auth_buttons.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f31.SocialAuthButtons(
            isLoading: true, onGoogle: () {}, onApple: () {}),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'SocialAuthButtons mínimo (core/widgets/design_system/social_auth_buttons.dart)',
      (tester) async {
    await smokeWidget(
        tester, () => f31.SocialAuthButtons(isLoading: true, onGoogle: () {}),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'SpatialEmergencyPulseDialog completo (core/widgets/design_system/spatial_emergency_pulse.dart)',
      (tester) async {
    await smokeWidget(tester, () => f32.SpatialEmergencyPulseDialog(),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'StatusBadge completo (core/widgets/design_system/status_badge.dart)',
      (tester) async {
    await smokeWidget(
        tester, () => f33.StatusBadge(status: 'id-1', compact: true),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'StatusBadge mínimo (core/widgets/design_system/status_badge.dart)',
      (tester) async {
    await smokeWidget(tester, () => f33.StatusBadge(status: 'id-1'),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'WebAiAssistantWidget completo (core/widgets/design_system/web_ai_assistant_widget.dart)',
      (tester) async {
    await smokeWidget(tester, () => f34.WebAiAssistantWidget(),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'WorkerCard completo (core/widgets/design_system/worker_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f35.WorkerCard(
            name: 'id-1',
            profession: 'id-1',
            rating: 1.0,
            avatarUrl: 'id-1',
            isAvailable: true,
            onTap: () {},
            leading: const SizedBox(),
            headerBadge: 'id-1',
            headerBadgeColor: const Color(0xFF000000),
            badges: [
              f35.WorkerCardBadge(
                  icon: Icons.star,
                  label: 'id-1',
                  color: const Color(0xFF000000))
            ],
            footnote: 'id-1',
            showChevron: true,
            margin: EdgeInsets.zero),
        seeded: true,
        role: 'usuario');
  });
  testWidgets('WorkerCard mínimo (core/widgets/design_system/worker_card.dart)',
      (tester) async {
    await smokeWidget(
        tester, () => f35.WorkerCard(name: 'id-1', profession: 'id-1'),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'NoJobsEmptyState completo (core/widgets/empty_state_widget.dart)',
      (tester) async {
    await smokeWidget(tester, () => f36.NoJobsEmptyState(onCreateJob: () {}),
        seeded: true, role: 'usuario');
  });
  testWidgets('NoJobsEmptyState mínimo (core/widgets/empty_state_widget.dart)',
      (tester) async {
    await smokeWidget(tester, () => f36.NoJobsEmptyState(),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'NoWorkersEmptyState completo (core/widgets/empty_state_widget.dart)',
      (tester) async {
    await smokeWidget(tester, () => f36.NoWorkersEmptyState(),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'NoSearchResultsEmptyState completo (core/widgets/empty_state_widget.dart)',
      (tester) async {
    await smokeWidget(
        tester, () => f36.NoSearchResultsEmptyState(onClearFilters: () {}),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'NoSearchResultsEmptyState mínimo (core/widgets/empty_state_widget.dart)',
      (tester) async {
    await smokeWidget(tester, () => f36.NoSearchResultsEmptyState(),
        seeded: false, role: 'usuario');
  });
  testWidgets('ErrorDisplayWidget completo (core/widgets/error_widget.dart)',
      (tester) async {
    await smokeWidget(
        tester, () => f37.ErrorDisplayWidget(message: 'id-1', onRetry: () {}),
        seeded: true, role: 'usuario');
  });
  testWidgets('ErrorDisplayWidget mínimo (core/widgets/error_widget.dart)',
      (tester) async {
    await smokeWidget(tester, () => f37.ErrorDisplayWidget(message: 'id-1'),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'EscrowCheckoutSheet completo (core/widgets/escrow_checkout_sheet.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f38.EscrowCheckoutSheet(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            quote: f39.PriceQuote.fromJson(samplePriceQuote),
            workerName: 'id-1',
            serviceName: 'id-1',
            changeOrderId: '00000000-0000-4000-8000-0000000000aa'),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'EscrowCheckoutSheet mínimo (core/widgets/escrow_checkout_sheet.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f38.EscrowCheckoutSheet(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            quote: f39.PriceQuote.fromJson(samplePriceQuote)),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'EvidencePhotoImage completo (core/widgets/evidence_photo_image.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f40.EvidencePhotoImage(
            photo: f41.JobPhotoModel.fromMap(sampleJobPhotoModel)),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'BrokenEvidencePlaceholder completo (core/widgets/evidence_photo_image.dart)',
      (tester) async {
    await smokeWidget(tester, () => f40.BrokenEvidencePlaceholder(),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'HourlyBlockSelector completo (core/widgets/hourly_block_selector.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f42.HourlyBlockSelector(selectedHours: 1, onChanged: (_) {}),
        seeded: true, role: 'usuario');
  });
  testWidgets('JobLocationMap completo (core/widgets/job_location_map.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f43.JobLocationMap(
            latitude: 1.0,
            longitude: 1.0,
            mode: f43.JobMapDisplayMode.values.first,
            height: 1.0,
            onTap: () {}),
        seeded: true,
        role: 'usuario');
  });
  testWidgets('JobLocationMap mínimo (core/widgets/job_location_map.dart)',
      (tester) async {
    await smokeWidget(
        tester, () => f43.JobLocationMap(latitude: 1.0, longitude: 1.0),
        seeded: false, role: 'usuario');
  });
  testWidgets('ActionButton completo (core/widgets/loading/action_button.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f44.ActionButton(
            label: 'id-1',
            onPressed: () {},
            isLoading: true,
            isEnabled: true,
            backgroundColor: const Color(0xFF000000),
            textColor: const Color(0xFF000000),
            icon: Icons.star),
        seeded: true,
        role: 'usuario');
  });
  testWidgets('ActionButton mínimo (core/widgets/loading/action_button.dart)',
      (tester) async {
    await smokeWidget(tester, () => f44.ActionButton(label: 'id-1'),
        seeded: false, role: 'usuario');
  });
  testWidgets('GlobalLoader completo (core/widgets/loading/global_loader.dart)',
      (tester) async {
    await smokeWidget(tester, () => f45.GlobalLoader(child: const SizedBox()),
        seeded: true, role: 'usuario');
  });
  testWidgets('LoadingWidget completo (core/widgets/loading_widget.dart)',
      (tester) async {
    await smokeWidget(tester, () => f46.LoadingWidget(message: 'id-1'),
        seeded: true, role: 'usuario');
  });
  testWidgets('LoadingWidget mínimo (core/widgets/loading_widget.dart)',
      (tester) async {
    await smokeWidget(tester, () => f46.LoadingWidget(),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'LocationPickerWidget completo (core/widgets/location_picker_widget.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f47.LocationPickerWidget(
            onLocationSelected: (_, __, ___) {}, initialAddress: 'id-1'),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'LocationPickerWidget mínimo (core/widgets/location_picker_widget.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f47.LocationPickerWidget(onLocationSelected: (_, __, ___) {}),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'LocationStatusCard completo (core/widgets/location_picker_widget.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f47.LocationStatusCard(
            status: f47.LocationStatus.values.first,
            address: 'id-1',
            hasCoords: true,
            preview: const SizedBox(),
            onPickOnMap: () {},
            onEditAddress: () {},
            onRefresh: () {}),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'LocationStatusCard mínimo (core/widgets/location_picker_widget.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f47.LocationStatusCard(
            status: f47.LocationStatus.values.first,
            address: 'id-1',
            hasCoords: true),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'NotificationListenerScope completo (core/widgets/notification_listener_scope.dart)',
      (tester) async {
    await smokeWidget(
        tester, () => f48.NotificationListenerScope(child: const SizedBox()),
        seeded: true, role: 'usuario');
  });
  testWidgets('PaginatedList completo (core/widgets/paginated_list.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f49.PaginatedList(
            loadData: (_, __) async => const [],
            itemBuilder: (_, __, ___) => const SizedBox(),
            emptyWidget: const SizedBox(),
            loadingWidget: const SizedBox(),
            errorWidget: const SizedBox(),
            pageSize: 1,
            scrollController: ScrollController(),
            padding: EdgeInsets.zero),
        seeded: true,
        role: 'usuario');
  });
  testWidgets('PaginatedList mínimo (core/widgets/paginated_list.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f49.PaginatedList(
            loadData: (_, __) async => const [],
            itemBuilder: (_, __, ___) => const SizedBox()),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'CameraPermissionPage completo (core/widgets/permissions/camera_permission_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f50.CameraPermissionPage(onGranted: () {}, onDenied: () {}),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'CameraPermissionPage mínimo (core/widgets/permissions/camera_permission_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f50.CameraPermissionPage(),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'LocationPermissionPage completo (core/widgets/permissions/location_permission_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f51.LocationPermissionPage(onGranted: () {}, onDenied: () {}),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'LocationPermissionPage mínimo (core/widgets/permissions/location_permission_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f51.LocationPermissionPage(),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'StoragePermissionPage completo (core/widgets/permissions/storage_permission_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f53.StoragePermissionPage(onGranted: () {}, onDenied: () {}),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'StoragePermissionPage mínimo (core/widgets/permissions/storage_permission_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f53.StoragePermissionPage(),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'PortfolioMediaTile completo (core/widgets/portfolio_media_tile.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f54.PortfolioMediaTile(
            photoPath: 'id-1',
            mediaType: 'id-1',
            description: 'id-1',
            enableViewer: true,
            showDescription: true,
            compact: true),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'PortfolioMediaTile mínimo (core/widgets/portfolio_media_tile.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f54.PortfolioMediaTile(photoPath: 'id-1', mediaType: 'id-1'),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'PricingModeSelector completo (core/widgets/pricing_mode_selector.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f55.PricingModeSelector(
            selected: 'id-1', onChanged: (_) {}, workerPreselected: true),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'PricingModeSelector mínimo (core/widgets/pricing_mode_selector.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f55.PricingModeSelector(selected: 'id-1', onChanged: (_) {}),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'ServerAlignedQuoteCard completo (core/widgets/pricing_quote_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f56.ServerAlignedQuoteCard(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            quote: f39.PriceQuote.fromJson(samplePriceQuote),
            workerName: 'id-1',
            serviceName: 'id-1'),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'ServerAlignedQuoteCard mínimo (core/widgets/pricing_quote_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f56.ServerAlignedQuoteCard(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            quote: f39.PriceQuote.fromJson(samplePriceQuote)),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'PricingQuoteCard completo (core/widgets/pricing_quote_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f56.PricingQuoteCard(
            quote: f39.PriceQuote.fromJson(samplePriceQuote),
            workerName: 'id-1',
            serviceName: 'id-1',
            footerNote: 'id-1'),
        seeded: true,
        role: 'usuario');
  });
  testWidgets('PricingQuoteCard mínimo (core/widgets/pricing_quote_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f56.PricingQuoteCard(
            quote: f39.PriceQuote.fromJson(samplePriceQuote)),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'ProfileAvatarImage completo (core/widgets/profile_avatar_picker.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f57.ProfileAvatarImage(
            displayName: 'id-1',
            photoPath: 'id-1',
            radius: 1.0,
            onDarkBackground: true),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'ProfileAvatarImage mínimo (core/widgets/profile_avatar_picker.dart)',
      (tester) async {
    await smokeWidget(tester, () => f57.ProfileAvatarImage(displayName: 'id-1'),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'ProfileAvatarView completo (core/widgets/profile_avatar_picker.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f57.ProfileAvatarView(
            displayName: 'id-1',
            photoPath: 'id-1',
            radius: 1.0,
            onDarkBackground: true),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'ProfileAvatarView mínimo (core/widgets/profile_avatar_picker.dart)',
      (tester) async {
    await smokeWidget(tester, () => f57.ProfileAvatarView(displayName: 'id-1'),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'ProfileAvatarPicker completo (core/widgets/profile_avatar_picker.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f57.ProfileAvatarPicker(
            displayName: 'id-1',
            photoPath: 'id-1',
            radius: 1.0,
            isLoading: true,
            onPickFromSource: (_) async {},
            onRemove: () async {}),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'ProfileAvatarPicker mínimo (core/widgets/profile_avatar_picker.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f57.ProfileAvatarPicker(
            displayName: 'id-1', onPickFromSource: (_) async {}),
        seeded: false,
        role: 'usuario');
  });
  testWidgets('SavedCardTile completo (core/widgets/saved_card_tile.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f58.SavedCardTile(onCardRemoved: () async {}, enabled: true),
        seeded: true, role: 'usuario');
  });
  testWidgets('SavedCardTile mínimo (core/widgets/saved_card_tile.dart)',
      (tester) async {
    await smokeWidget(
        tester, () => f58.SavedCardTile(onCardRemoved: () async {}),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'ServiceDisclaimerDialog completo (core/widgets/service_disclaimer_dialog.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f59.ServiceDisclaimerDialog(
            serviceId: '00000000-0000-4000-8000-0000000000aa',
            serviceName: 'id-1',
            chargeAmountClp: 1),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'ServiceDisclaimerDialog mínimo (core/widgets/service_disclaimer_dialog.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f59.ServiceDisclaimerDialog(
            serviceId: '00000000-0000-4000-8000-0000000000aa',
            serviceName: 'id-1'),
        seeded: false,
        role: 'usuario');
  });
  testWidgets('SkeletonList completo (core/widgets/skeleton_loading.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f60.SkeletonList(
            itemCount: 1, itemHeight: 1.0, padding: EdgeInsets.zero),
        seeded: true,
        role: 'usuario');
  });
  testWidgets('SkeletonList mínimo (core/widgets/skeleton_loading.dart)',
      (tester) async {
    await smokeWidget(tester, () => f60.SkeletonList(),
        seeded: false, role: 'usuario');
  });
  testWidgets('SkeletonItem completo (core/widgets/skeleton_loading.dart)',
      (tester) async {
    await smokeWidget(tester, () => f60.SkeletonItem(height: 1.0, width: 1.0),
        seeded: true, role: 'usuario');
  });
  testWidgets('SkeletonItem mínimo (core/widgets/skeleton_loading.dart)',
      (tester) async {
    await smokeWidget(tester, () => f60.SkeletonItem(),
        seeded: false, role: 'usuario');
  });
  testWidgets('ShimmerEffect completo (core/widgets/skeleton_loading.dart)',
      (tester) async {
    await smokeWidget(tester, () => f60.ShimmerEffect(child: const SizedBox()),
        seeded: true, role: 'usuario');
  });
  testWidgets('SkeletonCard completo (core/widgets/skeleton_loading.dart)',
      (tester) async {
    await smokeWidget(tester, () => f60.SkeletonCard(),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'WebpayWebViewPage completo (core/widgets/webpay_webview_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f61.WebpayWebViewPage(
            paymentUrl: 'id-1',
            html: 'id-1',
            title: 'id-1',
            watchOutcome: () async => null),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'WebpayWebViewPage mínimo (core/widgets/webpay_webview_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f61.WebpayWebViewPage(),
        seeded: false, role: 'usuario');
  });
}
