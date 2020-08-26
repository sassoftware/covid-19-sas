import React from 'react'
import $ from 'jquery'
import Highcharts from 'highcharts'
import {Column, Row} from 'carbon-components-react'

/**
 * A Chart button: tap the button to increase the count.
 */
class Chart extends React.Component {
  componentDidMount () {
    $(this.container).bind('mousemove touchmove touchstart', function (e) {
      var chart, point, i, event

      for (i = 0; i < Highcharts.charts.length; i = i + 1) {
        chart = Highcharts.charts[i]
        event = chart.pointer.normalize(e.originalEvent) // Find coordinates within the chart
        point = chart.series[0].searchPoint(event, true) // Get the hovered point

        if (point) {
          point.highlight(e)
        }
      }
    })

    Highcharts.Pointer.prototype.reset = function () {
      return undefined
    }

    Highcharts.Point.prototype.highlight = function (event) {
      this.onMouseOver() // Show the hover marker
      this.series.chart.tooltip.refresh(this) // Show the tooltip
      this.series.chart.xAxis[0].drawCrosshair(event, this) // Show the crosshair
    }

    function syncExtremes (e) {
      var thisChart = this.chart

      if (e.trigger !== 'syncExtremes') { // Prevent feedback loop
        Highcharts.each(Highcharts.charts, function (chart) {
          if (chart !== thisChart) {
            if (chart.xAxis[0].setExtremes) { // It is null while updating
              chart.xAxis[0].setExtremes(e.min, e.max, undefined, false, { trigger: 'syncExtremes' })
            }
          }
        })
      }
    }

    const self = this

    $.getJSON('https://www.highcharts.com/samples/data/jsonp.php?filename=activity.json&callback=?', function (activity) {
      $.each(activity.datasets, function (i, dataset) {
    // Add X values
        dataset.data = Highcharts.map(dataset.data, function (val, j) {
          return [activity.xData[j], val]
        })

				let chartContainer = self.container
				if (i === 1) {
					chartContainer = self.container1
				} else if (i === 2) {
					chartContainer = self.container2
				}

        const el = document.createElement('div')
        el.class = 'chart'
        // self.container.appendChild(el)
        chartContainer.appendChild(el)

        Highcharts.chart(el, {
          chart: {
            marginLeft: 40, // Keep all charts left aligned
            spacingTop: 20,
            spacingBottom: 20
          },
          title: {
            text: dataset.name,
            align: 'left',
            margin: 0,
            x: 30
          },
          credits: {
            enabled: false
          },
          legend: {
            enabled: false
          },
          xAxis: {
            crosshair: true,
            events: {
              setExtremes: syncExtremes
            },
            labels: {
              format: '{value} km'
            }
          },
          yAxis: {
            title: {
              text: null
            }
          },
          tooltip: {
            positioner: function () {
              return {
                x: this.chart.chartWidth - this.label.width, // right aligned
                y: -1 // align to title
              }
            },
            borderWidth: 0,
            backgroundColor: 'none',
            pointFormat: '{point.y}',
            headerFormat: '',
            shadow: false,
            style: {
              fontSize: '18px'
            },
            valueDecimals: dataset.valueDecimals
          },
          series: [{
            data: dataset.data,
            name: dataset.name,
            type: dataset.type,
            color: Highcharts.getOptions().colors[i],
            fillOpacity: 0.3,
            tooltip: {
              valueSuffix: ' ' + dataset.unit
            }
          }]
        })
      })
    })
  }

  render () {
    return (
    	<div>
				<Row>
					<Column md={2} lg={5}>
						<div ref={(container) => { this.container = container }} id='container' />
					</Column>
					<Column md={2} lg={5}>
						<div ref={(container) => { this.container1 = container }} id='container1' />
					</Column>
					<Column md={2} lg={5}>
						<div ref={(container) => { this.container2 = container }} id='container2' />
					</Column>
				</Row>
      {/*<div ref={(container) => { this.container = container }} id='container' />*/}
			</div>

    )
  }
}
export default Chart
