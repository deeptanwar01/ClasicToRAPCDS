CLASS lhc_Students DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Students RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Students RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE Students.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE Students.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE Students.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE Students.

    METHODS read FOR READ
      IMPORTING keys FOR READ Students RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK Students.
    METHODS setStatus FOR MODIFY
      IMPORTING keys FOR ACTION Students~setStatus RESULT result.
    METHODS upload FOR MODIFY
      IMPORTING keys FOR ACTION Students~upload.
    METHODS copy FOR MODIFY
      IMPORTING keys FOR ACTION Students~copy.
    METHODS copyFromTemplate FOR MODIFY
      IMPORTING keys FOR ACTION Students~copyFromTemplate.
    METHODS resetStatus FOR MODIFY
      IMPORTING keys FOR ACTION Students~resetStatus.

ENDCLASS.

CLASS lhc_Students IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
    DATA(auth_flag) = abap_true.
    IF auth_flag EQ abap_true.
      result-%create = if_abap_behv=>auth-allowed.
      result-%update = if_abap_behv=>auth-allowed.
      result-%delete = if_abap_behv=>auth-allowed.
      result-%action-setStatus = if_abap_behv=>auth-allowed.
    ELSE.
      result-%create = if_abap_behv=>auth-unauthorized.
      result-%update = if_abap_behv=>auth-unauthorized.
      result-%delete = if_abap_behv=>auth-unauthorized.
      result-%action-setStatus = if_abap_behv=>auth-unauthorized.
      APPEND VALUE #( %msg = new_message_with_text( text = 'Unauthorized!'
                                                  severity = if_abap_behv_message=>severity-error )
                    %global = if_abap_behv=>mk-on ) TO reported-students.
    ENDIF.
  ENDMETHOD.

  METHOD create.
    zday4_um_api=>get_instance(  )->create(
      EXPORTING
        entities = entities
      CHANGING
        mapped   = mapped
        failed   = failed
        reported = reported
    ).

  ENDMETHOD.

  METHOD earlynumbering_create.
    zday4_um_api=>get_instance(  )->earlynumbering_create(
      EXPORTING
        entities = entities
      CHANGING
        mapped   = mapped
        failed   = failed
        reported = reported
    ).
  ENDMETHOD.

  METHOD update.
    zday4_um_api=>get_instance(  )->update_student(
      EXPORTING
        entities = entities
      CHANGING
        mapped   = mapped
        failed   = failed
        reported = reported
    ).
  ENDMETHOD.

  METHOD delete.
    zday4_um_api=>get_instance(  )->delete(
      EXPORTING
        keys     = keys
      CHANGING
        mapped   = mapped
        failed   = failed
        reported = reported
    ).
  ENDMETHOD.

  METHOD read.
    SELECT * FROM zsprap_student FOR ALL ENTRIES IN @keys WHERE id EQ @keys-id INTO TABLE @DATA(it_stu) .
    result = CORRESPONDING #( it_stu ).
  ENDMETHOD.

  METHOD lock.
    TRY.
        DATA(o_lock) = cl_abap_lock_object_factory=>get_instance( iv_name = 'EZ_STUDENT_LOCK' ).
      CATCH cx_abap_lock_failure INTO DATA(error).
        RAISE SHORTDUMP error.
        "handle exception
    ENDTRY.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      TRY.
          o_lock->enqueue(
            it_parameter  =  VALUE #( ( name = 'ID' value = REF #( <key>-id ) ) )
          ).
        CATCH cx_abap_foreign_lock INTO DATA(foreign_lock).
          "handle exception
          APPEND VALUE #(
          id = keys[ 1 ]-id
          %msg = new_message_with_text(
                  severity = if_abap_behv_message=>severity-error
                  text = 'Record is locked by user' && foreign_lock->user_name
                   )
          ) TO reported-students.
        CATCH cx_abap_lock_failure INTO error.
          RAISE SHORTDUMP error.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.

  METHOD setStatus.
   DATA it_reset TYPE TABLE FOR ACTION IMPORT zday3_r_student_um~resetStatus.
   it_reset = CORRESPONDING #( keys ).
   MODIFY ENTITIES OF zday3_r_student_um IN LOCAL MODE
    ENTITY Students
    EXECUTE resetStatus
    FROM it_reset.
  ENDMETHOD.

  METHOD upload.
  ENDMETHOD.

  METHOD copy.
    DATA students TYPE TABLE FOR CREATE zday3_r_student_um\\Students.

    READ ENTITY IN LOCAL MODE zday3_r_student_um
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_students)
    FAILED DATA(lt_failed)
    REPORTED DATA(lt_reported).

    LOOP AT lt_students ASSIGNING FIELD-SYMBOL(<student>).

      APPEND VALUE #( %cid      = keys[ KEY entity %key = <student>-%key ]-%cid
                     %is_draft = keys[ KEY entity %key = <student>-%key ]-%param-%is_draft
                     %data     = CORRESPONDING #( <student> EXCEPT id )
                  )
      TO students ASSIGNING FIELD-SYMBOL(<new_student>).
      GET TIME STAMP FIELD DATA(tsl).
      <new_student>-Lastchangedat     = tsl.
      <new_student>-locallastchangedat = tsl.
      <new_student>-Createdby = sy-uname.
      <new_student>-Changedby = sy-uname.
      <new_student>-Id = cl_uuid_factory=>create_system_uuid(  )->create_uuid_x16( ).
    ENDLOOP.

    MODIFY ENTITIES OF zday3_r_student_um IN LOCAL MODE
        ENTITY Students
        CREATE FIELDS ( Id Createdby Changedby Course Lastchangedat Location Name Status locallastchangedat )
        WITH students
        MAPPED DATA(mapped_create).


    " set the new BO instances
    mapped-students   =  mapped_create-students .
  ENDMETHOD.

  METHOD copyFromTemplate.
    DATA students TYPE TABLE FOR CREATE zday3_r_student_um\\Students.
    GET TIME STAMP FIELD DATA(tsl).
    students = VALUE #( ( %cid = keys[ 1 ]-%cid
                          %is_draft = keys[ 1 ]-%param-%is_draft

                       %data = VALUE #( Course = 'SAP'
                                      Location = 'India'
                                           id = cl_uuid_factory=>create_system_uuid(  )->create_uuid_x16( )
                                           Lastchangedat = tsl
                                           locallastchangedat = tsl
                                         )
                   ) ).

    MODIFY ENTITIES OF zday3_r_student_um IN LOCAL MODE
         ENTITY Students
         CREATE FIELDS ( Id Createdby Changedby Course Lastchangedat Location Name Status locallastchangedat )
         WITH students
         MAPPED DATA(mapped_create).


    " set the new BO instances
    mapped-students   =  mapped_create-students .

  ENDMETHOD.

  METHOD resetStatus.
    READ ENTITY IN LOCAL MODE zday3_r_student_um
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(students)
    FAILED failed.

    LOOP at students ASSIGNING FIELD-SYMBOL(<student>).
    Clear <student>-Status.
    ENDLOOP.

    MODIFY ENTITY IN LOCAL MODE zday3_r_student_um
    UPDATE FIELDS ( Status )
    WITH VALUE #( FOR student IN students (
                    %tky = student-%tky
                    status = student-Status
                   ) ).
  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZDAY3_R_STUDENT_UM DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZDAY3_R_STUDENT_UM IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
    zday4_um_api=>get_instance(  )->save(
      CHANGING
        reported = reported
    ).
  ENDMETHOD.

  METHOD cleanup.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
