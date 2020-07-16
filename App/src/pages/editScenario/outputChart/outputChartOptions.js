import adapterService from '../../../adapterService/adapterService'
import Highcharts from 'highcharts'
import variwide from 'highcharts/modules/variwide'

variwide(Highcharts)

const colorMap = [
	"#DD5757",
	"#FF8224",
	"#2AD1D1",
	"#33A3FF",
	"#9471FF"
]

export const getOutputChartOptions = (props, scenarioObject, height = null) => {

	// Create map of columns data
	const columnsMap = props.length === 2 && adapterService.getObjOfTable(props[0], 'NAME')

	const hospLine = []
	const dialLine = []
	const ventLine = []
	const icuLine = []
	const ecmoLine = []

	const hospRange = []
	const dialRange = []
	const ventRange = []
	const icuRange = []
	const ecmoRange = []

	// This condition is set because of previus structure of chart data
	props.length === 2 && props[1].forEach(item => {
		let timestamp = new Date(adapterService.fromSasDateTime(item[columnsMap.DATETIME.VARNUM])).getTime()
		// HOSP
		hospLine.push([
			timestamp,
			item[columnsMap.HOSPITAL_OCCUPANCY.VARNUM]
		])
		hospRange.push({
			x: timestamp,
			low: item[columnsMap.LOWER_HOSPITAL_OCCUPANCY.VARNUM],
			high: item[columnsMap.UPPER_HOSPITAL_OCCUPANCY.VARNUM]
		})

		// DIAL
		dialLine.push([
			timestamp,
			item[columnsMap.DIAL_OCCUPANCY.VARNUM]
		])
		dialRange.push({
			x: timestamp,
			low: item[columnsMap.LOWER_DIAL_OCCUPANCY.VARNUM],
			high: item[columnsMap.UPPER_DIAL_OCCUPANCY.VARNUM]
		})

		// VENT
		ventLine.push([
			timestamp,
			item[columnsMap.VENT_OCCUPANCY.VARNUM]
		])
		ventRange.push({
			x: timestamp,
			low: item[columnsMap.LOWER_VENT_OCCUPANCY.VARNUM],
			high: item[columnsMap.UPPER_VENT_OCCUPANCY.VARNUM]
		})

		// ICU
		icuLine.push([
			timestamp,
			item[columnsMap.ICU_OCCUPANCY.VARNUM]
		])
		icuRange.push({
			x: timestamp,
			low: item[columnsMap.LOWER_ICU_OCCUPANCY.VARNUM],
			high: item[columnsMap.UPPER_ICU_OCCUPANCY.VARNUM]
		})

		// ECMO
		ecmoLine.push([
			timestamp,
			item[columnsMap.ECMO_OCCUPANCY.VARNUM]
		])
		ecmoRange.push({
			x: timestamp,
			low: item[columnsMap.LOWER_ECMO_OCCUPANCY.VARNUM],
			high: item[columnsMap.UPPER_ECMO_OCCUPANCY.VARNUM]
		})
	})

	const optionsArray = []
	const smallChartFontSize = "8px";
	const bigChartFontSize = "12px";
	let options = {
		height: height,
		color: colorMap,
		index:0,
		isXaxisVisible: false,
		fontSize: bigChartFontSize,
		scenario: scenarioObject
	}
	optionsArray[0] = getChartOptions(
		{ name: 'Hospital Census Line', data: hospLine },
		{ name: 'Hospital Census', data: hospRange }, options)
	options.index = 1
	options.isXaxisVisible = true
	optionsArray[1] = getChartOptions(
		{ name: 'Hospital Census - ICU Line', data: icuLine },
		{ name: 'Hospital Census - ICU', data: icuRange }, options)
	options.height = height * 2 / 3
	options.index = 2
	options.isXaxisVisible = false
	options.fontSize = smallChartFontSize
	options.scenario = null
	optionsArray[2] = getChartOptions(
		{ name: 'Hospital Census - Ventilator Line', data: ventLine },
		{ name: 'Hospital Census - Ventilator', data: ventRange }, options)
	options.index = 3
	optionsArray[3] = getChartOptions(
		{ name: 'Hospital Census - ECMO Line', data: ecmoLine },
		{ name: 'Hospital Census - ECMO', data: ecmoRange }, options)
	options.index = 4
	optionsArray[4] = getChartOptions(
		{ name: 'Hospital Census - Dialysis Line', data: dialLine },
		{ name: 'Hospital Census - Dialysis', data: dialRange }, options)

	return optionsArray
}

export default getOutputChartOptions

// function rotate(array, times) {
// 	const arrayClone = JSON.parse(JSON.stringify(array))
// 	while (times--) {
// 		arrayClone.push(arrayClone.shift())
// 	}
// 	return arrayClone
// }

function syncExtremes(e) {
	const thisChart = this.chart;
	if (e.trigger !== 'syncExtremes') { // Prevent feedback loop
		Highcharts.each(Highcharts.charts, function (chart) {
			if (chart !== thisChart) {
				if (chart.xAxis[0].setExtremes) { // It is null while updating
					chart.xAxis[0].setExtremes(
						e.min,
						e.max,
						undefined,
						false,
						{ trigger: 'syncExtremes' }
					);
				}
			}
		});
	}
}


function getChartOptions(line, range, options) {
	const height = options.height;
	const index=options.index
	const colors = options.color[index]
	const isXaxisVisible = options.isXaxisVisible
	const fontSize = options.fontSize
	const scenarioObject = options.scenario
	let variwideSeries = {
		showInLegend: false
	}
	let secondaryYAxis = {
		title: {
			enabled: false
		}
	}
	let xAxis = {
		type: "datetime",
		index: 0,
		isX: true,
		labels: {
			enabled: isXaxisVisible
		}
	}
	if (!!scenarioObject) {
		const [change1, change2, change3, change4] = scenarioObject.rangeValue
		const [d1, d2, d3, d4, d5] = scenarioObject.distancing
		const maxDay = scenarioObject.zeroDay + scenarioObject.nDays * scenarioObject.day
		const zeroDay = scenarioObject.zeroDay
		xAxis.min = zeroDay
		xAxis.max = maxDay
		variwideSeries =
		{
			name: 'Distancing',
			yAxis: 1,
			type: 'variwide',
			zIndex: -9999,
			data: [
				{
					x: zeroDay,
					y: d1,
					z: change1 - zeroDay,
					name: "SocialDistancing",
				},
				{
					x: change1,
					y: d2,
					z: change2 - change1,
					name: "SocialDistancingChange",
				},
				{
					x: change2,
					y: d3,
					z: change3 - change2,
					name: "SocialDistancingChangeTwo",
				},
				{
					x: change3,
					y: d4,
					z: change4 - change3,
					name: "SocialDistancingChange3",
				},

				{
					x: change4,
					y: d5,
					z: maxDay - change4,
					name: "SocialDistancingChange4",
				},

			],
			color: '#f4f4f455',
			borderColor: '#f4f4f455',
			enableMouseTracking: false,
			dataLabels: {
				enabled: false
			}
		}
		secondaryYAxis = {
			gridLineWidth: 0,
			title: {
				enabled: false
			},
			labels: {
				enabled: false
			},
			min: 0,
			max: 100,
			floor: 0,
			ceiling: 100
		}
	}
	const pattern=`url(#custom-pattern-${index})`
	return {
		// MyChartData
		"series": [
			{
				"data": line.data,
				"type": "spline",
				"name": line.name,
				"zoneAxis": 'y',
				"dashStyle": 'dot',
				"color": colors,
				"zones": [{
					"value": 3000,
					"dashStyle": 'solid'
				}]
			},
			{
				"data": range.data,
				"turboThreshold": 0,
				"_symbolIndex": 0,
				"type": "arearange",
				"name": range.name,
				"color": pattern,
				"zoneAxis": 'y',
				"zones": [{
					"value": 3000,
					"dashStyle": 'solid',
					"color": colors
				}]
			},
			variwideSeries
		],
		"symbols": [
			"circle",
			"diamond",
			"square",
			"triangle",
			"triangle-down"
		],
		"lang": {
			"loading": "Loading...",
			"months": [
				"January",
				"February",
				"March",
				"April",
				"May",
				"June",
				"July",
				"August",
				"September",
				"October",
				"November",
				"December"
			],
			"shortMonths": [
				"Jan",
				"Feb",
				"Mar",
				"Apr",
				"May",
				"Jun",
				"Jul",
				"Aug",
				"Sep",
				"Oct",
				"Nov",
				"Dec"
			],
			"weekdays": [
				"Sunday",
				"Monday",
				"Tuesday",
				"Wednesday",
				"Thursday",
				"Friday",
				"Saturday"
			],
			"decimalPoint": ".",
			"numericSymbols": [
				"k",
				"M",
				"G",
				"T",
				"P",
				"E"
			],
			"resetZoom": "Reset zoom",
			"resetZoomTitle": "Reset zoom level 1:1",
			"thousandsSep": " ",
			"rangeSelectorZoom": "Zoom",
			"rangeSelectorFrom": "From",
			"rangeSelectorTo": "To",
			"zoomIn": "Zoom in",
			"zoomOut": "Zoom out",
			"viewFullscreen": "View in full screen",
			"exitFullscreen": "Exit from full screen",
			"printChart": "Print chart",
			"downloadPNG": "Download PNG image",
			"downloadJPEG": "Download JPEG image",
			"downloadPDF": "Download PDF document",
			"downloadSVG": "Download SVG vector image",
			"contextButtonTitle": "Chart context menu",
			"downloadCSV": "Download CSV",
			"downloadXLS": "Download XLS",
			"viewData": "View data table",
			"navigation": {
				"popup": {
					"simpleShapes": "Simple shapes",
					"lines": "Lines",
					"circle": "Circle",
					"rectangle": "Rectangle",
					"label": "Label",
					"shapeOptions": "Shape options",
					"typeOptions": "Details",
					"fill": "Fill",
					"format": "Text",
					"strokeWidth": "Line width",
					"stroke": "Line color",
					"title": "Title",
					"name": "Name",
					"labelOptions": "Label options",
					"labels": "Labels",
					"backgroundColor": "Background color",
					"backgroundColors": "Background colors",
					"borderColor": "Border color",
					"borderRadius": "Border radius",
					"borderWidth": "Border width",
					"style": "Style",
					"padding": "Padding",
					"fontSize": "Font size",
					"color": "Color",
					"height": "Height",
					"shapes": "Shape options",
					"segment": "Segment",
					"arrowSegment": "Arrow segment",
					"ray": "Ray",
					"arrowRay": "Arrow ray",
					"line": "Line",
					"arrowLine": "Arrow line",
					"horizontalLine": "Horizontal line",
					"verticalLine": "Vertical line",
					"crooked3": "Crooked 3 line",
					"crooked5": "Crooked 5 line",
					"elliott3": "Elliott 3 line",
					"elliott5": "Elliott 5 line",
					"verticalCounter": "Vertical counter",
					"verticalLabel": "Vertical label",
					"verticalArrow": "Vertical arrow",
					"fibonacci": "Fibonacci",
					"pitchfork": "Pitchfork",
					"parallelChannel": "Parallel channel",
					"infinityLine": "Infinity line",
					"measure": "Measure",
					"measureXY": "Measure XY",
					"measureX": "Measure X",
					"measureY": "Measure Y",
					"flags": "Flags",
					"addButton": "add",
					"saveButton": "save",
					"editButton": "edit",
					"removeButton": "remove",
					"series": "Series",
					"volume": "Volume",
					"connector": "Connector",
					"innerBackground": "Inner background",
					"outerBackground": "Outer background",
					"crosshairX": "Crosshair X",
					"crosshairY": "Crosshair Y",
					"tunnel": "Tunnel",
					"background": "Background"
				}
			},
			"stockTools": {
				"gui": {
					"simpleShapes": "Simple shapes",
					"lines": "Lines",
					"crookedLines": "Crooked lines",
					"measure": "Measure",
					"advanced": "Advanced",
					"toggleAnnotations": "Toggle annotations",
					"verticalLabels": "Vertical labels",
					"flags": "Flags",
					"zoomChange": "Zoom change",
					"typeChange": "Type change",
					"saveChart": "Save chart",
					"indicators": "Indicators",
					"currentPriceIndicator": "Current Price Indicators",
					"zoomX": "Zoom X",
					"zoomY": "Zoom Y",
					"zoomXY": "Zooom XY",
					"fullScreen": "Fullscreen",
					"typeOHLC": "OHLC",
					"typeLine": "Line",
					"typeCandlestick": "Candlestick",
					"circle": "Circle",
					"label": "Label",
					"rectangle": "Rectangle",
					"flagCirclepin": "Flag circle",
					"flagDiamondpin": "Flag diamond",
					"flagSquarepin": "Flag square",
					"flagSimplepin": "Flag simple",
					"measureXY": "Measure XY",
					"measureX": "Measure X",
					"measureY": "Measure Y",
					"segment": "Segment",
					"arrowSegment": "Arrow segment",
					"ray": "Ray",
					"arrowRay": "Arrow ray",
					"line": "Line",
					"arrowLine": "Arrow line",
					"horizontalLine": "Horizontal line",
					"verticalLine": "Vertical line",
					"infinityLine": "Infinity line",
					"crooked3": "Crooked 3 line",
					"crooked5": "Crooked 5 line",
					"elliott3": "Elliott 3 line",
					"elliott5": "Elliott 5 line",
					"verticalCounter": "Vertical counter",
					"verticalLabel": "Vertical label",
					"verticalArrow": "Vertical arrow",
					"fibonacci": "Fibonacci",
					"pitchfork": "Pitchfork",
					"parallelChannel": "Parallel channel"
				}
			}
		},
		"global": {},
		"time": {
			"timezoneOffset": 0,
			"useUTC": true
		},
		"chart": {
			"styledMode": false,
			"borderRadius": 0,
			"colorCount": 10,
			"defaultSeriesType": "line",
			"ignoreHiddenSeries": true,
			"spacing": [
				16,
				16,
				16,
				16
			],
			"resetZoomButton": {
				"theme": {
					"zIndex": 6
				},
				"position": {
					"align": "right",
					"x": -10,
					"y": 10
				}
			},
			"width": null,
			"height": height,
			"borderColor": "#335cad",
			"backgroundColor": "#ffffff",
			"plotBorderColor": "#cccccc",
			"options3d": {
				"enabled": false,
				"alpha": 0,
				"beta": 0,
				"depth": 100,
				"fitToPlot": true,
				"viewDistance": 25,
				"axisLabelPosition": null,
				"frame": {
					"visible": "default",
					"size": 1,
					"bottom": {},
					"top": {},
					"left": {},
					"right": {},
					"back": {},
					"front": {}
				}
			},
			"type": "arearange",
			"polar": false
		},
		// "title": {
		// 	"style": {
		// 		"color": "#333333",
		// 		"fontSize": "18px",
		// 		"fill": "#333333",
		// 		"width": "827px"
		// 	},
		// 	"text": "",
		// 	"align": "left",
		// 	"margin": 15,
		// 	"widthAdjust": -44,
		// 	"x": 10
		// },
		"title": {
			"style": {
				"font-family": " 'Montserrat', sans-serif",
				"font-size": "18px",
				"font-weight": "bold",
				"line-height": "18px",
				"color": "#565656",
				"letter-spacing": "0.16px"
			},
			"text": line.name,
			"align": "left",
			"margin": 40
		},
		// "subtitle": {
		// 	"style": {
		// 		"color": "#666666",
		// 		"fill": "#666666",
		// 		"width": "827px"
		// 	},
		// 	"text": "",
		// 	"align": "left",
		// 	"widthAdjust": -44,
		// 	"x": 10
		// },
		"subtitle": false,
		"caption": {
			"style": {
				"color": "#666666",
				"fill": "#666666",
				"width": "871px"
			},
			"margin": 15,
			"text": "",
			"align": "left",
			"verticalAlign": "bottom"
		},
		"plotOptions": {
			"variwide": {
				"states": {
					"hover": {
						"enabled": false,
						"opacity": 1
					},
					"inactive": {
						"opacity": 1
					}
				}
			},
			"spline": {
				"lineWidth": 2,
				"allowPointSelect": false,
				"showCheckbox": false,
				"animation": {
					"duration": 1000
				},
				"events": {},
				"marker": {
					"enabledThreshold": 2,
					"lineColor": "#ffffff",
					"lineWidth": 0,
					"radius": 4,
					"states": {
						"normal": {
							"animation": true
						},
						"hover": {
							"animation": {
								"duration": 50
							},
							"enabled": true,
							"radiusPlus": 2,
							"lineWidthPlus": 1
						},
						"select": {
							"fillColor": "#cccccc",
							"lineColor": "#000000",
							"lineWidth": 2
						}
					}
				},
				"point": {
					"events": {}
				},
				"dataLabels": {
					"align": "center",
					"padding": 5,
					"style": {
						"fontSize": "11px",
						"fontWeight": "bold",
						"color": "contrast",
						"textOutline": "1px contrast"
					},
					"verticalAlign": "bottom",
					"x": 0,
					"y": 0
				},
				"cropThreshold": 300,
				"opacity": 1,
				"pointRange": 0,
				"softThreshold": true,
				"states": {
					"normal": {
						"animation": true
					},
					"hover": {
						"animation": {
							"duration": 50
						},
						"lineWidthPlus": 1,
						"marker": {},
						"halo": {
							"size": 10,
							"opacity": 0.25
						}
					},
					"select": {
						"animation": {
							"duration": 0
						}
					},
					"inactive": {
						"animation": {
							"duration": 50
						},
						"opacity": 0.2
					}
				},
				"stickyTracking": true,
				"turboThreshold": 1000,
				"findNearestPointBy": "x"
			},
			"arearange": {
				"lineWidth": 1,
				"allowPointSelect": false,
				"showCheckbox": false,
				"animation": {
					"duration": 1000
				},
				"events": {},
				"marker": {
					"enabledThreshold": 2,
					"lineColor": "#ffffff",
					"lineWidth": 0,
					"radius": 4,
					"states": {
						"normal": {
							"animation": true
						},
						"hover": {
							"animation": {
								"duration": 50
							},
							"enabled": true,
							"radiusPlus": 2,
							"lineWidthPlus": 1
						},
						"select": {
							"fillColor": "#cccccc",
							"lineColor": "#000000",
							"lineWidth": 2
						}
					}
				},
				"point": {
					"events": {}
				},
				"dataLabels": {
					"align": null,
					"padding": 5,
					"style": {
						"fontSize": "11px",
						"fontWeight": "bold",
						"color": "contrast",
						"textOutline": "1px contrast"
					},
					"verticalAlign": null,
					"x": 0,
					"y": 0,
					"xLow": 0,
					"xHigh": 0,
					"yLow": 0,
					"yHigh": 0
				},
				"cropThreshold": 300,
				"opacity": 1,
				"pointRange": 0,
				"softThreshold": false,
				"states": {
					"normal": {
						"animation": true
					},
					"hover": {
						"animation": {
							"duration": 50
						},
						"lineWidthPlus": 1,
						"marker": {},
						"halo": {
							"size": 10,
							"opacity": 0.25
						}
					},
					"select": {
						"animation": {
							"duration": 0
						}
					},
					"inactive": {
						"animation": {
							"duration": 50
						},
						"opacity": 0.2
					}
				},
				"stickyTracking": true,
				"turboThreshold": 1000,
				"findNearestPointBy": "x",
				"threshold": null,
				"trackByArea": true,
				"grouping": false,
				"shadow": false,
			},
			"series": {
				"allowPointSelect": true,
				"states": {
					"select": {
						"color": "#EFFFEF",
						"borderColor": "black",
						"dashStyle": "dot"
					}
				},
				"marker": {
					"enabled": false
				},
				"lineWidth": 3,
				"animation": false,
				"events": {},
				"tooltip": {}
			}
		},
		"labels": {
			"style": {
				"position": "absolute",
				"color": "#333333"
			}
		},
		"legend": {
			"enabled": true,
			"padding": 8,
			"layout": "vertical",
			"backgroundColor": "#F4F4F4",
			"align": "right",
			"verticalAlign": "top",
			"floating": true,
			"x": 0,
			"y": 0,
			"alignColumns": true,
			"borderColor": "#999999",
			"borderRadius": 0,
			"navigation": {
				"activeColor": "#003399",
				"inactiveColor": "#cccccc"
			},
			"itemStyle": {
				"color": "#565656",
				"cursor": "pointer",
				"fontSize": fontSize,
				"fontWeight": "bold",
				"font-family": " 'Montserrat', sans-serif",
				"textOverflow": "ellipsis"
			},
			"itemHoverStyle": {
				"color": "#000000"
			},
			"itemHiddenStyle": {
				"color": "#cccccc"
			},
			"shadow": false,
			"itemCheckboxStyle": {
				"position": "absolute",
				"width": "13px",
				"height": "13px"
			},
			"squareSymbol": true,
			"symbolPadding": 5,
			"title": {
				"style": {
					"fontWeight": "bold"
				}
			},
			"bubbleLegend": {
				"borderWidth": 2,
				"connectorDistance": 60,
				"connectorWidth": 1,
				"enabled": false,
				"labels": {
					"allowOverlap": false,
					"format": "",
					"align": "right",
					"style": {
						"fontSize": 10
					},
					"x": 0,
					"y": 0
				},
				"maxSize": 60,
				"minSize": 10,
				"legendIndex": 0,
				"ranges": {},
				"sizeBy": "area",
				"sizeByAbsoluteValue": false,
				"zIndex": 1,
				"zThreshold": 0
			},
			"symbolRadius": 2
		},
		"loading": {
			"labelStyle": {
				"fontWeight": "bold",
				"position": "relative",
				"top": "45%"
			},
			"style": {
				"position": "absolute",
				"backgroundColor": "#ffffff",
				"opacity": 0.5,
				"textAlign": "center"
			}
		},
		"tooltip": {
			"enabled": true,
			"animation": true,
			"borderRadius": 0,
			"dateTimeLabelFormats": {
				"millisecond": "%A, %b %e, %H:%M:%S.%L",
				"second": "%A, %b %e, %H:%M:%S",
				"minute": "%A, %b %e, %H:%M",
				"hour": "%A, %b %e, %H:%M",
				"day": "%A, %b %e, %Y",
				"week": "Week from %A, %b %e, %Y",
				"month": "%B %Y",
				"year": "%Y"
			},
			"footerFormat": "",
			"padding": 8,
			"snap": 10,
			"headerFormat": "<span style=\"font-size: 10px\">{point.key}</span><br/>",
			"pointFormat": "<span style=\"color:{point.color}\">●</span> {series.name}: <b>{point.y}</b><br/>",
			"backgroundColor": "rgba(247,247,247,0.85)",
			"borderWidth": 0,
			"shadow": true,
			"style": {
				"cursor": "default",
				"fontSize": "12px",
				"whiteSpace": "nowrap",
				"font-family": " 'Montserrat', sans-serif",
				"line-height": "18px",
				"color": "#565656",
				"letter-spacing": "0.16px"
			}
		},
		"credits": {
			"enabled": false,
			"href": "https://everviz.com",
			"position": {
				"align": "right",
				"x": -10,
				"verticalAlign": "bottom",
				"y": -5
			},
			"style": {
				"cursor": "pointer",
				"color": "#999999",
				"fontSize": "9px",
				"fill": "#999999"
			},
			"text": "everviz.com"
		},
		"scrollbar": {
			"height": 14,
			"barBorderRadius": 0,
			"buttonBorderRadius": 0,
			"margin": 10,
			"minWidth": 6,
			"step": 0.2,
			"zIndex": 3,
			"barBackgroundColor": "#cccccc",
			"barBorderWidth": 1,
			"barBorderColor": "#cccccc",
			"buttonArrowColor": "#333333",
			"buttonBackgroundColor": "#e6e6e6",
			"buttonBorderColor": "#cccccc",
			"buttonBorderWidth": 1,
			"rifleColor": "#333333",
			"trackBackgroundColor": "#f2f2f2",
			"trackBorderColor": "#f2f2f2",
			"trackBorderWidth": 1
		},
		"navigator": {
			"height": 40,
			"margin": 25,
			"maskInside": true,
			"handles": {
				"width": 7,
				"height": 15,
				"symbols": [
					"navigator-handle",
					"navigator-handle"
				],
				"enabled": true,
				"lineWidth": 1,
				"backgroundColor": "#f2f2f2",
				"borderColor": "#999999"
			},
			"maskFill": "rgba(102,133,194,0.3)",
			"outlineColor": "#cccccc",
			"outlineWidth": 1,
			"series": {
				"type": "areaspline",
				"fillOpacity": 0.05,
				"lineWidth": 1,
				"compare": null,
				"dataGrouping": {
					"approximation": "average",
					"enabled": true,
					"groupPixelWidth": 2,
					"smoothed": true,
					"units": [
						[
							"millisecond",
							[
								1,
								2,
								5,
								10,
								20,
								25,
								50,
								100,
								200,
								500
							]
						],
						[
							"second",
							[
								1,
								2,
								5,
								10,
								15,
								30
							]
						],
						[
							"minute",
							[
								1,
								2,
								5,
								10,
								15,
								30
							]
						],
						[
							"hour",
							[
								1,
								2,
								3,
								4,
								6,
								8,
								12
							]
						],
						[
							"day",
							[
								1,
								2,
								3,
								4
							]
						],
						[
							"week",
							[
								1,
								2,
								3
							]
						],
						[
							"month",
							[
								1,
								3,
								6
							]
						],
						[
							"year",
							null
						]
					]
				},
				"dataLabels": {
					"enabled": false,
					"zIndex": 2
				},
				"id": "highcharts-navigator-series",
				"className": "highcharts-navigator-series",
				"lineColor": null,
				"marker": {
					"enabled": false
				},
				"threshold": null
			},
			"xAxis": {
				"overscroll": 0,
				"className": "highcharts-navigator-xaxis",
				"tickLength": 0,
				"lineWidth": 0,
				"gridLineColor": "#e6e6e6",
				"gridLineWidth": 1,
				"tickPixelInterval": 200,
				"title": {
					"enabled": false
				},
				"labels": {
					"align": "left",
					"style": {
						"color": "#999999"
					},
					"x": 3,
					"y": -4
				},
				"crosshair": true,
				"events": {
					"extremes": syncExtremes
				}
			},
			"yAxis": {
				"className": "highcharts-navigator-yaxis",
				"gridLineWidth": 0,
				"startOnTick": false,
				"endOnTick": false,
				"minPadding": 0.1,
				"maxPadding": 0.1,
				"labels": {
					"enabled": false
				},
				"crosshair": false,
				"title": {
					"enabled": false
				},
				"tickLength": 0,
				"tickWidth": 0
			}
		},
		"rangeSelector": {
			"verticalAlign": "top",
			"buttonTheme": {
				"width": 28,
				"height": 18,
				"padding": 2,
				"zIndex": 7
			},
			"floating": false,
			"x": 0,
			"y": 0,
			"inputPosition": {
				"align": "right",
				"x": 0,
				"y": 0
			},
			"buttonPosition": {
				"align": "left",
				"x": 0,
				"y": 0
			},
			"labelStyle": {
				"color": "#666666"
			}
		},
		"mapNavigation": {
			"buttonOptions": {
				"alignTo": "plotBox",
				"align": "left",
				"verticalAlign": "top",
				"x": 0,
				"width": 18,
				"height": 18,
				"padding": 5,
				"style": {
					"fontSize": "15px",
					"fontWeight": "bold"
				},
				"theme": {
					"stroke-width": 1,
					"text-align": "center"
				}
			},
			"buttons": {
				"zoomIn": {
					"text": "+",
					"y": 0
				},
				"zoomOut": {
					"text": "-",
					"y": 28
				}
			},
			"mouseWheelSensitivity": 1.1
		},
		"navigation": {
			"buttonOptions": {
				"theme": {
					"padding": 5
				},
				"symbolSize": 14,
				"symbolX": 12.5,
				"symbolY": 10.5,
				"align": "right",
				"buttonSpacing": 3,
				"height": 22,
				"verticalAlign": "top",
				"width": 24,
				"symbolFill": "#666666",
				"symbolStroke": "#666666",
				"symbolStrokeWidth": 3
			},
			"menuStyle": {
				"border": "1px solid #999999",
				"background": "#ffffff",
				"padding": "5px 0"
			},
			"menuItemStyle": {
				"padding": "0.5em 1em",
				"color": "#333333",
				"background": "none",
				"fontSize": "11px",
				"transition": "background 250ms, color 250ms"
			},
			"menuItemHoverStyle": {
				"background": "#335cad",
				"color": "#ffffff"
			},
			"bindingsClassName": "tools-container",
			"bindings": {
				"circleAnnotation": {
					"className": "highcharts-circle-annotation",
					"steps": [
						null
					]
				},
				"rectangleAnnotation": {
					"className": "highcharts-rectangle-annotation",
					"steps": [
						null
					]
				},
				"labelAnnotation": {
					"className": "highcharts-label-annotation"
				},
				"segment": {
					"className": "highcharts-segment",
					"steps": [
						null
					]
				},
				"arrowSegment": {
					"className": "highcharts-arrow-segment",
					"steps": [
						null
					]
				},
				"ray": {
					"className": "highcharts-ray",
					"steps": [
						null
					]
				},
				"arrowRay": {
					"className": "highcharts-arrow-ray",
					"steps": [
						null
					]
				},
				"infinityLine": {
					"className": "highcharts-infinity-line",
					"steps": [
						null
					]
				},
				"arrowInfinityLine": {
					"className": "highcharts-arrow-infinity-line",
					"steps": [
						null
					]
				},
				"horizontalLine": {
					"className": "highcharts-horizontal-line"
				},
				"verticalLine": {
					"className": "highcharts-vertical-line"
				},
				"crooked3": {
					"className": "highcharts-crooked3",
					"steps": [
						null,
						null
					]
				},
				"crooked5": {
					"className": "highcharts-crooked5",
					"steps": [
						null,
						null,
						null,
						null
					]
				},
				"elliott3": {
					"className": "highcharts-elliott3",
					"steps": [
						null,
						null,
						null
					]
				},
				"elliott5": {
					"className": "highcharts-elliott5",
					"steps": [
						null,
						null,
						null,
						null,
						null
					]
				},
				"measureX": {
					"className": "highcharts-measure-x",
					"steps": [
						null
					]
				},
				"measureY": {
					"className": "highcharts-measure-y",
					"steps": [
						null
					]
				},
				"measureXY": {
					"className": "highcharts-measure-xy",
					"steps": [
						null
					]
				},
				"fibonacci": {
					"className": "highcharts-fibonacci",
					"steps": [
						null,
						null
					]
				},
				"parallelChannel": {
					"className": "highcharts-parallel-channel",
					"steps": [
						null,
						null
					]
				},
				"pitchfork": {
					"className": "highcharts-pitchfork",
					"steps": [
						null,
						null
					]
				},
				"verticalCounter": {
					"className": "highcharts-vertical-counter"
				},
				"verticalLabel": {
					"className": "highcharts-vertical-label"
				},
				"verticalArrow": {
					"className": "highcharts-vertical-arrow"
				},
				"flagCirclepin": {
					"className": "highcharts-flag-circlepin"
				},
				"flagDiamondpin": {
					"className": "highcharts-flag-diamondpin"
				},
				"flagSquarepin": {
					"className": "highcharts-flag-squarepin"
				},
				"flagSimplepin": {
					"className": "highcharts-flag-simplepin"
				},
				"zoomX": {
					"className": "highcharts-zoom-x"
				},
				"zoomY": {
					"className": "highcharts-zoom-y"
				},
				"zoomXY": {
					"className": "highcharts-zoom-xy"
				},
				"seriesTypeLine": {
					"className": "highcharts-series-type-line"
				},
				"seriesTypeOhlc": {
					"className": "highcharts-series-type-ohlc"
				},
				"seriesTypeCandlestick": {
					"className": "highcharts-series-type-candlestick"
				},
				"fullScreen": {
					"className": "highcharts-full-screen"
				},
				"currentPriceIndicator": {
					"className": "highcharts-current-price-indicator"
				},
				"indicators": {
					"className": "highcharts-indicators"
				},
				"toggleAnnotations": {
					"className": "highcharts-toggle-annotations"
				},
				"saveChart": {
					"className": "highcharts-save-chart"
				}
			},
			"events": {},
			"annotationsOptions": {}
		},
		"exporting": {
			"type": "image/png",
			"url": "https://export.highcharts.com/",
			"printMaxWidth": 780,
			"scale": 2,
			"buttons": {
				"contextButton": {
					"className": "highcharts-contextbutton",
					"menuClassName": "highcharts-contextmenu",
					"symbol": "menu",
					"titleKey": "contextButtonTitle",
					"menuItems": [
						"viewFullscreen",
						"printChart",
						"separator",
						"downloadPNG",
						"downloadJPEG",
						"downloadPDF",
						"downloadSVG",
						"separator",
						"downloadCSV",
						"downloadXLS",
						"viewData"
					]
				}
			},
			"menuItemDefinitions": {
				"viewFullscreen": {
					"textKey": "viewFullscreen"
				},
				"printChart": {
					"textKey": "printChart"
				},
				"separator": {
					"separator": true
				},
				"downloadPNG": {
					"textKey": "downloadPNG"
				},
				"downloadJPEG": {
					"textKey": "downloadJPEG"
				},
				"downloadPDF": {
					"textKey": "downloadPDF"
				},
				"downloadSVG": {
					"textKey": "downloadSVG"
				},
				"downloadCSV": {
					"textKey": "downloadCSV"
				},
				"downloadXLS": {
					"textKey": "downloadXLS"
				},
				"viewData": {
					"textKey": "viewData"
				}
			},
			"csv": {
				"columnHeaderFormatter": null,
				"dateFormat": "%Y-%m-%d %H:%M:%S",
				"decimalPoint": null,
				"itemDelimiter": null,
				"lineDelimiter": "\n"
			},
			"showTable": false,
			"useMultiLevelHeaders": true,
			"useRowspanHeaders": true
		},
		"stockTools": {
			"gui": {
				"enabled": false,
				"className": "highcharts-bindings-wrapper",
				"toolbarClassName": "stocktools-toolbar",
				"buttons": [
					"simpleShapes",
					"lines",
					"crookedLines"
				],
				"definitions": {
					"separator": {
						"symbol": "separator.svg"
					},
					"simpleShapes": {
						"items": [
							"label",
							"circle",
							"rectangle"
						],
						"circle": {
							"symbol": "circle.svg"
						},
						"rectangle": {
							"symbol": "rectangle.svg"
						},
						"label": {
							"symbol": "label.svg"
						}
					},
					"flags": {
						"items": [
							"flagCirclepin",
							"flagDiamondpin",
							"flagSquarepin",
							"flagSimplepin"
						],
						"flagSimplepin": {
							"symbol": "flag-basic.svg"
						},
						"flagDiamondpin": {
							"symbol": "flag-diamond.svg"
						},
						"flagSquarepin": {
							"symbol": "flag-trapeze.svg"
						},
						"flagCirclepin": {
							"symbol": "flag-elipse.svg"
						}
					},
					"lines": {
						"items": [
							"segment",
							"arrowSegment",
							"ray",
							"arrowRay",
							"line",
							"arrowLine",
							"horizontalLine",
							"verticalLine"
						],
						"segment": {
							"symbol": "segment.svg"
						},
						"arrowSegment": {
							"symbol": "arrow-segment.svg"
						},
						"ray": {
							"symbol": "ray.svg"
						},
						"arrowRay": {
							"symbol": "arrow-ray.svg"
						},
						"line": {
							"symbol": "line.svg"
						},
						"arrowLine": {
							"symbol": "arrow-line.svg"
						},
						"verticalLine": {
							"symbol": "vertical-line.svg"
						},
						"horizontalLine": {
							"symbol": "horizontal-line.svg"
						}
					},
					"crookedLines": {
						"items": [
							"elliott3",
							"elliott5",
							"crooked3",
							"crooked5"
						],
						"crooked3": {
							"symbol": "crooked-3.svg"
						},
						"crooked5": {
							"symbol": "crooked-5.svg"
						},
						"elliott3": {
							"symbol": "elliott-3.svg"
						},
						"elliott5": {
							"symbol": "elliott-5.svg"
						}
					},
					"verticalLabels": {
						"items": [
							"verticalCounter",
							"verticalLabel",
							"verticalArrow"
						],
						"verticalCounter": {
							"symbol": "vertical-counter.svg"
						},
						"verticalLabel": {
							"symbol": "vertical-label.svg"
						},
						"verticalArrow": {
							"symbol": "vertical-arrow.svg"
						}
					},
					"advanced": {
						"items": [
							"fibonacci",
							"pitchfork",
							"parallelChannel"
						],
						"pitchfork": {
							"symbol": "pitchfork.svg"
						},
						"fibonacci": {
							"symbol": "fibonacci.svg"
						},
						"parallelChannel": {
							"symbol": "parallel-channel.svg"
						}
					},
					"measure": {
						"items": [
							"measureXY",
							"measureX",
							"measureY"
						],
						"measureX": {
							"symbol": "measure-x.svg"
						},
						"measureY": {
							"symbol": "measure-y.svg"
						},
						"measureXY": {
							"symbol": "measure-xy.svg"
						}
					},
					"toggleAnnotations": {
						"symbol": "annotations-visible.svg"
					},
					"currentPriceIndicator": {
						"symbol": "current-price-show.svg"
					},
					"indicators": {
						"symbol": "indicators.svg"
					},
					"zoomChange": {
						"items": [
							"zoomX",
							"zoomY",
							"zoomXY"
						],
						"zoomX": {
							"symbol": "zoom-x.svg"
						},
						"zoomY": {
							"symbol": "zoom-y.svg"
						},
						"zoomXY": {
							"symbol": "zoom-xy.svg"
						}
					},
					"typeChange": {
						"items": [
							"typeOHLC",
							"typeLine",
							"typeCandlestick"
						],
						"typeOHLC": {
							"symbol": "series-ohlc.svg"
						},
						"typeLine": {
							"symbol": "series-line.svg"
						},
						"typeCandlestick": {
							"symbol": "series-candlestick.svg"
						}
					},
					"fullScreen": {
						"symbol": "fullscreen.svg"
					},
					"saveChart": {
						"symbol": "save-chart.svg"
					}
				}
			}
		},
		"xAxis": [
			xAxis
		],
		"data": {
			// "csv": "Date of Infection;Hospital Census;Hospital Census - ICU;Hospital Census - Ventilator;Hospital Census - ECMO;Hospital Census - Dialysis;Upper Bound: Hospital Census;Upper Bound: Hospital Census - ICU;Upper Bound: Hospital Census - Ventilator;Upper Bound: Hospital Census - ECMO;Upper Bound: Hospital Census - Dialysis\n13MAR2020;0;0;0;0;0;0;0;0;0;0\n14MAR2020;0;0;0;0;0;1;0;0;0;0\n15MAR2020;1;1;0;0;0;3;1;1;0;0\n16MAR2020;2;1;1;0;0;6;3;2;0;0\n17MAR2020;4;2;1;0;0;9;4;3;0;0\n18MAR2020;5;2;2;0;0;12;6;4;0;1\n19MAR2020;7;3;2;0;0;16;7;6;0;1\n20MAR2020;9;4;3;0;0;21;9;7;1;1\n21MAR2020;11;5;4;0;1;25;12;9;1;1\n22MAR2020;12;6;5;0;1;29;14;11;1;2\n23MAR2020;14;7;6;0;1;32;17;13;1;2\n24MAR2020;15;7;7;1;1;36;19;16;1;2\n25MAR2020;16;9;8;1;1;42;21;18;2;3\n26MAR2020;18;9;8;0;1;47;24;20;2;3\n27MAR2020;19;10;9;0;1;53;27;23;1;4\n28MAR2020;21;12;9;0;2;60;32;26;2;4\n29MAR2020;23;12;10;0;2;68;36;29;2;4\n30MAR2020;25;13;11;0;2;78;40;34;2;5\n31MAR2020;27;14;12;0;1;89;46;38;3;6\n01APR2020;29;16;13;1;2;100;52;43;3;7\n02APR2020;33;17;14;1;2;114;60;49;3;7\n03APR2020;36;19;16;1;2;129;68;55;4;8\n04APR2020;41;22;18;1;3;147;77;63;4;10\n05APR2020;45;24;21;1;3;167;87;71;5;10\n06APR2020;51;26;22;1;4;189;98;81;5;12\n07APR2020;57;30;25;1;3;210;110;90;6;13\n08APR2020;63;33;27;1;4;229;120;99;6;15\n09APR2020;68;35;30;2;4;249;132;108;7;16\n10APR2020;73;39;32;2;5;269;143;118;7;18\n11APR2020;78;42;35;2;6;289;155;129;8;19\n12APR2020;83;45;37;2;5;310;168;140;8;21\n13APR2020;88;48;41;2;6;332;181;152;9;23\n14APR2020;93;51;43;2;7;357;196;164;10;25\n15APR2020;100;55;46;2;7;389;210;177;11;27\n16APR2020;107;59;49;3;8;423;227;190;12;29\n17APR2020;115;63;52;3;8;460;248;206;12;32\n18APR2020;124;68;56;3;9;502;268;224;14;34\n19APR2020;133;72;60;3;9;548;293;244;15;37\n20APR2020;144;77;65;4;10;601;321;267;17;40\n21APR2020;152;83;69;4;11;639;343;285;17;43\n22APR2020;157;86;73;4;11;659;356;297;18;45\n23APR2020;160;89;74;4;12;670;368;308;18;47\n24APR2020;161;90;77;4;12;678;377;318;18;49\n25APR2020;161;91;77;4;12;680;386;327;18;51\n26APR2020;160;92;79;4;12;677;392;334;17;52\n27APR2020;156;92;80;3;12;668;397;341;17;53\n28APR2020;155;92;80;4;12;674;399;346;18;54\n29APR2020;155;92;80;4;12;696;399;350;18;55\n30APR2020;156;90;79;5;13;724;406;351;19;56\n01MAY2020;159;91;78;4;13;754;420;358;19;57\n02MAY2020;164;93;80;4;12;808;447;379;21;59\n03MAY2020;172;97;83;5;13;887;487;411;23;63\n04MAY2020;183;102;87;5;13;981;532;448;26;69\n05MAY2020;196;108;92;5;14;1087;584;488;29;74\n06MAY2020;211;115;98;5;15;1204;640;534;32;81\n07MAY2020;228;124;104;6;16;1335;703;585;37;88\n08MAY2020;247;132;111;7;17;1478;773;640;40;97\n09MAY2020;265;142;118;7;18;1614;848;700;43;106\n10MAY2020;282;153;127;7;20;1741;931;766;46;115\n11MAY2020;300;163;137;8;20;1872;1012;839;50;125\n12MAY2020;317;174;145;9;22;2011;1089;910;54;137\n13MAY2020;335;184;155;9;24;2158;1170;979;57;149\n14MAY2020;355;195;164;9;25;2314;1256;1051;61;160\n15MAY2020;374;206;174;10;27;2481;1347;1128;66;172\n16MAY2020;396;217;183;11;28;2657;1443;1209;71;185\n17MAY2020;419;230;193;11;30;2844;1545;1294;76;197\n18MAY2020;441;243;204;11;31;3040;1653;1385;80;211\n19MAY2020;466;256;216;13;33;3247;1767;1482;86;225\n20MAY2020;492;271;228;13;35;3467;1887;1583;92;241\n21MAY2020;519;286;241;14;37;3696;2014;1689;98;258\n22MAY2020;548;302;255;14;39;3935;2147;1801;104;275\n23MAY2020;578;318;268;15;41;4186;2285;1918;111;293\n24MAY2020;610;336;283;16;43;4448;2430;2041;118;312\n25MAY2020;644;354;298;16;45;4720;2582;2169;125;331\n26MAY2020;679;373;315;18;48;5002;2738;2302;132;351\n27MAY2020;716;394;333;18;51;5291;2900;2440;140;373\n28MAY2020;755;415;351;20;53;5590;3068;2582;148;395\n29MAY2020;796;438;370;21;57;5896;3240;2728;155;418\n30MAY2020;838;462;390;22;60;6207;3415;2878;164;441\n31MAY2020;883;487;410;24;63;6523;3595;3031;172;465\n01JUN2020;930;513;432;24;66;6843;3777;3187;180;489\n02JUN2020;980;540;456;26;70;7164;3961;3344;188;514\n03JUN2020;1032;569;480;27;74;7485;4144;3502;196;538\n04JUN2020;1086;599;506;29;78;7803;4328;3661;205;562\n05JUN2020;1143;630;532;30;82;8116;4511;3818;213;588\n06JUN2020;1203;664;560;31;86;8423;4691;3974;220;612\n07JUN2020;1264;698;589;34;91;8720;4866;4126;228;636\n08JUN2020;1330;733;619;35;95;9006;5037;4275;236;660\n09JUN2020;1397;771;651;37;100;9276;5199;4418;242;682\n10JUN2020;1468;811;685;38;105;9531;5354;4555;248;704\n11JUN2020;1541;852;719;41;111;9766;5499;4684;254;725\n12JUN2020;1618;895;755;43;116;9981;5634;4805;260;744\n13JUN2020;1698;939;793;44;122;10171;5757;4915;265;762\n14JUN2020;1782;985;832;47;128;10336;5865;5013;268;779\n15JUN2020;1868;1033;873;49;134;10474;5959;5101;272;794\n16JUN2020;1957;1083;915;52;141;10584;6038;5175;274;806\n17JUN2020;2050;1135;959;54;148;10664;6100;5236;275;817\n18JUN2020;2146;1189;1006;56;154;10715;6147;5282;276;824\n19JUN2020;2246;1244;1052;59;162;10734;6176;5315;276;831\n20JUN2020;2348;1302;1101;62;169;10725;6188;5332;275;835\n21JUN2020;2454;1360;1152;65;177;10690;6182;5334;276;837\n22JUN2020;2562;1422;1204;67;185;10733;6161;5322;277;835\n23JUN2020;2675;1485;1257;70;194;10747;6187;5325;277;833\n24JUN2020;2789;1550;1312;74;202;10730;6194;5339;276;836\n25JUN2020;2908;1616;1369;77;210;10706;6184;5338;276;837\n26JUN2020;3028;1685;1427;79;220;10746;6171;5324;277;836\n27JUN2020;3151;1754;1487;82;229;10755;6193;5333;277;834\n28JUN2020;3276;1825;1547;86;238;10734;6199;5345;276;837\n29JUN2020;3405;1897;1610;89;248;10683;6188;5342;275;838\n30JUN2020;3534;1972;1672;92;258;10616;6158;5325;272;837\n01JUL2020;3666;2046;1736;96;268;10565;6120;5293;271;833\n02JUL2020;3798;2122;1801;100;278;10485;6091;5266;270;827\n03JUL2020;3932;2198;1867;103;288;10443;6045;5235;269;823\n04JUL2020;4066;2275;1934;106;298;10385;6020;5202;267;818\n05JUL2020;4201;2352;2000;110;309;10301;5988;5180;263;814\n06JUL2020;4335;2430;2067;113;320;10230;5940;5145;263;809\n07JUL2020;4470;2508;2133;116;330;10204;5899;5098;262;804\n08JUL2020;4602;2585;2200;120;340;10151;5884;5083;261;798\n09JUL2020;4734;2661;2266;124;351;10075;5855;5064;259;795\n10JUL2020;4863;2738;2333;127;362;9976;5811;5032;256;792\n11JUL2020;4991;2812;2398;130;372;9853;5754;4989;252;786\n12JUL2020;5115;2885;2461;134;382;9815;5684;4935;253;779\n13JUL2020;5235;2957;2523;136;392;9814;5660;4879;253;769\n14JUL2020;5351;3026;2583;135;401;9791;5661;4885;252;766\n15JUL2020;5124;3093;2642;129;411;9747;5648;4879;250;766\n16JUL2020;4888;2970;2631;123;420;9679;5623;4862;248;764\n17JUL2020;4660;2834;2511;117;405;9591;5584;4835;246;761\n18JUL2020;4441;2703;2395;112;386;9483;5534;4797;243;756\n19JUL2020;4230;2576;2283;106;368;9356;5472;4749;239;749\n20JUL2020;4027;2454;2176;101;350;9212;5400;4691;235;740\n21JUL2020;3834;2336;2073;96;334;9050;5316;4625;230;731\n22JUL2020;3648;2224;1974;91;318;8874;5225;4550;226;720\n23JUL2020;3471;2118;1879;87;304;8685;5123;4467;220;708\n24JUL2020;3302;2014;1788;82;289;8483;5015;4377;215;694\n25JUL2020;3141;1917;1701;79;275;8271;4900;4280;210;679\n26JUL2020;2988;1824;1618;75;261;8086;4779;4179;206;664\n27JUL2020;2842;1734;1540;71;249;7903;4671;4076;200;647\n28JUL2020;2703;1650;1465;68;236;7709;4565;3988;196;633\n29JUL2020;2571;1569;1394;64;225;7516;4455;3895;191;619\n30JUL2020;2445;1493;1325;61;214;7360;4342;3798;187;604\n31JUL2020;2326;1420;1260;58;204;7197;4252;3711;183;589\n01AUG2020;2213;1350;1199;55;194;7025;4158;3632;179;576\n02AUG2020;2104;1285;1140;53;184;6849;4060;3549;174;563\n03AUG2020;2003;1222;1085;50;175;6678;3959;3464;170;551\n04AUG2020;1905;1162;1032;48;166;6547;3858;3375;166;537\n05AUG2020;1813;1106;982;46;158;6410;3783;3300;163;523\n06AUG2020;1726;1053;934;43;151;6269;3704;3234;159;513\n07AUG2020;1643;1002;889;41;143;6123;3624;3165;155;502\n08AUG2020;1564;954;846;39;137;5972;3540;3094;152;492\n09AUG2020;1490;908;806;38;130;5818;3452;3020;148;480\n10AUG2020;1419;865;767;36;124;5662;3365;2945;144;469\n11AUG2020;1352;823;731;34;118;5561;3275;2868;142;457\n12AUG2020;1288;785;696;33;112;5460;3214;2800;139;444\n13AUG2020;1228;748;663;31;107;5354;3155;2750;136;436\n14AUG2020;1170;713;632;29;102;5244;3094;2699;133;428\n15AUG2020;1115;679;603;28;98;5130;3031;2646;131;420\n16AUG2020;1063;648;575;26;93;5013;2966;2590;128;411\n17AUG2020;1014;617;547;25;88;4895;2899;2533;124;403\n18AUG2020;967;589;522;24;84;4774;2830;2474;121;393\n19AUG2020;923;561;498;23;80;4652;2761;2416;118;384\n20AUG2020;880;536;475;22;76;4528;2690;2355;115;374\n21AUG2020;840;511;453;21;73;4404;2619;2294;111;365\n22AUG2020;802;488;432;21;70;4281;2549;2233;108;355\n23AUG2020;766;465;413;19;66;4157;2477;2172;105;346\n24AUG2020;731;444;394;18;64;4033;2406;2110;102;336\n25AUG2020;698;424;376;18;60;3911;2334;2048;99;327\n26AUG2020;667;405;358;17;57;3789;2263;1987;96;317\n27AUG2020;637;387;343;16;55;3669;2193;1926;93;308\n28AUG2020;609;370;328;15;53;3550;2124;1866;90;298\n29AUG2020;582;353;313;15;51;3433;2056;1806;87;289\n30AUG2020;556;337;299;14;48;3317;1988;1748;84;279\n31AUG2020;531;322;285;13;46;3205;1921;1690;81;271\n01SEP2020;508;309;273;13;44;3094;1856;1633;78;261\n02SEP2020;486;295;261;12;42;2985;1791;1576;75;252\n03SEP2020;465;282;250;12;41;2879;1729;1522;73;244\n04SEP2020;444;270;238;11;38;2776;1668;1469;70;236\n05SEP2020;425;258;229;11;37;2674;1608;1416;67;227\n06SEP2020;407;246;218;10;35;2576;1549;1365;65;219\n07SEP2020;389;236;208;10;34;2480;1492;1316;63;211\n08SEP2020;373;226;200;9;32;2387;1437;1266;61;203\n09SEP2020;356;216;191;8;30;2296;1383;1219;57;195\n10SEP2020;341;206;183;9;30;2209;1331;1173;56;188\n11SEP2020;326;198;175;8;29;2124;1281;1129;54;181\n12SEP2020;312;189;167;8;27;2041;1231;1086;52;175\n13SEP2020;299;181;160;7;25;1962;1183;1044;49;168\n14SEP2020;286;173;154;7;24;1885;1137;1003;47;161\n15SEP2020;274;166;147;7;24;1810;1093;964;46;154\n16SEP2020;263;159;141;6;23;1739;1049;927;44;148\n17SEP2020;251;152;135;6;22;1669;1008;889;42;143\n18SEP2020;241;146;129;6;21;1602;968;855;40;137\n19SEP2020;231;140;124;6;20;1538;929;821;39;132\n20SEP2020;221;133;118;6;19;1475;891;787;37;127\n21SEP2020;212;128;114;5;18;1415;855;756;36;122\n22SEP2020;202;123;109;5;17;1358;821;725;34;116\n23SEP2020;194;118;104;5;16;1302;787;695;33;111\n24SEP2020;186;113;99;5;16;1249;755;667;31;107\n25SEP2020;178;108;95;5;16;1197;724;640;30;103\n26SEP2020;171;104;92;4;15;1148;694;613;29;99\n27SEP2020;163;99;88;4;14;1101;665;588;27;95\n28SEP2020;157;95;84;4;13;1055;637;564;26;90\n29SEP2020;151;91;80;4;13;1010;611;540;25;87\n30SEP2020;144;88;78;4;12;968;586;518;25;83\n01OCT2020;138;83;74;3;12;928;561;496;23;80\n02OCT2020;133;80;70;3;11;889;538;476;22;76\n03OCT2020;127;77;68;3;11;851;515;456;22;73\n04OCT2020;122;74;65;3;11;815;494;437;21;71\n05OCT2020;117;70;62;3;10;781;473;418;20;67\n06OCT2020;112;68;59;2;9;749;453;401;18;64\n07OCT2020;107;65;57;3;9;717;435;384;18;62\n08OCT2020;103;62;55;2;9;686;416;367;18;59\n09OCT2020;99;59;53;2;8;657;398;352;16;57\n10OCT2020;95;57;50;2;8;630;381;338;16;54\n11OCT2020;91;55;48;2;7;603;365;323;15;52\n12OCT2020;87;52;47;2;7;577;350;309;15;49\n13OCT2020;83;50;45;2;7;552;335;296;14;48\n14OCT2020;80;49;43;2;7;529;321;283;13;46\n15OCT2020;76;46;41;2;6;506;307;272;13;43\n16OCT2020;73;44;39;2;6;485;293;260;12;42\n17OCT2020;70;42;37;2;6;464;281;249;11;40\n18OCT2020;67;40;36;1;6;444;269;238;11;38\n19OCT2020;64;39;34;1;5;425;258;228;11;37\n20OCT2020;61;37;33;1;5;407;247;218;10;35\n21OCT2020;58;36;31;1;5;390;236;209;10;34\n22OCT2020;56;34;30;1;5;373;226;200;9;32\n23OCT2020;54;32;29;1;4;357;216;192;9;31\n24OCT2020;51;31;27;1;4;341;207;184;9;29\n25OCT2020;49;29;26;1;4;327;198;175;8;28\n26OCT2020;47;29;25;1;4;313;190;167;8;27\n27OCT2020;45;27;24;1;4;300;182;161;7;26\n28OCT2020;43;26;23;1;3;286;174;154;7;25\n29OCT2020;41;25;22;1;3;275;166;147;7;24\n30OCT2020;39;23;21;1;3;262;159;140;6;22\n31OCT2020;38;22;20;1;3;252;152;134;6;22\n01NOV2020;36;21;19;1;3;241;145;129;6;20\n02NOV2020;34;21;18;1;2;230;139;123;6;20\n03NOV2020;32;20;18;0;3;220;134;118;6;19\n04NOV2020;31;19;16;0;2;211;128;113;6;18\n05NOV2020;30;18;16;0;3;201;122;109;5;18\n06NOV2020;28;17;15;0;2;193;117;103;5;17\n07NOV2020;27;16;15;0;2;184;112;99;5;16\n08NOV2020;26;15;14;0;2;176;107;95;4;15\n09NOV2020;25;15;13;0;2;169;102;91;4;14\n10NOV2020;24;14;12;0;2;161;98;87;4;14\n11NOV2020;23;13;12;0;1;154;94;83;4;13\n12NOV2020;22;13;11;0;2;148;89;79;4;13\n13NOV2020;21;12;11;0;2;142;85;75;3;12\n14NOV2020;20;12;11;0;1;135;82;72;4;12\n15NOV2020;19;11;10;0;1;130;78;69;3;12\n16NOV2020;18;11;9;0;1;124;75;66;3;10\n17NOV2020;17;10;9;0;1;119;72;64;3;10\n18NOV2020;16;10;9;0;1;114;69;61;3;10\n19NOV2020;15;9;8;0;1;108;66;58;3;9\n20NOV2020;15;9;8;0;1;103;63;56;2;9\n21NOV2020;14;8;8;0;1;100;61;53;3;9\n22NOV2020;13;8;7;0;1;95;58;51;2;8\n23NOV2020;13;8;7;0;1;91;55;49;3;8\n24NOV2020;13;7;6;0;1;87;53;47;2;7\n25NOV2020;12;7;6;0;1;83;51;45;2;7\n26NOV2020;11;7;6;0;1;80;48;43;2;6\n27NOV2020;11;6;6;0;1;77;46;40;2;7\n28NOV2020;10;6;5;0;1;73;44;39;2;6\n29NOV2020;10;5;5;0;0;69;42;38;1;6\n30NOV2020;9;6;5;0;0;67;40;36;2;6\n01DEC2020;9;5;5;0;0;64;39;34;2;6\n02DEC2020;8;5;4;0;0;61;37;33;2;5\n03DEC2020;8;5;4;0;0;58;35;32;1;5\n04DEC2020;8;5;4;0;0;55;34;30;1;5\n05DEC2020;7;4;4;0;0;53;32;28;2;5\n06DEC2020;7;5;4;0;0;51;31;28;1;4\n07DEC2020;7;4;4;0;0;49;30;27;1;5\n08DEC2020;6;4;3;0;0;46;29;25;1;4\n09DEC2020;6;4;3;0;0;45;27;24;1;4\n10DEC2020;5;4;3;0;0;43;26;23;2;4\n11DEC2020;5;3;3;0;0;41;25;22;1;4\n12DEC2020;6;3;3;0;0;39;24;21;1;3\n13DEC2020;5;3;2;0;0;38;22;20;1;3\n14DEC2020;5;3;3;0;0;35;22;19;1;3\n15DEC2020;5;2;3;0;0;35;21;19;1;3\n16DEC2020;4;2;2;0;0;33;20;17;1;3\n17DEC2020;4;3;2;0;0;32;19;17;1;3\n18DEC2020;4;2;2;0;0;30;18;16;1;2\n19DEC2020;4;2;2;0;0;29;17;15;1;2\n20DEC2020;4;2;2;0;0;27;17;14;1;3\n21DEC2020;4;2;2;0;0;27;16;15;1;2\n22DEC2020;3;2;2;0;0;25;16;14;1;2\n23DEC2020;3;2;2;0;0;24;15;13;1;2\n24DEC2020;3;2;1;0;0;23;14;13;1;2\n25DEC2020;3;2;1;0;0;23;13;12;1;2\n26DEC2020;3;2;1;0;0;21;13;12;1;2\n27DEC2020;2;2;1;0;0;21;13;10;1;2\n28DEC2020;2;1;1;0;0;19;12;10;1;2\n29DEC2020;2;1;1;0;0;18;11;10;1;2\n30DEC2020;2;1;1;0;0;18;11;10;1;2\n31DEC2020;2;1;1;0;0;17;10;9;1;2\n01JAN2021;2;1;1;0;0;16;10;8;1;1\n02JAN2021;2;1;1;0;0;16;10;8;1;2\n03JAN2021;2;1;1;0;0;14;9;8;1;1\n04JAN2021;2;1;1;0;0;14;8;7;1;1\n05JAN2021;2;1;0;0;0;14;8;7;1;2\n06JAN2021;1;1;1;0;0;13;8;7;1;1\n07JAN2021;1;1;1;0;0;12;7;7;1;1\n08JAN2021;1;1;1;0;0;12;7;6;1;1\n09JAN2021;1;1;1;0;0;11;7;6;1;1\n10JAN2021;1;1;1;0;0;11;6;5;1;1\n11JAN2021;1;0;1;0;0;11;6;6;1;1\n12JAN2021;1;0;0;0;0;10;6;5;1;1\n13JAN2021;1;1;0;0;0;9;6;5;1;1\n14JAN2021;1;0;0;0;0;9;5;5;1;1\n15JAN2021;1;0;0;0;0;8;5;4;1;1\n16JAN2021;1;0;0;0;0;8;5;5;1;1\n17JAN2021;1;0;0;0;0;8;5;4;1;1\n18JAN2021;1;0;0;0;0;7;4;5;1;1\n19JAN2021;1;0;0;0;0;7;5;4;1;1\n20JAN2021;1;0;0;0;0;7;4;4;1;1\n21JAN2021;1;0;0;0;0;7;4;3;1;1\n22JAN2021;0;0;0;0;0;7;4;4;1;1\n23JAN2021;1;0;0;0;0;6;4;3;1;1\n24JAN2021;0;0;0;0;0;6;3;3;1;1\n25JAN2021;0;0;0;0;0;6;4;3;1;1\n26JAN2021;1;0;0;0;0;5;3;3;1;1\n27JAN2021;0;0;0;0;0;5;3;3;1;1\n28JAN2021;0;0;0;0;0;5;3;2;1;1\n29JAN2021;0;0;0;0;0;4;3;2;1;1\n30JAN2021;0;0;0;0;0;5;3;3;1;1\n31JAN2021;0;0;0;0;0;4;2;3;1;1\n01FEB2021;0;0;0;0;0;4;3;2;1;1\n02FEB2021;0;0;0;0;0;4;3;2;1;1\n03FEB2021;0;0;0;0;0;4;2;2;1;1\n04FEB2021;0;0;0;0;0;3;2;2;1;1\n05FEB2021;0;0;0;0;0;4;2;2;1;1\n06FEB2021;0;0;0;0;0;3;2;2;0;1\n07FEB2021;0;0;0;0;0;3;2;2;0;1\n08FEB2021;0;0;0;0;0;3;2;2;0;1\n09FEB2021;0;0;0;0;0;3;2;1;0;1\n10FEB2021;0;0;0;0;0;3;1;1;0;1\n11FEB2021;0;0;0;0;0;3;1;1;1;1\n12FEB2021;0;0;0;0;0;2;2;1;1;1\n13FEB2021;0;0;0;0;0;2;2;2;1;1\n14FEB2021;0;0;0;0;0;3;2;2;1;1\n15FEB2021;0;0;0;0;0;2;1;1;1;1\n16FEB2021;0;0;0;0;0;2;1;1;1;1\n17FEB2021;0;0;0;0;0;2;1;1;0;1\n18FEB2021;0;0;0;0;0;2;1;1;0;1\n19FEB2021;0;0;0;0;0;2;1;1;0;1\n20FEB2021;0;0;0;0;0;2;1;1;0;1\n21FEB2021;0;0;0;0;0;1;1;1;0;1\n22FEB2021;0;0;0;0;0;2;1;1;0;1\n23FEB2021;0;0;0;0;0;2;1;1;0;1\n24FEB2021;0;0;0;0;0;1;1;1;0;1\n25FEB2021;0;0;0;0;0;1;1;1;0;1\n26FEB2021;0;0;0;0;0;1;1;1;0;1\n27FEB2021;0;0;0;0;0;2;1;1;0;1\n28FEB2021;0;0;0;0;0;2;1;1;0;1\n01MAR2021;0;0;0;0;0;1;1;1;0;1\n02MAR2021;0;0;0;0;0;1;1;1;0;0\n03MAR2021;0;0;0;0;0;1;1;1;0;0\n04MAR2021;0;0;0;0;0;1;1;1;1;0\n05MAR2021;0;0;0;0;0;1;1;1;1;0\n06MAR2021;0;0;0;0;0;1;1;1;1;1\n07MAR2021;0;0;0;0;0;1;1;1;1;1\n08MAR2021;0;0;0;0;0;1;1;1;1;1\n09MAR2021;0;0;0;0;0;1;1;1;1;1\n10MAR2021;0;0;0;0;0;1;1;1;1;1\n11MAR2021;0;0;0;0;0;1;1;1;1;1\n12MAR2021;0;0;0;0;0;1;1;1;1;1\n13MAR2021;0;0;0;0;0;1;1;1;1;1",
			"googleSpreadsheet": false,
			"liveData": false,
			"text": false,
			"assignDataFields": [
				{
					"labels": "A",
					"low": "G",
					"high": "L"
				},
				{
					"labels": "A",
					"low": "H",
					"high": "M"
				},
				{
					"labels": "A",
					"low": "I",
					"high": "N"
				},
				{
					"labels": "A",
					"low": "J",
					"high": "O"
				},
				{
					"labels": "A",
					"low": "K",
					"high": "P"
				}
			],
			"seriesMapping": [
				{
					"x": 0,
					"low": 1,
					"high": 6
				},
				{
					"x": 0,
					"low": 2,
					"high": 7
				},
				{
					"x": 0,
					"low": 3,
					"high": 8
				},
				{
					"x": 0,
					"low": 4,
					"high": 9
				},
				{
					"x": 0,
					"low": 5,
					"high": 10
				}
			],
			"decimalPoint": ",",
			"dateFormat": "YYYY/mm/dd"
		},
		"annotations": [],
		"defs": {
			"patterns": [
				{
					"id": "custom-pattern-0",
					"path": {
						"d": "M 0 0 L 10 0 M 0 10 L 10 10 M 0 5 L 10 5",
						"stroke": "#DD5757",
						"strokeWidth": 1.5
					}
				},
				{
					"id": "custom-pattern-1",
					"path": {
						"d": "M 0 0 L 10 0 M 0 10 L 10 10 M 0 5 L 10 5",
						"stroke": "#FF8224",
						"strokeWidth": 1.5
					}
				},
				{
					"id": "custom-pattern-2",
					"path": {
						"d": "M 0 0 L 10 0 M 0 10 L 10 10 M 0 5 L 10 5",
						"stroke": "#2AD1D1",
						"strokeWidth": 1.5
					}
				},
				{
					"id": "custom-pattern-3",
					"path": {
						"d": "M 0 0 L 10 0 M 0 10 L 10 10 M 0 5 L 10 5",
						"stroke": "#33A3FF",
						"strokeWidth": 1.5
					}
				},
				{
					"id": "custom-pattern-4",
					"path": {
						"d": "M 0 0 L 10 0 M 0 10 L 10 10 M 0 5 L 10 5",
						"stroke": "#9471FF",
						"strokeWidth": 1.5
					}
				}
			],
			"arrow": {
				"tagName": "marker",
				"render": false,
				"id": "arrow",
				"refY": 5,
				"refX": 9,
				"markerWidth": 10,
				"markerHeight": 10,
				"children": [
					{
						"tagName": "path",
						"d": "M 0 0 L 10 5 L 0 10 Z",
						"strokeWidth": 0
					}
				]
			},
			"reverse-arrow": {
				"tagName": "marker",
				"render": false,
				"id": "reverse-arrow",
				"refY": 5,
				"refX": 1,
				"markerWidth": 10,
				"markerHeight": 10,
				"children": [
					{
						"tagName": "path",
						"d": "M 0 5 L 10 0 L 10 10 Z",
						"strokeWidth": 0
					}
				]
			}
		},
		"yAxis": [
			// Primary Y axis - axisId = 0
			{
				"index": 0,
				"showEmpty": false,
				"min": 0,
				"title": {
					"enabled": false
				},
				"gridLineWidth": 0
			},
			// Secondary Y axis - axisId = 1
			secondaryYAxis
		],
		// "zAxis": [
		// 	{
		// 		"title": {
		// 			"enabled": false
		// 		},
		// 		"labels": {
		// 			"enabled": false
		// 		}
		// 	}
		// ]
	}
}
