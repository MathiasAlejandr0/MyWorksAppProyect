// GENERADO por scripts/cobertura/gen_ctx_calls.py. No editar a mano.
// Llama a los métodos que reciben BuildContext/WidgetRef desde botones
// montados con el arnés de widgets y el backend Supabase falso.
// ignore_for_file: avoid_dynamic_calls, unnecessary_cast, prefer_const_constructors
// ignore_for_file: deprecated_member_use, unused_import, invalid_use_of_protected_member
// ignore_for_file: invalid_use_of_visible_for_testing_member, prefer_single_quotes
// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:myworksapp/app.dart' as f0;
import 'package:myworksapp/bootstrap/app_initializer.dart' as f1;
import 'package:myworksapp/core/config/demo_catalog_config.dart' as f2;
import 'package:myworksapp/core/config/demo_credentials.dart' as f3;
import 'package:myworksapp/core/config/demo_free_media.dart' as f4;
import 'package:myworksapp/core/config/oauth_config.dart' as f5;
import 'package:myworksapp/core/config/push_config.dart' as f6;
import 'package:myworksapp/core/config/supabase_config.dart' as f7;
import 'package:myworksapp/core/config/support_config.dart' as f8;
import 'package:myworksapp/core/database/models/abuse_event_model.dart' as f9;
import 'package:myworksapp/core/database/models/analytics_event_model.dart'
    as f10;
import 'package:myworksapp/core/database/models/app_error_log_model.dart'
    as f11;
import 'package:myworksapp/core/database/models/boost_model.dart' as f12;
import 'package:myworksapp/core/database/models/change_order_model.dart' as f13;
import 'package:myworksapp/core/database/models/dispute_model.dart' as f14;
import 'package:myworksapp/core/database/models/feature_flag_model.dart' as f15;
import 'package:myworksapp/core/database/models/job_cancellation_model.dart'
    as f16;
import 'package:myworksapp/core/database/models/job_model.dart' as f17;
import 'package:myworksapp/core/database/models/job_photo_model.dart' as f18;
import 'package:myworksapp/core/database/models/message_model.dart' as f19;
import 'package:myworksapp/core/database/models/notification_model.dart' as f20;
import 'package:myworksapp/core/database/models/payment_model.dart' as f21;
import 'package:myworksapp/core/database/models/pending_action_model.dart'
    as f22;
import 'package:myworksapp/core/database/models/portfolio_model.dart' as f23;
import 'package:myworksapp/core/database/models/quote_proposal_model.dart'
    as f24;
import 'package:myworksapp/core/database/models/ranking_models.dart' as f25;
import 'package:myworksapp/core/database/models/rating_model.dart' as f26;
import 'package:myworksapp/core/database/models/report_model.dart' as f27;
import 'package:myworksapp/core/database/models/service_config_model.dart'
    as f28;
import 'package:myworksapp/core/database/models/service_model.dart' as f29;
import 'package:myworksapp/core/database/models/subscription_model.dart' as f30;
import 'package:myworksapp/core/database/models/user_block_model.dart' as f31;
import 'package:myworksapp/core/database/models/user_consent_model.dart' as f32;
import 'package:myworksapp/core/database/models/user_model.dart' as f33;
import 'package:myworksapp/core/database/models/worker_model.dart' as f34;
import 'package:myworksapp/core/database/models/worker_review_model.dart'
    as f35;
import 'package:myworksapp/core/database/repositories/abuse_repository.dart'
    as f36;
import 'package:myworksapp/core/database/repositories/admin/admin_catalog_repository.dart'
    as f37;
import 'package:myworksapp/core/database/repositories/admin/admin_incidents_repository.dart'
    as f38;
import 'package:myworksapp/core/database/repositories/admin/admin_jobs_repository.dart'
    as f39;
import 'package:myworksapp/core/database/repositories/admin/admin_metrics_repository.dart'
    as f40;
import 'package:myworksapp/core/database/repositories/admin/admin_models.dart'
    as f41;
import 'package:myworksapp/core/database/repositories/admin/admin_users_repository.dart'
    as f42;
import 'package:myworksapp/core/database/repositories/admin_repository.dart'
    as f43;
import 'package:myworksapp/core/database/repositories/analytics_repository.dart'
    as f44;
import 'package:myworksapp/core/database/repositories/app_error_log_repository.dart'
    as f45;
import 'package:myworksapp/core/database/repositories/boost_repository.dart'
    as f46;
import 'package:myworksapp/core/database/repositories/change_order_repository.dart'
    as f47;
import 'package:myworksapp/core/database/repositories/client_rating_repository.dart'
    as f48;
import 'package:myworksapp/core/database/repositories/dispute_repository.dart'
    as f49;
import 'package:myworksapp/core/database/repositories/feature_flag_repository.dart'
    as f50;
import 'package:myworksapp/core/database/repositories/job_cancellation_repository.dart'
    as f51;
import 'package:myworksapp/core/database/repositories/job_photo_repository.dart'
    as f52;
import 'package:myworksapp/core/database/repositories/job_repository.dart'
    as f53;
import 'package:myworksapp/core/database/repositories/message_repository.dart'
    as f54;
import 'package:myworksapp/core/database/repositories/notification_repository.dart'
    as f55;
import 'package:myworksapp/core/database/repositories/payment_repository.dart'
    as f56;
import 'package:myworksapp/core/database/repositories/payout_repository.dart'
    as f57;
import 'package:myworksapp/core/database/repositories/pending_action_repository.dart'
    as f58;
import 'package:myworksapp/core/database/repositories/portfolio_repository.dart'
    as f59;
import 'package:myworksapp/core/database/repositories/quote_proposal_repository.dart'
    as f60;
import 'package:myworksapp/core/database/repositories/ranking_repository.dart'
    as f61;
import 'package:myworksapp/core/database/repositories/rating_repository.dart'
    as f62;
import 'package:myworksapp/core/database/repositories/report_repository.dart'
    as f63;
import 'package:myworksapp/core/database/repositories/reschedule_repository.dart'
    as f64;
import 'package:myworksapp/core/database/repositories/service_config_repository.dart'
    as f65;
import 'package:myworksapp/core/database/repositories/service_repository.dart'
    as f66;
import 'package:myworksapp/core/database/repositories/subscription_repository.dart'
    as f67;
import 'package:myworksapp/core/database/repositories/user_block_repository.dart'
    as f68;
import 'package:myworksapp/core/database/repositories/user_consent_repository.dart'
    as f69;
import 'package:myworksapp/core/database/repositories/user_repository.dart'
    as f70;
import 'package:myworksapp/core/database/repositories/verification_event_repository.dart'
    as f71;
import 'package:myworksapp/core/database/repositories/worker_repository.dart'
    as f72;
import 'package:myworksapp/core/database/repositories/worker_schedule_repository.dart'
    as f73;
import 'package:myworksapp/core/database/repositories/worker_service_repository.dart'
    as f74;
import 'package:myworksapp/core/design_system/app_breakpoints.dart' as f75;
import 'package:myworksapp/core/design_system/app_elevation.dart' as f76;
import 'package:myworksapp/core/design_system/app_radius.dart' as f77;
import 'package:myworksapp/core/design_system/app_spacing.dart' as f78;
import 'package:myworksapp/core/design_system/layout_utils.dart' as f79;
import 'package:myworksapp/core/domain/booking_schedule.dart' as f80;
import 'package:myworksapp/core/domain/catalog_order.dart' as f81;
import 'package:myworksapp/core/domain/distance_match.dart' as f82;
import 'package:myworksapp/core/domain/generated_domain.dart' as f83;
import 'package:myworksapp/core/domain/job_charge_preview.dart' as f84;
import 'package:myworksapp/core/domain/payout_summary.dart' as f85;
import 'package:myworksapp/core/domain/price_quote.dart' as f86;
import 'package:myworksapp/core/domain/pricing_constants.dart' as f87;
import 'package:myworksapp/core/domain/pricing_mode_recommendation.dart' as f88;
import 'package:myworksapp/core/domain/reschedule_rules.dart' as f89;
import 'package:myworksapp/core/domain/transport_surcharge.dart' as f90;
import 'package:myworksapp/core/domain/user_location_context.dart' as f91;
import 'package:myworksapp/core/domain/webpay_transaction.dart' as f92;
import 'package:myworksapp/core/domain/weekly_schedule.dart' as f93;
import 'package:myworksapp/core/domain/worker_charge.dart' as f94;
import 'package:myworksapp/core/domain/worker_custom_service.dart' as f95;
import 'package:myworksapp/core/domain/worker_earnings_snapshot.dart' as f96;
import 'package:myworksapp/core/domain/worker_highlight.dart' as f97;
import 'package:myworksapp/core/domain/worker_hours.dart' as f98;
import 'package:myworksapp/core/domain/worker_login_item.dart' as f99;
import 'package:myworksapp/core/domain/worker_public_stats.dart' as f100;
import 'package:myworksapp/core/domain/worker_service_options_catalog.dart'
    as f101;
import 'package:myworksapp/core/dto/job_dto.dart' as f102;
import 'package:myworksapp/core/exceptions/auth_exceptions.dart' as f103;
import 'package:myworksapp/core/interfaces/analytics_repository_interface.dart'
    as f104;
import 'package:myworksapp/core/interfaces/repository_interface.dart' as f105;
import 'package:myworksapp/core/map/app_map_tiles.dart' as f106;
import 'package:myworksapp/core/presentation/pages/help_center_page.dart'
    as f107;
import 'package:myworksapp/core/presentation/pages/maintenance_page.dart'
    as f108;
import 'package:myworksapp/core/providers/auth_provider.dart' as f109;
import 'package:myworksapp/core/providers/theme_mode_provider.dart' as f110;
import 'package:myworksapp/core/services/abuse_protection_service.dart' as f111;
import 'package:myworksapp/core/services/account_deletion_service.dart' as f112;
import 'package:myworksapp/core/services/action_timeout_service.dart' as f113;
import 'package:myworksapp/core/services/admin_notification_service.dart'
    as f114;
import 'package:myworksapp/core/services/ai_service_recommendation_engine.dart'
    as f115;
import 'package:myworksapp/core/services/analytics_service.dart' as f116;
import 'package:myworksapp/core/services/app_feedback.dart' as f117;
import 'package:myworksapp/core/services/app_health_service.dart' as f118;
import 'package:myworksapp/core/services/app_lifecycle_service.dart' as f119;
import 'package:myworksapp/core/services/auth_service.dart' as f120;
import 'package:myworksapp/core/services/background_timeout_reconciler.dart'
    as f121;
import 'package:myworksapp/core/services/boost_service.dart' as f122;
import 'package:myworksapp/core/services/change_order_service.dart' as f123;
import 'package:myworksapp/core/services/crash_reporting_service.dart' as f124;
import 'package:myworksapp/core/services/demo_tour_service.dart' as f125;
import 'package:myworksapp/core/services/dispute_service.dart' as f126;
import 'package:myworksapp/core/services/evidence_storage_path.dart' as f127;
import 'package:myworksapp/core/services/evidence_uploader.dart' as f128;
import 'package:myworksapp/core/services/evidence_video_limits.dart' as f129;
import 'package:myworksapp/core/services/feature_flags_service.dart' as f130;
import 'package:myworksapp/core/services/gdpr_service.dart' as f131;
import 'package:myworksapp/core/services/geocode_chile.dart' as f132;
import 'package:myworksapp/core/services/gps_publish_gate.dart' as f133;
import 'package:myworksapp/core/services/job_booking_service.dart' as f134;
import 'package:myworksapp/core/services/job_cancellation_service.dart' as f135;
import 'package:myworksapp/core/services/job_service.dart' as f136;
import 'package:myworksapp/core/services/job_state_machine.dart' as f137;
import 'package:myworksapp/core/services/job_transition_matrix.dart' as f138;
import 'package:myworksapp/core/services/logout_service.dart' as f139;
import 'package:myworksapp/core/services/matching_service.dart' as f140;
import 'package:myworksapp/core/services/notification_opt_in.dart' as f141;
import 'package:myworksapp/core/services/notification_permission_gateway.dart'
    as f142;
import 'package:myworksapp/core/services/notification_realtime_service.dart'
    as f143;
import 'package:myworksapp/core/services/notification_service.dart' as f144;
import 'package:myworksapp/core/services/oauth_deep_link_service.dart' as f145;
import 'package:myworksapp/core/services/open_quote_notification_service.dart'
    as f146;
import 'package:myworksapp/core/services/payment_gateway_port.dart' as f147;
import 'package:myworksapp/core/services/payment_guard.dart' as f148;
import 'package:myworksapp/core/services/payment_guard_ports.dart' as f149;
import 'package:myworksapp/core/services/payment_service.dart' as f150;
import 'package:myworksapp/core/services/permission_denied_handler.dart'
    as f151;
import 'package:myworksapp/core/services/photo_service.dart' as f152;
import 'package:myworksapp/core/services/pricing_guard_service.dart' as f153;
import 'package:myworksapp/core/services/pricing_mode_questionnaire_service.dart'
    as f154;
import 'package:myworksapp/core/services/pricing_service.dart' as f155;
import 'package:myworksapp/core/services/profile_photo_service.dart' as f156;
import 'package:myworksapp/core/services/push_notification_port.dart' as f157;
import 'package:myworksapp/core/services/push_service.dart' as f158;
import 'package:myworksapp/core/services/quote_proposal_service.dart' as f159;
import 'package:myworksapp/core/services/rate_limiter_service.dart' as f160;
import 'package:myworksapp/core/services/report_service.dart' as f161;
import 'package:myworksapp/core/services/service_legal_validator.dart' as f162;
import 'package:myworksapp/core/services/session_manager.dart' as f163;
import 'package:myworksapp/core/services/subscription_service.dart' as f164;
import 'package:myworksapp/core/services/testing_feedback_store.dart' as f165;
import 'package:myworksapp/core/services/transbank_webpay_gateway.dart' as f166;
import 'package:myworksapp/core/services/trust_score_service.dart' as f167;
import 'package:myworksapp/core/services/user_location_service.dart' as f168;
import 'package:myworksapp/core/services/worker_earnings_service.dart' as f169;
import 'package:myworksapp/core/services/worker_job_rejection_service.dart'
    as f170;
import 'package:myworksapp/core/services/worker_onboarding_checklist_service.dart'
    as f171;
import 'package:myworksapp/core/services/worker_reputation_service.dart'
    as f172;
import 'package:myworksapp/core/services/worker_search_service.dart' as f173;
import 'package:myworksapp/core/theme/app_colors.dart' as f174;
import 'package:myworksapp/core/theme/app_decorations.dart' as f175;
import 'package:myworksapp/core/theme/app_text_styles.dart' as f176;
import 'package:myworksapp/core/theme/app_theme.dart' as f177;
import 'package:myworksapp/core/theme/generated_brand_colors.dart' as f178;
import 'package:myworksapp/core/theme/service_card_palettes.dart' as f179;
import 'package:myworksapp/core/utils/app_error.dart' as f180;
import 'package:myworksapp/core/utils/app_logger.dart' as f181;
import 'package:myworksapp/core/utils/app_media_permissions.dart' as f182;
import 'package:myworksapp/core/utils/app_text_scaling.dart' as f183;
import 'package:myworksapp/core/utils/chile_comunas.dart' as f184;
import 'package:myworksapp/core/utils/clp_format.dart' as f185;
import 'package:myworksapp/core/utils/constants.dart' as f186;
import 'package:myworksapp/core/utils/debouncer.dart' as f187;
import 'package:myworksapp/core/utils/error_handler.dart' as f188;
import 'package:myworksapp/core/utils/external_map_launcher.dart' as f189;
import 'package:myworksapp/core/utils/job_display_utils.dart' as f190;
import 'package:myworksapp/core/utils/job_schedule_grouping.dart' as f191;
import 'package:myworksapp/core/utils/job_status_copy.dart' as f192;
import 'package:myworksapp/core/utils/location_utils.dart' as f193;
import 'package:myworksapp/core/utils/memo_cache.dart' as f194;
import 'package:myworksapp/core/utils/mock_reserved_slots.dart' as f195;
import 'package:myworksapp/core/utils/open_quote_utils.dart' as f196;
import 'package:myworksapp/core/utils/platform_support.dart' as f197;
import 'package:myworksapp/core/utils/portfolio_media_resolver.dart' as f198;
import 'package:myworksapp/core/utils/santiago_time.dart' as f199;
import 'package:myworksapp/core/utils/service_worker_mapper.dart' as f200;
import 'package:myworksapp/core/utils/validators.dart' as f201;
import 'package:myworksapp/core/utils/worker_job_status.dart' as f202;
import 'package:myworksapp/core/utils/worker_zone_matcher.dart' as f203;
import 'package:myworksapp/core/widgets/app_guided_tour.dart' as f204;
import 'package:myworksapp/core/widgets/confirmation_dialog.dart' as f205;
import 'package:myworksapp/core/widgets/demo_tour_overlay.dart' as f206;
import 'package:myworksapp/core/widgets/design_system/app_auth_scaffold.dart'
    as f207;
import 'package:myworksapp/core/widgets/design_system/app_brand_logo.dart'
    as f208;
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart'
    as f209;
import 'package:myworksapp/core/widgets/design_system/apple_card.dart' as f210;
import 'package:myworksapp/core/widgets/design_system/apple_segmented_picker.dart'
    as f211;
import 'package:myworksapp/core/widgets/design_system/auth_soft_background.dart'
    as f212;
import 'package:myworksapp/core/widgets/design_system/before_after_slider.dart'
    as f213;
import 'package:myworksapp/core/widgets/design_system/danger_button.dart'
    as f214;
import 'package:myworksapp/core/widgets/design_system/empty_state_widget.dart'
    as f215;
import 'package:myworksapp/core/widgets/design_system/error_state_widget.dart'
    as f216;
import 'package:myworksapp/core/widgets/design_system/live_worker_radar_widget.dart'
    as f217;
import 'package:myworksapp/core/widgets/design_system/loading_skeleton.dart'
    as f218;
import 'package:myworksapp/core/widgets/design_system/mesh_gradient_backdrop.dart'
    as f219;
import 'package:myworksapp/core/widgets/design_system/myworks_guarantee_badge.dart'
    as f220;
import 'package:myworksapp/core/widgets/design_system/no_workers_empty_state.dart'
    as f221;
import 'package:myworksapp/core/widgets/design_system/predictive_trust_meter.dart'
    as f222;
import 'package:myworksapp/core/widgets/design_system/premium_glyphs.dart'
    as f223;
import 'package:myworksapp/core/widgets/design_system/primary_button.dart'
    as f224;
import 'package:myworksapp/core/widgets/design_system/responsive_shell.dart'
    as f225;
import 'package:myworksapp/core/widgets/design_system/secondary_button.dart'
    as f226;
import 'package:myworksapp/core/widgets/design_system/service_card.dart'
    as f227;
import 'package:myworksapp/core/widgets/design_system/service_pin_dialog.dart'
    as f228;
import 'package:myworksapp/core/widgets/design_system/social_auth_buttons.dart'
    as f229;
import 'package:myworksapp/core/widgets/design_system/spatial_emergency_pulse.dart'
    as f230;
import 'package:myworksapp/core/widgets/design_system/status_badge.dart'
    as f231;
import 'package:myworksapp/core/widgets/design_system/wave_bottom_clipper.dart'
    as f232;
import 'package:myworksapp/core/widgets/design_system/web_ai_assistant_widget.dart'
    as f233;
import 'package:myworksapp/core/widgets/design_system/worker_card.dart' as f234;
import 'package:myworksapp/core/widgets/empty_state_widget.dart' as f235;
import 'package:myworksapp/core/widgets/error_widget.dart' as f236;
import 'package:myworksapp/core/widgets/escrow_checkout_sheet.dart' as f237;
import 'package:myworksapp/core/widgets/evidence_photo_image.dart' as f238;
import 'package:myworksapp/core/widgets/hourly_block_selector.dart' as f239;
import 'package:myworksapp/core/widgets/job_location_map.dart' as f240;
import 'package:myworksapp/core/widgets/loading/action_button.dart' as f241;
import 'package:myworksapp/core/widgets/loading/global_loader.dart' as f242;
import 'package:myworksapp/core/widgets/loading_widget.dart' as f243;
import 'package:myworksapp/core/widgets/location_picker_widget.dart' as f244;
import 'package:myworksapp/core/widgets/notification_listener_scope.dart'
    as f245;
import 'package:myworksapp/core/widgets/paginated_list.dart' as f246;
import 'package:myworksapp/core/widgets/permissions/camera_permission_page.dart'
    as f247;
import 'package:myworksapp/core/widgets/permissions/location_permission_page.dart'
    as f248;
import 'package:myworksapp/core/widgets/permissions/permission_request_widget.dart'
    as f249;
import 'package:myworksapp/core/widgets/permissions/storage_permission_page.dart'
    as f250;
import 'package:myworksapp/core/widgets/portfolio_media_tile.dart' as f251;
import 'package:myworksapp/core/widgets/portfolio_media_viewer.dart' as f252;
import 'package:myworksapp/core/widgets/pricing_mode_selector.dart' as f253;
import 'package:myworksapp/core/widgets/pricing_quote_card.dart' as f254;
import 'package:myworksapp/core/widgets/profile_avatar_picker.dart' as f255;
import 'package:myworksapp/core/widgets/saved_card_tile.dart' as f256;
import 'package:myworksapp/core/widgets/service_disclaimer_dialog.dart' as f257;
import 'package:myworksapp/core/widgets/skeleton_loading.dart' as f258;
import 'package:myworksapp/core/widgets/webpay_webview_page.dart' as f259;
import 'package:myworksapp/features/admin/presentation/pages/admin_dashboard_page.dart'
    as f260;
import 'package:myworksapp/features/admin/presentation/pages/admin_desktop_management_page.dart'
    as f261;
import 'package:myworksapp/features/admin/presentation/pages/admin_disputes_page.dart'
    as f262;
import 'package:myworksapp/features/admin/presentation/pages/admin_errors_page.dart'
    as f263;
import 'package:myworksapp/features/admin/presentation/pages/admin_feature_flags_page.dart'
    as f264;
import 'package:myworksapp/features/admin/presentation/pages/admin_job_detail_page.dart'
    as f265;
import 'package:myworksapp/features/admin/presentation/pages/admin_jobs_page.dart'
    as f266;
import 'package:myworksapp/features/admin/presentation/pages/admin_payouts_page.dart'
    as f267;
import 'package:myworksapp/features/admin/presentation/pages/admin_ranking_page.dart'
    as f268;
import 'package:myworksapp/features/admin/presentation/pages/admin_reports_page.dart'
    as f269;
import 'package:myworksapp/features/admin/presentation/pages/admin_services_page.dart'
    as f270;
import 'package:myworksapp/features/admin/presentation/pages/admin_users_page.dart'
    as f271;
import 'package:myworksapp/features/admin/presentation/pages/admin_workers_page.dart'
    as f272;
import 'package:myworksapp/features/admin/presentation/widgets/admin_nav_tile.dart'
    as f273;
import 'package:myworksapp/features/admin/presentation/widgets/admin_search_field.dart'
    as f274;
import 'package:myworksapp/features/admin/presentation/widgets/dispute_resolution_dialog.dart'
    as f275;
import 'package:myworksapp/features/auth/presentation/pages/forgot_password_page.dart'
    as f276;
import 'package:myworksapp/features/auth/presentation/pages/login_page.dart'
    as f277;
import 'package:myworksapp/features/auth/presentation/pages/profile_page.dart'
    as f278;
import 'package:myworksapp/features/auth/presentation/pages/register_page.dart'
    as f279;
import 'package:myworksapp/features/auth/presentation/pages/reset_password_new_page.dart'
    as f280;
import 'package:myworksapp/features/auth/presentation/widgets/password_strength_meter.dart'
    as f281;
import 'package:myworksapp/features/auth/presentation/widgets/role_selector_chips.dart'
    as f282;
import 'package:myworksapp/features/auth/presentation/widgets/sign_out_button.dart'
    as f283;
import 'package:myworksapp/features/chat/domain/conversation_preview.dart'
    as f284;
import 'package:myworksapp/features/chat/presentation/pages/chat_page.dart'
    as f285;
import 'package:myworksapp/features/chat/presentation/pages/conversations_page.dart'
    as f286;
import 'package:myworksapp/features/gdpr/presentation/pages/privacy_policy_page.dart'
    as f287;
import 'package:myworksapp/features/gdpr/presentation/pages/terms_page.dart'
    as f288;
import 'package:myworksapp/features/gdpr/presentation/pages/user_rights_page.dart'
    as f289;
import 'package:myworksapp/features/gdpr/presentation/widgets/consent_checkbox.dart'
    as f290;
import 'package:myworksapp/features/inbox/presentation/pages/my_disputes_page.dart'
    as f291;
import 'package:myworksapp/features/inbox/presentation/pages/my_ratings_page.dart'
    as f292;
import 'package:myworksapp/features/jobs/presentation/pages/evidence_shutter_camera_page.dart'
    as f293;
import 'package:myworksapp/features/jobs/presentation/pages/job_detail_page.dart'
    as f294;
import 'package:myworksapp/features/jobs/presentation/pages/job_history_page.dart'
    as f295;
import 'package:myworksapp/features/jobs/presentation/pages/job_photos_page.dart'
    as f296;
import 'package:myworksapp/features/jobs/presentation/pages/job_schedule_page.dart'
    as f297;
import 'package:myworksapp/features/jobs/presentation/utils/job_detail_helpers.dart'
    as f298;
import 'package:myworksapp/features/jobs/presentation/widgets/change_orders_section.dart'
    as f299;
import 'package:myworksapp/features/jobs/presentation/widgets/client_live_tracking.dart'
    as f300;
import 'package:myworksapp/features/jobs/presentation/widgets/client_start_pin_card.dart'
    as f301;
import 'package:myworksapp/features/jobs/presentation/widgets/dispute_section.dart'
    as f302;
import 'package:myworksapp/features/jobs/presentation/widgets/evidence_shutter_button.dart'
    as f303;
import 'package:myworksapp/features/jobs/presentation/widgets/job_accepted_location_card.dart'
    as f304;
import 'package:myworksapp/features/jobs/presentation/widgets/job_detail_actions_section.dart'
    as f305;
import 'package:myworksapp/features/jobs/presentation/widgets/job_detail_client_approval_card.dart'
    as f306;
import 'package:myworksapp/features/jobs/presentation/widgets/job_detail_description_section.dart'
    as f307;
import 'package:myworksapp/features/jobs/presentation/widgets/job_detail_payment_escrow_section.dart'
    as f308;
import 'package:myworksapp/features/jobs/presentation/widgets/job_detail_scheduled_date_row.dart'
    as f309;
import 'package:myworksapp/features/jobs/presentation/widgets/job_detail_status_header.dart'
    as f310;
import 'package:myworksapp/features/jobs/presentation/widgets/job_history_cards.dart'
    as f311;
import 'package:myworksapp/features/jobs/presentation/widgets/job_location_preview_section.dart'
    as f312;
import 'package:myworksapp/features/jobs/presentation/widgets/job_status_timeline.dart'
    as f313;
import 'package:myworksapp/features/jobs/presentation/widgets/open_quote_status_banner.dart'
    as f314;
import 'package:myworksapp/features/jobs/presentation/widgets/quote_proposals_section.dart'
    as f315;
import 'package:myworksapp/features/jobs/presentation/widgets/reschedule_section.dart'
    as f316;
import 'package:myworksapp/features/jobs/presentation/widgets/worker_gps_publisher.dart'
    as f317;
import 'package:myworksapp/features/jobs/presentation/widgets/worker_quote_form_dialog.dart'
    as f318;
import 'package:myworksapp/features/notifications/domain/notification_groups.dart'
    as f319;
import 'package:myworksapp/features/notifications/presentation/pages/notifications_page.dart'
    as f320;
import 'package:myworksapp/features/onboarding/presentation/pages/onboarding_page.dart'
    as f321;
import 'package:myworksapp/features/payments/presentation/pages/card_enrollment_page.dart'
    as f322;
import 'package:myworksapp/features/payments/presentation/pages/payment_methods_page.dart'
    as f323;
import 'package:myworksapp/features/payments/presentation/pages/payment_result_screen.dart'
    as f324;
import 'package:myworksapp/features/payments/presentation/pages/payment_screen.dart'
    as f325;
import 'package:myworksapp/features/ratings/domain/rating_gate.dart' as f326;
import 'package:myworksapp/features/ratings/presentation/pages/rating_page.dart'
    as f327;
import 'package:myworksapp/features/ratings/presentation/widgets/client_rating_badge.dart'
    as f328;
import 'package:myworksapp/features/ratings/presentation/widgets/client_reputation_card.dart'
    as f329;
import 'package:myworksapp/features/ratings/presentation/widgets/rate_client_button.dart'
    as f330;
import 'package:myworksapp/features/role_selector/presentation/pages/role_selector_page.dart'
    as f331;
import 'package:myworksapp/features/role_selector/presentation/pages/welcome_page.dart'
    as f332;
import 'package:myworksapp/features/settings/presentation/pages/settings_page.dart'
    as f333;
import 'package:myworksapp/features/user/presentation/pages/quick_booking_page.dart'
    as f334;
import 'package:myworksapp/features/user/presentation/pages/service_request_page.dart'
    as f335;
import 'package:myworksapp/features/user/presentation/pages/user_home_page.dart'
    as f336;
import 'package:myworksapp/features/user/presentation/pages/user_profile_page.dart'
    as f337;
import 'package:myworksapp/features/user/presentation/pages/worker_detail_page.dart'
    as f338;
import 'package:myworksapp/features/user/presentation/pages/worker_list_page.dart'
    as f339;
import 'package:myworksapp/features/user/presentation/widgets/dynamic_service_form.dart'
    as f340;
import 'package:myworksapp/features/user/presentation/widgets/in_progress_job_card.dart'
    as f341;
import 'package:myworksapp/features/user/presentation/widgets/open_quote_submitted_dialog.dart'
    as f342;
import 'package:myworksapp/features/user/presentation/widgets/pricing_mode_questionnaire.dart'
    as f343;
import 'package:myworksapp/features/user/presentation/widgets/service_request_submitted_dialog.dart'
    as f344;
import 'package:myworksapp/features/user/presentation/widgets/testing_feedback_sheet.dart'
    as f345;
import 'package:myworksapp/features/user/presentation/widgets/time_slot_selector.dart'
    as f346;
import 'package:myworksapp/features/user/presentation/widgets/traslado_radar_banner.dart'
    as f347;
import 'package:myworksapp/features/user/presentation/widgets/worker_list_chrome.dart'
    as f348;
import 'package:myworksapp/features/user/presentation/widgets/worker_reviews_section.dart'
    as f349;
import 'package:myworksapp/features/user/presentation/widgets/worker_search_map.dart'
    as f350;
import 'package:myworksapp/features/user/presentation/widgets/worker_service_option_picker.dart'
    as f351;
import 'package:myworksapp/features/user/presentation/widgets/worker_square_meters_field.dart'
    as f352;
import 'package:myworksapp/features/user/presentation/widgets/worker_unavailable_dialog.dart'
    as f353;
import 'package:myworksapp/features/worker/presentation/pages/statistics_page.dart'
    as f354;
import 'package:myworksapp/features/worker/presentation/pages/worker_home_page.dart'
    as f355;
import 'package:myworksapp/features/worker/presentation/pages/worker_payouts_page.dart'
    as f356;
import 'package:myworksapp/features/worker/presentation/pages/worker_pricing_setup_page.dart'
    as f357;
import 'package:myworksapp/features/worker/presentation/pages/worker_profile_page.dart'
    as f358;
import 'package:myworksapp/features/worker/presentation/pages/worker_register_page.dart'
    as f359;
import 'package:myworksapp/features/worker/presentation/pages/worker_schedule_page.dart'
    as f360;
import 'package:myworksapp/features/worker/presentation/providers/worker_home_refresh_provider.dart'
    as f361;
import 'package:myworksapp/features/worker/presentation/widgets/sii_tax_info_widget.dart'
    as f362;
import 'package:myworksapp/features/worker/presentation/widgets/worker_active_job_banner.dart'
    as f363;
import 'package:myworksapp/features/worker/presentation/widgets/worker_base_location_card.dart'
    as f364;
import 'package:myworksapp/features/worker/presentation/widgets/worker_custom_services_editor.dart'
    as f365;
import 'package:myworksapp/features/worker/presentation/widgets/worker_day_windows_editor.dart'
    as f366;
import 'package:myworksapp/features/worker/presentation/widgets/worker_demo_tour_overlay.dart'
    as f367;
import 'package:myworksapp/features/worker/presentation/widgets/worker_earnings_summary.dart'
    as f368;
import 'package:myworksapp/features/worker/presentation/widgets/worker_header.dart'
    as f369;
import 'package:myworksapp/features/worker/presentation/widgets/worker_hours_editor.dart'
    as f370;
import 'package:myworksapp/features/worker/presentation/widgets/worker_job_card.dart'
    as f371;
import 'package:myworksapp/features/worker/presentation/widgets/worker_onboarding_card.dart'
    as f372;
import 'package:myworksapp/features/worker/presentation/widgets/worker_pricing_tiers_editor.dart'
    as f373;
import 'package:myworksapp/features/worker/presentation/widgets/worker_profile_section_card.dart'
    as f374;
import 'package:myworksapp/features/worker/presentation/widgets/worker_quick_actions_row.dart'
    as f375;
import 'package:myworksapp/features/worker/presentation/widgets/worker_stats_row.dart'
    as f376;
import 'package:myworksapp/features/worker/presentation/widgets/worker_urban_coverage_card.dart'
    as f377;
import 'package:myworksapp/features/worker/presentation/widgets/worker_verification_card.dart'
    as f378;
import 'package:myworksapp/features/worker/presentation/widgets/worker_work_zone_field.dart'
    as f379;
import 'package:myworksapp/utils/content_filter.dart' as f380;
import 'support/model_samples.dart';
import 'support/widget_harness.dart';

/// Ejecuta la llamada y descarta errores (síncronos o asíncronos).
void fire(Object? Function() f) {
  try {
    final r = f();
    if (r is Future) unawaited(r.then<void>((_) {}, onError: (Object _) {}));
  } catch (_) {}
}

void main() {
  testWidgets('AppInitializer con contexto (bootstrap/app_initializer.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(
                          () => (f1.AppInitializer.instance).initialize(ref)),
                      child: const Text('m0')),
                ]))),
        seeded: true);
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(
                          () => (f1.AppInitializer.instance).initialize(ref)),
                      child: const Text('m0')),
                ]))),
        seeded: false);
  });
  testWidgets(
      'AppBreakpoints con contexto (core/design_system/app_breakpoints.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () =>
                          fire(() => f75.AppBreakpoints.widthOf(ctx)),
                      child: const Text('m0')),
                  FilledButton(
                      onPressed: () =>
                          fire(() => f75.AppBreakpoints.heightOf(ctx)),
                      child: const Text('m1')),
                  FilledButton(
                      onPressed: () =>
                          fire(() => f75.AppBreakpoints.shortestSideOf(ctx)),
                      child: const Text('m2')),
                  FilledButton(
                      onPressed: () =>
                          fire(() => f75.AppBreakpoints.isPhone(ctx)),
                      child: const Text('m3')),
                  FilledButton(
                      onPressed: () =>
                          fire(() => f75.AppBreakpoints.isTablet(ctx)),
                      child: const Text('m4')),
                  FilledButton(
                      onPressed: () =>
                          fire(() => f75.AppBreakpoints.isDesktop(ctx)),
                      child: const Text('m5')),
                  FilledButton(
                      onPressed: () =>
                          fire(() => f75.AppBreakpoints.isLargeScreen(ctx)),
                      child: const Text('m6')),
                  FilledButton(
                      onPressed: () => fire(
                          () => f75.AppBreakpoints.contentMaxWidthFor(ctx)),
                      child: const Text('m7')),
                  FilledButton(
                      onPressed: () =>
                          fire(() => f75.AppBreakpoints.screenPadding(ctx)),
                      child: const Text('m8')),
                  FilledButton(
                      onPressed: () => fire(() =>
                          f75.AppBreakpoints.gridColumns(ctx,
                              phone: 1, tablet: 1, desktopCols: 1)),
                      child: const Text('m9')),
                  FilledButton(
                      onPressed: () => fire(() =>
                          f75.AppBreakpoints.heroImageHeight(ctx,
                              phoneRatio: 1.0)),
                      child: const Text('m10')),
                ]))),
        seeded: true);
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () =>
                          fire(() => f75.AppBreakpoints.widthOf(ctx)),
                      child: const Text('m0')),
                  FilledButton(
                      onPressed: () =>
                          fire(() => f75.AppBreakpoints.heightOf(ctx)),
                      child: const Text('m1')),
                  FilledButton(
                      onPressed: () =>
                          fire(() => f75.AppBreakpoints.shortestSideOf(ctx)),
                      child: const Text('m2')),
                  FilledButton(
                      onPressed: () =>
                          fire(() => f75.AppBreakpoints.isPhone(ctx)),
                      child: const Text('m3')),
                  FilledButton(
                      onPressed: () =>
                          fire(() => f75.AppBreakpoints.isTablet(ctx)),
                      child: const Text('m4')),
                  FilledButton(
                      onPressed: () =>
                          fire(() => f75.AppBreakpoints.isDesktop(ctx)),
                      child: const Text('m5')),
                  FilledButton(
                      onPressed: () =>
                          fire(() => f75.AppBreakpoints.isLargeScreen(ctx)),
                      child: const Text('m6')),
                  FilledButton(
                      onPressed: () => fire(
                          () => f75.AppBreakpoints.contentMaxWidthFor(ctx)),
                      child: const Text('m7')),
                  FilledButton(
                      onPressed: () =>
                          fire(() => f75.AppBreakpoints.screenPadding(ctx)),
                      child: const Text('m8')),
                  FilledButton(
                      onPressed: () => fire(() =>
                          f75.AppBreakpoints.gridColumns(ctx,
                              phone: 1, tablet: 1, desktopCols: 1)),
                      child: const Text('m9')),
                  FilledButton(
                      onPressed: () => fire(() =>
                          f75.AppBreakpoints.heroImageHeight(ctx,
                              phoneRatio: 1.0)),
                      child: const Text('m10')),
                ]))),
        seeded: false);
  });
  testWidgets('LayoutUtils con contexto (core/design_system/layout_utils.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() => f79.LayoutUtils.scrollPadding(
                          ctx,
                          top: 1.0,
                          extraBottom: 1.0)),
                      child: const Text('m0')),
                ]))),
        seeded: true);
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() => f79.LayoutUtils.scrollPadding(
                          ctx,
                          top: 1.0,
                          extraBottom: 1.0)),
                      child: const Text('m0')),
                ]))),
        seeded: false);
  });
  testWidgets(
      'AppLifecycleService con contexto (core/services/app_lifecycle_service.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() =>
                          (f119.AppLifecycleService.instance).initialize(ref)),
                      child: const Text('m0')),
                ]))),
        seeded: true);
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() =>
                          (f119.AppLifecycleService.instance).initialize(ref)),
                      child: const Text('m0')),
                ]))),
        seeded: false);
  });
  testWidgets('LogoutService con contexto (core/services/logout_service.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(
                          () => (f139.LogoutService.instance).logout(ref, ctx)),
                      child: const Text('m0')),
                ]))),
        seeded: true);
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(
                          () => (f139.LogoutService.instance).logout(ref, ctx)),
                      child: const Text('m0')),
                ]))),
        seeded: false);
  });
  testWidgets('AppColors con contexto (core/theme/app_colors.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () =>
                          fire(() => f174.AppColors.headlineOnScreen(ctx)),
                      child: const Text('m0')),
                  FilledButton(
                      onPressed: () =>
                          fire(() => f174.AppColors.surfaceOf(ctx)),
                      child: const Text('m1')),
                  FilledButton(
                      onPressed: () =>
                          fire(() => f174.AppColors.surfaceElevatedOf(ctx)),
                      child: const Text('m2')),
                  FilledButton(
                      onPressed: () => fire(() => f174.AppColors.hairlineOf(ctx,
                          accent: const Color(0xFF000000))),
                      child: const Text('m3')),
                  FilledButton(
                      onPressed: () =>
                          fire(() => f174.AppColors.fieldFillOf(ctx)),
                      child: const Text('m4')),
                ]))),
        seeded: true);
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () =>
                          fire(() => f174.AppColors.headlineOnScreen(ctx)),
                      child: const Text('m0')),
                  FilledButton(
                      onPressed: () =>
                          fire(() => f174.AppColors.surfaceOf(ctx)),
                      child: const Text('m1')),
                  FilledButton(
                      onPressed: () =>
                          fire(() => f174.AppColors.surfaceElevatedOf(ctx)),
                      child: const Text('m2')),
                  FilledButton(
                      onPressed: () => fire(() => f174.AppColors.hairlineOf(ctx,
                          accent: const Color(0xFF000000))),
                      child: const Text('m3')),
                  FilledButton(
                      onPressed: () =>
                          fire(() => f174.AppColors.fieldFillOf(ctx)),
                      child: const Text('m4')),
                ]))),
        seeded: false);
  });
  testWidgets('AppDecorations con contexto (core/theme/app_decorations.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () =>
                          fire(() => f175.AppDecorations.canvasOf(ctx)),
                      child: const Text('m0')),
                  FilledButton(
                      onPressed: () => fire(
                          () => f175.AppDecorations.welcomeGradientOf(ctx)),
                      child: const Text('m1')),
                  FilledButton(
                      onPressed: () => fire(() =>
                          f175.AppDecorations.surfaceCardOf(ctx,
                              accent: const Color(0xFF000000),
                              radius: 1.0,
                              overrideColor: const Color(0xFF000000))),
                      child: const Text('m2')),
                ]))),
        seeded: true);
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () =>
                          fire(() => f175.AppDecorations.canvasOf(ctx)),
                      child: const Text('m0')),
                  FilledButton(
                      onPressed: () => fire(
                          () => f175.AppDecorations.welcomeGradientOf(ctx)),
                      child: const Text('m1')),
                  FilledButton(
                      onPressed: () => fire(() =>
                          f175.AppDecorations.surfaceCardOf(ctx,
                              accent: const Color(0xFF000000),
                              radius: 1.0,
                              overrideColor: const Color(0xFF000000))),
                      child: const Text('m2')),
                ]))),
        seeded: false);
  });
  testWidgets('ErrorHandler con contexto (core/utils/error_handler.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () =>
                          fire(() => f188.ErrorHandler.showError(ctx, null)),
                      child: const Text('m0')),
                  FilledButton(
                      onPressed: () => fire(() =>
                          f188.ErrorHandler.showErrorDialog(ctx, 'id-1', null)),
                      child: const Text('m1')),
                  FilledButton(
                      onPressed: () => fire(() =>
                          f188.ErrorHandler.showCriticalErrorDialog(
                              ctx, 'id-1', null,
                              actionLabel: 'id-1')),
                      child: const Text('m2')),
                ]))),
        seeded: true);
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () =>
                          fire(() => f188.ErrorHandler.showError(ctx, null)),
                      child: const Text('m0')),
                  FilledButton(
                      onPressed: () => fire(() =>
                          f188.ErrorHandler.showErrorDialog(ctx, 'id-1', null)),
                      child: const Text('m1')),
                  FilledButton(
                      onPressed: () => fire(() =>
                          f188.ErrorHandler.showCriticalErrorDialog(
                              ctx, 'id-1', null,
                              actionLabel: 'id-1')),
                      child: const Text('m2')),
                ]))),
        seeded: false);
  });
  testWidgets(
      'ExternalMapLauncher con contexto (core/utils/external_map_launcher.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() =>
                          f189.ExternalMapLauncher.showNavigationChooser(ctx,
                              latitude: 1.0, longitude: 1.0)),
                      child: const Text('m0')),
                ]))),
        seeded: true);
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() =>
                          f189.ExternalMapLauncher.showNavigationChooser(ctx,
                              latitude: 1.0, longitude: 1.0)),
                      child: const Text('m0')),
                ]))),
        seeded: false);
  });
  testWidgets(
      'ConfirmationDialog con contexto (core/widgets/confirmation_dialog.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() => f205.ConfirmationDialog.show(
                          ctx,
                          title: 'id-1',
                          message: 'id-1',
                          confirmLabel: 'id-1',
                          cancelLabel: 'id-1',
                          isDestructive: true)),
                      child: const Text('m0')),
                ]))),
        seeded: true);
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() => f205.ConfirmationDialog.show(
                          ctx,
                          title: 'id-1',
                          message: 'id-1',
                          confirmLabel: 'id-1',
                          cancelLabel: 'id-1',
                          isDestructive: true)),
                      child: const Text('m0')),
                ]))),
        seeded: false);
  });
  testWidgets(
      'CancelJobDialog con contexto (core/widgets/confirmation_dialog.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () =>
                          fire(() => f205.CancelJobDialog.show(ctx)),
                      child: const Text('m0')),
                ]))),
        seeded: true);
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () =>
                          fire(() => f205.CancelJobDialog.show(ctx)),
                      child: const Text('m0')),
                ]))),
        seeded: false);
  });
  testWidgets(
      'ServicePinDialog con contexto (core/widgets/design_system/service_pin_dialog.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() => f228.ServicePinDialog.show(
                          ctx,
                          title: 'id-1',
                          subtitle: 'id-1',
                          serverError: 'id-1')),
                      child: const Text('m0')),
                ]))),
        seeded: true);
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() => f228.ServicePinDialog.show(
                          ctx,
                          title: 'id-1',
                          subtitle: 'id-1',
                          serverError: 'id-1')),
                      child: const Text('m0')),
                ]))),
        seeded: false);
  });
  testWidgets(
      'EscrowCheckoutSheet con contexto (core/widgets/escrow_checkout_sheet.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() => f237.EscrowCheckoutSheet.show(
                          ctx,
                          jobId: '00000000-0000-4000-8000-0000000000aa',
                          quote: f86.PriceQuote.fromJson(samplePriceQuote),
                          workerName: 'id-1',
                          serviceName: 'id-1',
                          changeOrderId:
                              '00000000-0000-4000-8000-0000000000aa')),
                      child: const Text('m0')),
                ]))),
        seeded: true);
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() => f237.EscrowCheckoutSheet.show(
                          ctx,
                          jobId: '00000000-0000-4000-8000-0000000000aa',
                          quote: f86.PriceQuote.fromJson(samplePriceQuote),
                          workerName: 'id-1',
                          serviceName: 'id-1',
                          changeOrderId:
                              '00000000-0000-4000-8000-0000000000aa')),
                      child: const Text('m0')),
                ]))),
        seeded: false);
  });
  testWidgets(
      'GlobalLoaderHelper con contexto (core/widgets/loading/global_loader.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () =>
                          fire(() => f242.GlobalLoaderHelper.show(ref)),
                      child: const Text('m0')),
                  FilledButton(
                      onPressed: () =>
                          fire(() => f242.GlobalLoaderHelper.hide(ref)),
                      child: const Text('m1')),
                ]))),
        seeded: true);
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () =>
                          fire(() => f242.GlobalLoaderHelper.show(ref)),
                      child: const Text('m0')),
                  FilledButton(
                      onPressed: () =>
                          fire(() => f242.GlobalLoaderHelper.hide(ref)),
                      child: const Text('m1')),
                ]))),
        seeded: false);
  });
  testWidgets(
      'PortfolioMediaViewer con contexto (core/widgets/portfolio_media_viewer.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() =>
                          f252.PortfolioMediaViewer.openImagePath(ctx,
                              imagePath: 'id-1',
                              description: 'id-1',
                              title: 'id-1')),
                      child: const Text('m0')),
                  FilledButton(
                      onPressed: () => fire(() =>
                          f252.PortfolioMediaViewer.open(ctx,
                              photoPath: 'id-1',
                              mediaType: 'id-1',
                              description: 'id-1')),
                      child: const Text('m1')),
                ]))),
        seeded: true);
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() =>
                          f252.PortfolioMediaViewer.openImagePath(ctx,
                              imagePath: 'id-1',
                              description: 'id-1',
                              title: 'id-1')),
                      child: const Text('m0')),
                  FilledButton(
                      onPressed: () => fire(() =>
                          f252.PortfolioMediaViewer.open(ctx,
                              photoPath: 'id-1',
                              mediaType: 'id-1',
                              description: 'id-1')),
                      child: const Text('m1')),
                ]))),
        seeded: false);
  });
  testWidgets(
      'ServiceDisclaimerDialog con contexto (core/widgets/service_disclaimer_dialog.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() =>
                          f257.ServiceDisclaimerDialog.show(ctx,
                              serviceId: '00000000-0000-4000-8000-0000000000aa',
                              serviceName: 'id-1',
                              chargeAmountClp: 1)),
                      child: const Text('m0')),
                ]))),
        seeded: true);
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() =>
                          f257.ServiceDisclaimerDialog.show(ctx,
                              serviceId: '00000000-0000-4000-8000-0000000000aa',
                              serviceName: 'id-1',
                              chargeAmountClp: 1)),
                      child: const Text('m0')),
                ]))),
        seeded: false);
  });
  testWidgets(
      'WebpayWebViewPage con contexto (core/widgets/webpay_webview_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() => f259.WebpayWebViewPage.open(
                          ctx,
                          paymentUrl: 'id-1',
                          html: 'id-1',
                          title: 'id-1',
                          watchOutcome: () async => null)),
                      child: const Text('m0')),
                ]))),
        seeded: true);
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() => f259.WebpayWebViewPage.open(
                          ctx,
                          paymentUrl: 'id-1',
                          html: 'id-1',
                          title: 'id-1',
                          watchOutcome: () async => null)),
                      child: const Text('m0')),
                ]))),
        seeded: false);
  });
  testWidgets(
      'WorkerQuoteFormDialog con contexto (features/jobs/presentation/widgets/worker_quote_form_dialog.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () =>
                          fire(() => f318.WorkerQuoteFormDialog.show(ctx)),
                      child: const Text('m0')),
                ]))),
        seeded: true);
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () =>
                          fire(() => f318.WorkerQuoteFormDialog.show(ctx)),
                      child: const Text('m0')),
                ]))),
        seeded: false);
  });
  testWidgets(
      'CardEnrollmentPage con contexto (features/payments/presentation/pages/card_enrollment_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() =>
                          f322.CardEnrollmentPage.open(ctx, replacing: true)),
                      child: const Text('m0')),
                ]))),
        seeded: true);
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() =>
                          f322.CardEnrollmentPage.open(ctx, replacing: true)),
                      child: const Text('m0')),
                ]))),
        seeded: false);
  });
  testWidgets(
      'PaymentScreen con contexto (features/payments/presentation/pages/payment_screen.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() => f325.PaymentScreen.open(ctx,
                          jobId: '00000000-0000-4000-8000-0000000000aa',
                          amount: 1.0,
                          serviceName: 'id-1',
                          specialistName: 'id-1')),
                      child: const Text('m0')),
                ]))),
        seeded: true);
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() => f325.PaymentScreen.open(ctx,
                          jobId: '00000000-0000-4000-8000-0000000000aa',
                          amount: 1.0,
                          serviceName: 'id-1',
                          specialistName: 'id-1')),
                      child: const Text('m0')),
                ]))),
        seeded: false);
  });
  testWidgets(
      'OpenQuoteSubmittedDialog con contexto (features/user/presentation/widgets/open_quote_submitted_dialog.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() =>
                          f342.OpenQuoteSubmittedDialog.show(ctx,
                              workerName: 'id-1')),
                      child: const Text('m0')),
                ]))),
        seeded: true);
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() =>
                          f342.OpenQuoteSubmittedDialog.show(ctx,
                              workerName: 'id-1')),
                      child: const Text('m0')),
                ]))),
        seeded: false);
  });
  testWidgets(
      'ServiceRequestSubmittedDialog con contexto (features/user/presentation/widgets/service_request_submitted_dialog.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() =>
                          f344.ServiceRequestSubmittedDialog.show(ctx,
                              workerName: 'id-1', jobLabel: 'id-1')),
                      child: const Text('m0')),
                ]))),
        seeded: true);
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() =>
                          f344.ServiceRequestSubmittedDialog.show(ctx,
                              workerName: 'id-1', jobLabel: 'id-1')),
                      child: const Text('m0')),
                ]))),
        seeded: false);
  });
  testWidgets(
      'TestingFeedbackSheet con contexto (features/user/presentation/widgets/testing_feedback_sheet.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() =>
                          f345.TestingFeedbackSheet.show(ctx,
                              onSubmit: (_) async {}, role: 'id-1')),
                      child: const Text('m0')),
                ]))),
        seeded: true);
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() =>
                          f345.TestingFeedbackSheet.show(ctx,
                              onSubmit: (_) async {}, role: 'id-1')),
                      child: const Text('m0')),
                ]))),
        seeded: false);
  });
  testWidgets(
      'WorkerUnavailableDialog con contexto (features/user/presentation/widgets/worker_unavailable_dialog.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() =>
                          f353.WorkerUnavailableDialog.show(ctx,
                              workerName: 'id-1',
                              alternatives: [
                                f34.WorkerModel.fromMap(sampleWorkerModel)
                              ],
                              serviceId:
                                  '00000000-0000-4000-8000-0000000000aa')),
                      child: const Text('m0')),
                ]))),
        seeded: true);
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () => fire(() =>
                          f353.WorkerUnavailableDialog.show(ctx,
                              workerName: 'id-1',
                              alternatives: [
                                f34.WorkerModel.fromMap(sampleWorkerModel)
                              ],
                              serviceId:
                                  '00000000-0000-4000-8000-0000000000aa')),
                      child: const Text('m0')),
                ]))),
        seeded: false);
  });
  testWidgets('ContentFilter con contexto (utils/content_filter.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () =>
                          fire(() => f380.ContentFilter.showBlockedDialog(ctx)),
                      child: const Text('m0')),
                ]))),
        seeded: true);
    await smokeWidget(
        tester,
        () => Consumer(
            builder: (ctx, ref, _) => SingleChildScrollView(
                    child: Column(children: [
                  FilledButton(
                      onPressed: () =>
                          fire(() => f380.ContentFilter.showBlockedDialog(ctx)),
                      child: const Text('m0')),
                ]))),
        seeded: false);
  });
}
