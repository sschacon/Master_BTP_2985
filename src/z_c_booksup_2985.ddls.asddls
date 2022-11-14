@EndUserText.label: 'Consumption - Booking Supplement'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
define view entity Z_C_BOOKSUP_2985
  as projection on Z_I_BOOKSUP_2985
{

  key travel_id                   as TravelID,
  key booking_id                  as BookingID,
  key booking_supplement_id       as BookingSuppementID,
      supplement_id               as SupplementID,
      _SupplementText.Description as SupplementDescription : localized,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      price                       as Price,
      @Semantics.currencyCode: true
      currency_code               as CurrencyCode,
      /* Associations */
      _Travel  : redirected to Z_C_TRAVEL_2985,
      _Booking : redirected to parent Z_C_BOOKING_2985,
      _Product,
      _SupplementText

}
