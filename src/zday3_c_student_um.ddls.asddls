@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '.'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity ZDAY3_C_STUDENT_UM 
provider contract transactional_query
as projection on ZDAY3_R_STUDENT_UM
{
    key Id,
    Name,
    Location,
    Course,
    Status,
    Lastchangedat,
    Locallastchangedat,
    Createdby,
    Changedby
}
