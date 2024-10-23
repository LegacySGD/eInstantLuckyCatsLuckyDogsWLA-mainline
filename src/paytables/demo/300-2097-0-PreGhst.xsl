<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
    <xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl"/>
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl"/>

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />
			
			<!--
			TEMPLATE
			Match:
			-->
			<x:template match="/">
				<x:apply-templates select="*"/>
				<x:apply-templates select="/output/root[position()=last()]" mode="last"/>
				<br/>
			</x:template>
			<lxslt:component prefix="my-ext" functions="formatJson retrievePrizeTable">
				<lxslt:script lang="javascript">
					<![CDATA[
function formatJson(jsonContext, translations, prizeValues, prizeNamesDesc) {
	var scenario = getScenario(jsonContext);
	var result = new ScenarioConvertor(scenario).convert();

	var tranMap = parseTranslations(translations);
	var prizeMap = parsePrizes(prizeNamesDesc, prizeValues);

	var r = [];
	r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
	r.push('<tr>');
	r.push('<th class="tablehead">');
	r.push(tranMap["symbol"]);
	r.push('</th>');
	r.push('<th class="tablehead">');
	r.push(tranMap["prizeValue"]);
	r.push('</th>');
	r.push('</tr>');
	var arr = result.baseSymbol.split(",");
	arr.forEach(function (e) {
		r.push('<tr>');
		r.push('<td style="padding-right:10px" class="tablebody" align="center">');
		r.push(tranMap[e]);
		r.push('</td>');
		r.push('<td style="padding-right:10px" class="tablebody" align="center">');
		if ("X" === e) {
			r.push(prizeMap[result.bonusSymbol]);
		} else {
			r.push(prizeMap[e]);
		}
		r.push('</td>');
		r.push('</tr>');
	});
	r.push('</table>');

	r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable" >');
	r.push('<tr>');
	r.push('<th class="tablehead" colspan="2">');
	if (result.baseWin) {
		r.push(tranMap["baseWin"]);
	} else {
		r.push(tranMap["noBaseWin"]);
	}
	r.push('</th>');
	r.push('</tr>');
	if (result.baseWin) {
		for (var key in result.baseWinSymbol) {
			r.push('<tr>');
			r.push('<td style="padding-right:10px" class="tablebody" align="center">');
			r.push(tranMap[key]);
			r.push('</td>');
			r.push('<td style="padding-right:10px" class="tablebody" align="center">');
			r.push(prizeMap[key]);
			r.push('</td>');
			r.push('</tr>');
		}
	}
	r.push('</table>');

	r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
	r.push('<tr>');
	r.push('<th class="tablehead" colspan="2">');
	if (result.bonusWin) {
		r.push(tranMap["bonusWin"]);
	} else {
		r.push(tranMap["noBonusWin"]);
	}
	r.push('</th>');
	r.push('</tr>');
	if (result.bonusWin) {
		r.push('<tr>');
		r.push('<td style="padding-right:10px" class="tablebody" align="center">');
		r.push(tranMap["X"]);
		r.push('</td>');
		r.push('<td style="padding-right:10px" class="tablebody" align="center">');
		if (result.bonusWin) {
			r.push(prizeMap[result.bonusSymbol] + " * " + result.bonusMultiple);
		}
		r.push('</td>');
		r.push('</tr>');
	}
	r.push('</table>');

	return r.join('');
}
function getScenario(jsonContext) {
	var jsObj = JSON.parse(jsonContext);
	var scenario = jsObj.scenario;
	scenario = scenario.replace(/\0/g, '');
	return scenario;
}
function parsePrizes(prizeNamesDesc, prizeValues) {
	var prizeNames = (prizeNamesDesc.substring(1)).split(',');
	var convertedPrizeValues = (prizeValues.substring(1)).split('|');
	var map = [];
	for (var idx = 0; idx < prizeNames.length; idx++) {
		map[prizeNames[idx]] = convertedPrizeValues[idx];
	}
	return map;
}
function parseTranslations(translationNodeSet) {
	var map = [];
	var list = translationNodeSet.item(0).getChildNodes();
	for (var idx = 1; idx < list.getLength(); idx++) {
		var childNode = list.item(idx);
		if (childNode.name == "phrase") {
			map[childNode.getAttribute("key")] = childNode.getAttribute("value");
		}
	}
	return map;
}

function ScenarioConvertor(scenario) {
	function _parseSymbol(symbolArr) {
		var map = {"A": 0, "B": 0, "C": 0, "D": 0, "E": 0, "F": 0, "X": 0};
		symbolArr.forEach(function (e) {
			map[e]++;
		});
		return map;
	}
	function _parseWinSymbol(map) {
		var baseWin = false, bonusWin = false;
		var baseWinSymbol = {}, bonusMultiple = 0;
		["A", "B", "C", "D", "E", "F"].forEach(function (e) {
			if (map[e] === 3) {
				baseWin = true;
				baseWinSymbol[e] = map[e];
			}
		});
		if (map["X"] > 0) {
			bonusWin = true;
			bonusMultiple = map["X"];
		}
		return {baseWin: baseWin, baseWinSymbol: baseWinSymbol, bonusWin: bonusWin, bonusMultiple: bonusMultiple};
	}
	function _convertBonusSymbol(bonusSymbol) {
		var arr = ["IW1", "IW2", "IW3", "IW4", "IW5", "IW6"];
		var idx = bonusSymbol - 1;
		return arr[idx];
	}
	function _convert() {
		var ticketArr = scenario.split("|");
		var baseSymbol = ticketArr[0];
		var bonusSymbol = ticketArr[1];
		var baseSymbolArr = baseSymbol.split(",");
		var bonusNumber = parseInt(bonusSymbol);

		var result = _parseWinSymbol(_parseSymbol(baseSymbolArr));
		result.baseSymbol = baseSymbol;
		result.bonusSymbol = _convertBonusSymbol(bonusNumber);
		return result;
	}
	return {
		convert: _convert
	};
}
					]]>
				</lxslt:script>
			</lxslt:component>
			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit"/>
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount"/>
								<x:with-param name="code" select="/output/denom/currencycode"/>
								<x:with-param name="locale" select="//translation/@language"/>
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit"/>
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode"/>
								<x:with-param name="locale" select="//translation/@language"/>
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>
		
			<!--
			TEMPLATE
			Match:		digested/game
			-->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="History.Detail" />
				</x:if>
				<x:if test="OutcomeDetail/Stage = 'Wager' and OutcomeDetail/NextStage = 'Wager'">
					<x:call-template name="History.Detail" />
				</x:if>
			</x:template>
		
			<!--
			TEMPLATE
			Name:		Wager.Detail (base game)
			-->
			<x:template name="History.Detail">
				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value"/>
							<x:value-of select="': '"/>
							<x:value-of select="OutcomeDetail/RngTxnId"/>
						</td>
					</tr>
				</table>
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>
				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>
				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>
		
			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>
			
			<x:template match="text()"/>
			
		</x:stylesheet>
	</xsl:template>
	
	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
		    <clickcount>
		        <x:value-of select="."/>
		    </clickcount>
		</x:template>
		<x:template match="*|@*|text()">
		    <x:apply-templates/>
		</x:template>
	</xsl:template>
	
</xsl:stylesheet>
