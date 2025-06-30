import UIKit
import DGCharts

final class CoinPriceChartView: UIView {
    private let chartView = LineChartView()
    private let noDataLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(chartView)
        addSubview(noDataLabel)
        
        chartView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        noDataLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        setupChartView()
        setupNoDataLabel()
    }
    
    private func setupChartView() {
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
        
        // Настройка левой оси
        let leftAxis = chartView.leftAxis
        leftAxis.labelTextColor = .secondaryLabel
        leftAxis.labelFont = .systemFont(ofSize: 12)
        leftAxis.drawGridLinesEnabled = true
        leftAxis.gridColor = .systemGray5
        leftAxis.gridLineWidth = 0.5
        leftAxis.drawAxisLineEnabled = false
        leftAxis.valueFormatter = PriceAxisValueFormatter()
        
        // Настройка анимации
        chartView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
    }
    
    private func setupNoDataLabel() {
        noDataLabel.text = "Нет данных для отображения"
        noDataLabel.textColor = .secondaryLabel
        noDataLabel.font = .systemFont(ofSize: 14)
        noDataLabel.textAlignment = .center
        noDataLabel.isHidden = true
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
        
        let dataSet = LineChartDataSet(entries: entries, label: "Цена")
        dataSet.mode = .cubicBezier
        dataSet.drawCirclesEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.lineWidth = 2
        dataSet.setColor(.systemBlue)
        dataSet.fillColor = .systemBlue
        dataSet.fillAlpha = 0.1
        dataSet.drawFilledEnabled = true
//        dataSet.gradientColors = [.systemBlue.withAlphaComponent(0.3), .systemBlue.withAlphaComponent(0.1)]
//        dataSet.gradientOrientation = .vertical
        
        let data = LineChartData(dataSet: dataSet)
        chartView.data = data
        
        chartView.notifyDataSetChanged()
    }
}

// MARK: - PriceAxisValueFormatter
private class PriceAxisValueFormatter: AxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
} 
