//
//  ContentView.swift
//  Monitoring
//
//  Created by Чаусов Николай on 18.11.2022.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var monitoringModel = MonitoringModel()
    
    
    var body: some View {
        VStack {
            Text("\(monitoringModel.freeStorage)")
            Text("\(monitoringModel.allStorage)")
            Text("\(monitoringModel.totalRamValue)")
            Text("\(monitoringModel.cores)")
            Text("\(monitoringModel.activeCores)")
            Text("\(monitoringModel.lastRestartTime)")
            Text("\(monitoringModel.thermalState)")
        }
        .padding()
        .onAppear { monitoringModel.getStorage() }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
