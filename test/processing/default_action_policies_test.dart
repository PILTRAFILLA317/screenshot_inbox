import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_inbox/domain/actions/suggested_action.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/processing/actions/action_policy.dart';
import 'package:screenshot_inbox/processing/actions/default_action_policies.dart';

import '../support/fixtures.dart';

void main() {
  test('event actions require reliable date/place fields', () async {
    final proposals = await const EventActionPolicy().propose(
      objectFixture(
        type: ExtractedObjectType.event,
        structuredData: const {
          'startsAt': '2030-08-22T21:00:00Z',
          'venue': 'Wembley Stadium',
          'time': '21:00',
        },
      ),
    );

    expect(
      _types(proposals),
      containsAll([
        SuggestedActionType.calendar,
        SuggestedActionType.reminder,
        SuggestedActionType.maps,
      ]),
    );
  });

  test('coupon actions only include copy when no expiry exists', () async {
    final proposals = await const CouponActionPolicy().propose(
      objectFixture(structuredData: const {'couponCode': 'SAVE20'}),
    );

    expect(_types(proposals), [SuggestedActionType.copy]);
  });

  test(
    'order fallback searches web and copies tracking without inventing URL',
    () async {
      final proposals = await const OrderActionPolicy().propose(
        objectFixture(
          type: ExtractedObjectType.order,
          structuredData: const {'trackingNumber': '1Z999AA10123456784'},
        ),
      );

      expect(_types(proposals), [
        SuggestedActionType.copy,
        SuggestedActionType.searchWeb,
      ]);
      expect(
        proposals.any((proposal) => proposal.payload.containsKey('url')),
        isFalse,
      );
    },
  );

  test('product and place policies expose useful local actions', () async {
    final product = await const ProductActionPolicy().propose(
      objectFixture(
        type: ExtractedObjectType.product,
        structuredData: const {
          'productName': 'Headphones',
          'url': 'https://example.com/item',
        },
      ),
    );
    final place = await const PlaceActionPolicy().propose(
      objectFixture(
        type: ExtractedObjectType.place,
        structuredData: const {'mapsQuery': 'La Viña, San Sebastián'},
      ),
    );

    expect(
      _types(product),
      containsAll([
        SuggestedActionType.openUrl,
        SuggestedActionType.searchWeb,
        SuggestedActionType.copy,
      ]),
    );
    expect(_types(place), [
      SuggestedActionType.maps,
      SuggestedActionType.searchWeb,
    ]);
  });
}

List<SuggestedActionType> _types(List<ActionProposal> proposals) =>
    proposals.map((proposal) => proposal.type).toList(growable: false);
