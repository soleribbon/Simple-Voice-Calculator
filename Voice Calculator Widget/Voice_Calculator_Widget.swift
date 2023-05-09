//
//  Voice_Calculator_Widget.swift
//  Voice Calculator Widget
//
//  Created by Ravi  on 5/7/23.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationIntent())
    }
    
    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), configuration: configuration)
        completion(entry)
    }
    
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        
        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
}

struct Voice_Calculator_WidgetEntryView : View {
    var entry: Provider.Entry
    //    print entry.date
    
    @Environment(\.widgetFamily) var family
    var body: some View {
        
        ZStack {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(#colorLiteral(red: 0, green: 0.3116666078567505, blue: 0.9166666865348816, alpha: 1)), location: 0),
                    .init(color: Color(#colorLiteral(red: 0, green: 0.318346232175827, blue: 0.7958658933639526, alpha: 1)), location: 1)]),
                startPoint: UnitPoint(x: 0.6904957050526239, y: 5.502360664322303e-9),
                endPoint: UnitPoint(x: 0.5000000596046452, y: 1.0000000113544252))
            
            switch family {
                
                
            case .systemSmall:
                VStack {
                    Text("Input Equation")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.4)
                    
                        .padding(.horizontal)
                    Text("+ - × ÷")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .minimumScaleFactor(0.4)
                    Button(action: {
                        
                    }, label: {
                        Image(systemName: "mic.fill")
                            .padding()
                            .font(.title)
                            .foregroundColor(.white)
                            .opacity(0.9)
                            .overlay(
                                Circle()
                                    .stroke(Color(#colorLiteral(red: 0, green: 0.230, blue: 0.67, alpha: 1)), lineWidth: 2)
                                
                            ).background(
                                Circle()
                                    .fill(Color(#colorLiteral(red: 0, green: 0.378, blue: 0.945, alpha: 1)))
                                    .shadow(color: Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.1)), radius:12, x:0, y:4)
                            )
                        
                        
                    })
                }
                .padding()
                .widgetURL(URL(string: "calculator:///recordLink"))
                
            case .systemMedium:
                VStack {
                    Spacer()
                    Text("Simple Voice Calculator")
                        .padding()
                        .bold()
                        .font(.title2)
                        .minimumScaleFactor(0.4)
                    
                        .foregroundColor(.white)               .opacity(0.6)
                    
                    HStack (alignment: .center){
                        
                        
                        
                        Link(destination: URL(string: "calculator:///inputLink")!, label: {
                            
                            Text("Input Equation")
                                .font(.body)
                                .minimumScaleFactor(0.4)
                                .foregroundColor(.white)               .opacity(0.75)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(#colorLiteral(red: 0, green: 0.230, blue: 0.67, alpha: 1)), lineWidth: 2)
                                    
                                ).background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(#colorLiteral(red: 0, green: 0.378333181142807, blue: 0.9458333253860474, alpha: 1)))
                                        .shadow(color: Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.1)), radius:12, x:0, y:4)
                                )
                                .fontWeight(.bold)
                            
                            
                        })
                        Link(destination: URL(string: "calculator:///recordLink")!, label: {
                            Image(systemName: "mic.fill")
                                .padding()
                                .font(.title)
                                .foregroundColor(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.75)))
                                .overlay(
                                    Circle()
                                    
                                        .stroke(Color(#colorLiteral(red: 0, green: 0.230, blue: 0.67, alpha: 1)), lineWidth: 2)
                                    
                                ).background(
                                    Circle()
                                        .fill(Color(#colorLiteral(red: 0, green: 0.378333181142807, blue: 0.9458333253860474, alpha: 1)))
                                        .shadow(color: Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.1)), radius:12, x:0, y:4)
                                    
                                )
                            
                            
                        })
                        
                    }
                    .padding(.horizontal)
                    Spacer()
                }
                
                
                
                
            case .systemLarge:
                VStack (spacing: 10){
                    HStack (alignment: .center){
                        
                        
                        Text("Simple Voice Calculator")
                            .bold()
                            .font(.title2)
                            .minimumScaleFactor(0.4)
                            .foregroundColor(.white)
                            .opacity(0.6)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                    
                    Link(destination: URL(string: "calculator:///inputLink")!, label: {
                        Text("Input Equation")
                            .fontWeight(.bold)
                            .font(.title2)
                            .foregroundColor(.white)
                            .opacity(0.75)
                            .minimumScaleFactor(0.4)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(#colorLiteral(red: 0, green: 0.230, blue: 0.67, alpha: 1)), lineWidth: 2)
                                
                            ).background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(#colorLiteral(red: 0, green: 0.378, blue: 0.945, alpha: 1)))
                                    .shadow(color: Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.1)), radius:12, x:0, y:4)
                            )
                        
                    })
                    
                    Text("OR")
                        .bold()
                        .font(.caption)
                        .opacity(0.5)
                    
                    Link(destination: URL(string: "calculator:///recordLink")!, label: {
                        HStack {
                            Image(systemName: "mic.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .opacity(0.75)
                            
                            Text("Voice Input")
                                .minimumScaleFactor(0.4)
                                .bold()
                                .font(.title2)
                                .foregroundColor(.white)
                                .opacity(0.75)
                            
                            
                            
                            
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        
                        
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(#colorLiteral(red: 0, green: 0.230, blue: 0.67, alpha: 1)), lineWidth: 2)
                            
                        ).background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(#colorLiteral(red: 0, green: 0.378, blue: 0.945, alpha: 1)))
                                .shadow(color: Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.1)), radius:12, x:0, y:4)
                        )
                        
                        
                        
                    })
                    Spacer()
                }.padding()
                
                
                
                
                
            default:
                VStack {
                    Link(destination: URL(string: "calculator:///inputLink")!, label: {
                        Text("Input Equation")
                            .font(.title2)
                            .opacity(0.9)
                            .minimumScaleFactor(0.4)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(#colorLiteral(red: 0, green: 0.230, blue: 0.67, alpha: 1)), lineWidth: 2)
                                
                            ).background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.white)
                                    .shadow(color: Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.1)), radius:12, x:0, y:4)
                            )
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        
                    })
                    Spacer()
                    Link(destination: URL(string: "calculator:///recordLink")!, label: {
                        Image(systemName: "mic.fill")
                            .padding()
                            .font(.title)
                            .foregroundColor(Color(#colorLiteral(red: 0, green: 0.32, blue: 0.9, alpha: 1)))
                            .overlay(
                                Circle()
                                    .stroke(Color(#colorLiteral(red: 0, green: 0.230, blue: 0.67, alpha: 1)), lineWidth: 2)
                                
                            ).background(
                                Circle()
                                    .fill(.white)
                                    .shadow(color: Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.1)), radius:12, x:0, y:4)
                            )
                        
                        
                    })
                }.padding()
                
            }
        }
    }
}

struct Voice_Calculator_Widget: Widget {
    let kind: String = "Voice_Calculator_Widget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            Voice_Calculator_WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Voice Calculator Widget")
        .description("Input equations instantly.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
        ])
    }
}

struct Voice_Calculator_Widget_Previews: PreviewProvider {
    static var previews: some View {
        Voice_Calculator_WidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        Voice_Calculator_WidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        Voice_Calculator_WidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
