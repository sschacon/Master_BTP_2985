CLASS zcl_aux_travel_det_2985 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

*    TYPES:
*      gty_tt_travel_reported  TYPE TABLE FOR REPORTED z_i_travel_2985,
*      gty_tt_booking_reported TYPE TABLE FOR REPORTED z_i_booking_2985,
*      gty_tt_booksup_reported TYPE TABLE FOR REPORTED z_i_booksup_2985.

    TYPES:
      gty_tt_travel_id TYPE TABLE OF /dmo/travel_id.

    CLASS-METHODS calculate_price IMPORTING it_travel_id TYPE gty_tt_travel_id.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_AUX_TRAVEL_DET_2985 IMPLEMENTATION.


  METHOD calculate_price.

    DATA:
      lv_total_booking_price TYPE /dmo/total_price,
      lv_total_suppl_price   TYPE /dmo/total_price.

*   No se han seleccionado viajes modificados, nos vamos
    IF it_travel_id[] IS INITIAL.
      RETURN.
    ENDIF.

*   Leemos la entidad Travel (viajes)
    READ ENTITIES OF z_i_travel_2985
              ENTITY Travel
              FIELDS ( travel_id currency_code )
          WITH VALUE #( FOR lv_travel_id IN it_travel_id ( travel_id = lv_travel_id ) )
         RESULT DATA(lt_read_travel).

*   Leemos la entidad Booking (reservas)
    READ ENTITIES OF z_i_travel_2985
              ENTITY Travel BY \_Booking
          FROM VALUE #( FOR lv_travel_id IN it_travel_id (
                            travel_id              = lv_travel_id
                            %control-flight_price  = if_abap_behv=>mk-on
                            %control-currency_code = if_abap_behv=>mk-on ) )
         RESULT DATA(lt_read_booking).

*   Leemos las reservas agrupadas por viajes. La agrupación la dejamos en LV_TRAVEL_KEY
    LOOP AT lt_read_booking INTO DATA(ls_booking)
                             GROUP BY ls_booking-travel_id INTO DATA(lv_travel_key).

*     Leemos el viaje de la reserva que se está tratando
      ASSIGN lt_read_travel[ KEY entity COMPONENTS travel_id = lv_travel_key ]
          TO FIELD-SYMBOL(<ls_travel>).

*     Leemos las reservas agrupadas en LV_TRAVEL_KEY
*     Volvemos a agrupar por moneda. La agrupación la dejamos en LV_CURR
      LOOP AT GROUP lv_travel_key INTO DATA(ls_booking_result)
                                   GROUP BY ls_booking_result-currency_code INTO DATA(lv_curr).

        lv_total_booking_price = 0.

*       Sumamos los precios de la misma reserva y viaje agrupados por moneda
        LOOP AT GROUP lv_curr INTO DATA(ls_booking_line).
          lv_total_booking_price = lv_total_booking_price + ls_booking_line-flight_price.
        ENDLOOP.

*       La reserva tiene la misma moneda que se está tratando actualmente
        IF lv_curr EQ <ls_travel>-currency_code.
          <ls_travel>-total_price = <ls_travel>-total_price + lv_total_booking_price.

*       La reserva tiene otra moneda de la que se está tratando actualmente,
*       se hace una conversión del precio a la moneda de la reserva
        ELSE.

          /dmo/cl_flight_amdp=>convert_currency(
            EXPORTING
              iv_amount               = lv_total_booking_price
              iv_currency_code_source = lv_curr
              iv_currency_code_target = <ls_travel>-currency_code
              iv_exchange_rate_date   = cl_abap_context_info=>get_system_date( )
            IMPORTING
              ev_amount               = DATA(lv_amount_converted) ).

          <ls_travel>-total_price += lv_amount_converted.

        ENDIF.

      ENDLOOP.

    ENDLOOP.

*   Leemos la entidad Supplement (suplementos)
    READ ENTITIES OF z_i_travel_2985
              ENTITY Booking BY \_BookingSupplement
          FROM VALUE #( FOR ls_travel IN lt_read_booking (
                            travel_id              = ls_travel-travel_id
                            booking_id             = ls_travel-booking_id
                            %control-price         = if_abap_behv=>mk-on
                            %control-currency_code = if_abap_behv=>mk-on ) )
         RESULT DATA(lt_read_supplement).

*   Leemos los suplementos agrupados por viajes. La agrupación la dejamos en LV_TRAVEL_KEY
    LOOP AT lt_read_supplement INTO DATA(ls_booking_suppl)
                                GROUP BY ls_booking_suppl-travel_id INTO lv_travel_key.

*     Leemos el viaje del suplemento que se está tratando
      ASSIGN lt_read_travel[ KEY entity COMPONENTS travel_id = lv_travel_key ] TO <ls_travel>.

*     Leemos los suplementos que se han agrupado en la reserva que se está tratando
*     Volvemos a agrupar por moneda

*     Leemos los supplementos agrupados en LV_TRAVEL_KEY
*     Volvemos a agrupar por moneda. La agrupación la dejamos en LV_CURR
      LOOP AT GROUP lv_travel_key INTO DATA(ls_supplement_result)
                                   GROUP BY ls_supplement_result-currency_code INTO lv_curr.

        lv_total_suppl_price = 0.

*       Sumamos los precios del mismo suplemento y viaje agrupados por moneda
        LOOP AT GROUP lv_curr INTO DATA(ls_supplement_line).
          lv_total_suppl_price += ls_supplement_line-price.
        ENDLOOP.

*       El suplemento tiene la misma moneda que se está tratando actualmente
        IF lv_curr EQ <ls_travel>-currency_code.
          <ls_travel>-total_price += lv_total_suppl_price.

*       El suplemento tiene otra moneda de la que se está tratando actualmente,
*       se hace una conversión del precio a la moneda del suplemento
        ELSE.

          /dmo/cl_flight_amdp=>convert_currency(
            EXPORTING
              iv_amount               = lv_total_suppl_price
              iv_currency_code_source = lv_curr
              iv_currency_code_target = <ls_travel>-currency_code
              iv_exchange_rate_date   = cl_abap_context_info=>get_system_date( )
            IMPORTING
              ev_amount               = lv_amount_converted ).

          <ls_travel>-total_price += lv_amount_converted.

        ENDIF.

      ENDLOOP.

    ENDLOOP.

*   Actualizamos la capa de persistencia
    IF NOT lt_read_travel[] IS INITIAL.
      MODIFY ENTITIES OF z_i_travel_2985
                  ENTITY Travel
       UPDATE FROM VALUE #( FOR ls_travel_bo IN lt_read_travel (
                                travel_id            = ls_travel_bo-travel_id
                                total_price          = ls_travel_bo-total_price
                                %control-total_price = if_abap_behv=>mk-on ) ).
    ENDIF.

  ENDMETHOD.
ENDCLASS.
