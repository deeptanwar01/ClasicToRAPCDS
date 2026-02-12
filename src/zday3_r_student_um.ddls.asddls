@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '.'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZDAY3_R_STUDENT_UM as select from zsprap_student
{
    key id as Id,
    name as Name,
    location as Location,
    course as Course,
    status as Status,
   
    lastchangedat as Lastchangedat,
   
    locallastchangedat as Locallastchangedat,
  
    createdby as Createdby,

    changedby as Changedby
}
