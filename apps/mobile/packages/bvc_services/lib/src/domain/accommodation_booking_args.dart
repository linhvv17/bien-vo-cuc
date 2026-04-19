/// Truyền qua tham số [arguments] của [Modular.to.pushNamed] khi vào màn đặt phòng từ chi tiết.
class AccommodationBookingArgs {
  const AccommodationBookingArgs({this.roomLines});

  /// roomType (SINGLE, DOUBLE, …) → số phòng.
  final Map<String, int>? roomLines;
}
