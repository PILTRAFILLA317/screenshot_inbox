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
        structuredData: {
          'date': '2030-08-22',
          'startsAt': '2030-08-22T21:00:00Z',
          'venue': 'Wembley Stadium',
          'city': 'London',
          'time': '21:00',
          '_fieldMetadata': _trustedMetadata(const [
            'title',
            'date',
            'venue',
            'city',
          ]),
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
      objectFixture(
        structuredData: {
          'couponCode': 'SAVE20',
          '_fieldMetadata': _trustedMetadata(const ['couponCode']),
        },
      ),
    );

    expect(_types(proposals), [SuggestedActionType.copy]);
  });

  test(
    'order fallback searches web and copies tracking without inventing URL',
    () async {
      final proposals = await const OrderActionPolicy().propose(
        objectFixture(
          type: ExtractedObjectType.order,
          structuredData: {
            'trackingNumber': '1Z999AA10123456784',
            '_fieldMetadata': _trustedMetadata(const ['trackingNumber']),
          },
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
        structuredData: {
          'address': '31 de Agosto Kalea, 3, San Sebastián',
          '_fieldMetadata': _trustedMetadata(const ['address']),
        },
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

Map<String, Object?> _trustedMetadata(List<String> fields) => {
  for (final field in fields)
    field: {
      'source': 'machineLocalAI',
      'confidence': 0.9,
      'evidence': const ['B01'],
    },
};
