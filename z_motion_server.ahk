;@Ahk2Exe-SetMainIcon C:\Dih\zIco\2motion.ico
Menu,	Tray, NoStandard
FileInstall,	C:\Dih\zIco\2motion.ico, %A_ScriptDir%\Log\2motion.ico,1
FileInstall,	C:\Dih\zIco\2motionp.ico, %A_ScriptDir%\Log\2motionp.ico,1
ToolTip	Conexões
#Include	_adosql.ahk
#Include	header.ahk
ToolTip	Rodando em 1 segundo...
Sleep	1000
ToolTip
#Persistent
global con
Menu	Tray,	Tip,	Gerenciador de Imagens
Motion	=	D:\FTP\monitoramento\FTP\Motion\
SetTimer,	foscam_e_dahua,	1000
SetTimer,	distribuição,			999
SetTimer,	AjustaData,			3000000
return
	foscam_e_dahua:					;{
	Reset_inibidos()
		;{	Foscam
	Loop, Files, %Motion%Foscam\*.jpg, R
	{
		p_foscam	:=	StrSplit(A_LoopFileFullPath,	"\")
		mac				:=	SubStr(p_foscam[7],instr(p_foscam[7],"_")+1)
		data			:=	SubStr(p_foscam[9],InStr(p_foscam[9],"_")+1,8)
		hora			:=	SubStr(p_foscam[9],InStr(p_foscam[9],"_")+10,6)
		ip	=
		f					=
		(
			SELECT [ip]	FROM	[MotionDetection].[dbo].[Cameras]	WHERE	[mac]	=	'%mac%'
		)
		f					:=	adosql(con,f)
		ip					:=	f[2,1]
		if(StrLen(ip)=0)	{	;	Gera log se a consulta não retornar nome de câmera
			FileAppend,	 %	agora() " | Mac = " mac " | " A_LoopFileFullPath "`n", %A_ScriptDir%\Log\Foscam.txt
			FileMove,	%A_LoopFileFullPath%,	D:\FTP\monitoramento\FTP\AddBD\%A_LoopFileName%.jpg
		}
		else
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
	distribuição:							;{
Loop, Files, %motion%*.jpg	;{	Loop all files and distribute
{
	IfInString,	A_LoopFileName,	schedule
	{
		FileAppend,	  %	agora() "`n" A_LoopFileFullPath	"`n", %A_ScriptDir%\Log\Agendados.txt
		FileDelete,	%A_LoopFileLongPath%
		continue
	}
	img =
	local =
	setor = 
	StringSplit, img, A_LoopFileName,	_
	gosub	verificaInibidos	;--------------------------------------------------------------------------------------------------------------	Verifica se a câmera ainda está inibida
	if(inibida=1)	{
		FileAppend,	 %	agora() " | " img1 " inibida`n", %A_ScriptDir%\Log\log %A_DD%_%A_MM%.txt
		continue	;	alterado 03/05	-	Apenas IP e horário no LOG
	}
	sql_setor	=	;----------------------------------------------------------------------------------------------------------------------------	Busca nome e setor da câmera
	(
		SELECT [nome],[Setor] FROM [MotionDetection].[dbo].[Cameras] WHERE ip = '%img1%'
	)
	r_s	:=	adosql(con,sql_setor)
	Clipboard	:=	adosql_lq
	if (	r_s.MaxIndex()-1 = 0	)	{	;---------------------------------------------------------------------------------------------------	Se não constar no CADASTRO, gera log e move
		FileAppend,	% agora() " | " setor " | " img1 "`n", %A_ScriptDir%\Log\log - Câmeras sem Cadastro.txt
		FileMove,	%A_LoopFileFullPath%,	D:\FTP\monitoramento\FTP\AddBD\%A_LoopFileName%.jpg
		continue
	}
	local	:=	StrReplace(StrReplace(r_s[2,1],"`n"),"`r")	;-----------------------------------------------------------------------------------------------------------------	Nome da Câmera
	setor	:=	"000" r_s[2,2]	;---------------------------------------------------------------------------------------------------------	Operador 
	if	(	setor = "000"	)		;--------------------------------------------------------------------------------------------------------------	Se não estiver registrada para algum operador, define como operador 6
		setor = 0006
	img		:=	SubStr(img2,1,15)	;------------------------------------------------------------------------------------------------------	Data e Horário
	If(IS_TOOLTIP_ON=1)	;{	DEBUG APENAS
		ToolTip,	%		img1	"_" img "_" local "`n"	agora() "`n" setor "`n`tModo dia = " dia,	10, 10
	else
		ToolTip	;}
	if(dia!=1)
		if(SubStr(A_Now,9)>"060500"	AND	SubStr(A_Now,9)<"200500")
			FileAppend,	 %	agora() " | " setor " | " img1 " | " img "`t" local "`n", %A_ScriptDir%\Log\log FORA DA FAIXA DE HORÁRIO.txt
	else
		FileAppend,	%	agora() " | " setor " | " img1 " | " img "`t" local " `n", %A_ScriptDir%\Log\log %A_DD%_%A_MM%.txt
	FileMove,	%A_LoopFileFullPath%,	D:\FTP\monitoramento\FTP\%setor%\%img1%_%img%_%local%.jpg
}	;}
return	;}
	verificaInibidos:						;{
anot	:=	SubStr(StrReplace(img2,"-"),1,4)
mest	:=	SubStr(StrReplace(img2,"-"),5,2)
diat		:=	SubStr(StrReplace(img2,"-"),7,2)
hort	:=	SubStr(StrReplace(img2,"-"),9,2)
mint	:=	SubStr(StrReplace(img2,"-"),11,2)
segt		:=	SubStr(StrReplace(img2,"-"),13,2)
time	:=	anot "/" mest "/" diat " " hort ":" mint ":" segt
last_image	=	UPDATE	[MotionDetection].[dbo].[Cameras]	SET	[last_md]	=	CONVERT(DATETIME, '%time%',120)	WHERE	ip	=	'%img1%'
last_image	:=	adosql(con,last_image)
inibida	=	0
i	=	SELECT	*	FROM	[MotionDetection].[dbo].[inibidos]	WHERE	ip	=	'%img1%'	AND	restaurado is null
ii	:=	adosql(con,i)
if(ii.MaxIndex()-1	>=	1)	{
	inibida	=	1
	FileDelete,	%A_LoopFileFullPath%
}
else
	inibida	=	0
return
;}
	AjustaData:								;{
	AjustaData()
	return	;}
	DelEmpty(dir)						;{	a cada 1 segundo limpa os subfolders vazios
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
	Reset_inibidos()						;{	a cada 1 segundo informa o servidor sql que deve desinibir câmeras que tenha passado o tempo.
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
	AjustaDatas(dataatual)		;{	Ajusta a data do sistema para evitar discrepância nos eventos de detecção
	{
		if(StrLen(dataatual)!=11)	{
			FileAppend,	% agora() " | Falha ao ajustar datas`n" dataatual "`n`n", %A_ScriptDir%\Log\Complementos.txt
			ExitApp
		}
		else
			atualizador = ok
	}
	;}
	F1::											;{	Tooltips
	IS_TOOLTIP_ON	:=	!IS_TOOLTIP_ON
	If(IS_TOOLTIP_ON=1)
		Menu,	Tray,	Icon,	%A_ScriptDir%\Log\2motionp.ico
	else
		Menu,	Tray,	Icon,	%A_ScriptDir%\Log\2motion.ico
	MsgBox,,, Tooltip %IS_TOOLTIP_ON%, 1
	return	;}
	F2::											;{
	dia	:=	!dia
	if(dia=1)	{
		IS_TOOLTIP_ON	:=	!IS_TOOLTIP_ON = 1
		Menu,	Tray,	Icon,	%A_ScriptDir%\Log\2motionp.ico
		MsgBox,	,	Verificar Dia,	Ativado, 1
		ToolTip,	%img1%_%img%_%local% `n %A_Now% `n %setor%`n`tModo dia = %dia%,	10, 10
	}
	else	{
		MsgBox,	,	Verificar Dia,	Desativado, 1
		if(IS_TOOLTIP_ON	=1)
			ToolTip,	%img1%_%img%_%local% `n %A_Now% `n %setor%`n`tModo dia = %dia%,	10, 10
	}
	return
;}

	agora()	{
	agora	:=	st_insert("-",st_insert("-",st_insert(" ",st_insert(":",st_insert(":",A_now,13),11),9),7),5)
	return	agora
}
	st_Insert(insert,input,pos=1)	{
	Length := StrLen(input)
	((pos > 0) ? (pos2 := pos - 1) : (((pos = 0) ? (pos2 := StrLen(input),Length := 0) : (pos2 := pos))))
	output := SubStr(input, 1, pos2) . insert . SubStr(input, pos, Length)
	If (StrLen(output) > StrLen(input) + StrLen(insert))
		((Abs(pos) <= StrLen(input)/2) ? (output := SubStr(output, 1, pos2 - 1) . SubStr(output, pos + 1, StrLen(input))) : (output := SubStr(output, 1, pos2 - StrLen(insert) - 2) . SubStr(output, pos - StrLen(insert), StrLen(input))))
	return, output
}
	End::
	GuiClose:									;{
ExitApp	;}