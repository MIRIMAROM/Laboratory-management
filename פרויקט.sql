--1.
create view  G_SHUTS_VW as 
select  G_GERMS.NAME as GERM_NAME ,G_MEDICINE.NAME as MEDICINE_NAME ,MEDICINE_DATE from G_MEDICINE join 
G_GERMS on G_GERMS.MEDICINE_ID=G_MEDICINE.ID

go
--דרישות המערכת 
alter procedure ADD_TEST_SQL (@GERM_NAME VARCHAR (20) ,@MEDICINE_NAME VARCHAR(20)
,@TEST_DATE date,@REACTION_TYPE VARCHAR (10))as
 begin try
 declare @GERM_ID NUMERIC=(select G_GERMS .ID from G_GERMS where @GERM_NAME=G_GERMS.NAME)
 declare @MEDICIN_ID NUMERIC=(select  G_MEDICINE .ID from G_MEDICINE where @MEDICINE_NAME=G_MEDICINE.NAME)
 if  not exists (select * from G_GERMS join 
 G_MEDICINE on G_GERMS.MEDICINE_ID=G_MEDICINE.ID
where G_GERMS.NAME=@GERM_NAME and G_MEDICINE.NAME=@MEDICINE_NAME)
  begin 
    insert into G_EXCEPTION_TABLE values(ERROR_PROCEDURE()+'GERM_NAME and MEDICINE_NAME not invalid',getdate())
	print ERROR_PROCEDURE()+'GERM_NAME and MEDICINE_NAME not invalid'
  end 
else 
insert into G_TEST values(@GERM_ID ,@MEDICIN_ID,@TEST_DATE,@REACTION_TYPE )
if(@REACTION_TYPE ='dead')
 begin 
      execute  MOVE_TO_ARCHIVE @GERM_ID
     update G_GERMS set[MEDICINE_DATE]=@TEST_DATE where NAME=@GERM_NAME
 end
 end try
 begin catch
  insert into G_EXCEPTION_TABLE values(ERROR_PROCEDURE()+'This MEDICINE_NAME already try\error in the  REACTION_TYPE' + ERROR_MESSAGE(),getdate())
 end catch
 go
                ----------------------
 execute  ADD_TEST_SQL 'PASTI','UNTI','2020-06-21','dead'
 execute  ADD_TEST_SQL 'PASTI','UNTI','2020-06-21','alive'
 --2.	
create procedure UPDATE_STATUS (@GERM_ID NUMERIC,@MEDICIN_ID NUMERIC,@REACTION_TYPE VARCHAR (10)) 
as
if exists(select * from G_TEST where @GERM_ID=G_TEST.GERM_ID and G_TEST.MEDICIN_ID=@MEDICIN_ID)
 begin 
	update G_TEST set[REACTION_TYPE]=@REACTION_TYPE where @GERM_ID=G_TEST.GERM_ID and G_TEST.MEDICIN_ID=@MEDICIN_ID 
     if(@REACTION_TYPE='dead')
       begin
           update G_GERMS set[MEDICINE_DATE]= GETDATE() 
            exec MOVE_TO_ARCHIVE @GERM_ID
        end 
 end
    else
       begin 
          insert into G_EXCEPTION_TABLE values(ERROR_PROCEDURE()+'Test_code not invalid'+ ERROR_MESSAGE(),getdate())
	       print ERROR_PROCEDURE()+'Test_code not invalid'+ ERROR_MESSAGE()
        end
  go
                        -------------------------
  execute UPDATE_STATUS 2,1,'dying'
-- 3.	 
 create procedure MOVE_TO_ARCHIVE @GERM_ID int as
 begin try
 begin tran 
--ביטלתי את הטריגר  
 insert into G_ARCHIVE  select G_GERMS.NAME,GERM_ID,TEST_DATE,G_MEDICINE.NAME
,REACTION_TYPE from G_TEST join 
 G_MEDICINE on G_MEDICINE.ID=G_TEST.MEDICIN_ID join
 G_GERMS on G_GERMS.ID=G_TEST.GERM_ID
 where G_TEST .GERM_ID=@GERM_ID
 delete G_TEST  where G_TEST .GERM_ID=@GERM_ID
 commit tran
 end try
 begin catch
 rollback tran 
 insert into G_EXCEPTION_TABLE values(ERROR_PROCEDURE()+ERROR_MESSAGE(),getdate())
 print ERROR_PROCEDURE()+ ERROR_MESSAGE()
 end catch
 go 
               ---------------------
 execute MOVE_TO_ARCHIVE 1 
 --4.
alter procedure STAYING_ALIVE(@GERM_ID NUMERIC,@MEDICIN_ID NUMERIC)
as
declare @test_date date =(select  G_TEST.test_date from G_TEST where
G_TEST.GERM_ID=@GERM_ID and @MEDICIN_ID=G_TEST.MEDICIN_ID)
declare @REACTION_TYPE VARCHAR (10)=(select G_TEST.REACTION_TYPE from G_TEST where
G_TEST.GERM_ID=@GERM_ID and @MEDICIN_ID=G_TEST.MEDICIN_ID)
    if ( datediff(day ,@test_date,getdate())>61 and @REACTION_TYPE='dying')
        begin 
           execute UPDATE_STATUS @GERM_ID ,@MEDICIN_ID  ,'alive'
        end 

		                 -----------------------
execute STAYING_ALIVE 2,1
--צורה שניה ע"י סמן 
declare @g_id int
declare @m_id int
declare crs cursor 
for select GERM_ID ,MEDICIN_ID from G_TEST
where datediff(day, TEST_DATE,GetDate())>61 and REACTION_TYPE='dying'
open crs
fetch   crs  into @g_id,@M_id
	while @@FETCH_STATUS =0
	begin
	exec UPDATE_STATUS @g_id,@m_id,'alive'
	print @g_id
	fetch crs  into @g_id,@M_id
	end
close crs
deallocate crs
go

--5.
create trigger trg_MOVE_TO_ARCHIVE on g_test for delete
as
insert into G_ARCHIVE select G_GERMS.NAME,GERM_ID,TEST_DATE,G_MEDICINE.NAME
,REACTION_TYPE
 from G_TEST join G_MEDICINE on G_MEDICINE.ID=G_TEST.MEDICIN_ID join
 G_GERMS on G_GERMS.ID=G_TEST.GERM_ID
 where G_GERMS.ID in (select G_GERMS.ID from deleted)
 go
--6.
-- insert intoאת הMOVE_TO_ARCHIVEביטלתי בפרוצדורת      
-- 7.	
create function TEST_TO_GERM (@GERM_ID int)
returns  int 
as
 
begin
  declare @count int
  if not exists(select * from G_GERMS where @GERM_ID=G_GERMS.ID)
      begin
         return -1
	   end
 else 
	if exists(select * from G_TEST where @GERM_ID=G_TEST.GERM_ID)
	    begin 
	       set @count  =(select  count(G_TEST.GERM_ID)  from G_TEST
           where G_TEST .GERM_ID =@GERM_ID )
	     end
	else
	   begin 
	       set @count  =(select  count(G_ARCHIVE.GERM_ID)  from G_ARCHIVE
           where G_ARCHIVE .GERM_ID =@GERM_ID )
	    end
	return @count   
end 

                 -------------------
declare @1GERM_ID int =4
select dbo.TEST_TO_GERM(@1GERM_ID) as SUM_TEST
--   Results:
--   SUM_TEST
--      2   


--8.	
create function GERM_FOR_SHUT (@NAME_MEDICINE VARCHAR(20))
returns @t table(GERMS_NAME VARCHAR(20))
 as
 begin
 if  exists (select * from G_MEDICINE
 where  @NAME_MEDICINE=G_MEDICINE.NAME)
    insert into @t
	select G_GERMS.NAME from G_GERMS join
    G_MEDICINE on G_MEDICINE.ID=G_GERMS.MEDICINE_ID
    where @NAME_MEDICINE=G_MEDICINE.NAME
 return
 end
                ------------------
    select * from dbo.GERM_FOR_SHUT('UNTI')
-- Results:
--GERMS_NAME
--  PASTI
--   KA



--9.	
create function GERM_MOST_PRENSISTENT()
returns VARCHAR(20)
as 
 begin
     return
     (select  G_GERMS.NAME as BIG_GERMS from G_GERMS join
     G_TEST on G_TEST.GERM_ID =G_GERMS.ID  group by G_GERMS.NAME 
	 having count( G_TEST.GERM_ID) in
	 (select  top 1 count( G_TEST.GERM_ID) from G_TEST
	 group by G_TEST.GERM_ID
	 order by count(G_TEST.GERM_ID) desc)
	 union 
	 select  G_GERMS.NAME as BIG_GERMS from G_GERMS join
     G_ARCHIVE on G_ARCHIVE.GERM_ID =G_GERMS.ID  group by G_GERMS.NAME 
	 having count( G_ARCHIVE.GERM_ID) in
	 (select  top 1 count( G_ARCHIVE.GERM_ID) from G_ARCHIVE 
	  group by G_ARCHIVE.GERM_ID
	  order by count(G_ARCHIVE.GERM_ID) desc))

 end 
	           ------------------
select dbo.GERM_MOST_PRENSISTENT()as BIG_GERMS
--   Results:
--  BIG_GERMS
--    KARUS