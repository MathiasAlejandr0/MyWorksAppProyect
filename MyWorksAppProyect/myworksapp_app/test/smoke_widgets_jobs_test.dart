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
import 'package:myworksapp/features/jobs/presentation/pages/evidence_shutter_camera_page.dart'
    as f0;
import 'package:myworksapp/features/jobs/presentation/pages/job_detail_page.dart'
    as f1;
import 'package:myworksapp/features/jobs/presentation/pages/job_history_page.dart'
    as f2;
import 'package:myworksapp/features/jobs/presentation/pages/job_photos_page.dart'
    as f3;
import 'package:myworksapp/features/jobs/presentation/pages/job_schedule_page.dart'
    as f4;
import 'package:myworksapp/features/jobs/presentation/widgets/change_orders_section.dart'
    as f5;
import 'package:myworksapp/core/database/models/change_order_model.dart' as f6;
import 'package:myworksapp/features/jobs/presentation/widgets/client_live_tracking.dart'
    as f7;
import 'package:myworksapp/features/jobs/presentation/widgets/client_start_pin_card.dart'
    as f8;
import 'package:myworksapp/features/jobs/presentation/widgets/dispute_section.dart'
    as f9;
import 'package:myworksapp/core/database/models/dispute_model.dart' as f10;
import 'package:myworksapp/features/jobs/presentation/widgets/evidence_shutter_button.dart'
    as f11;
import 'package:myworksapp/features/jobs/presentation/widgets/job_accepted_location_card.dart'
    as f12;
import 'package:myworksapp/features/jobs/presentation/widgets/job_detail_actions_section.dart'
    as f13;
import 'package:myworksapp/core/database/models/job_model.dart' as f14;
import 'package:myworksapp/features/jobs/presentation/widgets/job_detail_client_approval_card.dart'
    as f15;
import 'package:myworksapp/core/domain/price_quote.dart' as f16;
import 'package:myworksapp/features/jobs/presentation/widgets/job_detail_description_section.dart'
    as f17;
import 'package:myworksapp/features/jobs/presentation/widgets/job_detail_payment_escrow_section.dart'
    as f18;
import 'package:myworksapp/core/database/models/quote_proposal_model.dart'
    as f19;
import 'package:myworksapp/features/jobs/presentation/widgets/job_detail_scheduled_date_row.dart'
    as f20;
import 'package:myworksapp/features/jobs/presentation/widgets/job_detail_status_header.dart'
    as f21;
import 'package:myworksapp/features/jobs/presentation/widgets/job_history_cards.dart'
    as f22;
import 'package:myworksapp/features/jobs/presentation/widgets/job_location_preview_section.dart'
    as f23;
import 'package:myworksapp/features/jobs/presentation/widgets/job_status_timeline.dart'
    as f24;
import 'package:myworksapp/features/jobs/presentation/widgets/open_quote_status_banner.dart'
    as f25;
import 'package:myworksapp/features/jobs/presentation/widgets/quote_proposals_section.dart'
    as f26;
import 'package:myworksapp/features/jobs/presentation/widgets/reschedule_section.dart'
    as f27;
import 'package:myworksapp/core/database/repositories/reschedule_repository.dart'
    as f28;
import 'package:myworksapp/core/database/repositories/worker_repository.dart'
    as f29;
import 'package:myworksapp/features/jobs/presentation/widgets/worker_gps_publisher.dart'
    as f30;
import 'package:myworksapp/features/jobs/presentation/widgets/worker_quote_form_dialog.dart'
    as f31;
import 'support/model_samples.dart';
import 'support/widget_harness.dart';

void main() {
  testWidgets(
      'EvidenceShutterCameraPage completo (features/jobs/presentation/pages/evidence_shutter_camera_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.EvidenceShutterCameraPage(),
        seeded: true);
  });
  testWidgets(
      'JobDetailPage completo (features/jobs/presentation/pages/job_detail_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f1.JobDetailPage(jobId: 'id-1'),
        seeded: true);
  });
  testWidgets(
      'JobHistoryPage completo (features/jobs/presentation/pages/job_history_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.JobHistoryPage(), seeded: true);
  });
  testWidgets(
      'JobPhotosPage completo (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(
        tester, () => f3.JobPhotosPage(jobId: 'id-1', canAddPhotos: true),
        seeded: true);
  });
  testWidgets(
      'JobPhotosPage mínimo (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f3.JobPhotosPage(jobId: 'id-1'),
        seeded: false);
  });
  testWidgets(
      'JobSchedulePage completo (features/jobs/presentation/pages/job_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.JobSchedulePage(), seeded: true);
  });
  testWidgets(
      'ChangeOrdersSection completo (features/jobs/presentation/widgets/change_orders_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f5.ChangeOrdersSection(
            orders: [f6.ChangeOrderModel.fromMap(sampleChangeOrderModel)],
            isWorker: true,
            onReview: (_) {},
            onRequest: () {},
            canRequest: true),
        seeded: true);
  });
  testWidgets(
      'ChangeOrdersSection mínimo (features/jobs/presentation/widgets/change_orders_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f5.ChangeOrdersSection(
            orders: [f6.ChangeOrderModel.fromMap(sampleChangeOrderModel)],
            isWorker: true),
        seeded: false);
  });
  testWidgets(
      'ClientLiveTracking completo (features/jobs/presentation/widgets/client_live_tracking.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f7.ClientLiveTracking(
            jobId: 'id-1',
            jobStatus: 'id-1',
            destinationLat: 1.0,
            destinationLng: 1.0),
        seeded: true);
  });
  testWidgets(
      'ClientLiveTracking mínimo (features/jobs/presentation/widgets/client_live_tracking.dart)',
      (tester) async {
    await smokeWidget(
        tester, () => f7.ClientLiveTracking(jobId: 'id-1', jobStatus: 'id-1'),
        seeded: false);
  });
  testWidgets(
      'ClientStartPinCard completo (features/jobs/presentation/widgets/client_start_pin_card.dart)',
      (tester) async {
    await smokeWidget(tester, () => f8.ClientStartPinCard(pin: 'id-1'),
        seeded: true);
  });
  testWidgets(
      'DisputeSection completo (features/jobs/presentation/widgets/dispute_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f9.DisputeSection(
            dispute: f10.DisputeModel.fromMap(sampleDisputeModel),
            canOpenDispute: true,
            isParticipant: true,
            canNegotiate: true,
            onOpenDispute: null,
            onAddComment: (_) async {},
            onAppeal: (_) async {},
            onRespondAgreement: (_) async {},
            onCancelRequest: () {},
            pendingAgreementType: 'id-1',
            pendingAgreementId: 'id-1'),
        seeded: true);
  });
  testWidgets(
      'DisputeSection mínimo (features/jobs/presentation/widgets/dispute_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f9.DisputeSection(
            dispute: f10.DisputeModel.fromMap(sampleDisputeModel),
            canOpenDispute: true,
            isParticipant: true),
        seeded: false);
  });
  testWidgets(
      'EvidenceShutterButton completo (features/jobs/presentation/widgets/evidence_shutter_button.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f11.EvidenceShutterButton(
            onPhoto: () {},
            onVideoStart: () {},
            onVideoEnd: () {},
            isRecording: true),
        seeded: true);
  });
  testWidgets(
      'EvidenceShutterButton mínimo (features/jobs/presentation/widgets/evidence_shutter_button.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f11.EvidenceShutterButton(
            onPhoto: () {}, onVideoStart: () {}, onVideoEnd: () {}),
        seeded: false);
  });
  testWidgets(
      'JobAcceptedLocationCard completo (features/jobs/presentation/widgets/job_accepted_location_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f12.JobAcceptedLocationCard(
            address: 'id-1',
            latitude: 1.0,
            longitude: 1.0,
            scheduledDate: DateTime.utc(2026, 1, 2, 15),
            isLoadingAddress: true),
        seeded: true);
  });
  testWidgets(
      'JobAcceptedLocationCard mínimo (features/jobs/presentation/widgets/job_accepted_location_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f12.JobAcceptedLocationCard(
            address: 'id-1', latitude: 1.0, longitude: 1.0),
        seeded: false);
  });
  testWidgets(
      'JobDetailActionsSection completo (features/jobs/presentation/widgets/job_detail_actions_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f13.JobDetailActionsSection(
            jobId: 'id-1',
            job: f14.JobModel.fromMap(sampleJobModel),
            isWorker: true,
            isOwner: true,
            canTransition: const {},
            onGoToDashboard: () {},
            onCancelJob: () async {},
            onAcceptJob: () {},
            onRejectJob: () async {},
            onMarkEnRoute: () {},
            onStartJob: () {},
            onRequestOvertimeHours: () {},
            onCompleteJob: () {},
            workPausedByDispute: true,
            ratingBlockedByDispute: true,
            alreadyRated: true,
            onRatingChanged: () {}),
        seeded: true);
  });
  testWidgets(
      'JobDetailActionsSection mínimo (features/jobs/presentation/widgets/job_detail_actions_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f13.JobDetailActionsSection(
            jobId: 'id-1',
            job: f14.JobModel.fromMap(sampleJobModel),
            isWorker: true,
            isOwner: true,
            canTransition: const {},
            onGoToDashboard: () {},
            onCancelJob: () async {},
            onAcceptJob: () {},
            onRejectJob: () async {},
            onMarkEnRoute: () {},
            onStartJob: () {},
            onRequestOvertimeHours: () {},
            onCompleteJob: () {}),
        seeded: false);
  });
  testWidgets(
      'JobDetailClientApprovalCard completo (features/jobs/presentation/widgets/job_detail_client_approval_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f15.JobDetailClientApprovalCard(
            jobId: 'id-1',
            quote: f16.PriceQuote.fromJson(samplePriceQuote),
            onApprove: () {},
            onReject: () {}),
        seeded: true);
  });
  testWidgets(
      'JobDetailDescriptionSection completo (features/jobs/presentation/widgets/job_detail_description_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f17.JobDetailDescriptionSection(
            job: f14.JobModel.fromMap(sampleJobModel)),
        seeded: true);
  });
  testWidgets(
      'JobDetailPaymentEscrowSection completo (features/jobs/presentation/widgets/job_detail_payment_escrow_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f18.JobDetailPaymentEscrowSection(
            job: f14.JobModel.fromMap(sampleJobModel),
            jobId: 'id-1',
            isWorker: true,
            isClientOwner: true,
            isAssignedWorker: true,
            invitedWorkerName: 'id-1',
            quoteProposals: [
              f19.QuoteProposalModel.fromMap(sampleQuoteProposalModel)
            ],
            onPayEscrow: () {},
            onApproveCompletion: () {},
            onRejectCompletion: () {},
            blockedByDispute: true),
        seeded: true);
  });
  testWidgets(
      'JobDetailPaymentEscrowSection mínimo (features/jobs/presentation/widgets/job_detail_payment_escrow_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f18.JobDetailPaymentEscrowSection(
            job: f14.JobModel.fromMap(sampleJobModel),
            jobId: 'id-1',
            isWorker: true,
            isClientOwner: true,
            isAssignedWorker: true,
            invitedWorkerName: 'id-1',
            quoteProposals: [
              f19.QuoteProposalModel.fromMap(sampleQuoteProposalModel)
            ],
            onPayEscrow: () {},
            onApproveCompletion: () {},
            onRejectCompletion: () {}),
        seeded: false);
  });
  testWidgets(
      'JobDetailScheduledDateRow completo (features/jobs/presentation/widgets/job_detail_scheduled_date_row.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f20.JobDetailScheduledDateRow(
            scheduledDate: DateTime.utc(2026, 1, 2, 15)),
        seeded: true);
  });
  testWidgets(
      'JobDetailStatusHeader completo (features/jobs/presentation/widgets/job_detail_status_header.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f21.JobDetailStatusHeader(
            job: f14.JobModel.fromMap(sampleJobModel)),
        seeded: true);
  });
  testWidgets(
      'JobHistoryLiveCard completo (features/jobs/presentation/widgets/job_history_cards.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f22.JobHistoryLiveCard(
            title: 'id-1',
            address: 'id-1',
            dateLabel: 'id-1',
            status: 'id-1',
            onTap: () {}),
        seeded: true);
  });
  testWidgets(
      'JobHistoryCompletedCard completo (features/jobs/presentation/widgets/job_history_cards.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f22.JobHistoryCompletedCard(
            title: 'id-1',
            address: 'id-1',
            dateLabel: 'id-1',
            paymentStatus: 'id-1',
            onTap: () {}),
        seeded: true);
  });
  testWidgets(
      'JobHistoryClosedCard completo (features/jobs/presentation/widgets/job_history_cards.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f22.JobHistoryClosedCard(
            title: 'id-1',
            address: 'id-1',
            dateLabel: 'id-1',
            status: 'id-1',
            onTap: () {}),
        seeded: true);
  });
  testWidgets(
      'JobLocationPreviewSection completo (features/jobs/presentation/widgets/job_location_preview_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f23.JobLocationPreviewSection(
            address: 'id-1',
            latitude: 1.0,
            longitude: 1.0,
            isLoadingAddress: true),
        seeded: true);
  });
  testWidgets(
      'JobLocationPreviewSection mínimo (features/jobs/presentation/widgets/job_location_preview_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f23.JobLocationPreviewSection(
            address: 'id-1', latitude: 1.0, longitude: 1.0),
        seeded: false);
  });
  testWidgets(
      'JobStatusTimeline completo (features/jobs/presentation/widgets/job_status_timeline.dart)',
      (tester) async {
    await smokeWidget(tester, () => f24.JobStatusTimeline(status: 'id-1'),
        seeded: true);
  });
  testWidgets(
      'OpenQuoteStatusBanner completo (features/jobs/presentation/widgets/open_quote_status_banner.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f25.OpenQuoteStatusBanner(
            jobStatus: 'id-1',
            isClient: true,
            workerName: 'id-1',
            proposalsCount: 1),
        seeded: true);
  });
  testWidgets(
      'OpenQuoteStatusBanner mínimo (features/jobs/presentation/widgets/open_quote_status_banner.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f25.OpenQuoteStatusBanner(jobStatus: 'id-1', isClient: true),
        seeded: false);
  });
  testWidgets(
      'QuoteProposalsSection completo (features/jobs/presentation/widgets/quote_proposals_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f26.QuoteProposalsSection(
                proposals: [
                  f19.QuoteProposalModel.fromMap(sampleQuoteProposalModel)
                ],
                isClient: true,
                jobStatus: 'id-1',
                onSelect: (_) {},
                onSubmitQuote: () {}),
        seeded: true);
  });
  testWidgets(
      'QuoteProposalsSection mínimo (features/jobs/presentation/widgets/quote_proposals_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f26.QuoteProposalsSection(proposals: [
              f19.QuoteProposalModel.fromMap(sampleQuoteProposalModel)
            ], isClient: true, jobStatus: 'id-1'),
        seeded: false);
  });
  testWidgets(
      'RescheduleSection completo (features/jobs/presentation/widgets/reschedule_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f27.RescheduleSection(
            job: f14.JobModel.fromMap(sampleJobModel),
            currentUserId: 'id-1',
            onChanged: () async {},
            repository: f28.RescheduleRepository(),
            workerRepository: f29.WorkerRepository()),
        seeded: true);
  });
  testWidgets(
      'RescheduleSection mínimo (features/jobs/presentation/widgets/reschedule_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f27.RescheduleSection(
            job: f14.JobModel.fromMap(sampleJobModel),
            currentUserId: 'id-1',
            onChanged: () async {}),
        seeded: false);
  });
  testWidgets(
      'WorkerGpsPublisher completo (features/jobs/presentation/widgets/worker_gps_publisher.dart)',
      (tester) async {
    await smokeWidget(
        tester, () => f30.WorkerGpsPublisher(jobId: 'id-1', active: true),
        seeded: true);
  });
  testWidgets(
      'WorkerQuoteFormDialog completo (features/jobs/presentation/widgets/worker_quote_form_dialog.dart)',
      (tester) async {
    await smokeWidget(tester, () => f31.WorkerQuoteFormDialog(), seeded: true);
  });
}
