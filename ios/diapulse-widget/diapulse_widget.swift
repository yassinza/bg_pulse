import ActivityKit
import WidgetKit
import SwiftUI

@main
struct Widgets: WidgetBundle {
  var body: some Widget {
    if #available(iOS 16.1, *) {
      GlucoseMonitorApp()
    }
  }
}

struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
  public typealias LiveDeliveryData = ContentState
  
  public struct ContentState: Codable, Hashable { }
  
  var id = UUID()
}

let sharedDefault = UserDefaults(suiteName: "group.diapulse")!

struct TrendLineChart: View {
    let readings: [Double]
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard readings.count > 1 else { return }

                let xStep = width / CGFloat(readings.count - 1)
                let yScale = height / (readings.max()! - readings.min()!)

                path.move(to: CGPoint(x: 0, y: height - (readings[0] - readings.min()!) * yScale))

                for i in 1..<readings.count {
                    let x = CGFloat(i) * xStep
                    let y = height - (readings[i] - readings.min()!) * yScale
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(Color.white, lineWidth: 2)
        }
        .frame(width: width, height: height)
    }
}

func getColor(from string: String) -> Color {
    switch string.lowercased() {
    case "red":
        return .red
    case "orange":
        return .orange
    case "green":
        return .green
    default:
        return .white // Default color if the string doesn't match
    }
}

@available(iOSApplicationExtension 16.1, *)
struct GlucoseMonitorApp: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
      let value = sharedDefault.double(forKey: context.attributes.prefixedKey("value"))
      let trend = sharedDefault.string(forKey: context.attributes.prefixedKey("trend")) ?? "→"
      let trendArrow = sharedDefault.string(forKey: context.attributes.prefixedKey("trendArrow")) ?? "→"
      let trendColor = sharedDefault.string(forKey: context.attributes.prefixedKey("trendColor")) ?? "green"
      let timestamp = Date(timeIntervalSince1970: sharedDefault.double(forKey: context.attributes.prefixedKey("timestamp")) / 1000)
      let readings = sharedDefault.array(forKey: context.attributes.prefixedKey("readings")) as? [Double] ?? []



      ZStack {
        LinearGradient(colors: [Color.black.opacity(0.5), Color.black.opacity(0.3)], startPoint: .topLeading, endPoint: .bottom)

        VStack(spacing: 5) {
          HStack {
            TrendLineChart(readings: readings, width: 150, height: 30)
            Text("\(Int(value))")
              .font(.system(size: 60, weight: .bold))
            Text(trendArrow)
              .font(.system(size: 20))
              .offset(y: 10)
          }

          Text(timestamp, style: .time)
            .font(.system(size: 16))

        }
      }
      .frame(height: 160)
    } dynamicIsland: { context in
      let value = sharedDefault.double(forKey: context.attributes.prefixedKey("value"))
      let trend = sharedDefault.string(forKey: context.attributes.prefixedKey("trend")) ?? "→"
      let trendArrow = sharedDefault.string(forKey: context.attributes.prefixedKey("trendArrow")) ?? "→"
      let trendColor = sharedDefault.string(forKey: context.attributes.prefixedKey("trendColor")) ?? "green"
      let timestamp = Date(timeIntervalSince1970: sharedDefault.double(forKey: context.attributes.prefixedKey("timestamp")) / 1000)
      let readings = sharedDefault.array(forKey: context.attributes.prefixedKey("readings")) as? [Double] ?? []

      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Text(trendArrow)
            .font(.system(size: 40))
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text(trendArrow)
            .font(.system(size: 40))
        }
        DynamicIslandExpandedRegion(.center) {
          VStack(spacing: 5) {
            Text("\(Int(value)) mg/dL")
              .font(.system(size: 30, weight: .bold))
            TrendLineChart(readings: readings, width: 100, height: 20)
            Text(timestamp, style: .time)
              .font(.system(size: 16))
          }
        }
      } compactLeading: {
        Text("\(Int(value))")
          .font(.system(size: 20, weight: .bold))
      } compactTrailing: {
         Text(trendArrow)
          .font(.system(size: 20, weight: .bold))
          .foregroundColor(getColor(from: trendColor))
      } minimal: {
        Text("\(Int(value))"+trendArrow)
          .font(.system(size: 20, weight: .bold))
          .foregroundColor(getColor(from: trendColor))
      }
    }
  }
}

extension LiveActivitiesAppAttributes {
  func prefixedKey(_ key: String) -> String {
    return "\(id)_\(key)"
  }
}