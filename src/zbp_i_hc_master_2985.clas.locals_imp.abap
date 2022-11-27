CLASS lcl_buffer DEFINITION.

  PUBLIC SECTION.

    CONSTANTS: created TYPE c LENGTH 1 VALUE 'C',
               updated TYPE c LENGTH 1 VALUE 'U',
               deleted TYPE c LENGTH 1 VALUE 'D'.

    TYPES: BEGIN OF ty_buffer_master,
             data TYPE zhc_master_2985.
    TYPES: flag TYPE c LENGTH 1,
           END OF ty_buffer_master.

    TYPES: tt_master TYPE SORTED TABLE OF ty_buffer_master WITH UNIQUE KEY data-e_number.

    CLASS-DATA mt_buffer_master TYPE tt_master.

ENDCLASS.

CLASS lcl_buffer IMPLEMENTATION.

ENDCLASS.

CLASS lhc_HCMaster DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS:
      create FOR MODIFY IMPORTING entities FOR CREATE HCMaster,
      delete FOR MODIFY IMPORTING keys     FOR DELETE HCMaster,
      update FOR MODIFY IMPORTING entities FOR UPDATE HCMaster.

    METHODS read FOR READ IMPORTING keys FOR READ HCMaster RESULT result.

ENDCLASS.

CLASS lhc_HCMaster IMPLEMENTATION.

  METHOD create.

    GET TIME STAMP FIELD DATA(lv_time_stamp).
    DATA(lv_uname) = cl_abap_context_info=>get_user_technical_name( ).

    SELECT MAX( e_number ) FROM zhc_master_2985 INTO @DATA(lv_max_employee_number).

    LOOP AT entities INTO DATA(ls_entities).

      ls_entities-%data-crea_date_time = lv_time_stamp.
      ls_entities-%data-crea_uname = lv_uname.
      ls_entities-%data-e_number = lv_max_employee_number + 1.

      INSERT VALUE #( flag = lcl_buffer=>created
                      data = CORRESPONDING #( ls_entities-%data ) )
        INTO TABLE lcl_buffer=>mt_buffer_master.

      IF NOT ls_entities-%cid IS INITIAL.
         INSERT VALUE #( %cid = ls_entities-%cid
                         e_number = ls_entities-e_number )
           INTO TABLE mapped-hcmaster.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD update.

    GET TIME STAMP FIELD DATA(lv_time_stamp).
    DATA(lv_uname) = cl_abap_context_info=>get_user_technical_name( ).

    LOOP AT entities INTO DATA(ls_entities).

    SELECT SINGLE * FROM zhc_master_2985
                   WHERE e_number eq @ls_entities-%data-e_number
                    INTO @DATA(ls_ddbb).

      ls_entities-%data-lchg_date_time = lv_time_stamp.
      ls_entities-%data-lchg_uname = lv_uname.

      INSERT VALUE #( flag = lcl_buffer=>updated
                      data = VALUE #( e_number = ls_entities-%data-e_number
                                        e_name = cond #( when ls_entities-%control-e_name eq if_abap_behv=>mk-on
                                                       then ls_entities-%data-e_name
                                                       else ls_ddbb-e_name )
                                e_department = cond #( when ls_entities-%control-e_department eq if_abap_behv=>mk-on
                                                       then ls_entities-%data-e_department
                                                       else ls_ddbb-e_department )
                                      status = cond #( when ls_entities-%control-status eq if_abap_behv=>mk-on
                                                       then ls_entities-%data-status
                                                       else ls_ddbb-status )
                                      job_title = cond #( when ls_entities-%control-job_title eq if_abap_behv=>mk-on
                                                       then ls_entities-%data-job_title
                                                       else ls_ddbb-job_title )
                                      start_date = cond #( when ls_entities-%control-start_date eq if_abap_behv=>mk-on
                                                       then ls_entities-%data-start_date
                                                       else ls_ddbb-start_date )
                                      end_date = cond #( when ls_entities-%control-end_date eq if_abap_behv=>mk-on
                                                       then ls_entities-%data-end_date
                                                       else ls_ddbb-end_date )
                                      email = cond #( when ls_entities-%control-email eq if_abap_behv=>mk-on
                                                       then ls_entities-%data-email
                                                       else ls_ddbb-email )
                                      m_number = cond #( when ls_entities-%control-m_number eq if_abap_behv=>mk-on
                                                       then ls_entities-%data-m_number
                                                       else ls_ddbb-m_number )
                                      m_name = cond #( when ls_entities-%control-m_name eq if_abap_behv=>mk-on
                                                       then ls_entities-%data-m_name
                                                       else ls_ddbb-m_name )
                                      m_department = cond #( when ls_entities-%control-m_department eq if_abap_behv=>mk-on
                                                       then ls_entities-%data-m_department
                                                       else ls_ddbb-m_department )
                                      crea_date_time = ls_ddbb-crea_date_time
                                      crea_uname = ls_ddbb-crea_uname
      ) ) INTO TABLE lcl_buffer=>mt_buffer_master.

    IF NOT ls_entities-%data-e_number IS INITIAL.
        INSERT VALUE #( %cid = ls_entities-%data-e_number
                        e_number = ls_entities-%data-e_number )
          INTO TABLE mapped-hcmaster.
    ENDIF.

   ENDLOOP.

  ENDMETHOD.

  METHOD delete.

   LOOP AT keys INTO DATA(ls_keys).

     INSERT VALUE #( flag = lcl_buffer=>deleted
                     data = VALUE #( e_number = ls_keys-%key-e_number ) )
       INTO TABLE lcl_buffer=>mt_buffer_master.

     IF NOT ls_keys-%key-e_number IS INITIAL.
        INSERT VALUE #( %cid = ls_keys-%key-e_number
                        e_number = ls_keys-%key-e_number )
          INTO TABLE mapped-hcmaster.
     ENDIF.

   ENDLOOP.

  ENDMETHOD.

  METHOD read.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_HCMaster DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS:
      check_before_save REDEFINITION,
      finalize REDEFINITION,
      save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_HCMaster IMPLEMENTATION.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD finalize.
  ENDMETHOD.

  METHOD save.

  DATA:
   lt_data_created type standard table of zhc_master_2985,
   lt_data_updated type standard table of zhc_master_2985,
   lt_data_deleted type standard table of zhc_master_2985.

   lt_data_created = VALUE #( FOR <row> IN lcl_buffer=>mt_buffer_master
                              WHERE ( flag = lcl_buffer=>created ) ( <row>-data ) ).

   IF NOT lt_data_created IS INITIAL.
        INSERT zhc_master_2985 FROM TABLE @lt_data_created.
   ENDIF.

   lt_data_updated = VALUE #( FOR <row> IN lcl_buffer=>mt_buffer_master
                              WHERE ( flag = lcl_buffer=>updated ) ( <row>-data ) ).

   IF NOT lt_data_updated IS INITIAL.
        UPDATE zhc_master_2985 FROM TABLE @lt_data_updated.
   ENDIF.

   lt_data_deleted = VALUE #( FOR <row> IN lcl_buffer=>mt_buffer_master
                              WHERE ( flag = lcl_buffer=>deleted ) ( <row>-data ) ).

   IF NOT lt_data_deleted IS INITIAL.
        DELETE zhc_master_2985 FROM TABLE @lt_data_deleted.
   ENDIF.

   CLEAR lcl_buffer=>mt_buffer_master.

  ENDMETHOD.

  METHOD cleanup.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
