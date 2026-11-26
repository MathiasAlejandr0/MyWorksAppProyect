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
import 'package:myworksapp/features/user/presentation/pages/quick_booking_page.dart'
    as f0;
import 'package:myworksapp/features/user/presentation/pages/service_request_page.dart'
    as f1;
import 'package:myworksapp/features/user/presentation/pages/user_home_page.dart'
    as f2;
import 'package:myworksapp/features/user/presentation/pages/user_profile_page.dart'
    as f3;
import 'package:myworksapp/features/user/presentation/pages/worker_detail_page.dart'
    as f4;
import 'package:myworksapp/features/user/presentation/pages/worker_list_page.dart'
    as f5;
import 'package:myworksapp/features/user/presentation/widgets/dynamic_service_form.dart'
    as f6;
import 'package:myworksapp/core/database/models/service_config_model.dart'
    as f7;
import 'package:myworksapp/features/user/presentation/widgets/in_progress_job_card.dart'
    as f8;
import 'package:myworksapp/features/user/presentation/widgets/open_quote_submitted_dialog.dart'
    as f9;
import 'package:myworksapp/features/user/presentation/widgets/pricing_mode_questionnaire.dart'
    as f10;
import 'package:myworksapp/core/domain/pricing_mode_recommendation.dart' as f11;
import 'package:myworksapp/features/user/presentation/widgets/service_request_submitted_dialog.dart'
    as f12;
import 'package:myworksapp/features/user/presentation/widgets/testing_feedback_sheet.dart'
    as f13;
import 'package:myworksapp/features/user/presentation/widgets/time_slot_selector.dart'
    as f14;
import 'package:myworksapp/features/user/presentation/widgets/traslado_radar_banner.dart'
    as f15;
import 'package:myworksapp/core/domain/transport_surcharge.dart' as f16;
import 'package:myworksapp/features/user/presentation/widgets/worker_list_chrome.dart'
    as f17;
import 'package:myworksapp/features/user/presentation/widgets/worker_reviews_section.dart'
    as f18;
import 'package:myworksapp/core/database/models/worker_review_model.dart'
    as f19;
import 'package:myworksapp/features/user/presentation/widgets/worker_search_map.dart'
    as f20;
import 'package:myworksapp/core/database/models/worker_model.dart' as f21;
import 'package:myworksapp/features/user/presentation/widgets/worker_service_option_picker.dart'
    as f22;
import 'package:myworksapp/features/user/presentation/widgets/worker_square_meters_field.dart'
    as f23;
import 'package:myworksapp/features/user/presentation/widgets/worker_unavailable_dialog.dart'
    as f24;
import 'support/model_samples.dart';
import 'support/widget_harness.dart';

void main() {
  testWidgets(
      'QuickBookingPage completo (features/user/presentation/pages/quick_booking_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f0.QuickBookingPage(
            workerId: '00000000-0000-4000-8000-0000000000aa',
            serviceId: '00000000-0000-4000-8000-0000000000aa'),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'ServiceRequestPage completo (features/user/presentation/pages/service_request_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f1.ServiceRequestPage(
            serviceId: '00000000-0000-4000-8000-0000000000aa',
            workerId: '00000000-0000-4000-8000-0000000000aa'),
        seeded: true,
        role: 'usuario',
        boundedButtons: true);
  });
  testWidgets(
      'ServiceRequestPage mínimo (features/user/presentation/pages/service_request_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f1.ServiceRequestPage(),
        seeded: false, role: 'usuario', boundedButtons: true);
  });
  testWidgets(
      'UserHomePage completo (features/user/presentation/pages/user_home_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.UserHomePage(),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'UserProfilePage completo (features/user/presentation/pages/user_profile_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f3.UserProfilePage(),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'WorkerDetailPage completo (features/user/presentation/pages/worker_detail_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f4.WorkerDetailPage(
            workerId: '00000000-0000-4000-8000-0000000000aa',
            serviceId: '00000000-0000-4000-8000-0000000000aa'),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'WorkerDetailPage mínimo (features/user/presentation/pages/worker_detail_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f4.WorkerDetailPage(
            workerId: '00000000-0000-4000-8000-0000000000aa'),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'WorkerListPage completo (features/user/presentation/pages/worker_list_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f5.WorkerListPage(
            serviceId: '00000000-0000-4000-8000-0000000000aa',
            jobId: '00000000-0000-4000-8000-0000000000aa'),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'WorkerListPage mínimo (features/user/presentation/pages/worker_list_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f5.WorkerListPage(),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'DynamicServiceForm completo (features/user/presentation/widgets/dynamic_service_form.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f6.DynamicServiceForm(
            config: f7.ServiceConfigModel.fromMap(sampleServiceConfigModel),
            initialValues: const {},
            onChanged: (_) {},
            formKey: null),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'DynamicServiceForm mínimo (features/user/presentation/widgets/dynamic_service_form.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f6.DynamicServiceForm(
            config: f7.ServiceConfigModel.fromMap(sampleServiceConfigModel),
            onChanged: (_) {}),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'InProgressJobCard completo (features/user/presentation/widgets/in_progress_job_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f8.InProgressJobCard(
            serviceName: 'id-1',
            description: 'id-1',
            address: 'id-1',
            status: 'id-1',
            onOpen: () {},
            pausedByDispute: true),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'InProgressJobCard mínimo (features/user/presentation/widgets/in_progress_job_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f8.InProgressJobCard(
            serviceName: 'id-1',
            description: 'id-1',
            address: 'id-1',
            status: 'id-1',
            onOpen: () {}),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'OpenQuoteSubmittedDialog completo (features/user/presentation/widgets/open_quote_submitted_dialog.dart)',
      (tester) async {
    await smokeWidget(
        tester, () => f9.OpenQuoteSubmittedDialog(workerName: 'id-1'),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'PricingModeQuestionnaire completo (features/user/presentation/widgets/pricing_mode_questionnaire.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f10.PricingModeQuestionnaire(
            workerPreselected: true,
            onRecommendation: (_) {},
            category: 'id-1',
            initialRecommendation: f11.PricingModeRecommendation(
                mode: 'id-1', title: 'id-1', explanation: 'id-1')),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'PricingModeQuestionnaire mínimo (features/user/presentation/widgets/pricing_mode_questionnaire.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f10.PricingModeQuestionnaire(
            workerPreselected: true, onRecommendation: (_) {}),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'ServiceRequestSubmittedDialog completo (features/user/presentation/widgets/service_request_submitted_dialog.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f12.ServiceRequestSubmittedDialog(
            workerName: 'id-1', jobLabel: 'id-1'),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'TestingFeedbackSheet completo (features/user/presentation/widgets/testing_feedback_sheet.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f13.TestingFeedbackSheet(onSubmit: (_) async {}, role: 'id-1'),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'TestingFeedbackSheet mínimo (features/user/presentation/widgets/testing_feedback_sheet.dart)',
      (tester) async {
    await smokeWidget(
        tester, () => f13.TestingFeedbackSheet(onSubmit: (_) async {}),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'TimeSlotSelector completo (features/user/presentation/widgets/time_slot_selector.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f14.TimeSlotSelector(
            selected: const TimeOfDay(hour: 10, minute: 0),
            onChanged: (_) {},
            availableLabels: ['id-1'],
            reservedLabels: const {},
            emptyHint: 'id-1'),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'TimeSlotSelector mínimo (features/user/presentation/widgets/time_slot_selector.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f14.TimeSlotSelector(
            selected: const TimeOfDay(hour: 10, minute: 0), onChanged: (_) {}),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'TrasladoRadarBanner completo (features/user/presentation/widgets/traslado_radar_banner.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f15.TrasladoRadarBanner(
            quote: f16.TransportSurcharge(
                distanceKm: 1.0,
                radiusKm: 1.0,
                extraKm: 1.0,
                extraClp: 1,
                insideRadar: true)),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'WorkerListFilters completo (features/user/presentation/widgets/worker_list_chrome.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f17.WorkerListFilters(
            searchController: TextEditingController(),
            sortBy: 'id-1',
            minRating: 1.0,
            onSortChanged: (_) {},
            onMinRatingChanged: (_) {}),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'WorkerListLocationHeader completo (features/user/presentation/widgets/worker_list_chrome.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f17.WorkerListLocationHeader(label: 'id-1', onChangeCity: () {}),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'WorkerListAddressRow completo (features/user/presentation/widgets/worker_list_chrome.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f17.WorkerListAddressRow(
            addressController: TextEditingController(),
            onSearch: () {},
            onUseGps: () {},
            locatingAddress: true,
            locatingGps: true,
            hasFix: true),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'WorkerListLocationChip completo (features/user/presentation/widgets/worker_list_chrome.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f17.WorkerListLocationChip(
            locating: true, ready: true, onPressed: () {}),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'WorkerListAvailableNowTile completo (features/user/presentation/widgets/worker_list_chrome.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f17.WorkerListAvailableNowTile(value: true, onChanged: (_) {}),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'WorkerReviewsSection completo (features/user/presentation/widgets/worker_reviews_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f18.WorkerReviewsSection(reviews: [
              f19.WorkerReviewModel(
                  id: 'id-1', score: 1, createdAt: DateTime.utc(2026, 1, 2, 15))
            ], averageRating: 1.0, maxVisible: 1, resumenResenas: 'id-1'),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'WorkerReviewsSection mínimo (features/user/presentation/widgets/worker_reviews_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f18.WorkerReviewsSection(reviews: [
              f19.WorkerReviewModel(
                  id: 'id-1', score: 1, createdAt: DateTime.utc(2026, 1, 2, 15))
            ], averageRating: 1.0),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'WorkerSearchMap completo (features/user/presentation/widgets/worker_search_map.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f20.WorkerSearchMap(
            workers: [f21.WorkerModel.fromMap(sampleWorkerModel)],
            users: const {},
            onSelectWorker: (_) {},
            selectedWorkerId: '00000000-0000-4000-8000-0000000000aa',
            clientLatitude: 1.0,
            clientLongitude: 1.0,
            categoryLabel: 'id-1',
            onPickClientLocation: (_, __) {},
            onOpenWorker: (_) {},
            addressController: TextEditingController(),
            onSearchAddress: () {},
            onUseGps: () {},
            locatingGps: true,
            locatingAddress: true,
            showSelectedCard: true,
            showLocationBar: true,
            interactive: true),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'WorkerSearchMap mínimo (features/user/presentation/widgets/worker_search_map.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f20.WorkerSearchMap(
            workers: [f21.WorkerModel.fromMap(sampleWorkerModel)],
            users: const {},
            onSelectWorker: (_) {}),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'WorkerMapOverlayHeader completo (features/user/presentation/widgets/worker_search_map.dart)',
      (tester) async {
    await smokeWidget(tester, () => f20.WorkerMapOverlayHeader(text: 'id-1'),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'WorkerServiceOptionPicker completo (features/user/presentation/widgets/worker_service_option_picker.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f22.WorkerServiceOptionPicker(
            worker: f21.WorkerModel.fromMap(sampleWorkerModel),
            category: 'id-1',
            onSelected: (_) {},
            initialOptionId: '00000000-0000-4000-8000-0000000000aa'),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'WorkerServiceOptionPicker mínimo (features/user/presentation/widgets/worker_service_option_picker.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f22.WorkerServiceOptionPicker(
            worker: f21.WorkerModel.fromMap(sampleWorkerModel),
            category: 'id-1',
            onSelected: (_) {}),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'WorkerSquareMetersField completo (features/user/presentation/widgets/worker_square_meters_field.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f23.WorkerSquareMetersField(
            controller: TextEditingController(),
            unitRateClp: 1,
            onChanged: () {},
            serviceCategory: 'id-1',
            squareMeters: 1,
            totalClp: 1),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'WorkerSquareMetersField mínimo (features/user/presentation/widgets/worker_square_meters_field.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f23.WorkerSquareMetersField(
            controller: TextEditingController(),
            unitRateClp: 1,
            onChanged: () {}),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'WorkerUnavailableDialog completo (features/user/presentation/widgets/worker_unavailable_dialog.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f24.WorkerUnavailableDialog(
            workerName: 'id-1',
            alternatives: [f21.WorkerModel.fromMap(sampleWorkerModel)],
            serviceId: '00000000-0000-4000-8000-0000000000aa'),
        seeded: true,
        role: 'usuario');
  });
}
