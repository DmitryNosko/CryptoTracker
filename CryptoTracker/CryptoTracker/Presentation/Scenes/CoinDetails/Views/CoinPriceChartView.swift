import UIKit
import DGCharts

final class CoinPriceChartView: UIView {
    // UI
    private let chartView = LineChartView()
    private let noDataLabel = UILabel()

    // Init
    override init(frame: CGRect) {
        super.init(frame: frame)

        assemble()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateChart(with priceHistory: [CoinPrice]) {
        guard !priceHistory.isEmpty else {
            chartView.isHidden = true
            noDataLabel.isHidden = false
            return
        }
        
        chartView.isHidden = false
        noDataLabel.isHidden = true
        
        let entries = priceHistory.enumerated().map { index, priceData in
            ChartDataEntry(x: Double(index), y: priceData.price ?? 0)
        }
        
        let dataSet = LineChartDataSet(entries: entries, label: "Price")
        dataSet.mode = .cubicBezier
        dataSet.drawCirclesEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.lineWidth = 2
        dataSet.setColor(.dodgerBlue)
        dataSet.fillColor = .dodgerBlue
        dataSet.fillAlpha = 0.1
        dataSet.drawFilledEnabled = true

        let data = LineChartData(dataSet: dataSet)
        chartView.data = data
        
        chartView.notifyDataSetChanged()
    }

    // Assemble
    private func assemble() {
        addSubviews()
        setConstraints()
        configureViews()
    }
}

// MARK: - Configure UI
private extension CoinPriceChartView {
    func addSubviews() {
        addSubview(chartView)
        addSubview(noDataLabel)
    }

    func setConstraints() {
        chartView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        noDataLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    func configureViews() {
        // chartView
        chartView.backgroundColor = .clear
        chartView.gridBackgroundColor = .clear
        chartView.drawGridBackgroundEnabled = false
        chartView.drawBordersEnabled = false
        chartView.legend.enabled = false
        chartView.rightAxis.enabled = false
        chartView.xAxis.enabled = false
        chartView.doubleTapToZoomEnabled = false
        chartView.pinchZoomEnabled = false
        chartView.scaleXEnabled = false
        chartView.scaleYEnabled = false
        chartView.autoScaleMinMaxEnabled = true
        chartView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)

        // leftAxis
        let leftAxis = chartView.leftAxis
        leftAxis.labelTextColor = .secondaryLabel
        leftAxis.labelFont = .systemFont(ofSize: 12)
        leftAxis.drawGridLinesEnabled = true
        leftAxis.gridColor = .systemGray5
        leftAxis.gridLineWidth = 0.5
        leftAxis.drawAxisLineEnabled = false
        leftAxis.valueFormatter = PriceAxisValueFormatter()

        // noDataLabel
        noDataLabel.text = "No Data Yet."
        noDataLabel.textColor = .secondaryLabel
        noDataLabel.font = .systemFont(ofSize: 14)
        noDataLabel.textAlignment = .center
        noDataLabel.isHidden = true
    }
}
