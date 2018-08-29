<%
'---------------------------------------------------------------------
'
'            Copyright 1986 .. 2005 Bear Consulting Group
'                          All Rights Reserved
'
'    This software-file/document, in whole or in part, including	
'    the structures and the procedures described herein, may not	
'    be provided or otherwise made available without prior written
'    authorization.  In case of authorized or unauthorized
'    publication or duplication, copyright is claimed.
'
'---------------------------------------------------------------------

DIM	gHtmlOption_embeddedLinebreaks
DIM	gHtmlOption_preserveSpaces
DIM	gHtmlOption_starListSupport
DIM	gHtmlOption_encodeEmailAddresses
gHtmlOption_embeddedLinebreaks = TRUE
gHtmlOption_preserveSpaces = TRUE
gHtmlOption_starListSupport = TRUE
gHtmlOption_encodeEmailAddresses = FALSE

DIM	g_htmlFormat_pictureFunc
DIM	g_htmlFormat_metaSubsFunc
g_htmlFormat_pictureFunc = "htmlFormatMeta_f_pictureFile"
g_htmlFormat_metaSubsFunc = ""
DIM	g_htmlFormat_pullunquoteFunc
g_htmlFormat_pullunquoteFunc = "htmlFormat_f_pullunquoteText"
DIM	g_htmlFormat_pullquoteFunc
g_htmlFormat_pullquoteFunc = "htmlFormatMeta_f_pullquoteText"
DIM	g_htmlFormat_sidebarFunc
g_htmlFormat_sidebarFunc = "htmlFormatMeta_f_sidebarText"


FUNCTION htmlFormatMID( BYREF sText, idx )
	IF 0 < idx  AND  idx <= LEN(sText) THEN
		htmlFormatMID = MID( sText, idx, 1 )
	ELSE
		htmlFormatMID = ""
	END IF
END FUNCTION


FUNCTION htmlFormatJustDashes( BYREF sLine, c )
	DIM	s
	s = STRING( LEN(sLine), c )
	IF s = sLine THEN
		htmlFormatJustDashes = TRUE
	ELSE
		htmlFormatJustDashes = FALSE
	END IF
END FUNCTION


FUNCTION htmlFormatWebLinkEnd( iLinkStart, BYREF sText, lenText, cKey )
	DIM	ix
	DIM	iLinkEnd
	
	ix = INSTR( iLinkStart, sText, cKey, vbTextCompare )
	IF 0 = ix THEN
		iLinkEnd = INSTR( iLinkStart, sText, " ", vbTextCompare )
		IF 0 = iLinkEnd THEN iLinkEnd = lenText + 1
	ELSE
		iLinkEnd = ix
		ix = INSTR( iLinkStart, sText, " ", vbTextCompare )
		IF 0 < ix  AND  ix < iLinkEnd THEN iLinkEnd = ix
	END IF
	ix = INSTR( iLinkStart, sText, vbLF, vbTextCompare )
	IF 0 < ix  AND  ix < iLinkEnd THEN iLinkEnd = ix
	htmlFormatWebLinkEnd = iLinkEnd
END FUNCTION


SUB htmlFormatFindWEB( iLinkStart, iLinkEnd, sText, sKey, iStart )
	DIM	ix
	DIM	i
	DIM	lenKey
	DIM	lenText
	DIM	c, n
	CONST kBegChar = """'([{<>`"
	CONST kEndChar = """')]}><'"
	
	lenKey = LEN(sKey)
	lenText = LEN(sText)
	IF lenText < iStart+lenKey+3 THEN
		iLinkStart = 0
		EXIT SUB
	END IF
	i = iStart
	
	DO
		ix = INSTR( i, sText, sKey, vbTextCompare )
		IF 0 = ix THEN
			iLinkStart = 0
			EXIT DO
		END IF
		
		iLinkStart = ix
		c = htmlFormatMID( sText, iLinkStart-1 )
		n = INSTR(1,kBegChar,c,vbTextCompare)
		IF 0 < n THEN
			iLinkEnd = htmlFormatWebLinkEnd( iLinkStart, sText, lenText, MID(kEndChar,n,1) )
		ELSE
			iLinkEnd = INSTR( iLinkStart, sText, " ", vbTextCompare )
		
			IF 0 = iLinkEnd THEN iLinkEnd = lenText + 1
			ix = INSTR( iLinkStart, sText, vbLF, vbTextCompare )
			IF 0 < ix  AND  ix < iLinkEnd THEN iLinkEnd = ix
			SELECT CASE MID(sText, iLinkEnd-1, 1)
			CASE ".", ",", "!", "?"
				iLinkEnd = iLinkEnd - 1
			END SELECT
		END IF
		
		IF iLinkStart+lenKey+3 < iLinkEnd THEN
			EXIT DO
		ELSE
			i = iLinkStart+1
			iLinkStart = 0
		END IF
	LOOP
END SUB


FUNCTION htmlFormatEncodeOther( BYREF sText )
	IF gHtmlOption_preserveSpaces THEN
		htmlFormatEncodeOther = REPLACE(Server.HTMLEncode(sText),"  ","&nbsp; ",1,-1,vbTextCompare)
	ELSE
		htmlFormatEncodeOther = Server.HTMLEncode(sText)
	END IF
END FUNCTION


DIM	g_aHtmlLinkRegExp(5,2)
g_aHtmlLinkRegExp(0,0) = "mailto:\w+[\w\.-]*\w+\@\w+[\w\.-]*\.\w+"
g_aHtmlLinkRegExp(0,1) = ""
g_aHtmlLinkRegExp(1,0) = "\w+[\w\.-]*\w+\@\w+[\w\.-]*\.\w+"
g_aHtmlLinkRegExp(1,1) = "mailto:"
g_aHtmlLinkRegExp(2,0) = "\\\\\w+[\w\._-]*\w+(\\\w+[\w_%~-]*)+(\\|\.\w+)?"
g_aHtmlLinkRegExp(2,1) = "file:"
'g_aHtmlLinkRegExp(3,0) = "[c-z]:(\\\w+[\w_%~-]*)+(\\|\.\w+)?"
'g_aHtmlLinkRegExp(3,1) = "file://"
g_aHtmlLinkRegExp(3,0) = "\w+[\w\.-]*\.(com|net|org|edu|gov|biz|info|mil|pro|cc|tv|us|ws)"
g_aHtmlLinkRegExp(3,1) = "http://"
'g_aHtmlLinkRegExp(3,0) = ""
'g_aHtmlLinkRegExp(3,1) = ""


FUNCTION htmlFormatEncodeMailTo( sKeyPrefix, sLinkURL, sLinkText )

	DIM	sOutput
	
	IF gHtmlOption_encodeEmailAddresses THEN
		DIM	i
		DIM	sName
		DIM	sDomain
		
		i = INSTR(sLinkURL,"@")
		IF 0 < i THEN
			sName = LEFT(sLinkURL,i-1)
			sDomain = MID(sLinkURL,i+1)
		ELSE
			sName = sLinkURL
			sDomain = ""
		END IF
		
		
		sOutput = "<script language=""JavaScript"">"
		sOutput = sOutput & "document.write('<a ' + 'hre' + 'f=""');"
		sOutput = sOutput & "document.write('ma' + 'il' + 'to:');"
		sOutput = sOutput & "document.write('" & sName & "');"
		sOutput = sOutput & "document.write('@' + '" & sDomain & """>');"
		i = INSTR(sLinkText,"@")
		IF 0 < i THEN
			sName = LEFT(sLinkText,i-1)
			sDomain = MID(sLinkText,i+1)
		ELSE
			sName = sLinkText
			sDomain = ""
		END IF
		sOutput = sOutput & "document.write('" & Server.HTMLEncode(sName) & "');"
		IF "" <> sDomain THEN
			sOutput = sOutput & "document.write('@');"
			sOutput = sOutput & "document.write('" & Server.HTMLEncode(sDomain) & "');"
		END IF
		sOutput = sOutput & "document.write('</a>');"
		sOutput = sOutput & "</script>"
	
	ELSE

		sOutput = "<a href=""" & sKeyPrefix & sLinkURL & """ target=""_blank"">" & Server.HTMLEncode(sLinkText) & "</a>"
	
	END IF

	
	htmlFormatEncodeMailTo = sOutput

END FUNCTION



FUNCTION htmlFormatEncodeTextLinkRegExp( BYREF sText, BYVAL idxKey )
	DIM	sOutput
	DIM	sLinkURL
	DIM	sLinkText
	DIM	i, ix
	DIM	iLinkStart
	DIM	iLinkEnd
	DIM	oReg
	DIM	oMatchList
	DIM	oMatch
	DIM	lenText
	DIM	lenKey
	DIM	sKey
	DIM	sKeyPrefix
	DIM	sTempText
	DIM	c

	sKey = g_aHtmlLinkRegExp(idxKey,0)
	lenKey = LEN(sKey)
	IF lenKey < 1 THEN
		htmlFormatEncodeTextLinkRegExp = htmlFormatEncodeOther( sText )
		EXIT FUNCTION
	END IF
	sKeyPrefix = g_aHtmlLinkRegExp(idxKey,1)
	idxKey = idxKey + 1

	lenText = LEN(sText)
	' u@d.aa
	IF lenText < 4 THEN
		htmlFormatEncodeTextLinkRegExp = htmlFormatEncodeOther( sText )
		EXIT FUNCTION
	END IF

	sOutput = ""
	SET oReg = NEW RegExp
	oReg.Pattern = sKey
	oReg.IgnoreCase = TRUE
	oReg.Global = TRUE
	SET oMatchList = oReg.Execute( sText )
	IF 0 = oMatchList.Count THEN
		htmlFormatEncodeTextLinkRegExp = htmlFormatEncodeTextLinkRegExp( sText, idxKey )
	ELSE
		i = 1
		FOR EACH oMatch IN oMatchList
			iLinkStart = oMatch.FirstIndex + 1		'adjust for zero index
			IF i <= iLinkStart THEN
				iLinkEnd = iLinkStart + oMatch.Length
				c = UCASE(htmlFormatMID( sText, iLinkEnd ))
				IF c < "A"  OR  "Z" < c THEN
				IF i < iLinkStart THEN sOutput = sOutput & htmlFormatEncodeTextLinkRegExp(MID(sText, i, iLinkStart - i),idxKey)
				sLinkURL = oMatch.Value
				sLinkText = sLinkURL
				IF iLinkEnd+3 < lenText THEN
					IF " [" = MID(sText,iLinkEnd,2) THEN
						ix = INSTR( iLinkEnd, sText, "]", vbTextCompare )
						IF iLinkEnd+2 < ix THEN
							sLinkText = MID(sText,iLinkEnd+2,ix-iLinkEnd-2)
							iLinkEnd = ix + 1
						END IF
					END IF
				END IF
				IF "mailto:" = sKeyPrefix THEN
					sOutput = sOutput & htmlFormatEncodeMailTo( sKeyPrefix, sLinkURL, sLinkText )
				ELSE
					sOutput = sOutput & "<a href=""" & sKeyPrefix & sLinkURL & """ target=""_blank"">" & Server.HTMLEncode(sLinkText) & "</a>"
				END IF
				i = iLinkEnd
				END IF
			END IF
		NEXT 'oMatch
		htmlFormatEncodeTextLinkRegExp = sOutput & htmlFormatEncodeTextLinkRegExp(MID(sText, i),idxKey)
	END IF
	SET oReg = Nothing
	
END FUNCTION


DIM	g_aHtmlLinks(5,2)
g_aHtmlLinks(0,0) = "http://"
g_aHtmlLinks(0,1) = ""
g_aHtmlLinks(1,0) = "https://"
g_aHtmlLinks(1,1) = ""
g_aHtmlLinks(2,0) = "www."
g_aHtmlLinks(2,1) = "http://"
g_aHtmlLinks(3,0) = "file://"
g_aHtmlLinks(3,1) = ""
g_aHtmlLinks(4,0) = "news:"
g_aHtmlLinks(4,1) = ""
g_aHtmlLinks(5,0) = ""
g_aHtmlLinks(5,1) = ""

FUNCTION htmlFormatEncodeTextLink( BYREF sText, BYVAL idxKey )
	DIM	sOutput
	DIM	sLinkURL
	DIM	sLinkText
	DIM	i, ix
	DIM	iLinkStart
	DIM	iLinkEnd
	DIM	lenText
	DIM	lenKey
	DIM	sKey
	DIM	sKeyPrefix
	DIM	sTempText
	
	sKey = g_aHtmlLinks(idxKey,0)
	lenKey = LEN(sKey)
	IF lenKey < 1 THEN
		htmlFormatEncodeTextLink = htmlFormatEncodeTextLinkRegExp( sText, 0 )
		EXIT FUNCTION
	END IF
	sKeyPrefix = g_aHtmlLinks(idxKey,1)
	idxKey = idxKey + 1
	
	lenText = LEN(sText)
	'http://aa.aa
	IF lenText < lenKey+4 THEN
		htmlFormatEncodeTextLink = htmlFormatEncodeTextLink(sText, idxKey)
		EXIT FUNCTION
	END IF
	
	'	file://\w+[\w\.-]*\.\w+
	sOutput = ""
	
	i = 1
	DO
		htmlFormatFindWEB iLinkStart, iLinkEnd, sText, sKey, i
		IF 0 = iLinkStart THEN EXIT DO
		
		IF i < iLinkStart THEN
			sTempText = MID(sText, i, iLinkStart - i)
			sOutput = sOutput & htmlFormatEncodeTextLink(sTempText, idxKey)
		END IF
		sLinkURL = MID(sText, iLinkStart, iLinkEnd - iLinkStart)
		sLinkText = sLinkURL
		IF iLinkEnd+3 < lenText THEN
			IF " [" = MID(sText,iLinkEnd,2) THEN
				ix = INSTR( iLinkEnd, sText, "]", vbTextCompare )
				IF iLinkEnd+2 < ix THEN
					sLinkText = MID(sText,iLinkEnd+2,ix-iLinkEnd-2)
					iLinkEnd = ix + 1
				END IF
			END IF
		END IF
		sOutput = sOutput & "<a href=""" & sKeyPrefix & sLinkURL & """ target=""_blank"">" & Server.HTMLEncode(sLinkText) & "</a>"
		
		i = iLinkEnd
	LOOP
	sTempText = MID(sText, i)
	htmlFormatEncodeTextLink = sOutput & htmlFormatEncodeTextLink(sTempText, idxKey)
END FUNCTION


FUNCTION htmlFormatEncodeText( BYREF sText )
	htmlFormatEncodeText = htmlFormatEncodeTextLink( sText, 0 )
END FUNCTION

FUNCTION htmlFormatSpecialP( BYREF sLine, nExtraBreaks )
	DIM	sTemp
	IF 1 < LEN(sLine) THEN
		sTemp = LEFT(sLine,1)
		IF "-" = sTemp  AND  htmlFormatJustDashes(sLine,"-") THEN
			htmlFormatSpecialP = "<hr class=""htmlformat"">" & vbCRLF
		ELSEIF "_" = sTemp  AND  htmlFormatJustDashes(sLine,"_") THEN
			htmlFormatSpecialP = "<hr class=""htmlformat"">" & vbCRLF
		ELSEIF "=" = sTemp  AND  htmlFormatJustDashes(sLine,"=") THEN
			htmlFormatSpecialP = "<hr size=""6"" class=""htmlformat"">" & vbCRLF
		ELSE
			htmlFormatSpecialP = ""
		END IF
	ELSE
		IF "|" = sLine THEN
			htmlFormatSpecialP = "<br>" & vbCRLF
			IF 0 < nExtraBreaks THEN htmlFormatSpecialP = htmlFormatSpecialP & "<br>" & vbCRLF
		ELSEIF "\" = sLine  OR  "/" = sLine THEN
			htmlFormatSpecialP = "<br clear=""all""><br>" & vbCRLF
			IF 0 < nExtraBreaks THEN htmlFormatSpecialP = htmlFormatSpecialP & "<br>" & vbCRLF
		ELSE
			htmlFormatSpecialP = ""
		END IF
	END IF

END FUNCTION

FUNCTION htmlFormatEncodeP( BYREF aText(), nBegin, nEnd )
	DIM	n
	DIM	s
	DIM	sTemp
	
	s = ""
	IF nBegin <= nEnd THEN
		s = s & "<p class=""htmlformat"">"
		FOR n = nBegin TO nEnd
			sTemp = htmlFormatSpecialP(aText(n),0)
			IF 0 < LEN(sTemp) THEN
				s = s & sTemp
			ELSE
				s = s & aText(n)
				IF n < nEnd THEN
					IF gHtmlOption_embeddedLinebreaks THEN
						s = s & "<br>" & vbCRLF
					ELSE
						s = s & vbCRLF
					END IF
				END IF
			END IF
		NEXT 'n
		s = s & "</p>" & vbCRLF
	END IF
	htmlFormatEncodeP = s
END FUNCTION


FUNCTION htmlFormatEncodeTable( BYREF aText(), nBegin, nEnd )
	DIM	n
	DIM	s
	DIM	sTemp
	DIM	b

	s = ""
	IF nBegin <= nEnd THEN
		s = s & "<table border=""1"" cellpadding=""3"" cellspacing=""0"" class=""htmlformattable"">"
		b = FALSE
		FOR n = nBegin TO nEnd
			sTemp = aText(n)
			IF NOT b THEN
				IF "|" = LEFT(sTemp,1) THEN
					b = TRUE
					sTemp = "<tr><td valign=""top"">" & MID(sTemp,2)
				END IF
			END IF
			IF "|" = RIGHT(sTemp,1) THEN
				b = FALSE
				sTemp = LEFT(sTemp,LEN(sTemp)-1) & "</td></tr>"
			ELSE
				IF gHtmlOption_embeddedLinebreaks THEN
					sTemp = sTemp & "<br>" & vbCRLF
				ELSE
					sTemp = sTemp & vbCRLF
				END IF
			END IF
			s = s & REPLACE( sTemp, "|", "</td><td valign=""top"">" )
		NEXT 'n
		s = s & "</table>" & vbCRLF
	END IF
	htmlFormatEncodeTable = s
END FUNCTION


FUNCTION htmlFormatEncodePcenter( BYREF aText(), nBegin, nEnd )
	DIM	n
	DIM	s
	DIM	sTemp
	
	s = ""
	IF nBegin <= nEnd THEN
		s = s & "<center><p align=""center"" class=""htmlformat"">"
		FOR n = nBegin TO nEnd
			sTemp = htmlFormatSpecialP(aText(n),0)
			IF 0 < LEN(sTemp) THEN
				s = s & sTemp
			ELSE
				IF "^" = LEFT(aText(n),1) THEN
					s = s & LTRIM(MID(aText(n),2))
				ELSE
					s = s & aText(n)
				END IF
				IF n < nEnd THEN
					IF gHtmlOption_embeddedLinebreaks THEN
						s = s & "<br>" & vbCRLF
					ELSE
						s = s & vbCRLF
					END IF
				END IF
			END IF
		NEXT 'n
		s = s & "</p></center>" & vbCRLF
	END IF
	htmlFormatEncodePcenter = s
END FUNCTION


FUNCTION htmlFormatEncodePindent( BYREF aText(), nBegin, nEnd )
	htmlFormatEncodePindent = htmlFormatEncodePrivateList( aText, nBegin, nEnd, "ul", "", "<br>", "]" )
END FUNCTION


FUNCTION htmlFormatEncodeH( BYREF aText(), nBegin, nEnd )
	DIM	i, j
	DIM	sTag
	
	i = htmlFormatCountChars( aText(nBegin), "!" )
	j = i
	IF 4 < i THEN i = 4
	i = i + 2
	sTag = "h" & i
	aText(nBegin) = "`" & TRIM(MID(aText(nBegin),j+1))
	htmlFormatEncodeH = _
			htmlFormatEncodePrivateList( aText, nBegin, nEnd, sTag, "", "", "`" )
	'htmlFormatEncodeH = "<h" & i & " class=""htmlformat"">" & MID(sLine,j+1) & "</h" & i & ">" & vbCRLF
END FUNCTION



FUNCTION htmlFormatCountChars( BYREF s, c )
	DIM	i
	DIM	j
	
	j = LEN(s)
	i = 1
	DO WHILE i < j
		IF c = MID(s,i,1) THEN
			i = i + 1
		ELSE
			i = i - 1
			EXIT DO
		END IF
	LOOP
	htmlFormatCountChars = i
END FUNCTION



CONST gHtmlFormatOutline = "IA1ai*@#"
CONST gHtmlFormatNumber = "1ai*@#*@#"
CONST gHtmlFormatBullet = "*@#*@#*@#"
CONST gHtmlFormatAlpha  = "a@#*@#*@#*"

FUNCTION htmlFormatNumberType( sPrefix, n )
	DIM	c
	SELECT CASE sPrefix
	CASE "*"
		c = htmlFormatMID(gHtmlFormatBullet,n)
		IF "" = c THEN c = "#"
	CASE "#"
		c = htmlFormatMID(gHtmlFormatNumber,n)
		IF "" = c THEN c = "#"
	CASE "%"
		c = htmlFormatMID(gHtmlFormatOutline,n)
		IF "" = c THEN c = "#"
	CASE "@"
		c = htmlFormatMID(gHtmlFormatAlpha,n)
		IF "" = c THEN c = "#"
	CASE "-"
		c = "#"
	CASE ELSE
		c = ""
	END SELECT
	IF c = "" THEN
		htmlFormatNumberType = ""
	ELSE
		SELECT CASE c
		CASE "*"
			c = "disc"
		CASE "@"
			c = "circle"
		CASE "#"
			c = "square"
		END SELECT
		htmlFormatNumberType = " type=""" & c & """"
	END IF
END FUNCTION


FUNCTION htmlFormatEncodePrivateList( BYREF aText(), nBegin, nEnd, _
									sTag, sItemBegin, sItemEnd, sPrefix )
	DIM	n
	DIM	i, j
	DIM	s
	DIM	sLine
	DIM	sTemp
	DIM	sLastPrefix
	
	sLastPrefix = ""
	s = ""
	j = 0
	IF nBegin <= nEnd THEN
		FOR n = nBegin TO nEnd
			sTemp = htmlFormatSpecialP(aText(n),1)
			IF 0 < LEN(sTemp) THEN
				s = s & sTemp
			ELSE
				sTemp = LEFT(aText(n),1)
				IF sPrefix = sTemp THEN
					i = htmlFormatCountChars( aText(n), sPrefix )
					sLine = TRIM(MID(aText(n),i+1))
					IF "" <> sLastPrefix THEN s = s & sItemEnd & vbCRLF
					IF j < i THEN
						DO WHILE j < i
							j = j + 1
							s = s & "<" & sTag & htmlFormatNumberType(sPrefix, j) & " class=""htmlformat"">" & vbCRLF
						LOOP
					ELSE
						DO WHILE i < j
							s = s & "</" & sTag & ">" & vbCRLF
							j = j - 1
						LOOP
					END IF
					s = s & sItemBegin & sLine
				ELSE
					IF gHtmlOption_embeddedLinebreaks THEN
						s = s & "<br>" & vbCRLF
					ELSE
						s = s & vbCRLF
					END IF
					s = s & aText(n)
				END IF
				sLastPrefix = sTemp
			END IF
		NEXT 'n
		s = s & sItemEnd & vbCRLF
		DO WHILE 0 < j
			s = s & "</" & sTag & ">" & vbCRLF
			j = j - 1
		LOOP
	END IF
	htmlFormatEncodePrivateList = s
END FUNCTION


FUNCTION htmlFormatEncodeLI( BYREF aText(), nBegin, nEnd, sTag, sPrefix )
	htmlFormatEncodeLI = htmlFormatEncodePrivateList( aText, nBegin, nEnd, sTag, "<li>", "</li>", sPrefix )
END FUNCTION

'=================================================================================


FUNCTION htmlFormatMeta_fail( aArgs(), sText )
	htmlFormatMeta_fail = ""
END FUNCTION


FUNCTION htmlFormatMeta_f_bold( aArgs(), sText )
	IF UBOUND(aArgs) < 1 THEN
		htmlFormatMeta_f_bold = "<b>" & sText & "</b>"
	ELSE
		htmlFormatMeta_f_bold = htmlFormatMeta_fail( aArgs, sText )
	END IF
END FUNCTION

FUNCTION htmlFormatMeta_f_italic( aArgs(), sText )
	IF UBOUND(aArgs) < 1 THEN
		htmlFormatMeta_f_italic = "<i>" & sText & "</i>"
	ELSE
		htmlFormatMeta_f_italic = htmlFormatMeta_fail( aArgs, sText )
	END IF
END FUNCTION

FUNCTION htmlFormatMeta_f_underline( aArgs(), sText )
	IF UBOUND(aArgs) < 1 THEN
		htmlFormatMeta_f_underline = "<u>" & sText & "</u>"
	ELSE
		htmlFormatMeta_f_underline = htmlFormatMeta_fail( aArgs, sText )
	END IF
END FUNCTION

FUNCTION htmlFormatMeta_f_big( aArgs(), sText )
	IF UBOUND(aArgs) < 1 THEN
		htmlFormatMeta_f_big = "<font size=""+1"">" & sText & "</font>"
	ELSE
		htmlFormatMeta_f_big = htmlFormatMeta_fail( aArgs, sText )
	END IF
END FUNCTION

FUNCTION htmlFormatMeta_f_small( aArgs(), sText )
	IF UBOUND(aArgs) < 1 THEN
		htmlFormatMeta_f_small = "<font size=""-1"">" & sText & "</font>"
	ELSE
		htmlFormatMeta_f_small = htmlFormatMeta_fail( aArgs, sText )
	END IF
END FUNCTION

FUNCTION htmlFormatMeta_f_color( aArgs(), sText )
	IF UBOUND(aArgs) < 1 THEN
		htmlFormatMeta_f_color = "<font color=""" & aArgs(0) & """>" & sText & "</font>"
	ELSE
		htmlFormatMeta_f_color = htmlFormatMeta_fail( aArgs, sText )
	END IF
END FUNCTION


FUNCTION htmlFormatMetaColorName( sText )
	SELECT CASE LCASE(sText)
	CASE "red", "darkred", "maroon", "pink", _
			"yellow", "gold", "goldenrod", "orange", "brown", "olive", _
			"green", "darkgreen", "lime", _
			"aqua", "teal", _
			"blue", "darkblue", "navy", "skyblue", _
			"fuchsia", "magenta", "purple", _
			"black", "gray", "darkgray", "silver"
		htmlFormatMetaColorName = LCASE(sText)
	CASE ELSE
		htmlFormatMetaColorName = ""
	END SELECT
END FUNCTION


FUNCTION htmlFormatMeta_f_style( aArgs(), sText )
	IF 0 < UBOUND(aArgs) THEN
		DIM	sPrefix
		DIM	sPostfix
		DIM	sTemp
		DIM	i
		sPrefix = ""
		sPostfix = ""
		FOR i = 1 TO UBOUND(aArgs)
			SELECT CASE LCASE(aArgs(i))
			CASE "b", "bold"
				sPrefix = sPrefix & "<b>"
				sPostfix = "</b>" & sPostfix
			CASE "i", "italic", "italics"
				sPrefix = sPrefix & "<i>"
				sPostfix = "</i>" & sPostfix
			CASE "u", "underline"
				sPrefix = sPrefix & "<u>"
				sPostfix = "</u>" & sPostfix
			CASE "large", "big"
				sPrefix = sPrefix & "<font size=""+1"">"
				sPostfix = "</font>" & sPostfix
			CASE "small"
				sPrefix = sPrefix & "<font size=""-1"">"
				sPostfix = "</font>" & sPostfix
			CASE ELSE
				sTemp = htmlFormatMetaColorName( aArgs(i) )
				IF 0 < LEN(sTemp) THEN
					sPrefix = sPrefix & "<font color=""" & sTemp & """>"
					sPostfix = "</font>" & sPostfix
				ELSE
					sPrefix = ""
					EXIT FOR
				END IF
			END SELECT
		NEXT 'i
		IF 0 < LEN(sPrefix) THEN
			htmlFormatMeta_f_style = sPrefix & sText & sPostfix
		ELSE
			htmlFormatMeta_f_style = htmlFormatMeta_fail( aArgs, sText )
		END IF
	ELSE
		htmlFormatMeta_f_style = htmlFormatMeta_fail( aArgs, sText )
	END IF
END FUNCTION

FUNCTION htmlFormatMeta_f_args( BYREF sAlign, BYREF sBorder, BYREF sWidth, BYREF sColor, aArgs(), idx )
	DIM	sTemp
	DIM	sTag
	DIM	sValue
	DIM	i, j
	
	sAlign = ""
	sBorder = ""
	sWidth = ""
	sColor = ""
	
	htmlFormatMeta_f_args = TRUE
	FOR i = idx TO UBOUND(aArgs)
		sTemp = aArgs(i)
		IF 0 < LEN(sTemp) THEN
			j = INSTR(1,sTemp,"=",vbTextCompare)
			IF 0 < j THEN
				sTag = LEFT(sTemp,j-1)
				sValue = MID(sTemp,j+1)
			ELSE
				sTag = sTemp
				sValue = ""
			END IF
			IF 0 < LEN(sValue) THEN
				SELECT CASE LCASE(sTag)
				CASE "align"
					sAlign = " align=""" & sValue & """"
				CASE "width"
					sWidth = " width=""" & sValue & """"
				CASE "border"
					sBorder = " border=""" & sValue & """"
				CASE ELSE
					htmlFormatMeta_f_args = FALSE
					EXIT FOR
				END SELECT
			ELSE
				SELECT CASE LCASE(sTag)
				CASE "left"
					sAlign = " align=""left"""
				CASE "right"
					sAlign = " align=""right"""
				CASE "noborder"
					sBorder = " border=""0"""
				CASE ELSE
					IF ISNUMERIC(LEFT(sTag,1)) THEN
						sWidth = " width=""" & sTag & """"
					ELSE
						htmlFormatMeta_f_args = FALSE
						EXIT FOR
					END IF
				END SELECT
			END IF
		END IF
	NEXT 'i
END FUNCTION

FUNCTION htmlFormatMeta_f_sidebarText( sAlign, sWidth, sText )
	DIM	xWidth
	DIM	xAlign
	DIM	sOutput
	DIM	sUnquote
	IF 0 < LEN(sAlign) THEN
		xAlign = sAlign
	ELSE
		xAlign = " align=""right"""
	END IF
	IF 0 < LEN(sWidth) THEN
		xWidth = sWidth
	ELSE
		xWidth = " width=""100"""
	END IF
	sOutput = "" _
			&	"<table border=""1"" cellpadding=""2"" cellspacing=""0""" & xWidth & xAlign & " class=""htmlformatsidebar"">" _
			&	"<tr>" _
			&	"<td class=""htmlformatsidebar"">" & htmlFormatMeta(sText) & "</td>" _
			&	"</tr>" _
			&	"</table> "
	htmlFormatMeta_f_sidebarText = sOutput
END FUNCTION


FUNCTION htmlFormatMeta_f_sidebar( aArgs(), sText )
	IF 0 < LEN(sText) THEN
		DIM	sAlign
		DIM	sWidth
		DIM	sBorder
		DIM	sColor
	
		sAlign = ""
		sWidth = ""
		sBorder = ""
		sColor = ""
		IF htmlFormatMeta_f_args( sAlign, sBorder, sWidth, sColor, aArgs, 1 ) THEN
			htmlFormatMeta_f_sidebar = EVAL( g_htmlFormat_sidebarFunc & "( sAlign, sWidth, sText )" )
		ELSE
			htmlFormatMeta_f_sidebar = ""
		END IF
	ELSE
		htmlFormatMeta_f_sidebar = " "
	END IF
END FUNCTION




FUNCTION htmlFormat_f_pullunquoteEllipses( sText )
	htmlFormat_f_pullunquoteEllipses = vbLF & "..." & vbLF
END FUNCTION

FUNCTION htmlFormat_f_pullunquoteText( sText )
	htmlFormat_f_pullunquoteText = sText
END FUNCTION


FUNCTION htmlFormatMeta_f_pullunquote( aArgs(), sText )
	IF 0 < LEN(sText) THEN
		htmlFormatMeta_f_pullunquote = EVAL( g_htmlFormat_pullunquoteFunc & "( sText )" )
	ELSE
		htmlFormatMeta_f_pullquote = ""
	END IF
END FUNCTION

FUNCTION htmlFormatMeta_f_pullquoteText( sAlign, sWidth, sText )
	DIM	xWidth
	DIM	xAlign
	DIM	sOutput
	DIM	sUnquote
	IF 0 < LEN(sAlign) THEN
		xAlign = sAlign
	ELSE
		xAlign = " align=""right"""
	END IF
	IF 0 < LEN(sWidth) THEN
		xWidth = sWidth
	ELSE
		xWidth = " width=""100"""
	END IF
	sUnquote = g_htmlFormat_pullunquoteFunc
	g_htmlFormat_pullunquoteFunc = "htmlFormat_f_pullunquoteEllipses"
	sOutput = "" _
			&	"<table border=""1"" cellpadding=""2"" cellspacing=""0""" & xWidth & xAlign & " class=""htmlformatpullquote"">" _
			&	"<tr>" _
			&	"<th class=""htmlformatpullquote"">" & htmlFormatMeta(sText) & "</th>" _
			&	"</tr>" _
			&	"</table> "
	g_htmlFormat_pullunquoteFunc = sUnquote
	htmlFormatMeta_f_pullquoteText = sOutput
END FUNCTION


FUNCTION htmlFormatMeta_f_pullquote( aArgs(), sText )
	IF 0 < LEN(sText) THEN
		DIM	sAlign
		DIM	sWidth
		DIM	sBorder
		DIM	sColor
	
		sAlign = ""
		sWidth = ""
		sBorder = ""
		sColor = ""
		IF htmlFormatMeta_f_args( sAlign, sBorder, sWidth, sColor, aArgs, 1 ) THEN
			htmlFormatMeta_f_pullquote = EVAL( g_htmlFormat_pullquoteFunc & "( sAlign, sWidth, sText )" ) & sText
		ELSE
			htmlFormatMeta_f_pullquote = ""
		END IF
	ELSE
		htmlFormatMeta_f_pullquote = " "
	END IF
END FUNCTION


FUNCTION htmlFormatMeta_f_pictureFile( sName )
	htmlFormatMeta_f_pictureFile = ""
END FUNCTION


FUNCTION htmlFormatMeta_f_picture( aArgs(), sText )
	DIM	sOutput
	DIM	sFile
	DIM	sAlign
	DIM	sWidth
	DIM	sBorder
	DIM	sColor
	DIM	sTWidth
	
	sAlign = ""
	sWidth = ""
	sBorder = ""
	sColor = ""
	sTWidth = ""
	
	sOutput = ""
	IF 0 < UBOUND(aArgs) THEN
		sFile = EVAL( g_htmlFormat_pictureFunc & "( aArgs(1) )" )
		IF 0 < LEN(sFile) THEN
			IF htmlFormatMeta_f_args( sAlign, sBorder, sWidth, sColor, aArgs, 2 ) THEN
				IF 0 < LEN(sText) THEN
					IF 0 = LEN(sBorder) THEN sBorder = " border=""0"""
					'IF 0 < INSTR(1,sWidth,"%",vbTextCompare) THEN sWidth = ""
					IF 0 < LEN(sWidth) THEN
						IF 0 < INSTR(1,sWidth,"%",vbTextCompare) THEN
							sTWidth = " width=""1"""
							sWidth = ""
						ELSE
							sTWidth = " width=""1"""
						END IF
					ELSE
						sTWidth = " width=""1"""
					END IF
					sOutput = "" _
						&	"<table cellpadding=""2"" cellspacing=""0""" & sBorder & sTWidth & sAlign & " class=""htmlformatpicture"">" _
						&	"<tr>" _
						&	"<td align=""center"">" _
						&	"<img src=""" & sFile & """" & sWidth & "></td>" _
						&	"</tr>" _
						&	"<tr>" _
						&	"<td align=""center"" class=""htmlformatcaption"">" & sText & "</td>" _
						&	"</tr>" _
						&	"</table>"
				ELSE
					sOutput = "<img src=""" & sFile & """" & sAlign & sWidth & sBorder &  ">"
				END IF
			END IF
		END IF
	END IF
	htmlFormatMeta_f_picture = sOutput
END FUNCTION


FUNCTION htmlFormatMeta_f_link( aArgs(), sText )
	IF UBOUND(aArgs) = 1 THEN
		htmlFormatMeta_f_link = "<a href=""" & aArgs(1) & """>" & sText & "</a>"
	ELSE
		htmlFormatMeta_f_link = htmlFormatMeta_fail( aArgs, sText )
	END IF
END FUNCTION


FUNCTION htmlFormatMeta_f_fontName( sName )
	DIM	i
	i = INSTR( 1, sName, "_" )
	IF 0 < i THEN
		htmlFormatMeta_f_fontName = "'" & REPLACE( sName, "_", " " ) & "'"
	ELSE
		htmlFormatMeta_f_fontName = sName
	END IF
END FUNCTION

FUNCTION htmlFormatMeta_f_font( aArgs(), sText )
	IF UBOUND(aArgs) = 1 THEN
		DIM	sFonts
		DIM	sFont
		DIM	aFonts
		aFonts = SPLIT( aArgs(1), "," )
		sFonts = ""
		FOR EACH sFont IN aFonts
			sFonts = "," & htmlFormatMeta_f_fontName( sFont )
		NEXT 'sFont
		htmlFormatMeta_f_font = "<span style=""font-family:" & MID(sFonts,2) & """>" & sText & "</span>"
	ELSE
		htmlFormatMeta_f_font = htmlFormatMeta_fail( aArgs, sText )
	END IF
END FUNCTION


FUNCTION htmlFormatMeta_f_comment( aArgs(), sText )
	IF UBOUND(aArgs) < 1 THEN
		htmlFormatMeta_f_comment = " "
	ELSE
		htmlFormatMeta_f_comment = htmlFormatMeta_fail( aArgs, sText )
	END IF
END FUNCTION


FUNCTION privateHtmlFormatMetaSubsFunc( aArgs, sGenText )
	privateHtmlFormatMetaSubsFunc = ""
END FUNCTION

FUNCTION htmlFormatMetaSubsFunc( sText )
	DIM	i
	DIM	sTag
	DIM	sGenText
	DIM	sTemp
	IF 2 < LEN(sText) THEN
		i = INSTR(1,sText,":",vbTextCompare)
		IF 0 < i THEN
			sTag = TRIM(LEFT(sText,i-1))
			sGenText = TRIM(MID(sText,i+1))
		ELSE
			sTag = TRIM(sText)
			sGenText = ""
		END IF
		aFormatSplit = SPLIT( sTag, " ", -1, vbTextCompare )
		IF "" <> g_htmlFormat_metaSubsFunc THEN
			htmlFormatMetaSubsFunc = EVAL( g_htmlFormat_metaSubsFunc & "( aFormatSplit, sGenText )" )
		ELSE
			htmlFormatMetaSubsFunc = ""
		END IF
		IF "" = htmlFormatMetaSubsFunc THEN
		SELECT CASE LCASE( aFormatSplit(0) )
		CASE "picture", "pict", "image", "img"
			htmlFormatMetaSubsFunc = htmlFormatMeta_f_picture( aFormatSplit, sGenText )
		CASE "b", "bold"
			htmlFormatMetaSubsFunc = htmlFormatMeta_f_bold( aFormatSplit, sGenText )
		CASE "i", "italics", "italic"
			htmlFormatMetaSubsFunc = htmlFormatMeta_f_italic( aFormatSplit, sGenText )
		CASE "u", "underline", "underlined", "_"
			htmlFormatMetaSubsFunc = htmlFormatMeta_f_underline( aFormatSplit, sGenText )
		CASE "big", "large"
			htmlFormatMetaSubsFunc = htmlFormatMeta_f_big( aFormatSplit, sGenText )
		CASE "small"
			htmlFormatMetaSubsFunc = htmlFormatMeta_f_small( aFormatSplit, sGenText )
		CASE "style"
			htmlFormatMetaSubsFunc = htmlFormatMeta_f_style( aFormatSplit, sGenText )
		CASE "pullquote", "quote", "q"
			htmlFormatMetaSubsFunc = htmlFormatMeta_f_pullquote( aFormatSplit, sGenText )
		CASE "unquote", "uq", "...", "�"
			htmlFormatMetaSubsFunc = htmlFormatMeta_f_pullunquote( aFormatSplit, sGenText )
		CASE "sidebar", "block"
			htmlFormatMetaSubsFunc = htmlFormatMeta_f_sidebar( aFormatSplit, sGenText )
		CASE "href", "link"
			htmlFormatMetaSubsFunc = htmlFormatMeta_f_link( aFormatSplit, sGenText )
		CASE "font"
			htmlFormatMetaSubsFunc = htmlFormatMeta_f_font( aFormatSplit, sGenText )
		CASE "!", "comment"
			htmlFormatMetaSubsFunc = htmlFormatMeta_f_comment( aFormatSplit, sGenText )
		CASE ELSE
			sTemp = htmlFormatMetaColorName( aFormatSplit(0) )
			IF 0 < LEN(sTemp) THEN
				htmlFormatMetaSubsFunc = htmlFormatMeta_f_color( aFormatSplit, sGenText )
			ELSE
				htmlFormatMetaSubsFunc = ""
			END IF
		END SELECT
		END IF
	ELSE
		htmlFormatMetaSubsFunc = ""
	END IF
END FUNCTION


FUNCTION htmlFormatMeta( sText )
	DIM	sOutput
	DIM	sSubs
	DIM	i, j, k
	DIM	ix
	DIM	iLinkStart
	DIM	iLinkEnd

	sOutput = ""

	i = 1
	DO
		ix = INSTR( i, sText, "{{", vbTextCompare )
		IF ix < 1 THEN EXIT DO
		
		iLinkStart = ix
		iLinkEnd = INSTR( iLinkStart, sText, "}}", vbTextCompare )
		IF 0 < iLinkEnd THEN
			j = iLinkStart
			DO
				ix = INSTR( j+2, sText, "{{", vbTextCompare )
				IF ix < 1 THEN EXIT DO
				IF iLinkEnd < ix THEN EXIT DO
				k = INSTR( iLinkEnd+2, sText, "}}", vbTextCompare )
				IF k < 1 THEN EXIT DO
				j = ix
				iLinkEnd = k
			LOOP

			sOutput = sOutput & MID(sText,i,iLinkStart-i)
			iLinkStart = iLinkStart + 2
			sSubs = htmlFormatMetaSubsFunc( MID(sText,iLinkStart,iLinkEnd-iLinkStart) )
			IF 0 < LEN(sSubs) THEN
				sOutput = sOutput & htmlFormatMeta( sSubs )
			ELSE
				sOutput = sOutput & MID(sText,iLinkStart-2,iLinkEnd-iLinkStart+4)
			END IF
			i = iLinkEnd + 2
		ELSE
			iLinkStart = iLinkStart + 2
			sOutput = sOutput & MID(sText,i, iLinkStart-i)
			i = iLinkStart
		END IF

	LOOP
	htmlFormatMeta = sOutput & MID(sText,i)
END FUNCTION


FUNCTION htmlFormat_matchRegExp( BYREF sLine, BYREF oRegOL )

	DIM	oMatchList
	DIM	oMatch

	htmlFormat_matchRegExp = 0
	IF 0 < LEN(sLine) THEN
		SET oMatchList = oRegOL.Execute( sLine )
		IF 0 < oMatchList.Count THEN
			SET oMatch = oMatchList.Item(0)
			htmlFormat_matchRegExp = oMatch.Length
		END IF
	END IF
END FUNCTION


FUNCTION htmlFormat_trimRegExp( BYREF sLine, BYREF oReg )
	DIM	n
	
	n = htmlFormat_matchRegExp( sLine, oReg )
	IF 0 < n THEN
		htmlFormat_trimRegExp = TRIM(MID(sLine,n))
	ELSE
		htmlFormat_trimRegExp = TRIM(sLine)
	END IF
END FUNCTION


PUBLIC aFormatSplit
FUNCTION htmlFormat( BYREF sText )
	DIM	i,j,n,m
	DIM	nPrev
	DIM	state
	DIM	sTemp
	DIM	sLine
	DIM	nItemCount
	DIM	sFirstItemHold
	DIM	oRegOL
	DIM	oReg1
	DIM	oRegA
	DIM	oRegOLa
	DIM	oRegDashList
	DIM	oRegSpaces
	DIM	oRegList
	
	SET oRegOL = new RegExp
	oRegOL.Pattern = "^(\&nbsp;| )*\d+(\.\s*\).|\.[^,\d]|\).|\s+.)"
	oRegOL.Global = FALSE
	
	SET oReg1 = new RegExp
	oReg1.Pattern = "^(\&nbsp;| )*1(\.\s*\).|\.[^,\d]|\).)"
	oReg1.Global = FALSE
	
	SET oRegA = new RegExp
	oRegA.Pattern = "^(\&nbsp;| )*a[\)\.]."
	oRegA.Global = FALSE
	oRegA.IgnoreCase = TRUE
	
	SET oRegOLa = new RegExp
	oRegOLa.Pattern = "^(\&nbsp;| )*[b-z][\)\.]."
	oRegOLa.Global = FALSE
	oRegOLa.IgnoreCase = TRUE
	
	SET oRegDashList = new RegExp
	oRegDashList.Pattern = "^(\&nbsp;| )*-[^\d-]."
	oRegDashList.Global = FALSE
	oRegDashList.IgnoreCase = TRUE
	
	SET oRegSpaces = new RegExp
	oRegSpaces.Pattern = "^(\&nbsp;| )+"
	oRegSpaces.Global = FALSE
	
	sTemp = htmlFormatEncodeText( sText )
	IF 0 < INSTR(1,sText,"{{",vbTextCompare) THEN sTemp = htmlFormatMeta( sTemp )
	
	htmlFormat = ""
	aFormatSplit = SPLIT( sTemp & vbLF, vbLF, -1, vbTextCompare )
	
	state = ""
	j = 5000
	FOR i = LBOUND(aFormatSplit) TO UBOUND(aFormatSplit)
		sLine = htmlFormat_trimRegExp( aFormatSplit(i), oRegSpaces )
		sTemp = LEFT(sLine,1)
		SELECT CASE state
		CASE "p"
			IF "" = sLine THEN
				htmlFormat = htmlFormat & htmlFormatEncodeP( aFormatSplit, j, i-1 )
				state = ""
				j = 5000
			END IF
		CASE "*"
			IF "*" <> sTemp THEN
				IF "" = sLine THEN
					htmlFormat = htmlFormat & htmlFormatEncodeLI( aFormatSplit, j, i-1, "ul", "*" )
					state = ""
					j = 5000
				END IF
			ELSE
				aFormatSplit(i) = sLine
			END IF
		CASE "-"
			IF 0 < htmlFormat_matchRegExp( sLine, oRegDashList ) THEN
				nItemCount = nItemCount + 1
				aFormatSplit(i) = sLine
			ELSE
				IF "" = sLine THEN
					IF 1 < nItemCount THEN
						htmlFormat = htmlFormat & htmlFormatEncodeLI( aFormatSplit, j, i-1, "ul", "-" )
					ELSE
						htmlFormat = htmlFormat & htmlFormatEncodeP( aFormatSplit, j, i-1 )
					END IF
					state = ""
					nItemCount = 0
					j = 5000
				END IF
			END IF
		CASE "#"
			IF "#" <> sTemp THEN
				IF "" = sLine THEN
					IF 1 < nItemCount THEN
						htmlFormat = htmlFormat & htmlFormatEncodeLI( aFormatSplit, j, i-1, "ol", "#" )
					ELSE
						htmlFormat = htmlFormat & htmlFormatEncodeP( aFormatSplit, j, i-1 )
					END IF
					state = ""
					nItemCount = 0
					j = 5000
				END IF
			ELSE
				nItemCount = nItemCount + 1
				aFormatSplit(i) = sLine
			END IF
		CASE "%"
			IF "%" <> sTemp THEN
				IF "" = sLine THEN
					IF 1 < nItemCount THEN
						htmlFormat = htmlFormat & htmlFormatEncodeLI( aFormatSplit, j, i-1, "ol", "%" )
					ELSE
						htmlFormat = htmlFormat & htmlFormatEncodeP( aFormatSplit, j, i-1 )
					END IF
					nItemCount = 0
					state = ""
					j = 5000
				END IF
			ELSE
				nItemCount = nItemCount + 1
				aFormatSplit(i) = sLine
			END IF
		CASE "]"
			IF "]" <> sTemp THEN
				IF "" = sLine THEN
					htmlFormat = htmlFormat & htmlFormatEncodePindent( aFormatSplit, j, i-1 )
					state = ""
					j = 5000
				END IF
			ELSE
				aFormatSplit(i) = sLine
			END IF
		CASE "^"
			IF "" = sLine THEN
				htmlFormat = htmlFormat & htmlFormatEncodePcenter( aFormatSplit, j, i-1 )
				state = ""
				j = 5000
			END IF
		CASE "1)"
			n = htmlFormat_matchRegExp( sLine, oRegOL )
			IF 0 = n THEN
				IF "" = sLine THEN
					IF 1 < nItemCount THEN
						SET oRegList = oRegA
						FOR m = nPrev+1 TO i-1
							n = htmlFormat_matchRegExp( aFormatSplit(m), oRegList )
							IF 0 < n THEN
								SET oRegList = oRegOLa
								sTemp = MID(aFormatSplit(m),n)
								aFormatSplit(m) = "##" & htmlFormat_trimRegExp( sTemp, oRegSpaces )
							END IF
						NEXT 'm
						htmlFormat = htmlFormat & htmlFormatEncodeLI( aFormatSplit, j, i-1, "ol", "#" )
					ELSE
						aFormatSplit(j) = sFirstItemHold & " " & MID(aFormatSplit(j),2)
						htmlFormat = htmlFormat & htmlFormatEncodeP( aFormatSplit, j, i-1 )
					END IF
					state = ""
					nItemCount = 0
					j = 5000
				END IF
			ELSEIF 0 < n THEN
				nItemCount = nItemCount + 1
				sTemp = MID(sLine,n)
				aFormatSplit(i) = "#" & htmlFormat_trimRegExp( sTemp, oRegSpaces )
				SET oRegList = oRegA
				FOR m = nPrev+1 TO i-1
					n = htmlFormat_matchRegExp( aFormatSplit(m), oRegList )
					IF 0 < n THEN
						SET oRegList = oRegOLa
						sTemp = MID(aFormatSplit(m),n)
						aFormatSplit(m) = "##" & htmlFormat_trimRegExp( sTemp, oRegSpaces )
					END IF
				NEXT 'm
				nPrev = i
			END IF
		CASE "a)"
			n = htmlFormat_matchRegExp( sLine, oRegOLa )
			IF 0 = n THEN
				IF "" = sLine THEN
					IF 1 < nItemCount THEN
						htmlFormat = htmlFormat & htmlFormatEncodeLI( aFormatSplit, j, i-1, "ol", "@" )
					ELSE
						aFormatSplit(j) = sFirstItemHold & " " & MID(aFormatSplit(j),2)
						htmlFormat = htmlFormat & htmlFormatEncodeP( aFormatSplit, j, i-1 )
					END IF
					state = ""
					nItemCount = 0
					j = 5000
				END IF
			ELSEIF 0 < n THEN
				nItemCount = nItemCount + 1
				sTemp = MID(sLine,n)
				aFormatSplit(i) = "@" & htmlFormat_trimRegExp( sTemp, oRegSpaces )
			END IF
		CASE "h"
			IF "" = sLine THEN
				htmlFormat = htmlFormat & htmlFormatEncodeH( aFormatSplit, j, i-1 )
				state = ""
				j = 5000
			END IF
		CASE "table"
			IF "" = sLine THEN
				htmlFormat = htmlFormat & htmlFormatEncodeTable( aFormatSplit, j, i-1 )
				state = ""
				j = 5000
			END IF
		CASE ELSE
			IF "" = sLine THEN
				state = ""
				nItemCount = 0
				j = 5000
			ELSEIF "*" = sTemp  _
					AND  (NOT(gHtmlOption_starListSupport)  OR  LEFT(sLine,3) <> STRING( 3, "*" ) ) THEN
				state = "*"
				nItemCount = 1
				j = i
				aFormatSplit(i) = sLine
			ELSEIF "-" = sTemp _
					AND  0 < htmlFormat_matchRegExp( sLine, oRegDashList ) THEN
				state = "-"
				nItemCount = 1
				j = i
				aFormatSplit(i) = sLine
			ELSEIF "-" = sTemp  AND  htmlFormatJustDashes(sLine,"-") THEN
				htmlFormat = htmlFormat & "<hr class=""htmlformat"">" & vbCRLF
				state = ""
				nItemCount = 0
				j = 5000
			ELSEIF "=" = sTemp  AND  htmlFormatJustDashes(sLine,"=") THEN
				htmlFormat = htmlFormat & "<hr size=""6"" class=""htmlformat"">" & vbCRLF
				state = ""
				nItemCount = 0
				j = 5000
			ELSEIF "#" = sTemp  _
					AND  (NOT(gHtmlOption_starListSupport)  OR  LEFT(sLine,3) <> STRING( 3, "#" ) ) THEN
				state = "#"
				nItemCount = 1
				j = i
				aFormatSplit(i) = sLine
			ELSEIF "%" = sTemp _
					AND  (NOT(gHtmlOption_starListSupport)  OR  LEFT(sLine,3) <> STRING(3,"%")) THEN
				state = "%"
				nItemCount = 1
				j = i
				aFormatSplit(i) = sLine
			ELSEIF "]" = sTemp _
					AND  (NOT(gHtmlOption_starListSupport)  OR  LEFT(sLine,3) <> STRING(3,"]")) THEN
				state = "]"
				j = i
				aFormatSplit(i) = sLine
			ELSEIF "!" = sTemp THEN
				'htmlFormat = htmlFormat & htmlFormatEncodeH( sLine )
				state = "h"
				j = i
			ELSEIF "^" = sTemp THEN
				state = "^"
				j = i
			ELSEIF "|" = sTemp THEN
				state = "table"
				j = i
			ELSEIF "\" = sLine THEN
				htmlFormat = htmlFormat & "<br clear=""all"">" & vbCRLF
				state = ""
				j = 5000
			ELSEIF "/" = sLine THEN
				htmlFormat = htmlFormat & "<br>" & vbCRLF
				state = ""
				j = 5000
			ELSE
				n = htmlFormat_matchRegExp( sLine, oReg1 )
				IF 0 < n THEN
					state = "1)"
					nItemCount = 1
					j = i
					nPrev = i
					sFirstItemHold = LEFT(sLine,n-1)
					sTemp = MID(sLine,n)
					aFormatSplit(i) = "#" & htmlFormat_trimRegExp( sTemp, oRegSpaces )
				ELSE
					n = htmlFormat_matchRegExp( sLine, oRegA )
					IF 0 < n THEN
						state = "a)"
						nItemCount = 1
						j = i
						nPrev = i
						sFirstItemHold = LEFT(sLine,n-1)
						sTemp = MID(sLine,n)
						aFormatSplit(i) = "@" & htmlFormat_trimRegExp( sTemp, oRegSpaces )
					ELSE
						state = "p"
						j = i
					END IF
				END IF
			END IF
		END SELECT
	NEXT 'i
	SET oRegOL = Nothing
	SET oReg1 = Nothing
	SET oRegA = Nothing
	SET oRegOLa = Nothing
	SET oRegDashList = Nothing
	SET oRegSpaces = Nothing
END FUNCTION


FUNCTION htmlFormatCRLF( sText )
	DIM	sString
	
	sString = REPLACE( sText, vbCRLF, vbLF, 1, -1, vbTextCompare )
	sString = REPLACE( sString, vbCR, vbLF, 1, -1, vbTextCompare )
	
	htmlFormatCRLF = htmlFormat( sString )
END FUNCTION


%>