enum DeliveryStatus {
  inDelivery('Dalam Pengiriman', 'Dalam Pengiriman'),
  pending('Pending', 'Pending'),
  completed('Selesai', 'Selesai'),
  delivered('Terkirim', 'Terkirim');

  const DeliveryStatus(this.value, this.label);

  final String value;
  final String label;

  static DeliveryStatus fromValue(String value) {
    final normalized = value.trim().toLowerCase();

    return DeliveryStatus.values.firstWhere(
      (status) =>
          status.value.toLowerCase() == normalized ||
          _aliases[status]!.contains(normalized),
      orElse: () => DeliveryStatus.pending,
    );
  }

  static const Map<DeliveryStatus, List<String>> _aliases =
      <DeliveryStatus, List<String>>{
        DeliveryStatus.inDelivery: <String>[
          'assigned',
          'on_the_way',
          'in_transit',
          'dalam perjalanan',
          'dalam pengiriman',
        ],
        DeliveryStatus.pending: <String>['baru', 'pending'],
        DeliveryStatus.completed: <String>['selesai', 'completed', 'done'],
        DeliveryStatus.delivered: <String>[
          'delivered',
          'terkirim',
          'sampai',
        ],
      };

  List<String> get trackingFallbackValues {
    switch (this) {
      case DeliveryStatus.inDelivery:
        return <String>[
          value,
          'Dalam Perjalanan',
          'in_transit',
          'on_the_way',
          'assigned',
        ];
      case DeliveryStatus.pending:
        return <String>[
          value,
          'baru',
          'assigned',
          'pending',
        ];
      case DeliveryStatus.completed:
        return <String>[
          value,
          'Sampai',
          'completed',
          'done',
        ];
      case DeliveryStatus.delivered:
        return <String>[
          value,
          'Sampai',
          'delivered',
          'completed',
        ];
    }
  }
}
