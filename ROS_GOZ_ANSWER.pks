CREATE OR REPLACE PACKAGE IBS.ros_goz_answer as


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
  for rec in  ros_goz_answer.MessageHeader(6987183461) loop
      dbms_output.put_line( rec.xml);
  end loop;
end;

*/

cursor MessageHeader( p_Answer number) is
select Mess.PacketUID, Mess.ResultCode
      from z#ros_goz_mo_answ rgmo
,     xmlTable(
           '.'
           passing extract( xmlType( convert( rgmo.c_data, 'CL8MSWIN1251', 'UTF8')) , '//ns4:Message', 'xmlns:ns4="http://smb.mil.ru/integration/reply')
         columns
            packetUID  varChar2( 250) path 'PacketUID',
            resultCode varChar2( 25)  path 'ResultCode'
         ) Mess
 where rgmo.id = p_Answer;


cursor SessionWarnings( p_Answer number) is
select warnings.*
      from z#ros_goz_mo_answ rgmo
,     xmlTable(
           '.'
           passing extract( xmlType( convert( rgmo.c_data, 'CL8MSWIN1251', 'UTF8')) , '//ns4:Message/Warnings', 'xmlns:ns4="http://smb.mil.ru/integration/reply')
         columns
            warnings   xmlType        path 'Warnings'
         ) mess
, xmlTable(
   'Warnings'
   passing mess.Warnings
              columns
                errLevel varChar2( 25) path '/Warnings/@ErrorWarningLevel',
                errCode varChar2( 25) path '/Warnings/@ErrorWarningCode',
                errText varChar2( 255) path '/Warnings/@ErrorWarningText'
   ) warnings
 where rgmo.id = p_Answer;


cursor ClosedContracts( p_Answer number) is
 select closed.gozuid, closed.finishDate from z#ros_goz_mo_answ rgmo,
     xmlTable(
           '.'
           passing extract( xmlType( convert( rgmo.c_data_closed, 'CL8MSWIN1251', 'UTF8')) , 
           '//ns8:Message/FinishedGOZ', 
           'xmlns:ns8="http://smb.mil.ru/integration/gozfin"')
         columns
            finishedGOZ   xmlType        path 'FinishedGOZ'
         ) finished,
     xmlTable(
       'FinishedGOZ'
       passing finished.finishedGOZ
       columns 
          gozuid     varchar2(25) path '/FinishedGOZ/@GOZUID',
          finishDate varchar2(20) path '/FinishedGOZ/@FinishDate'
     ) closed            
where rgmo.id = p_Answer;



-- отсутсвующие контракты
cursor MissingContracts( p_Answer number) is
select contracts.contractID
      from z#ros_goz_mo_answ rgmo
,     xmlTable(
           '.'
           passing extract( xmlType( convert( rgmo.c_data, 'CL8MSWIN1251', 'UTF8')) , '//ns4:Message/MissingContracts', 'xmlns:ns4="http://smb.mil.ru/integration/reply')
         columns
            mContracts   xmlType        path 'MissingContracts'
         ) mContracts
, xmlTable(
   'MissingContracts'
   passing mContracts.mContracts
              columns
                ContractID varChar2( 25) path 'text()'
   ) contracts
 where rgmo.id = p_Answer;


-- контейнеры
cursor Containers( p_Answer number) is
select Containers.reqUID, Containers.resultCode, Containers.AcceptTime
      from z#ros_goz_mo_answ rgmo
,     xmlTable(
           '/Containers'
           passing extract( xmlType( convert( rgmo.c_data, 'CL8MSWIN1251', 'UTF8')) , '//ns4:Message/Containers', 'xmlns:ns4="http://smb.mil.ru/integration/reply')
         columns
            reqUID     varChar2( 250) path 'ReqUID',
            resultCode varChar2( 25)  path 'ResultCode',
            AcceptTime varChar2( 100) path 'AcceptTime'
         ) Containers
where rgmo.id = p_Answer;


-- список замечаний для контейнера
cursor ContainerWarnings( p_Answer number, p_ContainerID varChar2) is
select Containers.reqUID,
       W.errLevel, W.errCode, W.errText
      from z#ros_goz_mo_answ rgmo
,     xmlTable(
           '/Containers'
           passing extract( xmlType( convert( rgmo.c_data, 'CL8MSWIN1251', 'UTF8')) , '//ns4:Message/Containers', 'xmlns:ns4="http://smb.mil.ru/integration/reply')
         columns
            reqUID     varChar2( 250) path 'ReqUID',
            resultCode varChar2( 25)  path 'ResultCode',
            AcceptTime varChar2( 100) path 'AcceptTime',
            Warnings   xmlType        path 'Warnings'
         ) Containers
   , xmlTable( 'Warnings'
              passing Containers.Warnings
              columns
                errLevel varChar2( 25) path '/Warnings/@ErrorWarningLevel',
                errCode varChar2( 25) path '/Warnings/@ErrorWarningCode',
                errText varChar2( 250) path '/Warnings/@ErrorWarningText'
      )  w
 where rgmo.id = p_Answer
 and Containers.reqUID = p_ContainerID;


-- список элементов для контейнера
cursor ContainerElements( p_Answer number, p_ContainerID varChar2) is
select distinct elements.elementType, elements.elementID, elements.resultCode
from z#ros_goz_mo_answ rgmo
,     xmlTable(
           '/Containers'
           passing extract( xmlType( convert( rgmo.c_data, 'CL8MSWIN1251', 'UTF8')) , '//ns4:Message/Containers', 'xmlns:ns4="http://smb.mil.ru/integration/reply')
         columns
            reqUID     varChar2( 250) path 'ReqUID',
            resultCode varChar2( 25)  path 'ResultCode',
            AcceptTime varChar2( 100) path 'AcceptTime',
            Elements   xmlType        path 'Elements'
         ) Containers
   , xmlTable( 'Elements'
              passing Containers.Elements
              columns
                elementType varChar2( 25) path '/Elements/@ElementType',
                elementID   varChar2( 25) path 'ElementId',
                resultCode  varChar2( 25) path 'ResultCode',
                errors         xmlType       path 'Errors'
      )  elements
where rgmo.id = p_Answer
 and Containers.reqUID = p_ContainerID;


-- список ошибок ошибок для элемента
cursor ContainerElementsErrors( p_Answer number, p_ContainerID varChar2, p_ElementID varChar2) is
   select errList.errLevel, errList.errCode, errList.errText
      from z#ros_goz_mo_answ rgmo
,     xmlTable(
           '/Containers'
           passing extract( xmlType( convert( rgmo.c_data, 'CL8MSWIN1251', 'UTF8')) , '//ns4:Message/Containers', 'xmlns:ns4="http://smb.mil.ru/integration/reply')
         columns
            reqUID     varChar2( 250) path 'ReqUID',
            resultCode varChar2( 25)  path 'ResultCode',
            AcceptTime varChar2( 100) path 'AcceptTime',
            Elements   xmlType        path 'Elements'
         ) Containers
   , xmlTable( 'Elements'
              passing Containers.Elements
              columns
                elementType varChar2( 25) path '/Elements/@ElementType',
                elementID   varChar2( 25) path 'ElementId',
                resultCode  varChar2( 25) path 'ResultCode',
                errors         xmlType       path 'Errors'
      )  elements
   , xmlTable( 'Errors'
              passing Elements.errors
              columns
                errLevel varChar2( 25) path '/Errors/@ErrorWarningLevel',
                errCode varChar2( 25) path '/Errors/@ErrorWarningCode',
                errText varChar2( 250) path '/Errors/@ErrorWarningText'
      )  errList
where rgmo.id = p_Answer
 and Containers.reqUID = p_ContainerID
 and elements.elementID = p_ElementID ;

end;
/