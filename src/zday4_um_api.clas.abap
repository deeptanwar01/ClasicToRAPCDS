CLASS zday4_um_api DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    TYPES : tt_entities        TYPE TABLE FOR CREATE zday3_r_student_um\\students,
            tt_mapped          TYPE RESPONSE FOR MAPPED EARLY zday3_r_student_um,
            tt_failed          TYPE RESPONSE FOR FAILED EARLY zday3_r_student_um,
            tt_reported        TYPE RESPONSE FOR REPORTED EARLY zday3_r_student_um,
            tt_reported_save   TYPE RESPONSE FOR REPORTED LATE zday3_r_student_um,
            tt_entities_update TYPE TABLE FOR UPDATE zday3_r_student_um\\students,
            tt_keys_delete     TYPE TABLE FOR DELETE zday3_r_student_um\\students.

    CLASS-METHODS get_instance RETURNING VALUE(ro_instance) TYPE REF TO zday4_um_api.
    METHODS earlynumbering_create
      IMPORTING entities TYPE tt_entities
      CHANGING  mapped   TYPE tt_mapped
                failed   TYPE tt_failed
                reported TYPE tt_reported.

    METHODS create
      IMPORTING entities TYPE tt_entities
      CHANGING  mapped   TYPE tt_mapped
                failed   TYPE tt_failed
                reported TYPE tt_reported.
    METHODS : update_student
      IMPORTING entities TYPE tt_entities_update
      CHANGING  mapped   TYPE tt_mapped
                failed   TYPE tt_failed
                reported TYPE tt_reported.
    METHODS delete
      IMPORTING keys     TYPE tt_keys_delete
      CHANGING  mapped   TYPE tt_mapped
                failed   TYPE tt_failed
                reported TYPE tt_reported.
    METHODS save
      CHANGING reported TYPE   tt_reported_save.
  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-DATA mo_instance TYPE REF TO zday4_um_api.
    CLASS-DATA it_students TYPE STANDARD TABLE OF zsprap_student.
    CLASS-DATA gt_students_del TYPE STANDARD TABLE OF zsprap_student.
ENDCLASS.



CLASS zday4_um_api IMPLEMENTATION.
  METHOD get_instance.
    mo_instance = ro_instance = COND #( WHEN mo_instance IS BOUND
                                        THEN mo_instance
                                        ELSE NEW #(  ) ).
  ENDMETHOD.

  METHOD earlynumbering_create.
    DATA(newID) = cl_uuid_factory=>create_system_uuid(  )->create_uuid_x16( ).
    IF entities IS NOT INITIAL.
      mapped-students = VALUE #(
*                              for entity in entities where ( id is initial )
                                  ( %cid = entities[ 1 ]-%cid
                                  %is_draft = entities[ 1 ]-%is_draft
                                  Id = newID ) ).

    ENDIF.
  ENDMETHOD.

  METHOD create.
    it_students = CORRESPONDING #( entities ).
    IF it_students IS NOT INITIAL.
      GET TIME STAMP FIELD DATA(tsl).
      it_students[ 1 ]-lastchangedat = tsl.
      it_students[ 1 ]-locallastchangedat = tsl.
      it_students[ 1 ]-createdby = sy-uname.
      it_students[ 1 ]-changedby = sy-uname.
    ENDIF.
  ENDMETHOD.

  METHOD save.
    IF it_students IS NOT INITIAL.
      MODIFY zsprap_student FROM TABLE @it_students.
      reported-students = VALUE #( ( Id = it_students[ 1 ]-id ) ).
    ENDIF.
    IF gt_students_del IS NOT INITIAL.
      DELETE zsprap_student FROM TABLE @it_students.
      reported-students = VALUE #( ( Id = it_students[ 1 ]-id ) ).
    ENDIF.
  ENDMETHOD.

  METHOD update_student.
    it_students = CORRESPONDING #( entities ).
    IF it_students IS NOT INITIAL.
      GET TIME STAMP FIELD DATA(tsl).
      it_students[ 1 ]-lastchangedat = tsl.
      it_students[ 1 ]-locallastchangedat = tsl.
    ENDIF.
  ENDMETHOD.

  METHOD delete.
    SELECT * FROM zsprap_student  FOR ALL ENTRIES IN @keys WHERE id = @keys-Id INTO TABLE @gt_students_del.
  ENDMETHOD.

ENDCLASS.
