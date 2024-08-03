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

@available(iOSApplicationExtension 16.1, *)
struct GlucoseMonitorApp: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
      let value = sharedDefault.double(forKey: context.attributes.prefixedKey("value"))
      let trend = sharedDefault.string(forKey: context.attributes.prefixedKey("trend")) ?? "→"
      let emoji = sharedDefault.string(forKey: context.attributes.prefixedKey("emoji")) ?? "🟢"
      let timestamp = Date(timeIntervalSince1970: sharedDefault.double(forKey: context.attributes.prefixedKey("timestamp")) / 1000)
      let readings = sharedDefault.array(forKey: context.attributes.prefixedKey("readings")) as? [Double] ?? []
      
      ZStack {
        LinearGradient(colors: [Color.black.opacity(0.5), Color.black.opacity(0.3)], startPoint: .topLeading, endPoint: .bottom)
        
        VStack(spacing: 10) {
          HStack {
            Text("\(Int(value))")
              .font(.system(size: 60, weight: .bold))
            Text("mg/dL")
              .font(.system(size: 20))
              .offset(y: 10)
          }
          
          HStack(spacing: 20) {
            Text(emoji)
              .font(.system(size: 40))
            Text(trend)
              .font(.system(size: 40))
          }
          
          Text(timestamp, style: .time)
            .font(.system(size: 16))

          Link(destination: URL(string: "la://my.app/glucose")!) {
            Text("See details 📊")
              .font(.system(size: 14))
              .padding(.vertical, 5)
              .padding(.horizontal, 10)
              .background(Color.blue.opacity(0.6))
              .cornerRadius(8)
          }
        }
      }
      .frame(height: 160)
    } dynamicIsland: { context in
      let value = sharedDefault.double(forKey: context.attributes.prefixedKey("value"))
      let trend = sharedDefault.string(forKey: context.attributes.prefixedKey("trend")) ?? "→"
      let emoji = sharedDefault.string(forKey: context.attributes.prefixedKey("emoji")) ?? "🟢"
      let timestamp = Date(timeIntervalSince1970: sharedDefault.double(forKey: context.attributes.prefixedKey("timestamp")) / 1000)

      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Text(emoji)
            .font(.system(size: 40))
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text(trend)
            .font(.system(size: 40))
        }
        DynamicIslandExpandedRegion(.center) {
          VStack {
            Text("\(Int(value)) mg/dL")
              .font(.system(size: 30, weight: .bold))
            Text(timestamp, style: .time)
              .font(.system(size: 16))
            Link(destination: URL(string: "la://my.app/glucose")!) {
              Text("See details")
                .font(.system(size: 12))
                .padding(.vertical, 3)
                .padding(.horizontal, 8)
                .background(Color.blue.opacity(0.6))
                .cornerRadius(6)
            }
          }
        }
      } compactLeading: {
        Text(emoji)
      } compactTrailing: {
        Text("\(Int(value))")
          .font(.system(size: 20, weight: .bold))
      } minimal: {
        Text(emoji)
      }
    }
  }
}

extension LiveActivitiesAppAttributes {
  func prefixedKey(_ key: String) -> String {
    return "\(id)_\(key)"
  }
}