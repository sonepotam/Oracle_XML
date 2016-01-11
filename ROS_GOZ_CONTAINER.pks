CREATE OR REPLACE PACKAGE IBS.ros_goz_container as

/*

*
*
*


---
--- так можно тестировать и вызывать блоки
---
declare
   str varChar2( 32000);
begin
  for rec in  ros_goz_container.block2(6985239725) loop
      dbms_output.put_line( rec.xml);
  end loop;
end;

*/


-- block 1
cursor block1( p_Container number) is
select
xmlSerialize( content
  XMLElement( "MetaInf",
     XMLAttributes(
       rgo.ID "ReqUID",
       to_char( rgo.c_ReqCreateDate, 'yyyy-mm-dd') || 'T' ||
          to_char( rgo.c_ReqCreateDate, 'hh24:mi:ss') ||
          sessiontimezone "ReqCreateDate",
       to_char( rgo.c_ReqExportDate, 'yyyy-mm-dd') || 'T' ||
          to_char( rgo.c_ReqExportDate, 'hh24:mi:ss') ||
          sessiontimezone "ReqExportDate",
       RGO.C_GOZUID "GOZUID",
       to_char( rgo.c_PeriodStart, 'yyyy-mm-dd') || 'T' ||
          to_char( rgo.c_PeriodStart, 'hh24:mi:ss') ||
          sessiontimezone "PeriodStart",
       to_char( rgo.c_PeriodEnd, 'yyyy-mm-dd') || 'T' ||
          to_char( rgo.c_PeriodEnd, 'hh24:mi:ss') ||
          sessiontimezone "PeriodEnd"),
     XMLElement( "Bank",
        XMLAttributes(
          rgo.c_Bank#BankName "BankName",
          rgo.c_Bank#BankBIC  "BankBIC",
          rgo.c_Bank#BankINN  "BankINN",
          rgo.c_Bank#BankKPP  "BankKPP",
          rgo.c_Bank#BankAccount "BankAccount"
     ))
  )
  as clob)
 xml
from z#ros_goz_contain rgo
where rgo.id = p_Container;





--- BLOCK 2
cursor block2( p_FileLink_Arr number) is
select
xmlSerialize( content
  XMLElement( "FileLinks",
     XMLAttributes( RGF.c_file_ID "Id", decode( ps.id, null, '', 'scan_' || rgf.c_file_id || substr( rgf.c_name, inStr( rgf.c_name, '.', -1))) "Name", RGF.C_FILE_SIZE "Size", RGF.C_CRC "CRC",  RGF.C_DOCTYPE "DocType", RGF.C_COMMENT "Comment"),
     XMLElement( "Owner",
        XMLAttributes( RGF.C_OWNER#CLIENT_ID "ID", RGF.C_OWNER#INN "INN", RGF.C_OWNER#KPP "KPP", RGF.C_OWNER#OGRN "OGRN"  )
        )
)
as clob) XML
from z#ros_goz_filelink rgf, z#dossier_doc dd, z#patt_signs ps
where rgf.collection_id= p_FileLink_Arr
  and DD.ID (+)=RGF.C_FILE_IMAGE_REF
  and PS.COLLECTION_ID  (+)= DD.C_DATA;


--- BLOCK 3
cursor block3( p_Contract_Arr number) is
select
xmlSerialize( content
  XMLElement( "Contracts",
     XMLAttributes( rgc.c_contractUID "ContractUID",
                    to_char( RGC.C_REGDATE, 'yyyy-mm-dd') "RegDate",
                    to_char( RGC.c_lastupdated, 'yyyy-mm-dd') "LastUpdated",
                    RGC.C_COST "Cost",
                    RGC.C_PREPAYMENT "Prepayment",
                    RGC.C_PROFIT "Profit",
                    RGC.C_PREVLOSS "PrevLoss",
                    RGC.C_NUM "Num",
                    to_char( RGC.C_CONTR_DATE, 'yyyy-mm-dd') "Date"
     ),
     XMLElement( "Contractor",
        XMLAttributes( RGC.C_CONTRACTOR#CLIENT_ID "ID", RGC.C_CONTRACTOR#INN "INN", RGC.C_CONTRACTOR#KPP "KPP", RGC.C_CONTRACTOR#OGRN "OGRN"  )
        ),
     XMLElement( "ContractorCorr",
        XMLAttributes( RGC.C_CONTRACTORcorr#CLIENT_ID "ID", RGC.C_CONTRACTORcorr#INN "INN", RGC.C_CONTRACTORcorr#KPP "KPP", RGC.C_CONTRACTORcorr#OGRN "OGRN"  )
        ),
     ( select XMLAgg(
                 XMLElement( "FileAttach", XMLAttributes( rgfr.c_File_ID "Id"))
              )
              from z#ros_goz_file_ref rgfr
              where RGFR.COLLECTION_ID = RGC.C_FILEATTACH_ARR
     ),
     ( select XMLAgg(
                   XMLElement( "GOZUID", rgg.c_gozuid)
                )
          from z#ros_goz_gozuid rgg
          where rgg.collection_id =rgc.c_gozUID
     )
)
as clob) XML
from z#ros_goz_contract rgc
where rgc.collection_id= p_Contract_Arr;


---
--- курсор возвращает блок 4 контейнера(Владельцы)
-- в качестве параметра нужно передать [ROS_GOZ_CONTAIN].[CONTRACTOR_ARR]
---
cursor block4( p_Contractor_Arr number) is
-- block2
select
xmlSerialize( content
  XMLElement( "Contractors",
         XMLAttributes(
         rgo.c_client_id as "ID",
         rgo.c_fullname  as "FullName",
         rgo.c_shortname as "ShortName",
         rgo.c_opf       as "OPF",
         rgo.c_opfname   as "OPFName",
         rgo.c_inn       as "INN",
         rgo.c_kpp       as "KPP",
         rgo.c_ogrn      as "OGRN",
         to_char( rgo.c_regDate, 'yyyy-mm-dd') as "RegDate",
         rgo.c_capital   as "Capital",
         rgo.c_oktmo     as "OKTMO",
         rgo.c_okato     as "OKATO"),
            -- addr begin
            (select
               XMLAgg(
                  XMLElement( "Addr",
                     XMLAttributes(
                        ADDR.C_ADDR_TYPE "Type",
                        ADDR.C_ADDRESSLINE "AddressLine",
                        ADDR.C_REGION "Region",
                        ADDR.C_OKRUG "Okrug",
                        ADDR.C_DISTRICT "District",
                        ADDR.C_CITY "City",
                        ADDR.C_CITYDISTRICT "CityDistrict",
                        ADDR.C_SETTLEMENT "Settlement",
                        ADDR.C_TERRITORY "Territory",
                        ADDR.C_HOUSE "House",
                        ADDR.C_BUILDING "Building",
                        ADDR.C_FLAT "Flat",
                        ADDR.C_POST_INDEX "Index"
                                  )
                             )
                     )
               from z#ros_goz_addr addr
               where addr.collection_id = RGO.C_ADDR_ARR
            ),
         -- assignee begin
            (
                 select
                   XMLAgg(
                     XMLElement( "Assignee",
                       XMLAttributes(
                          rga.c_Position    as "Position",
                          rga.c_NameSurname as "NameSurname",
                          rga.c_NameName    as "NameName",
                          rga.c_NamePatron  as "NamePatron",
                          rga.c_INN         as "INN" ),
                          -- dul
                          (select
                               XMLAgg(
                                  XMLElement( "DUL",
                                     XMLAttributes(
                                        rgd.c_doc_type "Type",
                                        rgd.c_comment "Comment",
                                        RGD.C_SERIESNUMBER "SeriesNumber",
                                        RGD.C_ISSUEORGAN "IssueOrganization",
                                        rgd.c_IssueDC "IssueDC",
                                        RGD.C_ISSUEDATE "IssueDate"
                                     )
                                  ) -- xmlelement
                               ) -- xmlagg
                           from z#ros_goz_dul rgd
                           where rgd.collection_id = RGA.C_DUL_ARR
                           )
--
                   )
                   )
                 from z#ros_goz_assignee rga
                 where rga.collection_id = RGO.C_ASSIGNEE_ARR
            ), -- assignee end
            -- addr end
            -- contact begin
            ( select
                XMLAgg(
                   XMLElement( "Contact",
                      XMLAttributes( rgc.C_cont_type "Type", RGC.C_CONT_VAL "Val")
                             )
                      )
              from z#ros_goz_contact rgc
              where rgc.collection_id=RGO.C_CONTACT_ARR
            ), -- contact end
            -- license begin
(select
 XMLAgg(
   XMLElement( "License",
      XMLAttributes( lic.c_num "Num", to_char( lic.c_lic_date, 'yyyy-mm-dd') "Date"),
      -- begin ativity
      (
        select XMLAgg(
             XMLElement( "Activity",
                XMLAttributes( ACT.C_NAME "Name", ACT.C_CODE "Code")
          )
          )
          from z#ros_goz_activity act
          where ACT.COLLECTION_ID = lic.c_activity_arr
      )
      --end activity
      )
 )
 from
z#ros_goz_license lic
where collection_id=RGO.C_LICENSE_ARR
)
            -- license end
  )
as clob)   xml
from z#ros_goz_owner rgo
where rgo.collection_id = p_Contractor_Arr;



---
--- курсор возвращает блок 4 контейнера(Владельцы)
-- в качестве параметра нужно передать [ROS_GOZ_CONTAIN].[CONTRACTOR_ARR]
---
cursor block4Test( p_Contractor_Arr number) is
-- block2
select
xmlSerialize( content
  XMLElement( "Contractors",
         XMLAttributes(
         rgo.c_client_id as "ID",
         rgo.c_fullname  as "FullName",
         rgo.c_shortname as "ShortName",
         rgo.c_opf       as "OPF",
         rgo.c_opfname   as "OPFName",
         rgo.c_inn       as "INN",
         rgo.c_kpp       as "KPP",
         rgo.c_ogrn      as "OGRN",
         to_char( rgo.c_regDate, 'yyyy-mm-dd') as "RegDate",
         rgo.c_capital   as "Capital",
         rgo.c_oktmo     as "OKTMO",
         rgo.c_okato     as "OKATO"),
            -- addr begin
            (select
               XMLAgg(
                  XMLElement( "Addr",
                     XMLAttributes(
                        ADDR.C_ADDR_TYPE "Type",
                        ADDR.C_ADDRESSLINE "AddressLine",
                        ADDR.C_REGION "Region",
                        ADDR.C_OKRUG "Okrug",
                        ADDR.C_DISTRICT "District",
                        ADDR.C_CITY "City",
                        ADDR.C_CITYDISTRICT "CityDistrict",
                        ADDR.C_SETTLEMENT "Settlement",
                        ADDR.C_TERRITORY "Territory",
                        ADDR.C_HOUSE "House",
                        ADDR.C_BUILDING "Building",
                        ADDR.C_FLAT "Flat",
                        ADDR.C_POST_INDEX "Index"
                                  )
                             )
                     )
               from z#ros_goz_addr addr
               where addr.collection_id = RGO.C_ADDR_ARR
            ),
         -- assignee begin
            (
                 select
                   XMLAgg(
                     XMLElement( "Assignee",
                       XMLAttributes(
                          rga.c_Position    as "Position",
                          rga.c_NameSurname as "NameSurname",
                          rga.c_NameName    as "NameName",
                          rga.c_NamePatron  as "NamePatron",
                          rga.c_INN         as "INN" ),
                          -- dul
                          (select
                               XMLAgg(
                                  XMLElement( "DUL",
                                     XMLAttributes(
                                        rgd.c_doc_type "Type",
                                        rgd.c_comment "Comment",
                                        RGD.C_SERIESNUMBER "SeriesNumber",
                                        RGD.C_ISSUEORGAN "IssueOrganization",
                                        rgd.c_IssueDC "IssueDC",
                                        RGD.C_ISSUEDATE "IssueDate"
                                     )
                                  ) -- xmlelement
                               ) -- xmlagg
                           from z#ros_goz_dul rgd
                           where rgd.collection_id = RGA.C_DUL_ARR
                           )
--
                   )
                   )
                 from z#ros_goz_assignee rga
                 where rga.collection_id = RGO.C_ASSIGNEE_ARR
            ), -- assignee end
            -- addr end
            -- contact begin
            ( select
                XMLAgg(
                   XMLElement( "Contact",
                      XMLAttributes( rgc.C_cont_type "Type", RGC.C_CONT_VAL "Val")
                             )
                      )
              from z#ros_goz_contact rgc
              where rgc.collection_id=RGO.C_CONTACT_ARR
            ), -- contact end
            -- license begin
(select
 XMLAgg(
   XMLElement( "License",
      XMLAttributes( lic.c_num "Num", to_char( lic.c_lic_date, 'yyyy-mm-dd') "Date"),
      -- begin ativity
      (
        select XMLAgg(
             XMLElement( "Activity",
                XMLAttributes( ACT.C_NAME "Name", ACT.C_CODE "Code")
          )
          )
          from z#ros_goz_activity act
          where ACT.COLLECTION_ID = lic.c_activity_arr
      )
      --end activity
      )
 )
 from
z#ros_goz_license lic
where collection_id=RGO.C_LICENSE_ARR
)
            -- license end
  )
  as clob)
xml
from z#ros_goz_owner rgo
where rgo.collection_id = p_Contractor_Arr;




-- block 5
cursor block5( p_Acc_Arr number) is
select
xmlSerialize( content
  XMLElement( "Accs",
     XMLAttributes(
       rga.c_ACC_ID "ID",
       rga.c_BIK "BIK", rga.c_BankAccount "BankAccount", rga.c_Num "Num",
       to_char( rga.c_CreateDate, 'yyyy-mm-dd') "CreateDate",
       to_char( rga.c_CloseDate, 'yyyy-mm-dd') "CloseDate",
       rga.c_GOZUID "GOZUID", rga.c_initSum "InitSum", rga.c_FinalSum "FinalSum",
       rga.c_bankBranch "BankBranch", rga.c_BankBranchID "BankBranchID"
                  ),
       XMLElement( "Owner",
        XMLAttributes( RGa.C_Owner#CLIENT_ID "ID", RGa.C_Owner#INN "INN", RGa.C_Owner#KPP "KPP", RGa.C_Owner#OGRN "OGRN")
          )
)
as clob) XML
from z#ros_goz_account rga
where collection_id = p_Acc_Arr;


--block6
cursor block6( p_AccRep_Arr number) is
select
xmlSerialize( content
  XMLElement( "AccReps",
     XMLAttributes(
        RGAP.C_ACCREPUID "AccRepUID", RGAP.C_CONTRACT#GOZUID "GOZUID",
        RGAP.C_NUM "Num", rgap.c_act_date "Date", rgap.c_cost "Cost"),
     XMLElement( "Contractor",
        XMLAttributes( rgap.C_CONTRACTOR#CLIENT_ID "ID", rgap.C_CONTRACTOR#INN "INN", rgap.C_CONTRACTOR#KPP "KPP", rgap.C_CONTRACTOR#OGRN "OGRN"  )
        ),
     XMLElement( "ContractorCorr",
        XMLAttributes( rgap.C_CONTRACTORcorr#CLIENT_ID "ID", rgap.C_CONTRACTORcorr#INN "INN", rgap.C_CONTRACTORcorr#KPP "KPP", rgap.C_CONTRACTORcorr#OGRN "OGRN"  )
        ),
     XMLElement( "Contract",
        XMLAttributes( RGAP.C_CONTRACT#CONTRACTUID "ContractUID", RGAP.C_CONTRACT#GOZUID "GOZUID" )
        ),
     ( select XMLAgg(
                 XMLElement( "FileAttach", XMLAttributes( rgfr.c_File_ID "Id"))
              )
              from z#ros_goz_file_ref rgfr
              where RGFR.COLLECTION_ID = rgap.C_FILEATTACH_ARR
     )
)
as clob) XML
from z#ros_goz_AccRep rgap
where collection_id = p_AccRep_Arr;


-- block7
cursor block7( p_AccCreateOp_Arr number) is
select
xmlSerialize( content
  XMLElement( "AccCreateOps",
     XMLAttributes( RGOP.C_OPUID "OpUID", RGOP.C_CORRECTEDOPUID "CorrectedOpUID"),
     XMLElement( "Acc",
        XMLAttributes( RGOP.C_ACC#ACC_ID "ID",
                       rgop.c_Acc#BIK "BIK", rgop.c_Acc#Num "Num")
        ),
     ( select XMLAgg(
                 XMLElement( "FileAttach", XMLAttributes( rgfr.c_File_ID "Id"))
              )
              from z#ros_goz_file_ref rgfr
              where RGFR.COLLECTION_ID = rgop.C_FILEATTACH_ARR
     )
)
as clob) XML
from z#ros_goz_acccr_op rgop
where collection_id = p_AccCreateOp_Arr;


-- block8
cursor block8( p_AccEditOp_Arr number) is
select
xmlSerialize( content
  XMLElement( "AccEditOps",
     XMLAttributes( RGED.C_OPUID "OpUID", RGED.C_CORRECTEDOPUID "CorrectedOpUID", RGED.C_CHANGE_DATE "Date"),            
     XMLElement( "Acc",
        XMLAttributes(
        RGED.C_ACC#ACC_ID "ID",
        rged.c_Acc#BIK "BIK", rged.c_Acc#Num "Num")
        ),
     decode(rged.c_AccPrev#Num, null, null,
     XMLElement( "AccPrev",
        XMLAttributes( RGED.C_ACCPREV#ACC_ID "ID", rged.c_AccPrev#BIK "BIK", rged.c_AccPrev#Num "Num")
        )),
     ( select XMLAgg(
                 XMLElement( "FileAttach", XMLAttributes( rgfr.c_File_ID "Id"))
              )
              from z#ros_goz_file_ref rgfr
              where RGFR.COLLECTION_ID = rged.C_FILEATTACH_ARR
  )
)
as clob) XML
from z#ros_goz_acced_op rged
where collection_id = p_AccEditOp_Arr ;


-- block9
cursor block9( p_DebitOpToSpecialAcc_Arr number) is
select
xmlSerialize( content
     XMLElement( "DebitOpsToSpecialAcc",
        XMLAttributes(
           RGDEBIT.C_OPUID "OpUID", rgdebit.c_correctedopuid "CorrectedOpUID",
           decode( RGDEBIT.c_correctiondate, null, null,
             to_char( RGDEBIT.c_correctiondate, 'yyyy-mm-dd') || 'T' ||
             to_char( RGDEBIT.c_correctiondate, 'hh24:mi:ss') ||
             sessiontimezone) "CorrectionDate",
           to_char( RGDEBIT.C_DOCDATE, 'yyyy-mm-dd') "DocDate", RGDEBIT.C_DOCNUM "DocNum",
             to_char( RGDEBIT.C_ACCEPTDATE, 'yyyy-mm-dd') ||  'T' ||
             to_char( RGDEBIT.C_ACCEPTDATE, 'hh24:mi:ss') ||
             sessiontimezone  "AcceptDate",
           RGDEBIT.C_PURP "Purp", RGDEBIT.C_SUM_DEBET "Sum",
           RGDEBIT.C_GOZUID "GOZUID"
           ),
     XMLElement( "AccFrom",
        XMLAttributes( RGDEBIT.C_ACCFROM#ACC_ID "ID",
             rgdebit.c_AccFrom#BIK "BIK", rgdebit.c_AccFrom#Num "Num")
        ),
     XMLElement( "AccTo",
        XMLAttributes( RGDEBIT.C_ACCTO#ACC_ID "ID",
           rgdebit.c_AccTo#BIK "BIK", rgdebit.c_AccTo#Num "Num")
        ),
     ( select XMLAgg(
           XMLElement( "Contract",
             XMLAttributes( rgcf.c_CONTRACTUID "ContractUID", rgcf.c_GOZUID "GOZUID" )
            ))
       from z#ros_goz_cont_ref rgcf
       where rgcf.collection_id = rgdebit.c_contract_arr
     ),
          ( select XMLAgg( XMLElement( "AccRep", XMLAttributes( rgap.c_AccRepUID "AccRepUID"))  )
       from z#ros_goz_acrepref rgap
       where rgap.COLLECTION_ID = RGDEBIT.C_ACCREP_ARR
     ) ,
          ( select XMLAgg( XMLElement( "FileAttach", XMLAttributes( rgfr.c_File_ID "Id"))  )
       from z#ros_goz_file_ref rgfr
       where RGFR.COLLECTION_ID = rgdebit.C_FILEATTACH_ARR
))
as clob) XML
from z#ros_goz_debitopt rgdebit
where collection_id = p_DebitOpToSpecialAcc_Arr;

-- block10
cursor block10( p_CreditOp_Arr number) is
select
xmlSerialize( content
     XMLElement( "CreditOps",
        XMLAttributes(
           rgcred.C_OPUID "OpUID", rgcred.c_correctedopuid "CorrectedOpUID",
           decode( rgcred.c_correctiondate, null, null,
             to_char( rgcred.c_correctiondate, 'yyyy-mm-dd') || 'T' ||
             to_char( rgcred.c_correctiondate, 'hh24:mi:ss') ||
             sessiontimezone) "CorrectionDate",
           RGCRED.C_OPTYPE "OpType",
           to_char( rgcred.C_DOCDATE, 'yyyy-mm-dd') "DocDate", rgcred.C_DOCNUM "DocNum",
           rgcred.C_PURP "Purp", rgcred.C_OP_SUM "Sum",
           RGCRED.C_PAYERNAME    "PayerName",
           RGCRED.C_PAYERINN     "PayerINN",
           RGCRED.C_PAYERKPP     "PayerKPP",
           RGCRED.C_AccFrom      "AccFrom",
           RGCRED.c_BankFromBIK  "BankFromBIK",
           RGCRED.c_BankFromName "BankFromName",
           RGCRED.c_BankFromAcc  "BankFromAcc"),
        XMLElement( "AccTo", XMLAttributes(
           RGCRED.C_ACCTO#ACC_ID "ID",
           rgcred.c_AccTo#BIK "BIK", rgcred.c_AccTo#Num "Num"
        ) )
)
as clob) XML
from z#ros_goz_creditop rgcred
where collection_id = p_CreditOp_Arr;



-- block11
cursor block11( p_DebitOp_Arr number) is
select
xmlSerialize( content
     XMLElement( "DebitOps",
        XMLAttributes(
           rgdeb.C_OPUID "OpUID", rgdeb.c_correctedopuid "CorrectedOpUID",
           decode( rgdeb.c_correctiondate, null, null,
             to_char( rgdeb.c_correctiondate, 'yyyy-mm-dd') || 'T' ||
             to_char( rgdeb.c_correctiondate, 'hh24:mi:ss') ||
             sessiontimezone) "CorrectionDate",
           rgdeb.C_OPTYPE "OpType",
           to_char( rgdeb.C_DOCDATE, 'yyyy-mm-dd') "DocDate", rgdeb.C_DOCNUM "DocNum",
           to_char( rgdeb.c_acceptdate, 'yyyy-mm-dd') || 'T' ||
              to_char( rgdeb.c_acceptdate, 'hh24:mi:ss') ||
              sessiontimezone "AcceptDate",
           rgdeb.C_PURP "Purp", rgdeb.C_OP_SUM "Sum",
           rgdeb.C_CorrNAME    "CorrName",
           rgdeb.C_CorrINN     "CorrINN",
           rgdeb.C_CorrKPP     "CorrKPP",
           rgdeb.C_AccTo      "AccTo",
           rgdeb.c_BankToBIK  "BankToBIK",
           rgdeb.c_BankToName "BankToName",
           rgdeb.c_BankToAcc  "BankToAcc",
           rgdeb.c_TaxStat    "TaxStat",
           RGDEB.C_TAXKBK     "TaxKBK",
           RGDEB.C_TaxOKTMO   "TaxOKTMO",
           RGDEB.C_TAXCause   "TaxCause",
           RGDEB.C_TAXPERIOD    "TaxPeriod",
           RGDEB.C_TAXCAUSEDATE "TaxCauseDate",
           RGDEB.C_TAXCAUSENUM  "TaxCauseNum",
           rgdeb.c_comment      "comment"   ),
        XMLElement( "AccFrom", XMLAttributes(
             RGDEB.C_ACCFROM#ACC_ID "ID",
             rgdeb.c_AccFrom#BIK "BIK", rgdeb.c_AccFrom#Num "Num") ),
        (
          select XMLAgg( XMLElement( "SalaryTaxUID", mdr.c_value))
               from z#main_docum_ref mdr
               where mdr.collection_id =RGDEB.C_SALARYTAXUID
        ),
          ( select XMLAgg( XMLElement( "FileAttach", XMLAttributes( rgfr.c_File_ID "Id"))  )
       from z#ros_goz_file_ref rgfr
       where RGFR.COLLECTION_ID = rgdeb.C_FILEATTACH_ARR
))
as clob) XML
from z#ros_goz_debitop rgdeb
where collection_id = p_DebitOp_Arr;


cursor controlFileContainers( p_Containers_Arr number) is
select
xmlSerialize( content
XMLElement( "Containers",
          XMLAttributes( rgcr.c_ReqUID "ReqUID",
                         nvl( RGCr.C_FILE_NAME, '-') "name",
                         nvl( RGCr.C_FILE_SIZE, '-1') "size",
                         nvl( RGCr.C_CRC, '-1')       "CRC"
          ))
as clob)           xml
from z#ros_goz_contanrs rgcr
where rgcr.collection_id = p_Containers_Arr;


cursor controlFileNoData( p_ControlFileID number) is
select
xmlSerialize( content
XMLElement( "NoData",
       XMLAttributes(
          to_char( c_noData#periodStart, 'yyyy-mm-dd') || 'T' ||
          to_char( c_noData#periodStart, 'hh24:mi:ss') ||
          sessionTimeZone "PeriodStart",
          to_char( c_noData#periodEnd, 'yyyy-mm-dd') || 'T' ||
          to_char( c_noData#periodEnd, 'hh24:mi:ss') ||
          sessionTimeZone "PeriodEnd"
          ),
         ( select XMLAgg( XMLElement( "GOZUID", rgc.C_GOZuid) )
               FROM Z#ROS_GOZ_CONTAIN RGC, z#ros_goz_contanrs RGS
               WHERE RGC.ID = RGS.C_REQUID
                 AND RGS.COLLECTION_ID = RGCF.C_NODATA#GOZUID
         )
       )
as clob)        xml
  from z#ros_goz_cont_fil rgcf
where rgcf.id = p_ControlFileID;



end;
/