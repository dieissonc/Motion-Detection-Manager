;@Ahk2Exe-SetMainIcon C:\Dih\zIco\2motions.ico
#Include	header.ahk
#Persistent
global con
Menu	Tray,	Tip,	Gerenciador de Imagens
Motion	=	D:\FTP\monitoramento\FTP\Motion\
f_sini		=	D:\FTP\monitoramento\FTP\Motion\Sinistro\
SetTimer,	foscam_e_dahua,	500
SetTimer,	distribuição,			1000
return
	foscam_e_dahua:	;{
Reset_inibidos()
	;{	Foscam
Loop, Files, %Motion%Foscam\*.jpg, R
{
	p_foscam	:=	StrSplit(A_LoopFileFullPath,	"\")
	mac		:=	SubStr(p_foscam[7],instr(p_foscam[7],"_")+1)
	data	:=	SubStr(p_foscam[9],InStr(p_foscam[9],"_")+1,8)
	hora	:=	SubStr(p_foscam[9],InStr(p_foscam[9],"_")+10,6)
	f			=
	(
		SELECT [ip]	FROM	[MotionDetection].[dbo].[Cameras]	WHERE	[mac]	=	'%mac%'
	)
	f			:=	adosql(con,f)
	ip			:=	f[2,1]
	FileMove,	%A_LoopFileFullPath%, %Motion%%ip%_%data%-%hora%.jpg
}
;}
	;{	Dahua
Loop, Files, %Motion%Dahua\*.jpg, R
{
	StringSplit,	path,	A_LoopFileFullPath,	\
	if(path0 = 10)	{
	horario			:=	StrReplace(SubStr(path10,1,instr(path10,"[")-1),".")
	ip						:=	strreplace(path7,"_",".")
	novonome		:=	ip "_" strreplace(path8,"-") "-" horario ".jpg"
	}
	else
	{
	segundos		:=	SubStr(path13,1,instr(path13,"[")-1)
	ip						:=	strreplace(path7,"_",".")
	novonome		:=	ip "_" strreplace(path8,"-") "-" path11 path12 segundos ".jpg"
	}
	FileMove,	%A_LoopFileFullPath%,	%Motion%%novonome%,	1
}	;}
	;{	Limpa folders vazios
DelEmpty_Folder = %Motion%Dahua
DelEmpty(DelEmpty_Folder) 
DelEmpty_Folder = %Motion%Foscam
DelEmpty(DelEmpty_Folder) 
return	;}
;}
	distribuição:			;{
Loop, Files, %motion%*.jpg	;	if Schedule Picture DELETE
{
	IfInString,	A_LoopFileName,	schedule
		FileDelete,	%A_LoopFileLongPath%
}
Loop, Files, %motion%*.jpg
{
	img =
	local =
	setor = 
	StringSplit, img, A_LoopFileName, _
	gosub	verificaInibidos	;--------------------------------------------------------------------------------------------------------------	Verifica se a câmera ainda está inibida ou em Sinistro
	if(inibida=1	or	sinistro_=1)
		return
	sql_setor	=
	(
		SELECT [nome],[Setor] FROM [MotionDetection].[dbo].[Cameras] WHERE ip = '%img1%'
	)
	r_s	:=	adosql(con,sql_setor)
	if (	r_s.MaxIndex()-1 = 0	)	{	;---------------------------------------------------------------------------------------------------	Se não constar no CADASTRO, move para posteriormente ser adicionada
		FileCopy,	%A_LoopFileFullPath%,	D:\FTP\monitoramento\FTP\AddBD\%A_LoopFileName%
		FileMove,	%A_LoopFileFullPath%,	D:\FTP\monitoramento\FTP\0006\%img1%_%img%_%local% nao cadastrado.jpg
		return
	}
	local	:=	r_s[2,1]	;-----------------------------------------------------------------------------------------------------------------	Nome da Câmera
	local	:=	StrReplace(StrReplace(local,"`n"),"`r")	;-----------------------------------------------------------------------------	Remove nova linha da var
	setor	:=	"000" r_s[2,2]	;---------------------------------------------------------------------------------------------------------	Operador 
	if	(setor	=	"000")	{	;--------------------------------------------------------------------------------------------------------------	Se não estiver registrada para algum operador, define como operador 6
		setor	=	0006
	}
	img		:=	SubStr(img2,1,15)	;-----------------------------------------------------------------------------------------------------	Data e Horário
	;~ MsgBox	%A_LoopFileFullPath% `nD:\FTP\monitoramento\FTP\%setor%\%img1%_%img%_%local%.jpg
	FileMove,	%A_LoopFileFullPath%,	D:\FTP\monitoramento\FTP\%setor%\%img1%_%img%_%local%.jpg
}
return	;}
	verificaInibidos:		;{
i	=	;{	Inibidos
(
	SELECT	*	FROM	[MotionDetection].[dbo].[inibidos]
	WHERE	ip	=	'%img1%'	AND	restaurado is null
)
adosql_le =
ii	:=	adosql(con,i)
if(ii.MaxIndex()-1	>=	1)	{
	inibida	=	1
	FileDelete,	%A_LoopFileFullPath%
}
else
	inibida	=	0	;}

s	=	;{	Sinistros	Verificar ou não
(
		SELECT TOP(1)	Hora_sinistro					FROM	[MotionDetection].[dbo].[Sinistro]
		WHERE				operador						= 		'%setor%'
		AND					Eventos_Não_Exibidos	IS			NULL
		ORDER BY			1										DESC
)
s	:=	adosql(con,s)
s	:=	s[2,1]
sinistro_	=
if(StrLen(s)>2) 	{
	FileMove,	%A_LoopFileFullPath%,	D:\FTP\monitoramento\FTP\Sinistro\%setor%\%A_LoopFileName%
	sinistro_	=	1
}	;}
return	;}
	DelEmpty(dir)		;{
{ 
   Loop %dir%\*.*, 2 
	{
		FileDelete, %dir%\DVRWorkDirectory
		FileDelete, %A_LoopFileFullPath%\DVRWorkDirectory
		DelEmpty(A_LoopFileFullPath) 
	}
	FileRemoveDir %A_LoopFileFullPath% 
}
return	;}
	Reset_inibidos()		;{
{
	rdia	:=	A_YDay
	rsec	:=	(A_Hour*60*60)+(A_Min*60)+A_Sec
	ix	=
	(
		UPDATE	[MotionDetection].[dbo].[inibidos]
		SET			[restaurado]			=		GETDATE()
		WHERE	[encerraDia]			<=	'%rdia%'
		AND		[encerraHorario]	<=	'%rsec%'
		AND		[restaurado]	IS	NULL
	)
	di	:=	adosql(con,ix)
}
	;}
	GuiClose:					;{
ExitApp	;}