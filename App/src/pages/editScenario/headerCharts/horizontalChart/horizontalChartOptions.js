
export function horizontalChartOptions(marketShareInterest,admissionRate,icuRate,ventRate,fatalityRate) {
    return ({
        chart: {
            type: 'bar',
            height: 200,
					width: 300
        },
        credits: {
            enabled: false
        },
        title: false,
        subtitle: false,
        xAxis: {
            categories:['Hospital and Virus'],
            title: {
                enabled: false
            },
            labels: {
                enabled: false
            }
        },
        yAxis: {
            min: 0,
            max: 100,
            title: {
                enabled: false
            },
            gridLineWidth: 0
        },
        legend: {
            enabled: false
        },
        tooltip: {
			enabled: true,
			formatter: function () {
				let tooltipMessage = `${this.series.name}: <b>${this.y}%</b>`
				return tooltipMessage;
			}
		},
        series: [
            {
                name: 'Anticipated share in region addmitted to hospital of interest',
                data: [marketShareInterest],
                color: '#0378CD'

            },
            {
                name: 'Percentage of Infected in region who will be hospitalized',
                data: [admissionRate],
                color: '#FFCC32'
            },
            {
                name: 'Percentage of hospitalized patients who will require ICU',
                data: [icuRate],
                color: '#FF8224'

            },
            {
                name: 'Percentage of hospitalized patients who will require Ventilators',
                data: [ventRate],
                color: '#DD5757'

            },
            {
                name: 'Percentage of hospitalized patients who will die',
                data: [fatalityRate],
                color: '#86134F'

            }]
    })
}
